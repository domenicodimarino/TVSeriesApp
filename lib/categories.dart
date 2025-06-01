import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';
import 'widgets/movie_grid_dynamic.dart';

const Map<String, String> genreEmojis = {
  'drammatico': '🎭',
  'crime': '🔍',
  'commedia': '😂',
  'sci-fi': '👽',
  'azione': '💥',
  'thriller': '🔪',
  'fantasy': '🧙‍♂️',
  'horror': '👻',
  'avventura': '🗺️',
  'romantico': '❤️',
  'animazione': '🎬',
  'mistero': '🕵️',
  'storico': '📜',
  'medico': '🏥',
  'reality': '📹',
  'cucina': '🍳',
  'sport': '🏆',
  'documentario': '📚',
  'automobilismo': '🏎️',
};

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  static const routeName = '/categories';

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  // Categorie e serie
  Map<String, List<Series>> _genreSeriesMap = {};
  Map<String, List<Series>> _platformSeriesMap = {};
  List<String> _customGenres = [];
  List<String> _customPlatforms = [];
  Map<String, List<Series>> _customGenreSeriesMap = {};
  Map<String, List<Series>> _customPlatformSeriesMap = {};

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
      
      // Creazione mappe per generi e piattaforme
      final genreSeriesMap = <String, List<Series>>{};
      final platformSeriesMap = <String, List<Series>>{};
      
      for (final series in allSeries) {
        // Gestione generi (possono essere multipli separati da virgola)
        final genres = series.genere.split(',');
        for (var genre in genres) {
          genre = genre.trim();
          if (genre.isNotEmpty) {
            genreSeriesMap.putIfAbsent(genre, () => []).add(series);
          }
        }
        
        // Gestione piattaforme (singola piattaforma per serie)
        final platform = series.piattaforma.trim();
        if (platform.isNotEmpty) {
          platformSeriesMap.putIfAbsent(platform, () => []).add(series);
        }
      }
      
      // Caricamento categorie personalizzate
      List<String> customGenres = [];
      List<String> customPlatforms = [];
      Map<String, List<Series>> customGenreSeriesMap = {};
      Map<String, List<Series>> customPlatformSeriesMap = {};
      
      try {
        customGenres = await dbHelper.getCustomGenres();
        customPlatforms = await dbHelper.getCustomPlatforms();
        
        // Caricamento le serie per ogni categoria personalizzata
        for (final genre in customGenres) {
          final seriesIds = await dbHelper.getSeriesInCustomCategory(genre, true);
          final categorySeries = allSeries.where((s) => seriesIds.contains(s.id)).toList();
          customGenreSeriesMap[genre] = categorySeries;
        }
        
        for (final platform in customPlatforms) {
          final seriesIds = await dbHelper.getSeriesInCustomCategory(platform, false);
          final categorySeries = allSeries.where((s) => seriesIds.contains(s.id)).toList();
          customPlatformSeriesMap[platform] = categorySeries;
        }
      } catch (e) {
        print('Errore nel caricamento delle categorie personalizzate: $e');
      }
      
      setState(() {
        _genreSeriesMap = genreSeriesMap;
        _platformSeriesMap = platformSeriesMap;
        _customGenres = customGenres;
        _customPlatforms = customPlatforms;
        _customGenreSeriesMap = customGenreSeriesMap;
        _customPlatformSeriesMap = customPlatformSeriesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento delle categorie: $e');
      setState(() {
        _isLoading = false;
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
          'Aggiungi ${isGenre ? 'Genere' : 'Piattaforma'} Personalizzata',
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
      final dbHelper = DatabaseHelper.instance;
      
      if (isGenre) {
        await dbHelper.addCustomGenre(result);
      } else {
        await dbHelper.addCustomPlatform(result);
      }
      
      _loadCategories();
    }
  }

  void _manageCustomCategory(String categoryName, bool isGenre) async {
    final currentSeries = isGenre 
        ? _customGenreSeriesMap[categoryName] ?? []
        : _customPlatformSeriesMap[categoryName] ?? [];
    
    final allSeries = await DatabaseHelper.instance.getAllSeries();
    
    await showDialog(
      context: context,
      builder: (context) => _CustomCategoryManagerDialog(
        categoryName: categoryName,
        isGenre: isGenre,
        currentSeries: currentSeries,
        allSeries: allSeries,
        onUpdate: _loadCategories,
      ),
    );
  }

  void _refreshSeries() {
    _hasChanges = true; // Segna che ci sono state modifiche
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          Navigator.pop(context, true); // Propaga le modifiche alla home
          return false;
        }
        return true;
      },
      child: Scaffold(
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
                  _buildGenreTab(),
                  _buildPlatformTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFB71C1C),
          onPressed: () => _addCustomCategory(_tabController.index == 0),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGenreTab() {
    final allCategories = <String, List<Series>>{};
    allCategories.addAll(_customGenreSeriesMap);
    allCategories.addAll(_genreSeriesMap);

    if (allCategories.isEmpty) {
      return _buildEmptyState('Nessun genere disponibile');
    }

    // Ordina le categorie: prima quelle personalizzate, poi per numero di serie
    final sortedCategories = allCategories.keys.toList()
      ..sort((a, b) {
        final isACustom = _customGenres.contains(a);
        final isBCustom = _customGenres.contains(b);
        
        if (isACustom && !isBCustom) return -1;
        if (!isACustom && isBCustom) return 1;
        
        return allCategories[b]!.length.compareTo(allCategories[a]!.length);
      });

    return ListView(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 90),
      children: [
        ...sortedCategories.map((genre) {
          final series = allCategories[genre]!;
          final isCustom = _customGenres.contains(genre);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(genre, series.length, isCustom, true),
              if (series.isNotEmpty)
                MovieGridDynamic(
                  series: series,
                  onSeriesUpdated: _refreshSeries,
                )
              else
                _buildEmptyCategory(),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPlatformTab() {
    final allCategories = <String, List<Series>>{};
    allCategories.addAll(_customPlatformSeriesMap);
    allCategories.addAll(_platformSeriesMap);

    if (allCategories.isEmpty) {
      return _buildEmptyState('Nessuna piattaforma disponibile');
    }

    // Ordina le categorie: prima quelle personalizzate, poi per numero di serie
    final sortedCategories = allCategories.keys.toList()
      ..sort((a, b) {
        final isACustom = _customPlatforms.contains(a);
        final isBCustom = _customPlatforms.contains(b);
        
        if (isACustom && !isBCustom) return -1;
        if (!isACustom && isBCustom) return 1;
        
        return allCategories[b]!.length.compareTo(allCategories[a]!.length);
      });

    return ListView(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 90),
      children: [
        ...sortedCategories.map((platform) {
          final series = allCategories[platform]!;
          final isCustom = _customPlatforms.contains(platform);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(platform, series.length, isCustom, false),
              if (series.isNotEmpty)
                MovieGridDynamic(
                  series: series,
                  onSeriesUpdated: _refreshSeries,
                )
              else
                _buildEmptyCategory(),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count, bool isCustom, bool isGenre) {
    // Aggiungi l'emoji al titolo solo per i generi predefiniti (non personalizzati)
    String displayTitle = title;
    if (isGenre && !isCustom) {
      // Cerca l'emoji per questo genere (case insensitive)
      final lowercaseTitle = title.toLowerCase();
      final emoji = genreEmojis[lowercaseTitle];
      
      // Aggiungi l'emoji se trovata
      if (emoji != null) {
        displayTitle = '$emoji $title';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$count serie${isCustom ? ' • Personalizzata' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isCustom ? Colors.amber : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (isCustom) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
              onPressed: () => _manageCustomCategory(title, isGenre),
              tooltip: 'Gestisci categoria',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteCustomCategory(title, isGenre),
              tooltip: 'Elimina categoria',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              color: Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Nessuna serie in questa categoria',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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

  void _deleteCustomCategory(String categoryName, bool isGenre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Conferma eliminazione', style: TextStyle(color: Colors.white)),
        content: Text(
          'Sei sicuro di voler eliminare la categoria "$categoryName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final dbHelper = DatabaseHelper.instance;
      if (isGenre) {
        await dbHelper.deleteCustomGenre(categoryName);
      } else {
        await dbHelper.deleteCustomPlatform(categoryName);
      }
      _loadCategories();
    }
  }
}

// Dialog per gestire le categorie personalizzate
class _CustomCategoryManagerDialog extends StatefulWidget {
  final String categoryName;
  final bool isGenre;
  final List<Series> currentSeries;
  final List<Series> allSeries;
  final VoidCallback onUpdate;

  const _CustomCategoryManagerDialog({
    required this.categoryName,
    required this.isGenre,
    required this.currentSeries,
    required this.allSeries,
    required this.onUpdate,
  });

  @override
  State<_CustomCategoryManagerDialog> createState() => _CustomCategoryManagerDialogState();
}

class _CustomCategoryManagerDialogState extends State<_CustomCategoryManagerDialog> {
  late List<Series> _selectedSeries;

  @override
  void initState() {
    super.initState();
    _selectedSeries = List.from(widget.currentSeries);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: Text(
        'Gestisci "${widget.categoryName}"',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.allSeries.length,
          itemBuilder: (context, index) {
            final series = widget.allSeries[index];
            final isSelected = _selectedSeries.any((s) => s.id == series.id);
            
            return CheckboxListTile(
              value: isSelected,
              title: Text(
                series.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${series.genere} • ${series.piattaforma}',
                style: const TextStyle(color: Colors.white70),
              ),
              activeColor: const Color(0xFFB71C1C),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    if (!_selectedSeries.any((s) => s.id == series.id)) {
                      _selectedSeries.add(series);
                    }
                  } else {
                    _selectedSeries.removeWhere((s) => s.id == series.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Salva', style: TextStyle(color: Colors.red)),
          onPressed: () async {
            final dbHelper = DatabaseHelper.instance;
            final seriesIds = _selectedSeries.map((s) => s.id!).toList();
            
            await dbHelper.updateCustomCategorySeries(
              widget.categoryName,
              widget.isGenre,
              seriesIds,
            );
            
            widget.onUpdate();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}