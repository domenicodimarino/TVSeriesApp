import 'package:flutter/material.dart';
import 'series.dart';
import 'series_screen.dart';
import 'search_screen.dart';
import 'add_edit_series_screen.dart';
import 'database_helper.dart';
import 'widgets/series_image.dart';

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
      home: const DomflixHomePage(),
    );
  }
}

class DomflixHomePage extends StatefulWidget {
  const DomflixHomePage({Key? key}) : super(key: key);

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

  // Carica le serie da guardare (potrebbe piacerti)
  Future<List<Series>> _loadWatchLaterSeries() async {
    final allSeries = await DatabaseHelper.instance.getAllSeries();
    return allSeries.where((series) => series.stato == 'Da guardare').toList();
  }

  // Carica le serie completate
  Future<List<Series>> _loadCompletedSeries() async {
    final allSeries = await DatabaseHelper.instance.getAllSeries();
    return allSeries.where((series) => series.stato == 'Completata').toList();
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

            // Sezione Preferiti
            const SectionTitle(title: "⭐ I tuoi preferiti"),
            FutureBuilder<List<Series>>(
              future: _loadFavoriteSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: CircularProgressIndicator());
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

            // Sezione Da guardare (Potrebbe piacerti)
            const SectionTitle(title: "🎬 Potrebbe piacerti"),
            FutureBuilder<List<Series>>(
              future: _loadWatchLaterSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: CircularProgressIndicator());
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
    return Container(
      height: 200, // Stessa altezza delle altre sezioni
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
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
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
    return SizedBox(
      height: 200, // Altezza fissa per il contenitore
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Scroll orizzontale
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: 130, // Larghezza fissa per ogni elemento
            margin: const EdgeInsets.only(right: 12), // Spazio tra gli elementi
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesScreen(
                      series: Series(
                        imageUrl: movie["image"]!,
                        title: movie["title"]!,
                        trama: "Trama di esempio per ${movie["title"]}",
                        genere: "Genere di esempio",
                        stato: "In corso",
                        piattaforma: "Netflix",
                        isFavorite: false
                      ),
                      onSeriesUpdated: onSeriesUpdated,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine del film/serie
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        movie["image"]!,
                        width: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 130,
                          color: Colors.grey[800],
                          child: const Icon(Icons.broken_image, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Titolo del film/serie
                  Text(
                    movie["title"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
    return SizedBox(
      height: 200, // Altezza fissa per il contenitore
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Scroll orizzontale
        itemCount: series.length,
        itemBuilder: (context, index) {
          final s = series[index];
          return Container(
            width: 130, // Larghezza fissa per ogni elemento
            margin: const EdgeInsets.only(right: 12), // Spazio tra gli elementi
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesScreen(
                      series: s,
                      onSeriesUpdated: onSeriesUpdated,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine della serie
                  Expanded(
                    child: SeriesImage(
                      series: s,
                      width: 130,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 6),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditSeriesScreen(),
                ),
              );
              if (result == true) {
                onSeriesAdded();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          // Bottone di debug del database
          IconButton(
            icon: const Icon(Icons.storage, color: Colors.orange, size: 30),
            onPressed: () async {
              try {
                String dbPath = await DatabaseHelper.instance.getDatabasePath();
                print('Il tuo database si trova in: $dbPath');
                
                // Testa anche il contenuto
                await DatabaseHelper.instance.printAllSeries();
                
                // Mostra una notifica all'utente
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Database info stampata nel console'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                print('Errore nel debug del database: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Image.network(
                "https://i.imgur.com/7jOfbHH.png",
                width: 36,
                height: 36,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}