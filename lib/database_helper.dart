import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'series.dart';

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
    final initialSeries = [
      Series(
        title: 'Breaking Bad',
        trama: 'Walter White, un professore di chimica delle superiori che si trasforma in un produttore di metanfetamine dopo aver scoperto di avere un cancro ai polmoni.',
        genere: 'Drammatico, Crime',
        stato: 'Da guardare',
        piattaforma: 'Netflix',
        imageUrl: 'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
      ),
      Series(
        title: 'Stranger Things',
        trama: 'Quando un ragazzo scompare, la sua città natale si ritrova al centro di un mistero che coinvolge esperimenti governativi segreti, forze soprannaturali terrificanti e una ragazzina molto strana.',
        genere: 'Sci-Fi, Horror',
        stato: 'Da guardare',
        piattaforma: 'Netflix',
        imageUrl: 'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg',
      ),
      Series(
        title: 'The Mandalorian',
        trama: 'Le avventure di un cacciatore di taglie mandaloriano nei confini esterni della galassia, lontano dall\'autorità della Nuova Repubblica.',
        genere: 'Sci-Fi, Avventura',
        stato: 'Da guardare',
        piattaforma: 'Disney+',
        imageUrl: 'https://image.tmdb.org/t/p/w500/sWgBv7LV2PRoQgkxwlibdGXKz1S.jpg',
      ),
      Series(
        title: 'House of the Dragon',
        trama: 'La saga della Casa Targaryen ambientata 200 anni prima degli eventi de Il Trono di Spade.',
        genere: 'Fantasy, Drammatico',
        stato: 'Da guardare',
        piattaforma: 'HBO Max',
        imageUrl: 'https://image.tmdb.org/t/p/w500/z2yahl2uefxDCl0nogcRBstwruJ.jpg',
      ),
      Series(
        title: 'Wednesday',
        trama: 'Segue Wednesday Addams come studentessa alla Nevermore Academy, dove tenta di padroneggiare le sue abilità psichiche emergenti.',
        genere: 'Commedia, Horror',
        stato: 'Da guardare',
        piattaforma: 'Netflix',
        imageUrl: 'https://image.tmdb.org/t/p/w500/9PFonBhy4cQy7Jz20NpMygczOkv.jpg',
      ),
      Series(
        title: 'The Boys',
        trama: 'Un gruppo di vigilanti si propone di abbattere dei supereroi corrotti che abusano delle loro superpotenze.',
        genere: 'Azione, Drammatico',
        stato: 'Da guardare',
        piattaforma: 'Prime Video',
        imageUrl: 'https://image.tmdb.org/t/p/w500/stTEycfG9928HYGEISBFaG1ngjM.jpg',
      ),
    ];

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