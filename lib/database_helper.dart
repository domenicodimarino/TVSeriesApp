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
      onCreate: (db, version) {
        return db.execute(
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
      },
      version: 1,
    );
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