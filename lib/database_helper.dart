import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'series.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'series_database.db'),
      onCreate: (db, version) async {
        // Prima crea la tabella
        await db.execute(
          '''CREATE TABLE series(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imageUrl TEXT NOT NULL,
            title TEXT NOT NULL,
            trama TEXT NOT NULL,
            genere TEXT NOT NULL,
            stato TEXT NOT NULL,
            piattaforma TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )''',
        );
        
        // Poi popola con i dati iniziali
        await _insertInitialData(db);
      },
      version: 1,
    );
  }

  // Metodo per inserire i dati iniziali
  Future<void> _insertInitialData(Database db) async {
    final List<Map<String, dynamic>> initialSeries = [
      {
        'title': 'Breaking Bad',
        'trama': 'Walter White, un professore di chimica delle superiori che si trasforma in un produttore di metanfetamine dopo aver scoperto di avere un cancro ai polmoni.',
        'genere': 'Drammatico, Crime',
        'stato': 'Da guardare',
        'piattaforma': 'Netflix',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
        'isFavorite': 0,
      },
      {
        'title': 'Stranger Things',
        'trama': 'Quando un ragazzo scompare, la sua città natale si ritrova al centro di un mistero che coinvolge esperimenti governativi segreti, forze soprannaturali terrificanti e una ragazzina molto strana.',
        'genere': 'Sci-Fi, Horror',
        'stato': 'Da guardare',
        'piattaforma': 'Netflix',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg',
        'isFavorite': 0,
      },
      {
        'title': 'The Mandalorian',
        'trama': 'Le avventure di un cacciatore di taglie mandaloriano nei confini esterni della galassia, lontano dall\'autorità della Nuova Repubblica.',
        'genere': 'Sci-Fi, Avventura',
        'stato': 'Da guardare',
        'piattaforma': 'Disney+',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/sWgBv7LV2PRoQgkxwlibdGXKz1S.jpg',
        'isFavorite': 0,
      },
      {
        'title': 'House of the Dragon',
        'trama': 'La saga della Casa Targaryen ambientata 200 anni prima degli eventi de Il Trono di Spade.',
        'genere': 'Fantasy, Drammatico',
        'stato': 'Da guardare',
        'piattaforma': 'HBO Max',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/z2yahl2uefxDCl0nogcRBstwruJ.jpg',
        'isFavorite': 0,
      },
      {
        'title': 'Wednesday',
        'trama': 'Segue Wednesday Addams come studentessa alla Nevermore Academy, dove tenta di padroneggiare le sue abilità psichiche emergenti.',
        'genere': 'Commedia, Horror',
        'stato': 'Da guardare',
        'piattaforma': 'Netflix',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/9PFonBhy4cQy7Jz20NpMygczOkv.jpg',
        'isFavorite': 0,
      },
      {
        'title': 'The Boys',
        'trama': 'Un gruppo di vigilanti si propone di abbattere dei supereroi corrotti che abusano delle loro superpotenze.',
        'genere': 'Azione, Drammatico',
        'stato': 'Da guardare',
        'piattaforma': 'Prime Video',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/stTEycfG9928HYGEISBFaG1ngjM.jpg',
        'isFavorite': 0,
      },
    ];

    // Inserisce ogni serie nel database
    for (final series in initialSeries) {
      await db.insert('series', series, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    print('Database popolato con ${initialSeries.length} serie iniziali');
  }

  Future<int> insertSeries(Series series) async {
    final db = await database;
    return await db.insert(
      'series',
      series.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Series>> getAllSeries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('series');
    return List.generate(maps.length, (i) => Series.fromMap(maps[i]));
  }

  Future<List<Series>> getFavoriteSeries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Series.fromMap(maps[i]));
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

  // Elimina una serie dal database
  Future<int> deleteSeries(int id) async {
    Database db = await instance.database;
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

//METODI DI DEBUG PER IL DB

  // Metodo per ottenere il percorso completo del database
  Future<String> getDatabasePath() async {
    final path = join(await getDatabasesPath(), 'series_database.db');
    print('Database path: $path');
    return path;
  }

  // Metodo per stampare tutte le serie nel debug console
  Future<void> printAllSeries() async {
    final series = await getAllSeries();
    print('=== DATABASE CONTENT ===');
    print('Total series: ${series.length}');
    for (var s in series) {
      print('ID: ${s.id}, Title: ${s.title}, Favorite: ${s.isFavorite}');
    }
    print('========================');
  }
}