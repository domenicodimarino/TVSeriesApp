import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'main.dart';
import 'series.dart';
import 'database_helper.dart';
import 'add_edit_series_screen.dart';
import 'season_episode_screen.dart';
import 'widgets/series_image.dart';

class SeriesScreen extends StatefulWidget {
  final Series series;
  final VoidCallback onSeriesUpdated;

  const SeriesScreen({
    super.key,
    required this.series,
    required this.onSeriesUpdated,
  });

  static const routeName = '/series';

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late Series currentSeries;
  late String statoSelezionato;
  late bool isFavorite;
  final List<String> stati = ["In corso", "Completata", "Da guardare"];
  bool _hasChanges = false; // Aggiungi questa variabile per tracciare le modifiche

  @override
  void initState() {
    super.initState();
    currentSeries = widget.series;
    statoSelezionato = currentSeries.stato;
    isFavorite = currentSeries.isFavorite;
  }

  Future<void> _refreshSeries() async {
    final updatedSeries = await DatabaseHelper.instance.getSeriesById(currentSeries.id!);
    if (updatedSeries != null) {
      setState(() {
        currentSeries = updatedSeries;
        statoSelezionato = updatedSeries.stato;
        isFavorite = updatedSeries.isFavorite;
      });
    }
    widget.onSeriesUpdated();
  }

  Future<void> _toggleFavorite() async {
    setState(() => isFavorite = !isFavorite);
    
    await DatabaseHelper.instance.updateFavoriteStatus(
      currentSeries.id!,
      isFavorite,
    );

    _showSnackBar(
      isFavorite 
        ? '${currentSeries.title} aggiunta ai preferiti!'
        : '${currentSeries.title} rimossa dai preferiti!',
      isFavorite ? Colors.green : Colors.red,
    );

    _hasChanges = true; // Segna che ci sono state modifiche
    _refreshSeries();
  }

  Future<void> _updateSeriesState(String newState) async {
    setState(() => statoSelezionato = newState);
    
    // Se lo stato è "Completata", imposta tutti gli episodi come visti
    List<Season> updatedSeasons = [...currentSeries.seasons];
    
    // Determina se dobbiamo aggiornare la data di completamento
    DateTime? newDateCompleted = currentSeries.dateCompleted;
    if (newState == "Completata" && newDateCompleted == null) {
      newDateCompleted = DateTime.now();
    }
    
    if (newState == "Completata") {
      updatedSeasons = currentSeries.seasons.map((season) {
        final updatedEpisodes = season.episodes.map((episode) => 
            Episode(
              episodeNumber: episode.episodeNumber,
              title: episode.title,
              watched: true,
            )
        ).toList();
        
        final updatedSeason = Season(
          seasonNumber: season.seasonNumber,
          name: season.name,
          episodes: updatedEpisodes,
        )..updateCompletionStatus();
        
        return updatedSeason;
      }).toList();
    } else if (newState == "Da guardare") {
      // Opzionale: se imposti la serie come "Da guardare", reimposta tutti gli episodi come non visti
      updatedSeasons = currentSeries.seasons.map((season) {
        final updatedEpisodes = season.episodes.map((episode) => 
            Episode(
              episodeNumber: episode.episodeNumber,
              title: episode.title,
              watched: false,
            )
        ).toList();
        
        final updatedSeason = Season(
          seasonNumber: season.seasonNumber,
          name: season.name,
          episodes: updatedEpisodes,
        )..updateCompletionStatus();
        
        return updatedSeason;
      }).toList();
    }
    
    final updatedSeries = currentSeries.copyWith(
      stato: newState,
      seasons: updatedSeasons,
      dateCompleted: newDateCompleted  // Add this line
    );
    
    await DatabaseHelper.instance.updateSeries(updatedSeries);
    
    _hasChanges = true;
    _refreshSeries();
  }

  Future<void> _toggleEpisodeWatchStatus(int seasonIndex, int episodeIndex) async {
    final season = currentSeries.seasons[seasonIndex];
    
    final updatedEpisodes = season.episodes.mapIndexed((i, e) {
      return i == episodeIndex
          ? Episode(
              episodeNumber: e.episodeNumber,
              title: e.title,
              watched: !e.watched,
            )
          : e;
    }).toList();
    
    final updatedSeason = Season(
      seasonNumber: season.seasonNumber,
      name: season.name,
      episodes: updatedEpisodes,
    )..updateCompletionStatus();
    
    final updatedSeasons = currentSeries.seasons.mapIndexed((i, s) {
      return i == seasonIndex ? updatedSeason : s;
    }).toList();
    
    final updatedSeries = currentSeries.copyWith(seasons: updatedSeasons);
    final newStatus = updatedSeries.determineCorrectStatus();
    
    
    DateTime? newDateCompleted = updatedSeries.dateCompleted;
    if (newStatus == "Completata" && updatedSeries.dateCompleted == null) {
      newDateCompleted = DateTime.now();
    }
    
    final finalSeries = updatedSeries.copyWith(
      stato: newStatus,
      dateCompleted: newDateCompleted 
    );
    
    await DatabaseHelper.instance.updateSeries(finalSeries);
    _hasChanges = true;
    
    // Aggiorna anche lo stato selezionato nell'interfaccia
    setState(() {
      statoSelezionato = newStatus;
    });
    
    _refreshSeries();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          // Se ci sono state modifiche, ritorna true come risultato
          // per far sapere alla schermata precedente che serve un refresh
          Navigator.pop(context, true);
          return false; // Impedisce il pop predefinito
        }
        return true; // Lascia gestire il pop normalmente
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: CustomFooter(
          onSeriesAdded: widget.onSeriesUpdated,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFB71C1C),
      title: Image.asset("assets/domflix_logo.jpeg", height: 38),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _editSeries,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _showDeleteConfirmation,
        ),
      ],
    );
  }

  Future<void> _editSeries() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSeriesScreen(existingSeries: currentSeries),
      ),
    );

    if (result == true) {
      _refreshSeries();
    }
  }

  void _manageSeasons() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeasonEpisodeScreen(
          series: currentSeries,
          onSave: (updatedSeries) {
            setState(() => currentSeries = updatedSeries);
            DatabaseHelper.instance.updateSeries(updatedSeries);
            _refreshSeries();
          },
        ),
      ),
    );

    if (result != null) {
      _refreshSeries();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Conferma eliminazione',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Sei sicuro di voler eliminare "${currentSeries.title}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSeries();
              },
              child: const Text(
                'Elimina',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSeries() async {
    try {
      await DatabaseHelper.instance.deleteSeries(currentSeries.id!);
      
      _showSnackBar(
        '${currentSeries.title} eliminata con successo!',
        Colors.green,
      );

      _hasChanges = true; // Segna che ci sono state modifiche
      widget.onSeriesUpdated();
      Navigator.pop(context, true); // Ritorna true quando elimini
    } catch (e) {
      _showSnackBar(
        'Errore durante l\'eliminazione: $e',
        Colors.red,
      );
    }
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeriesImage(),
                const SizedBox(height: 18),
                _buildTitleRow(),
                const SizedBox(height: 8),
                _buildInfoRow("Genere:", currentSeries.genere),
                const SizedBox(height: 8),
                _buildStateDropdown(),
                const SizedBox(height: 8),
                _buildInfoRow("Piattaforma:", currentSeries.piattaforma),
                const SizedBox(height: 8),
                _buildProgressInfo(),
                const SizedBox(height: 16),
                _buildPlotSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildSeasonsSection(),
      ],
    );
  }

  Widget _buildSeriesImage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth < 400 ? 150.0 : (screenWidth < 600 ? 200.0 : 240.0);
    final imageHeight = screenWidth < 400 ? 220.0 : (screenWidth < 600 ? 300.0 : 360.0);

    return Center(
      child: SeriesImage(
        series: currentSeries,
        width: imageWidth,
        height: imageHeight,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildTitleRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: Text(
            currentSeries.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 20 : (screenWidth < 600 ? 24 : 26),
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white70,
            size: screenWidth < 400 ? 26 : 32,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth < 400 ? 13 : 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth < 400 ? 13 : 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Text(
          "Progresso:",
          style: TextStyle(
            fontSize: screenWidth < 400 ? 13 : 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "${currentSeries.watchedEpisodes}/${currentSeries.totalEpisodes} episodi",
          style: TextStyle(
            fontSize: screenWidth < 400 ? 13 : 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Text(
          "Stato:",
          style: TextStyle(
            fontSize: screenWidth < 400 ? 13 : 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: statoSelezionato,
          dropdownColor: const Color(0xFF181c23),
          style: TextStyle(color: Colors.white, fontSize: screenWidth < 400 ? 13 : 16),
          underline: Container(),
          items: stati.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) _updateSeriesState(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildPlotSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Trama:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 400 ? 15 : 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currentSeries.trama,
          style: TextStyle(
            fontSize: screenWidth < 400 ? 13 : 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _manageSeasons,
            icon: const Icon(
              Icons.playlist_add,
              color: Colors.white,
            ),
            label: Text(
              "Gestisci Stagioni ed Episodi",
              style: TextStyle(color: Colors.white, fontSize: screenWidth < 400 ? 13 : 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 400 ? 12 : 20,
                vertical: screenWidth < 400 ? 8 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsSection() {
    if (currentSeries.seasons.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Center(
            child: Text(
              "Nessuna stagione disponibile",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, seasonIndex) {
          final season = currentSeries.seasons[seasonIndex];
          return _buildSeasonCard(season, seasonIndex);
        },
        childCount: currentSeries.seasons.length,
      ),
    );
  }

  Widget _buildSeasonCard(Season season, int seasonIndex) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      color: const Color(0xFF23272F),
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth < 400 ? 8 : 16,
        vertical: screenWidth < 400 ? 4 : 8,
      ),
      child: ExpansionTile(
        leading: Checkbox(
          value: season.isCompleted,
          onChanged: null,
        ),
        title: Text(
          season.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 400 ? 14 : 16,
          ),
        ),
        subtitle: Text(
          '${season.episodes.where((e) => e.watched).length}/${season.episodes.length} episodi visti',
          style: TextStyle(
            color: Colors.white70,
            fontSize: screenWidth < 400 ? 12 : 14,
          ),
        ),
        children: [
          ...season.episodes.mapIndexed((episodeIndex, episode) {
            return _buildEpisodeTile(episode, seasonIndex, episodeIndex);
          }),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(Episode episode, int seasonIndex, int episodeIndex) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      leading: Checkbox(
        value: episode.watched,
        onChanged: (_) => _toggleEpisodeWatchStatus(seasonIndex, episodeIndex),
      ),
      title: Text(
        episode.title,
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth < 400 ? 13 : 15,
          decoration: episode.watched ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        "Episodio ${episode.episodeNumber}",
        style: TextStyle(
          color: Colors.white70,
          fontSize: screenWidth < 400 ? 11 : 13,
        ),
      ),
    );
  }
}

extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}