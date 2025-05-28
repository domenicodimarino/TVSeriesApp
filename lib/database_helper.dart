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

  static const int _currentVersion = 4; // Aggiornata a 4 per le nuove funzionalità

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'series_database.db');
    
    return openDatabase(
      path,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      version: _currentVersion,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _upgradeToVersion2(db);
    }
    if (oldVersion < 3) {
      await _upgradeToVersion3(db);
    }
    if (oldVersion < 4) {
      await _upgradeToVersion4(db);
    }
  }

  Future<void> _createTables(Database db) async {
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
  }

  Future<void> _upgradeToVersion2(Database db) async {
    await db.execute('''
      ALTER TABLE series ADD COLUMN totalEpisodes INTEGER NOT NULL DEFAULT 1
    ''');
    
    await db.execute('''
      ALTER TABLE series ADD COLUMN watchedEpisodes INTEGER NOT NULL DEFAULT 0
    ''');
    
    await db.execute('''
      ALTER TABLE series ADD COLUMN lastWatched INTEGER
    ''');
    
    await db.execute('''
      ALTER TABLE series ADD COLUMN dateAdded INTEGER
    ''');
    
    print('Database aggiornato alla versione 2');
  }

  Future<void> _upgradeToVersion3(Database db) async {
    await db.execute('ALTER TABLE series ADD COLUMN seasons TEXT DEFAULT \'[]\'');
    
    try {
      await db.execute('ALTER TABLE series DROP COLUMN totalEpisodes');
      await db.execute('ALTER TABLE series DROP COLUMN watchedEpisodes');
      await db.execute('ALTER TABLE series DROP COLUMN lastWatched');
    } catch (e) {
      print("Ignorato errore rimozione colonne obsolete: $e");
    }
    
    print('Database aggiornato alla versione 3 con supporto stagioni/episodi');
  }

  Future<void> _upgradeToVersion4(Database db) async {
    await db.execute('ALTER TABLE series ADD COLUMN dateCompleted INTEGER');
    print('Database aggiornato alla versione 4 con supporto statistiche avanzate');
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