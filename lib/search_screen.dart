import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';
import 'series_screen.dart';
import 'main.dart'; // Per il CustomFooter

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const routeName = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Series> _allSeries = [];
  List<Series> _filteredSeries = [];
  
  // Filtro per stato
  String? _selectedStateFilter;
  final List<String> _stateFilters = ["Tutti", "In corso", "Completata", "Da guardare"];

  @override
  void initState() {
    super.initState();
    _selectedStateFilter = _stateFilters.first; // "Tutti" come default
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final dbHelper = DatabaseHelper.instance;
    final series = await dbHelper.getAllSeries();
    setState(() {
      _allSeries = series;
      _applyFilters();
    });
  }

  void _searchSeries(String query) {
    setState(() {
      _applyFilters(query: query);
    });
  }

  void _applyFilters({String? query}) {
    final searchQuery = query ?? _searchController.text;
    final lowerCaseQuery = searchQuery.toLowerCase();
    
    List<Series> filtered = _allSeries;
    
    // Applica filtro per stato
    if (_selectedStateFilter != null && _selectedStateFilter != "Tutti") {
      filtered = filtered.where((series) {
        return series.stato == _selectedStateFilter;
      }).toList();
    }
    
    // Applica filtro per ricerca testuale
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((series) {
        return series.title.toLowerCase().contains(lowerCaseQuery) ||
            series.genere.toLowerCase().contains(lowerCaseQuery) ||
            series.piattaforma.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
    
    setState(() {
      _filteredSeries = filtered;
    });
  }

  void _onStateFilterChanged(String? newState) {
    setState(() {
      _selectedStateFilter = newState;
      _applyFilters();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedStateFilter = "Tutti";
      _applyFilters(query: '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cerca per titolo, genere o piattaforma...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: _clearSearch,
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _searchSeries,
        ),
        actions: [
          _buildFilterButton(),
        ],
      ),
      body: Column(
        children: [
          _buildActiveFiltersBar(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list, color: Colors.white),
      color: const Color(0xFF181c23),
      onSelected: _onStateFilterChanged,
      itemBuilder: (BuildContext context) {
        return _stateFilters.map((String state) {
          return PopupMenuItem<String>(
            value: state,
            child: Row(
              children: [
                Icon(
                  _selectedStateFilter == state ? Icons.check : Icons.radio_button_unchecked,
                  color: _selectedStateFilter == state ? const Color(0xFFB71C1C) : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  state,
                  style: TextStyle(
                    color: _selectedStateFilter == state ? const Color(0xFFB71C1C) : Colors.white,
                    fontWeight: _selectedStateFilter == state ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildActiveFiltersBar() {
    // Mostra la barra dei filtri attivi solo se c'è un filtro applicato
    if (_selectedStateFilter == null || _selectedStateFilter == "Tutti") {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF23272F),
      child: Row(
        children: [
          const Text(
            'Filtro attivo:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedStateFilter!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _onStateFilterChanged("Tutti"),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredSeries.length} risultati',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredSeries.isEmpty && _allSeries.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessun risultato trovato',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _selectedStateFilter != "Tutti"
                  ? 'Prova a modificare i criteri di ricerca'
                  : 'Aggiungi delle serie per iniziare',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_allSeries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv_off,
              color: Colors.white70,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Nessuna serie disponibile',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Aggiungi le tue prime serie TV!',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredSeries.length,
      itemBuilder: (context, index) {
        final series = _filteredSeries[index];
        return _buildSeriesTile(series);
      },
    );
  }

  Widget _buildSeriesTile(Series series) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildSeriesImage(series.imageUrl),
      title: Text(
        series.title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${series.genere} • ${series.piattaforma}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStateColor(series.stato),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              series.stato,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      trailing: series.isFavorite
          ? const Icon(Icons.favorite, color: Colors.red, size: 20)
          : null,
      onTap: () => _navigateToSeriesDetail(series),
    );
  }

  Color _getStateColor(String stato) {
    switch (stato) {
      case "Completata":
        return Colors.green.shade600;
      case "In corso":
        return Colors.blue.shade600;
      case "Da guardare":
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildSeriesImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 50,
        height: 75,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 50,
          height: 75,
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.white70, size: 24),
        ),
      ),
    );
  }

  void _navigateToSeriesDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesScreen(
          series: series,
          onSeriesUpdated: () {
            _loadSeries(); // Ricarica i dati dopo le modifiche
          },
        ),
      ),
    );
  }
}