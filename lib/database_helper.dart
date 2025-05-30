import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'series.dart';
import 'initial_series.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  static const int _currentVersion = 1; // Versione unica

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'series_database.db');
    
    return openDatabase(
      path,
      onCreate: _onCreate,
      version: _currentVersion,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabella principale delle serie
    await db.execute('''
      CREATE TABLE series(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imageUrl TEXT NOT NULL,
        title TEXT NOT NULL,
        trama TEXT NOT NULL,
        genere TEXT NOT NULL,
        stato TEXT NOT NULL,
        piattaforma TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        seasons TEXT NOT NULL DEFAULT '[]',
        dateAdded INTEGER,
        dateCompleted INTEGER
      )
    ''');
    
    // Tabella per generi personalizzati
    await db.execute('''
      CREATE TABLE custom_genres(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');
    
    // Tabella per piattaforme personalizzate
    await db.execute('''
      CREATE TABLE custom_platforms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');
    
    // Tabella per l'associazione serie-categorie
    await db.execute('''
      CREATE TABLE custom_category_series(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL,
        series_id INTEGER NOT NULL,
        is_genre INTEGER NOT NULL,
        FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
      )
    ''');
    
    // Inserisci i dati iniziali
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    for (final series in initialSeries) {
      await insertSeries(series, db: db);
    }

    print('Database popolato con ${initialSeries.length} serie iniziali');
  }

  Future<int> insertSeries(Series series, {Database? db}) async {
    final database = db ?? await this.database;
    return await database.insert(
      'series',
      series.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Series>> getAllSeries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('series');
    return maps.map(Series.fromMap).toList();
  }

  Future<List<Series>> getFavoriteSeries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return maps.map(Series.fromMap).toList();
  }

  Future<Series?> getSeriesById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Series.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSeries(Series series) async {
    final db = await database;
    return await db.update(
      'series',
      series.toMap(),
      where: 'id = ?',
      whereArgs: [series.id],
    );
  }

  Future<int> deleteSeries(int id) async {
    final db = await database;
    return await db.delete(
      'series',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateFavoriteStatus(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'series',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistiche avanzate
  Future<List<Series>> getSeriesCompletedBetween(DateTime start, DateTime end) async {
    final db = await database;
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'dateCompleted >= ? AND dateCompleted <= ?',
      whereArgs: [startMillis, endMillis],
    );
    
    return maps.map(Series.fromMap).toList();
  }

  Future<List<Series>> getSeriesAddedBetween(DateTime start, DateTime end) async {
    final db = await database;
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'dateAdded >= ? AND dateAdded <= ?',
      whereArgs: [startMillis, endMillis],
    );
    
    return maps.map(Series.fromMap).toList();
  }

  Future<int> getTotalCompletedSeries() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM series WHERE dateCompleted IS NOT NULL'
    ));
    return count ?? 0;
  }

  Future<int> getTotalInProgressSeries() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM series WHERE stato = ?',
      ['In corso']
    ));
    return count ?? 0;
  }

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final db = await database;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    final completed = await getSeriesCompletedBetween(firstDay, lastDay);
    final added = await getSeriesAddedBetween(firstDay, lastDay);
    
    return {
      'completed': completed.length,
      'added': added.length,
      'completedDetails': completed,
      'addedDetails': added,
    };
  }

  Future<Map<String, dynamic>> getWeeklyStats(DateTime referenceDate) async {
    final start = referenceDate.subtract(const Duration(days: 7));
    final end = referenceDate;
    
    final completed = await getSeriesCompletedBetween(start, end);
    final added = await getSeriesAddedBetween(start, end);
    
    return {
      'completed': completed.length,
      'added': added.length,
      'completedDetails': completed,
      'addedDetails': added,
    };
  }

  Future<Map<String, dynamic>> getPlatformStats() async {
    final db = await database;
    final platformMap = <String, int>{};
    
    final platforms = await db.rawQuery(
      'SELECT piattaforma, COUNT(*) as count FROM series GROUP BY piattaforma'
    );
    
    for (final platform in platforms) {
      platformMap[platform['piattaforma'] as String] = platform['count'] as int;
    }
    
    return platformMap;
  }

  Future<List<Series>> getRandomSuggestions({int limit = 8}) async {
    final db = await database;
    
    // Query per ottenere serie casuali
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM series ORDER BY RANDOM() LIMIT ?',
      [limit],
    );
    
    return List.generate(maps.length, (i) => Series.fromMap(maps[i]));
  }

  // Suggerimenti basati su generi delle serie preferite
  Future<List<Series>> getSmartSuggestions({int limit = 8}) async {
    final db = await database;

    // Trova i generi delle serie preferite
    final favoriteGenres = await db.rawQuery('''
      SELECT DISTINCT genere FROM series WHERE isFavorite = 1
    ''');

    if (favoriteGenres.isEmpty) {
      // Se non ci sono preferiti, restituisci casuali
      return getRandomSuggestions(limit: limit);
    }

    // Costruisci condizioni LIKE per ogni genere preferito
    final likeClauses = <String>[];
    final args = <dynamic>[];
    for (final g in favoriteGenres) {
      final genre = g['genere'] as String;
      // Se ci sono più generi separati da virgola, splitta e aggiungi tutti
      for (final singleGenre in genre.split(',')) {
        final trimmed = singleGenre.trim();
        if (trimmed.isNotEmpty) {
          likeClauses.add("genere LIKE ?");
          args.add('%$trimmed%');
        }
      }
    }

    if (likeClauses.isEmpty) {
      return getRandomSuggestions(limit: limit);
    }

    // Costruisci la query finale
    final whereClause = likeClauses.join(' OR ');
    args.add(limit);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM series 
      WHERE ($whereClause)
      AND isFavorite = 0 
      ORDER BY RANDOM() 
      LIMIT ?
      ''',
      args,
    );

    return List.generate(maps.length, (i) => Series.fromMap(maps[i]));
  }

  // DEBUG UTILITIES
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'series_database.db');
    print('Database path: $path');
    return path;
  }

  Future<void> printAllSeries() async {
    final series = await getAllSeries();
    print('=== DATABASE CONTENT ===');
    print('Total series: ${series.length}');
    for (var s in series) {
      print(s.toString());
      for (var season in s.seasons) {
        print('  Season ${season.seasonNumber}: ${season.name}');
        for (var episode in season.episodes) {
          print('    Episode ${episode.episodeNumber}: ${episode.title} - Watched: ${episode.watched}');
        }
      }
    }
    print('========================');
  }

  // Metodi per gestire generi personalizzati
  Future<List<String>> getCustomGenres() async {
    final db = await database;
    
    // Controlla se la tabella esiste
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_genres'");
    
    if (tables.isEmpty) {
      // Crea la tabella se non esiste
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_genres(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE
        )
      ''');
      return [];
    }
    
    final result = await db.query('custom_genres');
    return result.map((row) => row['name'] as String).toList();
  }

  Future<List<String>> getCustomPlatforms() async {
    final db = await database;
    
    // Controlla se la tabella esiste
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_platforms'");
    
    if (tables.isEmpty) {
      // Crea la tabella se non esiste
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_platforms(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE
        )
      ''');
      return [];
    }
    
    final result = await db.query('custom_platforms');
    return result.map((row) => row['name'] as String).toList();
  }

  // Metodi per aggiungere categorie personalizzate
  Future<int> addCustomGenre(String name) async {
    final db = await database;
    
    // Assicurati che la tabella esista
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_genres(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');
    
    return await db.insert(
      'custom_genres',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora se esiste già
    );
  }

  Future<int> addCustomPlatform(String name) async {
    final db = await database;
    
    // Assicurati che la tabella esista
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_platforms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');
    
    return await db.insert(
      'custom_platforms',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora se esiste già
    );
  }

  // Metodi per gestire l'associazione delle serie alle categorie personalizzate
  Future<void> deleteCustomGenre(String name) async {
    final db = await database;
    await db.delete('custom_genres', where: 'name = ?', whereArgs: [name]);
    // Elimina anche le associazioni nella tabella di collegamento
    await db.delete('custom_category_series', where: 'category_name = ? AND is_genre = 1', whereArgs: [name]);
  }

  Future<void> deleteCustomPlatform(String name) async {
    final db = await database;
    await db.delete('custom_platforms', where: 'name = ?', whereArgs: [name]);
    // Elimina anche le associazioni nella tabella di collegamento
    await db.delete('custom_category_series', where: 'category_name = ? AND is_genre = 0', whereArgs: [name]);
  }

  Future<List<int>> getSeriesInCustomCategory(String categoryName, bool isGenre) async {
    final db = await database;
    
    // Controlla se la tabella esiste
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_category_series'");
    
    if (tables.isEmpty) {
      // Crea la tabella se non esiste
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_category_series(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_name TEXT NOT NULL,
          series_id INTEGER NOT NULL,
          is_genre INTEGER NOT NULL,
          FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
        )
      ''');
      return [];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_category_series',
      where: 'category_name = ? AND is_genre = ?',
      whereArgs: [categoryName, isGenre ? 1 : 0],
    );
    return List.generate(maps.length, (i) => maps[i]['series_id']);
  }

  Future<void> updateCustomCategorySeries(String categoryName, bool isGenre, List<int> seriesIds) async {
    final db = await database;
    
    // Assicurati che la tabella esista
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_category_series(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL,
        series_id INTEGER NOT NULL,
        is_genre INTEGER NOT NULL,
        FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
      )
    ''');
    
    // Rimuovi tutte le serie esistenti per questa categoria
    await db.delete(
      'custom_category_series',
      where: 'category_name = ? AND is_genre = ?',
      whereArgs: [categoryName, isGenre ? 1 : 0],
    );
    
    // Aggiungi le nuove serie
    for (final seriesId in seriesIds) {
      await db.insert('custom_category_series', {
        'category_name': categoryName,
        'series_id': seriesId,
        'is_genre': isGenre ? 1 : 0,
      });
    }
  }

  Future<void> addSeriesToCustomCategory(String categoryName, bool isGenre, int seriesId) async {
    final db = await database;
    
    // Assicurati che la tabella esista
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_category_series(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL,
        series_id INTEGER NOT NULL,
        is_genre INTEGER NOT NULL,
        FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
      )
    ''');
    
    await db.insert('custom_category_series', {
      'category_name': categoryName,
      'series_id': seriesId,
      'is_genre': isGenre ? 1 : 0,
    });
  }

  Future<void> removeSeriesFromCustomCategory(String categoryName, bool isGenre, int seriesId) async {
    final db = await database;
    await db.delete(
      'custom_category_series',
      where: 'category_name = ? AND is_genre = ? AND series_id = ?',
      whereArgs: [categoryName, isGenre ? 1 : 0, seriesId],
    );
  }

  // Metodo per pulire il database dalle dipendenze orfane
  Future<void> cleanOrphanedCategoryEntries() async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM custom_category_series 
      WHERE series_id NOT IN (SELECT id FROM series)
    ''');
  }
}

// Estensione per mappe indicizzate
extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index, element);
      index++;
    }
  }
}