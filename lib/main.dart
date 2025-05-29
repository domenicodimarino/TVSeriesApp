import 'package:flutter/material.dart';
import 'series.dart';
import 'series_screen.dart';
import 'search_screen.dart';
import 'add_edit_series_screen.dart';
import 'database_helper.dart';
import 'analytics_screen.dart';
import 'widgets/series_image.dart';
import 'splash_screen.dart';
import 'categories.dart';  // Aggiungi questo import

void main() => runApp(const LetterboxdApp());

class LetterboxdApp extends StatelessWidget {
  const LetterboxdApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domflix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181c23),
        appBarTheme: const AppBarTheme(
          color: Color(0xFFB71C1C),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      initialRoute: SplashScreen.routeName, // Cambia qui
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        DomflixHomePage.routeName: (context) => const DomflixHomePage(),
        SearchScreen.routeName: (context) => const SearchScreen(),
        AnalyticsScreen.routeName: (context) => const AnalyticsScreen(),
        AddEditSeriesScreen.routeName: (context) => const AddEditSeriesScreen(),
        CategoriesScreen.routeName: (context) => const CategoriesScreen(), 
      },
      onGenerateRoute: (settings) {
        if (settings.name == SeriesScreen.routeName) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SeriesScreen(
              series: args['series'],
              onSeriesUpdated: args['onSeriesUpdated'],
            ),
          );
        }
        return null;
      },
    );
  }
}

class DomflixHomePage extends StatefulWidget {
  const DomflixHomePage({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  State<DomflixHomePage> createState() => _DomflixHomePageState();
}

class _DomflixHomePageState extends State<DomflixHomePage> {
  // Carica le serie in corso
  Future<List<Series>> _loadInProgressSeries() async {
    final allSeries = await DatabaseHelper.instance.getAllSeries();
    return allSeries.where((series) => series.stato == 'In corso').toList();
  }

  // Carica le serie preferite
  Future<List<Series>> _loadFavoriteSeries() async {
    return await DatabaseHelper.instance.getFavoriteSeries();
  }

  // Carica le serie da guardare
  Future<List<Series>> _loadWatchLaterSeries() async {
    final allSeries = await DatabaseHelper.instance.getAllSeries();
    return allSeries.where((series) => series.stato == 'Da guardare').toList();
  }

  // Carica le serie completate
  Future<List<Series>> _loadCompletedSeries() async {
    final allSeries = await DatabaseHelper.instance.getAllSeries();
    return allSeries.where((series) => series.stato == 'Completata').toList();
  }

  // Carica suggerimenti dal database
  Future<List<Series>> _loadDatabaseSuggestions() async {
    // Usa i metodi del database per suggerimenti intelligenti
    return await DatabaseHelper.instance.getSmartSuggestions(limit: 6);
  }

  void _refreshSeries() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        elevation: 0,
        title: Image.asset(
          "assets/domflix_logo.jpeg",
          height: 38,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 0),
        child: ListView(
          children: [
            // NUOVA SEZIONE: Suggerimenti dal database
            const SectionTitle(title: "🔥 Per te"),
            FutureBuilder<List<Series>>(
              future: _loadDatabaseSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Errore nel caricamento dei suggerimenti", 
                      style: TextStyle(color: Colors.white70));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptySection(message: "Aggiungi qualche serie per vedere i suggerimenti");
                }
                return MovieGridDynamic(
                  series: snapshot.data!,
                  onSeriesUpdated: _refreshSeries,
                );
              },
            ),
            const SizedBox(height: 24),

            // Sezione Preferiti
            const SectionTitle(title: "⭐ I tuoi preferiti"),
            FutureBuilder<List<Series>>(
              future: _loadFavoriteSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Errore nel caricamento dei preferiti", 
                      style: TextStyle(color: Colors.white70));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptySection(message: "Nessuna serie tra i preferiti");
                }
                return MovieGridDynamic(
                  series: snapshot.data!,
                  onSeriesUpdated: _refreshSeries,
                );
              },
            ),
            const SizedBox(height: 24),

            // Sezione In corso
            const SectionTitle(title: "📺 Le tue serie in corso"),
            FutureBuilder<List<Series>>(
              future: _loadInProgressSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Errore nel caricamento delle serie in corso",
                      style: TextStyle(color: Colors.white70));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptySection(message: "Nessuna serie in corso");
                }
                return MovieGridDynamic(
                  series: snapshot.data!,
                  onSeriesUpdated: _refreshSeries,
                );
              },
            ),
            const SizedBox(height: 24),

            // Sezione Da guardare
            const SectionTitle(title: "🎬 Tutte le serie da guardare"),
            FutureBuilder<List<Series>>(
              future: _loadWatchLaterSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Errore nel caricamento dei suggerimenti",
                      style: TextStyle(color: Colors.white70));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptySection(message: "Nessuna serie da guardare");
                }
                return MovieGridDynamic(
                  series: snapshot.data!,
                  onSeriesUpdated: _refreshSeries,
                );
              },
            ),
            const SizedBox(height: 24),

            // Sezione Completate
            const SectionTitle(title: "✅ Serie completate"),
            FutureBuilder<List<Series>>(
              future: _loadCompletedSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Errore nel caricamento delle serie completate",
                      style: TextStyle(color: Colors.white70));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptySection(message: "Nessuna serie completata");
                }
                return MovieGridDynamic(
                  series: snapshot.data!,
                  onSeriesUpdated: _refreshSeries,
                );
              },
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(onSeriesAdded: _refreshSeries),
    );
  }
}

// Widget per sezioni vuote
class EmptySection extends StatelessWidget {
  final String message;
  
  const EmptySection({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = screenWidth < 400 ? 120.0 : 200.0;
    final iconSize = screenWidth < 400 ? 24.0 : 32.0;
    final fontSize = screenWidth < 400 ? 12.0 : 14.0;

    return Container(
      height: height,
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
              size: iconSize,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      );
}

class MovieGrid extends StatelessWidget {
  final List<Map<String, String>> movies;
  final VoidCallback onSeriesUpdated;

  const MovieGrid({
    super.key,
    required this.movies,
    required this.onSeriesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 400 ? 90.0 : (screenWidth < 600 ? 110.0 : 130.0);

    return SizedBox(
      height: cardWidth * 1.5,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: cardWidth,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  SeriesScreen.routeName,
                  arguments: {
                    'series': Series(
                      imageUrl: movie["image"]!,
                      title: movie["title"]!,
                      trama: "Trama di esempio per ${movie["title"]}",
                      genere: "Genere di esempio",
                      stato: "In corso",
                      piattaforma: "Netflix",
                      isFavorite: false
                    ),
                    'onSeriesUpdated': onSeriesUpdated,
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        movie["image"]!,
                        width: cardWidth,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: cardWidth,
                          color: Colors.grey[800],
                          child: const Icon(Icons.broken_image, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie["title"]!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 400 ? 10 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MovieGridDynamic extends StatelessWidget {
  final List<Series> series;
  final VoidCallback onSeriesUpdated;

  const MovieGridDynamic({
    super.key,
    required this.series,
    required this.onSeriesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth < 400 ? 150.0 : (screenWidth < 600 ? 200.0 : 240.0);
    final imageHeight = screenWidth < 400 ? 220.0 : (screenWidth < 600 ? 300.0 : 360.0);

    return SizedBox(
      height: imageHeight + 40, // spazio per il titolo
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: series.length,
        itemBuilder: (context, index) {
          final s = series[index];
          return Container(
            width: imageWidth,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  SeriesScreen.routeName,
                  arguments: {
                    'series': s,
                    'onSeriesUpdated': onSeriesUpdated,
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SeriesImage(
                    series: s,
                    width: imageWidth,
                    height: imageHeight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 400 ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomFooter extends StatelessWidget {
  final VoidCallback onSeriesAdded;
  const CustomFooter({super.key, required this.onSeriesAdded});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFF23272F),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white, size: 30),
            onPressed: () {
              // Controlla se sei già sulla home per evitare di creare duplicati
              if (ModalRoute.of(context)?.settings.name != DomflixHomePage.routeName) {
                // Rimuovi tutto lo stack e vai alla home
                Navigator.of(context).pushNamedAndRemoveUntil(
                  DomflixHomePage.routeName,
                  (route) => false, // Rimuove tutte le routes esistenti
                );
              }
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 30),
            onPressed: () async {  // Aggiungi async qui
              if (ModalRoute.of(context)?.settings.name != SearchScreen.routeName) {
                // Se non sei già sulla schermata di ricerca, vai lì
                final result = await Navigator.pushNamed(  // Aggiungi await qui
                  context,
                  SearchScreen.routeName,
                );
                
                // Aggiorna la home quando torni dalla ricerca con modifiche
                if (result == true) {
                  onSeriesAdded();
                }
              }
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AddEditSeriesScreen.routeName,
              );
              if (result == true) {
                onSeriesAdded();
              }
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white, size: 30),
            onPressed: () async {  // Aggiungi async qui
              if (ModalRoute.of(context)?.settings.name != CategoriesScreen.routeName) {
                final result = await Navigator.pushNamed(  // Aggiungi await qui
                  context,
                  CategoriesScreen.routeName,
                );
                
                // Aggiorna la home quando torni dalle categorie con modifiche
                if (result == true) {
                  onSeriesAdded();
                }
              }
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white, size: 30),
            onPressed: () async {  // Aggiungi async qui
              if (ModalRoute.of(context)?.settings.name != AnalyticsScreen.routeName) {
                final result = await Navigator.pushNamed(  // Aggiungi await qui
                  context,
                  AnalyticsScreen.routeName,
                );
                
                // Aggiorna la home quando torni da analytics con modifiche
                if (result == true) {
                  onSeriesAdded();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
