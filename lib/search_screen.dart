// search_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';
import 'series_screen.dart';

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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cerca per titolo, genere o piattaforma...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
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
      body: ListView.builder(
        itemCount: _filteredSeries.length,
        itemBuilder: (context, index) {
          final series = _filteredSeries[index];
          return ListTile(
            leading: Image.network(
              series.imageUrl,
              width: 50,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50,
                height: 75,
                color: Colors.grey[800],
              ),
            ),
            title: Text(
              series.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${series.genere} • ${series.piattaforma}',
              style: const TextStyle(color: Colors.white70),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SeriesScreen(series: series),
                ),
              );
            },
          );
        },
      ),
    );
  }
}