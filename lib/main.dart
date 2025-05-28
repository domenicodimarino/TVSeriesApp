import 'package:flutter/material.dart';
import 'series.dart';
import 'series_screen.dart';
import 'search_screen.dart';
import 'add_edit_series_screen.dart';
import 'database_helper.dart';
import 'widgets/series_image.dart'; // Aggiungi questo import

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
  static const movies1 = [
    {
      "title": "Mission: Impossible",
      "image": "https://m.media-amazon.com/images/M/MV5BZGQ5NGEyYTItMjNiMi00Y2EwLTkzOWItMjc5YjJiMjMyNTI0XkEyXkFqcGc@._V1_.jpg",
    },
    {
      "title": "Final Destination",
      "image": "https://m.media-amazon.com/images/M/MV5BYjZkZDUwNWYtN2QzMy00M2U4LTgyY2QtYjhiMTYxZDcyZmYwXkEyXkFqcGc@._V1_FMjpg_UX1000_.jpg",
    },
    {
      "title": "Prom Queen",
      "image": "https://pad.mymovies.it/filmclub/2025/05/110/locandina.jpg",
    },
  ];

  static const movies3 = [
    {
      "title": "Friendship",
      "image": "https://i.ebayimg.com/images/g/nQQAAOSw3R1nqsAn/s-l400.jpg",
    },
    {
      "title": "Mickey 17",
      "image": "https://pad.mymovies.it/filmclub/2023/11/247/locandinapg3.jpg",
    },
    {
      "title": "Mission: Impossible 2",
      "image": "https://m.media-amazon.com/images/I/31zB1f3gHIL._AC_UF894,1000_QL80_.jpg",
    },
  ];

  static const movies4 = [
    {
      "title": "Alessandro Borghese 4 Ristoranti",
      "image": "https://images.justwatch.com/poster/241301900/s718/alessandro-borghese-4-ristoranti.jpg",
    },
    {
      "title": "The Last of Us",
      "image": "https://i.ebayimg.com/images/g/bzwAAOSwhfFknCUl/s-l1200.jpg",
    },
    {
      "title": "Make Cavese Great Again",
      "image": "https://m.media-amazon.com/images/S/pv-target-images/e581c8d3b7e005fa48542674173fabc0578988fdee6f3b818e43132fe17a489a.png",
    },
  ];

  Future<List<Series>> _loadUserSeries() async {
    return await DatabaseHelper.instance.getAllSeries();
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
            const SectionTitle(title: "Popular this week"),
            MovieGrid(
              movies: movies1,
              onSeriesUpdated: _refreshSeries,
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: "Le tue serie"),
            FutureBuilder<List<Series>>(
              future: _loadUserSeries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text("Errore nel caricamento delle serie");
                }
                return MovieGridDynamic(
                  series: snapshot.data!,
                  onSeriesUpdated: _refreshSeries,
                );
              },
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: "Consigliati per te"),
            MovieGrid(
              movies: movies3,
              onSeriesUpdated: _refreshSeries,
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: "Da non perdere"),
            MovieGrid(
              movies: movies4,
              onSeriesUpdated: _refreshSeries,
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(onSeriesAdded: _refreshSeries),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              movie["image"]!,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey[800],
              ),
            ),
          ),
        );
      },
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemCount: series.length,
      itemBuilder: (context, index) {
        final s = series[index];
        return GestureDetector(
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
          child: SeriesImage(
            series: s,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
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