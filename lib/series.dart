import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Season {
  final int seasonNumber;
  String name;
  final List<Episode> episodes;
  bool isCompleted;

  Season({
    required this.seasonNumber,
    required this.name,
    required this.episodes,
    this.isCompleted = false,
  });

  void updateCompletionStatus() {
    isCompleted = episodes.isNotEmpty && 
        episodes.every((episode) => episode.watched);
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonNumber': seasonNumber,
      'name': name,
      'episodes': episodes.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Season.fromMap(Map<String, dynamic> map) {
    return Season(
      seasonNumber: map['seasonNumber'] ?? 1,
      name: map['name'] ?? 'Stagione ${map['seasonNumber'] ?? 1}',
      episodes: List<Episode>.from(
          (map['episodes'] as List?)?.map((x) => Episode.fromMap(x)) ?? []),
      isCompleted: (map['isCompleted'] ?? 0) == 1,
    );
  }
}

class Episode {
  final int episodeNumber;
  String title;
  bool watched;

  Episode({
    required this.episodeNumber,
    required this.title,
    this.watched = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'episodeNumber': episodeNumber,
      'title': title,
      'watched': watched ? 1 : 0,
    };
  }

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      episodeNumber: map['episodeNumber'] ?? 1,
      title: map['title'] ?? 'Episodio ${map['episodeNumber'] ?? 1}',
      watched: (map['watched'] ?? 0) == 1,
    );
  }
}

class Series {
  final int? id;
  final String imageUrl;
  final String title;
  final String trama;
  final String genere;
  final String stato;
  final String piattaforma;
  final bool isFavorite;
  final List<Season> seasons;
  final DateTime? dateAdded;
  final DateTime? dateCompleted; // Nuovo campo per tracciare il completamento

  const Series({
    this.id,
    required this.imageUrl,
    required this.title,
    required this.trama,
    required this.genere,
    required this.stato,
    required this.piattaforma,
    this.isFavorite = false,
    this.seasons = const [],
    this.dateAdded,
    this.dateCompleted, // Aggiunto al costruttore
  });

  int get totalEpisodes {
    return seasons.fold(0, (sum, season) => sum + season.episodes.length);
  }

  int get watchedEpisodes {
    return seasons.fold(0, (sum, season) {
      return sum + season.episodes.where((e) => e.watched).length;
    });
  }

  bool get allSeasonsCompleted {
    return seasons.isNotEmpty && seasons.every((season) => season.isCompleted);
  }

  double get completionPercentage {
    if (totalEpisodes == 0) return 0.0;
    return (watchedEpisodes / totalEpisodes) * 100;
  }

  bool get isCompleted => totalEpisodes > 0 && watchedEpisodes >= totalEpisodes;

  bool get isLocalImage {
    return imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http') &&
        !imageUrl.contains('/');
  }

  bool get isRemoteImage {
    return imageUrl.startsWith('http');
  }

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
    List<Season>? seasons,
    DateTime? dateAdded,
    DateTime? dateCompleted, // Aggiunto al copyWith
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
      seasons: seasons ?? this.seasons,
      dateAdded: dateAdded ?? this.dateAdded,
      dateCompleted: dateCompleted ?? this.dateCompleted, // Copiato
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
      'seasons': jsonEncode(seasons.map((s) => s.toMap()).toList()),
      'dateAdded': dateAdded?.millisecondsSinceEpoch,
      'dateCompleted': dateCompleted?.millisecondsSinceEpoch, // Aggiunto
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
      seasons: map['seasons'] != null
          ? (jsonDecode(map['seasons']) as List)
              .map((s) => Season.fromMap(s))
              .toList()
          : [],
      dateAdded: map['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateAdded'] as int)
          : null,
      dateCompleted: map['dateCompleted'] != null // Aggiunto
          ? DateTime.fromMillisecondsSinceEpoch(map['dateCompleted'] as int)
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
  seasons: ${seasons.length},
  dateAdded: ${dateAdded?.toIso8601String()},
  dateCompleted: ${dateCompleted?.toIso8601String()},
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
            seasons.length == other.seasons.length &&
            dateAdded == other.dateAdded &&
            dateCompleted == other.dateCompleted); // Aggiunto
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
      seasons.length,
      dateAdded,
      dateCompleted, // Aggiunto
    );
  }
}