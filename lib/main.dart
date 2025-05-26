import 'package:flutter/material.dart';

void main() => runApp(const LetterboxdApp());

class LetterboxdApp extends StatelessWidget {
  const LetterboxdApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Letterboxd',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181c23),
        appBarTheme: const AppBarTheme(
          color: Color(0xFFB71C1C), // Rosso fisso
          elevation: 0,
        ),
      ),
      home: const LetterboxdHomePage(),
    );
  }
}

class LetterboxdHomePage extends StatelessWidget {
  const LetterboxdHomePage({Key? key}) : super(key: key);

  static const movies1 = [
    {
      "title": "Mission: Impossible",
      "image": "https://upload.wikimedia.org/wikipedia/en/2/2d/Mission_Impossible_Fallout_poster.jpg",
    },
    {
      "title": "Final Destination",
      "image": "https://m.media-amazon.com/images/I/81G2QkZ3Z-L._AC_SY679_.jpg",
    },
    {
      "title": "Prom Queen",
      "image": "https://m.media-amazon.com/images/I/71F5Lh6Y8GL._AC_SY679_.jpg",
    },
  ];

  static const movies2 = [
    {
      "title": "Lilo & Stitch",
      "image": "https://m.media-amazon.com/images/I/81K6ZQfQmPL._AC_SY679_.jpg",
    },
    {
      "title": "Sinners",
      "image": "https://m.media-amazon.com/images/I/81uL0kDgD-L._AC_SY679_.jpg",
    },
    {
      "title": "Thunderbolts",
      "image": "https://m.media-amazon.com/images/I/81fB5bq1rPL._AC_SY679_.jpg",
    },
  ];

  static const movies3 = [
    {
      "title": "Friendship",
      "image": "https://m.media-amazon.com/images/I/81C3mB3p3XL._AC_SY679_.jpg",
    },
    {
      "title": "Mickey 17",
      "image": "https://m.media-amazon.com/images/I/81ntqBsN8CL._AC_SY679_.jpg",
    },
    {
      "title": "Mission: Impossible 2",
      "image": "https://m.media-amazon.com/images/I/81bJZkZ7pIL._AC_SY679_.jpg",
    },
  ];

  static const movies4 = [
    {
      "title": "Nuova Serie 1",
      "image": "https://m.media-amazon.com/images/I/81BESZ4nKPL._AC_SY679_.jpg",
    },
    {
      "title": "Nuova Serie 2",
      "image": "https://m.media-amazon.com/images/I/81gTwYAhU7L._AC_SY679_.jpg",
    },
    {
      "title": "Nuova Serie 3",
      "image": "https://m.media-amazon.com/images/I/81vpsIs58WL._AC_SY679_.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C), // Rosso fisso
        elevation: 0,
        title: const Text(
          "DomFlix",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.grey[900],
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