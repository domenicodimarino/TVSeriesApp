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
  final int totalEpisodes;
  final int watchedEpisodes;
  final DateTime? lastWatched;
  final DateTime? dateAdded;

  const Series({
    this.id,
    required this.imageUrl,
    required this.title,
    required this.trama,
    required this.genere,
    required this.stato,
    required this.piattaforma,
    this.isFavorite = false,
    this.totalEpisodes = 1,
    this.watchedEpisodes = 0,
    this.lastWatched,
    this.dateAdded,
  });

  bool get isLocalImage {
    return imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http') &&
        !imageUrl.contains('/');
  }

  bool get isRemoteImage {
    return imageUrl.startsWith('http');
  }

  double get completionPercentage {
    if (totalEpisodes == 0) return 0.0;
    return (watchedEpisodes / totalEpisodes) * 100;
  }

  bool get isCompleted => watchedEpisodes >= totalEpisodes;

  Future<String> getLocalImagePath() async {
    if (!isLocalImage) return imageUrl;
    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'images', imageUrl);
  }

  Series copyWith({
    int? id,
    String? imageUrl,
    String? title,
    String? trama,
    String? genere,
    String? stato,
    String? piattaforma,
    bool? isFavorite,
    int? totalEpisodes,
    int? watchedEpisodes,
    DateTime? lastWatched,
    DateTime? dateAdded,
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
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      lastWatched: lastWatched ?? this.lastWatched,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

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
      'totalEpisodes': totalEpisodes,
      'watchedEpisodes': watchedEpisodes,
      'lastWatched': lastWatched?.millisecondsSinceEpoch,
      'dateAdded': dateAdded?.millisecondsSinceEpoch,
    };
  }

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
      totalEpisodes: map['totalEpisodes'] as int? ?? 1,
      watchedEpisodes: map['watchedEpisodes'] as int? ?? 0,
      lastWatched: map['lastWatched'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWatched'] as int)
          : null,
      dateAdded: map['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateAdded'] as int)
          : null,
    );
  }

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
  isFavorite: $isFavorite,
  totalEpisodes: $totalEpisodes,
  watchedEpisodes: $watchedEpisodes,
  lastWatched: ${lastWatched?.toIso8601String()},
  dateAdded: ${dateAdded?.toIso8601String()},
  completionPercentage: ${completionPercentage.toStringAsFixed(1)}%
}''';
  }

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
            isFavorite == other.isFavorite &&
            totalEpisodes == other.totalEpisodes &&
            watchedEpisodes == other.watchedEpisodes &&
            lastWatched == other.lastWatched &&
            dateAdded == other.dateAdded);
  }

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
      totalEpisodes,
      watchedEpisodes,
      lastWatched,
      dateAdded,
    );
  }
}