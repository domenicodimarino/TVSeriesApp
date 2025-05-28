import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'series.dart';
import 'initial_series.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  static const int _currentVersion = 2; // Versione corrente del database

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
    // Aggiungi qui ulteriori migrazioni per versioni future
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
        totalEpisodes INTEGER NOT NULL DEFAULT 1,
        watchedEpisodes INTEGER NOT NULL DEFAULT 0,
        lastWatched INTEGER,
        dateAdded INTEGER
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

  Future<int> updateWatchedEpisodes(int id, int watchedEpisodes) async {
    final db = await database;
    return await db.update(
      'series',
      {
        'watchedEpisodes': watchedEpisodes,
        'lastWatched': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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
    }
    print('========================');
  }
}