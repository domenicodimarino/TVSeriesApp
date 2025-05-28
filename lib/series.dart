import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class Series {
  final int? id;
  final String imageUrl;
  final String title;
  final String trama;
  final String genere;
  final String stato;
  final String piattaforma;
  final bool isFavorite;

  const Series({
    this.id,
    required this.imageUrl,
    required this.title,
    required this.trama,
    required this.genere,
    required this.stato,
    required this.piattaforma,
    this.isFavorite = false,
  });

  /// Determina se l'immagine è locale
  bool get isLocalImage {
    return imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http') &&
        !imageUrl.contains('/'); // Solo nome file, non percorso
  }

  /// Determina se l'immagine è remota (URL)
  bool get isRemoteImage {
    return imageUrl.startsWith('http');
  }

  /// Ottiene il percorso completo dell'immagine locale
  Future<String> getLocalImagePath() async {
    if (!isLocalImage) return imageUrl;

    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'images', imageUrl);
  }

  /// Crea una copia dell'oggetto Series con i campi specificati sovrascritti
  Series copyWith({
    int? id,
    String? imageUrl,
    String? title,
    String? trama,
    String? genere,
    String? stato,
    String? piattaforma,
    bool? isFavorite,
  }) {
    return Series(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      trama: trama ?? this.trama,
      genere: genere ?? this.genere,
      stato: stato ?? this.stato,
      piattaforma: piattaforma ?? this.piattaforma,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Converte l'oggetto Series in una mappa per il database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'trama': trama,
      'genere': genere,
      'stato': stato,
      'piattaforma': piattaforma,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// Crea un oggetto Series da una mappa del database
  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'] as int?,
      imageUrl: map['imageUrl'] as String,
      title: map['title'] as String,
      trama: map['trama'] as String,
      genere: map['genere'] as String,
      stato: map['stato'] as String,
      piattaforma: map['piattaforma'] as String,
      isFavorite: (map['isFavorite'] as int) == 1,
    );
  }

  /// Override del metodo toString per il debugging
  @override
  String toString() {
    return '''
Series {
  id: $id,
  title: "$title",
  imageUrl: "$imageUrl",
  genere: "$genere",
  stato: "$stato",
  piattaforma: "$piattaforma",
  isFavorite: $isFavorite
}''';
  }

  /// Override dell'operatore di uguaglianza per il confronto degli oggetti
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Series &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            imageUrl == other.imageUrl &&
            title == other.title &&
            trama == other.trama &&
            genere == other.genere &&
            stato == other.stato &&
            piattaforma == other.piattaforma &&
            isFavorite == other.isFavorite);
  }

  /// Override di hashCode per il corretto funzionamento delle collezioni
  @override
  int get hashCode {
    return Object.hash(
      id,
      imageUrl,
      title,
      trama,
      genere,
      stato,
      piattaforma,
      isFavorite,
    );
  }
}