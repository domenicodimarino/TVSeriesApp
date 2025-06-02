import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'series.dart';

class SeasonEpisodeScreen extends StatefulWidget {
  final Series series;
  final Function(Series) onSave;

  const SeasonEpisodeScreen({
    super.key,
    required this.series,
    required this.onSave,
  });

  @override
  _SeasonEpisodeScreenState createState() => _SeasonEpisodeScreenState();
}

class _SeasonEpisodeScreenState extends State<SeasonEpisodeScreen> {
  late Series editedSeries;
  final List<TextEditingController> _seasonNameControllers = [];
  final List<List<TextEditingController>> _episodeTitleControllers = [];

  @override
  void initState() {
    super.initState();
    editedSeries = widget.series;
    // Controller per i nomi delle stagioni
    _seasonNameControllers.addAll(
      editedSeries.seasons.map(
        (season) => TextEditingController(text: season.name)
      )
    );
    // Controller per i titoli degli episodi
    _episodeTitleControllers.clear();
    for (final season in editedSeries.seasons) {
      _episodeTitleControllers.add([
        for (final episode in season.episodes)
          TextEditingController(text: episode.title)
      ]);
    }
  }

  @override
  void dispose() {
    for (var controller in _seasonNameControllers) {
      controller.dispose();
    }
    for (var seasonControllers in _episodeTitleControllers) {
      for (var controller in seasonControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _addSeason() {
    final newSeasonNumber = editedSeries.seasons.length + 1;
    final defaultName = 'Stagione $newSeasonNumber';
    final newController = TextEditingController(text: defaultName);

    setState(() {
      editedSeries = editedSeries.copyWith(
        seasons: [
          ...editedSeries.seasons,
          Season(
            seasonNumber: newSeasonNumber,
            name: defaultName,
            episodes: [],
          )
        ]
      );
      _seasonNameControllers.add(newController);
      _episodeTitleControllers.add([]);
    });
  }

  void _addEpisodesToSeason(int seasonIndex, int count) {
    if (count <= 0) return;

    final season = editedSeries.seasons[seasonIndex];
    final startEpisode = season.episodes.length + 1;

    final newEpisodes = List.generate(
      count,
      (i) => Episode(
        episodeNumber: startEpisode + i,
        title: 'Episodio ${startEpisode + i}',
      ),
    );

    setState(() {
      editedSeries = editedSeries.copyWith(
        seasons: editedSeries.seasons.mapIndexed((i, s) {
          if (i == seasonIndex) {
            final updatedSeason = Season(
              seasonNumber: s.seasonNumber,
              name: s.name,
              episodes: [...s.episodes, ...newEpisodes],
            )..updateCompletionStatus();

            return updatedSeason;
          }
          return s;
        }).toList(),
      );
      _episodeTitleControllers[seasonIndex].addAll(
        newEpisodes.map((e) => TextEditingController(text: e.title))
      );
    });
  }

  void _toggleEpisodeWatchStatus(int seasonIndex, int episodeIndex) {
    setState(() {
      editedSeries = editedSeries.copyWith(
        seasons: editedSeries.seasons.mapIndexed((i, season) {
          if (i == seasonIndex) {
            final updatedEpisodes = season.episodes.mapIndexed((j, episode) {
              return j == episodeIndex
                  ? Episode(
                      episodeNumber: episode.episodeNumber,
                      title: episode.title,
                      watched: !episode.watched,
                    )
                  : episode;
            }).toList();

            final updatedSeason = Season(
              seasonNumber: season.seasonNumber,
              name: season.name,
              episodes: updatedEpisodes,
            )..updateCompletionStatus();

            return updatedSeason;
          }
          return season;
        }).toList(),
      );
    });
  }

  void _updateSeasonName(int seasonIndex, String newName) {
    setState(() {
      editedSeries = editedSeries.copyWith(
        seasons: editedSeries.seasons.mapIndexed((i, season) {
          return i == seasonIndex
              ? Season(
                  seasonNumber: season.seasonNumber,
                  name: newName,
                  episodes: season.episodes,
                )
              : season;
        }).toList(),
      );
    });
  }

  void _updateEpisodeTitle(int seasonIndex, int episodeIndex, String newTitle) {
    setState(() {
      editedSeries = editedSeries.copyWith(
        seasons: editedSeries.seasons.mapIndexed((i, season) {
          if (i == seasonIndex) {
            final updatedEpisodes = season.episodes.mapIndexed((j, episode) {
              return j == episodeIndex
                  ? Episode(
                      episodeNumber: episode.episodeNumber,
                      title: newTitle,
                      watched: episode.watched,
                    )
                  : episode;
            }).toList();

            return Season(
              seasonNumber: season.seasonNumber,
              name: season.name,
              episodes: updatedEpisodes,
            );
          }
          return season;
        }).toList(),
      );
    });
  }

  void _deleteSeason(int seasonIndex) {
    if (editedSeries.seasons.length <= 1) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare "${editedSeries.seasons[seasonIndex].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                editedSeries = editedSeries.copyWith(
                  seasons: editedSeries.seasons
                      .whereIndexed((i, _) => i != seasonIndex)
                      .toList(),
                );
                _seasonNameControllers[seasonIndex].dispose();
                _seasonNameControllers.removeAt(seasonIndex);
                for (final c in _episodeTitleControllers[seasonIndex]) {
                  c.dispose();
                }
                _episodeTitleControllers.removeAt(seasonIndex);
              });
              Navigator.pop(context);
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteEpisode(int seasonIndex, int episodeIndex) {
    final season = editedSeries.seasons[seasonIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare "${season.episodes[episodeIndex].title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                editedSeries = editedSeries.copyWith(
                  seasons: editedSeries.seasons.mapIndexed((i, s) {
                    if (i == seasonIndex) {
                      final updatedEpisodes = s.episodes
                          .whereIndexed((j, _) => j != episodeIndex)
                          .toList();

                      final updatedSeason = Season(
                        seasonNumber: s.seasonNumber,
                        name: s.name,
                        episodes: updatedEpisodes,
                      )..updateCompletionStatus();

                      return updatedSeason;
                    }
                    return s;
                  }).toList(),
                );
                _episodeTitleControllers[seasonIndex][episodeIndex].dispose();
                _episodeTitleControllers[seasonIndex].removeAt(episodeIndex);
              });
              Navigator.pop(context);
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    // Aggiornamento dello stato della serie in base al completamento
    final newSeries = editedSeries.copyWith(
      stato: editedSeries.isCompleted ? 'Completata' : editedSeries.stato,
      dateCompleted: editedSeries.isCompleted && editedSeries.dateCompleted == null
          ? DateTime.now()
          : editedSeries.dateCompleted,
    );

    widget.onSave(newSeries);
    Navigator.pop(context, true); // Indica che le modifiche sono state salvate
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 400 ? 8.0 : 16.0;
    final cardFontSize = screenWidth < 400 ? 13.0 : 16.0;
    final sectionTitleSize = screenWidth < 400 ? 15.0 : 18.0;
    final buttonFontSize = screenWidth < 400 ? 13.0 : 16.0;
    final episodeTitleFontSize = screenWidth < 400 ? 12.0 : 15.0;
    final episodeSubtitleFontSize = screenWidth < 400 ? 10.0 : 13.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione: ${widget.series.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Salva modifiche',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // Riepilogo serie
            Card(
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Episodi totali: ${editedSeries.totalEpisodes}',
                          style: TextStyle(fontSize: cardFontSize, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Episodi visti: ${editedSeries.watchedEpisodes}',
                          style: TextStyle(fontSize: cardFontSize, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Chip(
                      backgroundColor: editedSeries.isCompleted
                          ? Colors.green[800]
                          : Theme.of(context).primaryColor,
                      label: Text(
                        editedSeries.isCompleted
                            ? 'COMPLETATA'
                            : 'IN CORSO',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: cardPadding),

            // Intestazione e pulsante aggiungi stagione
            Row(
              children: [
                Text(
                  'Stagioni:',
                  style: TextStyle(
                    fontSize: sectionTitleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addSeason,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Aggiungi Stagione',
                    style: TextStyle(fontSize: buttonFontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 400 ? 8 : 16,
                      vertical: screenWidth < 400 ? 6 : 10,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: cardPadding),

            // Lista stagioni
            Expanded(
              child: ListView.builder(
                itemCount: editedSeries.seasons.length,
                itemBuilder: (context, seasonIndex) {
                  final season = editedSeries.seasons[seasonIndex];
                  return Card(
                    margin: EdgeInsets.only(bottom: cardPadding),
                    elevation: 3,
                    child: ExpansionTile(
                      leading: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSeason(seasonIndex),
                        tooltip: 'Elimina stagione',
                      ),
                      trailing: Checkbox(
                        value: season.isCompleted,
                        onChanged: null,
                      ),
                      title: TextField(
                        controller: _seasonNameControllers[seasonIndex],
                        onChanged: (value) => _updateSeasonName(seasonIndex, value),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: season.isCompleted ? Colors.green : null,
                          decoration: season.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontSize: cardFontSize,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nome stagione',
                        ),
                      ),
                      subtitle: Text(
                        'Episodi: ${season.episodes.length} | '
                        'Visti: ${season.episodes.where((e) => e.watched).length}',
                        style: TextStyle(fontSize: screenWidth < 400 ? 11 : 13),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            children: [
                              // Intestazione episodi
                              Row(
                                children: [
                                  Text(
                                    'Episodi:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: cardFontSize,
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => EpisodeCountDialog(
                                          onConfirm: (count) {
                                            _addEpisodesToSeason(seasonIndex, count);
                                          },
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth < 400 ? 8 : 16,
                                        vertical: screenWidth < 400 ? 6 : 10,
                                      ),
                                    ),
                                    child: Text(
                                      '+ Aggiungi Episodi',
                                      style: TextStyle(fontSize: buttonFontSize),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: cardPadding),

                              // Lista episodi
                              ...season.episodes.mapIndexed((episodeIndex, episode) {
                                final controller = _episodeTitleControllers.length > seasonIndex &&
                                        _episodeTitleControllers[seasonIndex].length > episodeIndex
                                    ? _episodeTitleControllers[seasonIndex][episodeIndex]
                                    : TextEditingController(text: episode.title);

                                return ListTile(
                                  leading: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteEpisode(seasonIndex, episodeIndex),
                                  ),
                                  title: TextField(
                                    controller: controller,
                                    onChanged: (value) => _updateEpisodeTitle(seasonIndex, episodeIndex, value),
                                    style: TextStyle(
                                      decoration: episode.watched
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: episode.watched
                                          ? Colors.green
                                          : null,
                                      fontSize: episodeTitleFontSize,
                                    ),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Titolo episodio',
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: episode.watched,
                                    onChanged: (_) => _toggleEpisodeWatchStatus(seasonIndex, episodeIndex),
                                  ),
                                  subtitle: Text(
                                    'Episodio ${episode.episodeNumber}',
                                    style: TextStyle(fontSize: episodeSubtitleFontSize),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodeCountDialog extends StatefulWidget {
  final Function(int) onConfirm;

  const EpisodeCountDialog({super.key, required this.onConfirm});

  @override
  _EpisodeCountDialogState createState() => _EpisodeCountDialogState();
}

class _EpisodeCountDialogState extends State<EpisodeCountDialog> {
  final _countController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi Episodi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Numero di episodi',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Quanti episodi vuoi aggiungere a questa stagione?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            final count = int.tryParse(_countController.text) ?? 1;
            widget.onConfirm(count);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}