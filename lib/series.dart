import 'package:sqflite/sqflite.dart';

class Series {
  final int? id; // Nullable per nuove serie
  final String imageUrl;
  final String title;
  final String trama;
  final String genere;
  final String stato;
  final String piattaforma;

  const Series({
    this.id,
    required this.imageUrl,
    required this.title,
    required this.trama,
    required this.genere,
    required this.stato,
    required this.piattaforma,
  });

  // Conversione per database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'trama': trama,
      'genere': genere,
      'stato': stato,
      'piattaforma': piattaforma,
    };
  }

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'],
      imageUrl: map['imageUrl'],
      title: map['title'],
      trama: map['trama'],
      genere: map['genere'],
      stato: map['stato'],
      piattaforma: map['piattaforma'],
    );
  }
}