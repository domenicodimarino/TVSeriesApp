import 'package:flutter/material.dart';

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
          surfaceTintColor: Colors.transparent, // aggiungi questa riga
        ),
      ),
      home: const DomflixHomePage(),
    );
  }
}

class DomflixHomePage extends StatelessWidget {
  const DomflixHomePage({Key? key}) : super(key: key);

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

  static const movies2 = [
    {
      "title": "Lilo & Stitch",
      "image": "https://pad.mymovies.it/filmclub/2023/02/172/locandina.jpg",
    },
    {
      "title": "Sinners",
      "image": "https://m.media-amazon.com/images/M/MV5BNjIwZWY4ZDEtMmIxZS00NDA4LTg4ZGMtMzUwZTYyNzgxMzk5XkEyXkFqcGc@._V1_.jpg",
    },
    {
      "title": "Thunderbolts",
      "image": "https://imgc.allpostersimages.com/img/posters/marvel-thunderbolts-2025-teaser-one-sheet_u-l-q1tebjc0.jpg?artHeight=550&artPerspective=y&artWidth=550&background=ffffff",
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
            MovieGrid(movies: movies1),
            const SizedBox(height: 24),
            const SectionTitle(title: "Le tue serie in corso"),
            MovieGrid(movies: movies2),
            const SizedBox(height: 24),
            const SectionTitle(title: "Consigliati per te"),
            MovieGrid(movies: movies3),
            const SizedBox(height: 24),
            const SectionTitle(title: "Da non perdere"),
            MovieGrid(movies: movies4),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: const CustomFooter(),
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
  const MovieGrid({super.key, required this.movies});

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
                  imageUrl: movie["image"]!,
                  title: movie["title"]!,
                  trama: "Trama di esempio per ${movie["title"]}", // DA SOSTITUIRE con la trama reale
                  genere: "Genere di esempio", // DA SOSTITUIRE con il genere reale
                  stato: "In corso", // DA SOSTITUIRE con lo stato reale
                  piattaforma: "Netflix", // DA SOSTITUIRE con la piattaforma reale
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

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFF23272F),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.white, size: 30),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 30),
            onPressed: () {},
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

class SeriesScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String trama;
  final String genere;
  final String stato;
  final String piattaforma;

  const SeriesScreen({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.trama,
    required this.genere,
    required this.stato,
    required this.piattaforma,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(imageUrl),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Trama: $trama",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Genere: $genere",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Stato: $stato",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Piattaforma: $piattaforma",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}