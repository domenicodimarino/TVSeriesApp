import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';
import 'series_screen.dart';
import 'main.dart'; // Per il CustomFooter

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Series> _allSeries = [];
  List<Series> _filteredSeries = [];

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final dbHelper = DatabaseHelper.instance;
    final series = await dbHelper.getAllSeries();
    setState(() {
      _allSeries = series;
      _filteredSeries = series;
    });
  }

  void _searchSeries(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredSeries = _allSeries.where((series) {
        return series.title.toLowerCase().contains(lowerCaseQuery) ||
            series.genere.toLowerCase().contains(lowerCaseQuery) ||
            series.piattaforma.toLowerCase().contains(lowerCaseQuery);
      }).toList();
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
              onPressed: () {
                _searchController.clear();
                _searchSeries('');
              },
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _searchSeries,
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredSeries.isEmpty) {
      return const Center(
        child: Text(
          'Nessun risultato trovato',
          style: TextStyle(color: Colors.white70, fontSize: 16),
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
      subtitle: Text(
        '${series.genere} • ${series.piattaforma}',
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      onTap: () => _navigateToSeriesDetail(series),
    );
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
            if (_searchController.text.isNotEmpty) {
              _searchSeries(_searchController.text);
            }
          },
        ),
      ),
    );
  }
}