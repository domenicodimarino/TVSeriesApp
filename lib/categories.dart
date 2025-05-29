import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';
import 'series_screen.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  static const routeName = '/categories';

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Categorie e conteggi
  Map<String, int> _genreCount = {};
  Map<String, int> _platformCount = {};
  List<String> _customGenres = [];
  List<String> _customPlatforms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final allSeries = await dbHelper.getAllSeries();
      
      // Calcola i conteggi per genere
      final genreCounts = <String, int>{};
      final platformCounts = <String, int>{};
      
      for (final series in allSeries) {
        // Gestione generi (possono essere multipli separati da virgola)
        final genres = series.genere.split(',');
        for (var genre in genres) {
          genre = genre.trim();
          if (genre.isNotEmpty) {
            genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
          }
        }
        
        // Gestione piattaforme
        final platform = series.piattaforma.trim();
        if (platform.isNotEmpty) {
          platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;
        }
      }
      
      // Carica categorie personalizzate
      List<String> customGenres = [];
      List<String> customPlatforms = [];
      
      try {
        customGenres = await dbHelper.getCustomGenres();
        customPlatforms = await dbHelper.getCustomPlatforms();
      } catch (e) {
        print('Errore nel caricamento delle categorie personalizzate: $e');
        // Se il metodo non è implementato o fallisce, usiamo liste vuote
      }
      
      setState(() {
        _genreCount = genreCounts;
        _platformCount = platformCounts;
        _customGenres = customGenres;
        _customPlatforms = customPlatforms;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento delle categorie: $e');
      setState(() {
        _isLoading = false; // Importante: imposta isLoading a false anche in caso di errore
      });
    }
  }

  void _addCustomCategory(bool isGenre) async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          'Aggiungi ${isGenre ? 'Genere' : 'Piattaforma'}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nome ${isGenre ? 'genere' : 'piattaforma'}',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Aggiungi', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Aggiungi al database e aggiorna la UI
      final dbHelper = DatabaseHelper.instance;
      
      if (isGenre) {
        await dbHelper.addCustomGenre(result);
      } else {
        await dbHelper.addCustomPlatform(result);
      }
      
      _loadCategories();
    }
  }

  Widget _buildCategoryCard(String category, int count, [bool isCustom = false]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400 ? 14.0 : 16.0;
    final countSize = screenWidth < 400 ? 13.0 : 15.0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: screenWidth < 400 ? 8.0 : 16.0,
      ),
      color: const Color(0xFF23272F),
      child: ListTile(
        onTap: () => _navigateToSearch(category, _tabController.index == 0),
        title: Text(
          category,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: isCustom
            ? Text(
                'Categoria personalizzata',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: countSize - 2,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: countSize,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSearch(String category, bool isGenre) async {
    // Qui implementeremo la navigazione alla ricerca filtrata per categoria
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialFilter: isGenre ? {'genre': category} : {'platform': category},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: const Text('Categorie', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.category, color: Colors.white),
              text: 'Generi',
            ),
            Tab(
              icon: Icon(Icons.tv, color: Colors.white),
              text: 'Piattaforme',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab Generi
                _buildGenreTab(),
                
                // Tab Piattaforme
                _buildPlatformTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB71C1C),
        onPressed: () => _addCustomCategory(_tabController.index == 0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGenreTab() {
    if (_genreCount.isEmpty && _customGenres.isEmpty) {
      return _buildEmptyState('Nessun genere disponibile');
    }

    // Ordina i generi per numero di serie (decrescente)
    final sortedGenres = _genreCount.keys.toList()
      ..sort((a, b) => _genreCount[b]!.compareTo(_genreCount[a]!));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Mostra prima le categorie personalizzate
        if (_customGenres.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Generi personalizzati',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._customGenres.map((genre) {
            final count = _genreCount[genre] ?? 0;
            return _buildCategoryCard(genre, count, true);
          }),
          const Divider(color: Colors.white24),
        ],

        // Mostra tutte le categorie esistenti
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            'Tutti i generi',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...sortedGenres.map((genre) {
          // Escludiamo i generi personalizzati che sono già stati mostrati sopra
          if (!_customGenres.contains(genre)) {
            return _buildCategoryCard(genre, _genreCount[genre]!);
          } else {
            return const SizedBox.shrink();
          }
        }).where((widget) => widget is! SizedBox),
      ],
    );
  }

  Widget _buildPlatformTab() {
    if (_platformCount.isEmpty && _customPlatforms.isEmpty) {
      return _buildEmptyState('Nessuna piattaforma disponibile');
    }

    // Ordina le piattaforme per numero di serie (decrescente)
    final sortedPlatforms = _platformCount.keys.toList()
      ..sort((a, b) => _platformCount[b]!.compareTo(_platformCount[a]!));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Mostra prima le piattaforme personalizzate
        if (_customPlatforms.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Piattaforme personalizzate',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._customPlatforms.map((platform) {
            final count = _platformCount[platform] ?? 0;
            return _buildCategoryCard(platform, count, true);
          }),
          const Divider(color: Colors.white24),
        ],

        // Mostra tutte le piattaforme esistenti
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            'Tutte le piattaforme',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...sortedPlatforms.map((platform) {
          // Escludiamo le piattaforme personalizzate che sono già state mostrate sopra
          if (!_customPlatforms.contains(platform)) {
            return _buildCategoryCard(platform, _platformCount[platform]!);
          } else {
            return const SizedBox.shrink();
          }
        }).where((widget) => widget is! SizedBox),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _tabController.index == 0 ? Icons.category_outlined : Icons.tv_outlined,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi serie TV per visualizzare le categorie',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}