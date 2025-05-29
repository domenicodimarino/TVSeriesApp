import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';
import 'series_screen.dart';
import 'widgets/series_image.dart'; // Assicurati che questo import sia presente

class SearchScreen extends StatefulWidget {
  final Map<String, String>? initialFilter;
  
  const SearchScreen({super.key, this.initialFilter});

  static const routeName = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Series> _allSeries = [];
  List<Series> _filteredSeries = [];
  bool _hasModified = false; // <--- aggiungi questa variabile
  
  // Filtro per stato
  String? _selectedStateFilter;
  final List<String> _stateFilters = ["Tutti", "In corso", "Completata", "Da guardare"];

  @override
  void initState() {
    super.initState();
    
    _selectedStateFilter = _stateFilters.first; // "Tutti" come default
    
    // Se c'è un filtro iniziale, applicalo
    if (widget.initialFilter != null) {
      if (widget.initialFilter!.containsKey('genre')) {
        _searchController.text = widget.initialFilter!['genre']!;
      } else if (widget.initialFilter!.containsKey('platform')) {
        _searchController.text = widget.initialFilter!['platform']!;
      }
    }
    
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

  void _navigateToSeriesDetail(Series series) async {
    final result = await Navigator.pushNamed(
      context,
      SeriesScreen.routeName,
      arguments: {
        'series': series,
        'onSeriesUpdated': _loadSeries,
      },
    );
    
    // Se ci sono state modifiche, aggiorna ma NON fare un altro pop
    if (result == true) {
      _hasModified = true;
      await _loadSeries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasModified);
        return false;
      },
      child: Scaffold(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 8.0 : 16.0;
    final verticalPadding = screenWidth < 400 ? 4.0 : 8.0;

    if (_selectedStateFilter == null || _selectedStateFilter == "Tutti") {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      color: const Color(0xFF23272F),
      child: Row(
        children: [
          const Text(
            'Filtro attivo:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth < 400 ? 8 : 12, vertical: 4),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 8.0 : 16.0;

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
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      itemCount: _filteredSeries.length,
      itemBuilder: (context, index) {
        final series = _filteredSeries[index];
        return _buildSeriesTile(series, screenWidth);
      },
    );
  }

  Widget _buildSeriesTile(Series series, double screenWidth) {
    final imageWidth = screenWidth < 400 ? 80.0 : (screenWidth < 600 ? 100.0 : 120.0);
    final imageHeight = screenWidth < 400 ? 110.0 : (screenWidth < 600 ? 140.0 : 170.0);
    final containerHeight = imageHeight + 20;
    final horizontalPadding = screenWidth < 400 ? 8.0 : 16.0;
    final verticalPadding = screenWidth < 400 ? 8.0 : 12.0;

    return InkWell(
      onTap: () => _navigateToSeriesDetail(series),
      child: Container(
        height: containerHeight,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SeriesImage(
              series: series,
              width: imageWidth,
              height: imageHeight,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 400 ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${series.genere} • ${series.piattaforma}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth < 400 ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStateColor(series.stato),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      series.stato,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth < 400 ? 11 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (series.isFavorite)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
          ],
        ),
      ),
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
}