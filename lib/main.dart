import 'package:flutter/material.dart';
import 'series.dart';
import 'series_screen.dart';
import 'search_screen.dart';
import 'add_edit_series_screen.dart';
import 'database_helper.dart';
import 'analytics_screen.dart';
import 'splash_screen.dart';
import 'categories.dart';
import 'widgets/movie_grid_dynamic.dart';

void main() => runApp(const LetterboxdApp());

class LetterboxdApp extends StatelessWidget {
  const LetterboxdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domflix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181c23),
        appBarTheme: const AppBarTheme(
          color: Color(0xFFB71C1C),
          elevation: 0, // Rimuove l'ombra dell'app bar
          surfaceTintColor: Colors.transparent, // serve per mantenere il colore rosso
        ),
      ),
      // Le route per il navigator dell'app
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        DomflixHomePage.routeName: (context) => const DomflixHomePage(),
        SearchScreen.routeName: (context) => const SearchScreen(),
        AnalyticsScreen.routeName: (context) => const AnalyticsScreen(),
        AddEditSeriesScreen.routeName: (context) => const AddEditSeriesScreen(),
        CategoriesScreen.routeName: (context) => const CategoriesScreen(), 
      },
      onGenerateRoute: (settings) {
        /*
        Per la navigazione verso la schermata di dettaglio di una serie,
        utilizziamo onGenerateRoute per passare gli argomenti necessari.
        */
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
  const DomflixHomePage({super.key});

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
  /*
  Funzione per aggiornare la lista delle serie quando viene aggiunta o modificata una serie.
  Questa funzione viene chiamata dopo che l'utente ha aggiunto o modificato una serie,
  per ricaricare le serie e aggiornare l'interfaccia utente.
  In questo modo viene invocato il metodo build
  */
  void _refreshSeries() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      L'appbar (header) con il logo.
      */
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
        child: FutureBuilder<List<List<Series>>>(
          // vengono caricate le serie in modo asincrono dal db.
          future: Future.wait([
            _loadDatabaseSuggestions(),
            _loadFavoriteSeries(),
            _loadInProgressSeries(),
            _loadWatchLaterSeries(),
            _loadCompletedSeries(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // i dati pronti vengono estratti dallo snapshot.
            // e divisi in diverse sezioni.
            final suggestions = snapshot.data?[0] ?? [];
            final favorites = snapshot.data?[1] ?? [];
            final inProgress = snapshot.data?[2] ?? [];
            final watchLater = snapshot.data?[3] ?? [];
            final completed = snapshot.data?[4] ?? [];
            
            return ListView(
              children: [
                /*
                Sezione con i suggerimenti personalizzati.
                Le serie presenti sono suggerite in base ai generi
                delle serie preferite dell'utente.
                */
                const SectionTitle(title: "🔥 Per te"),
                suggestions.isEmpty
                    ? const EmptySection(message: "Aggiungi qualche serie per vedere i suggerimenti")
                    : MovieGridDynamic(series: suggestions, onSeriesUpdated: _refreshSeries),
                const SizedBox(height: 24),
                
                // Sezione dei preferiti
                const SectionTitle(title: "⭐ I tuoi preferiti"),
                favorites.isEmpty
                    ? const EmptySection(message: "Nessuna serie tra i preferiti")
                    : MovieGridDynamic(series: favorites, onSeriesUpdated: _refreshSeries),
                const SizedBox(height: 24),
                
                // Sezioene delle serie in corso
                const SectionTitle(title: "📺 Le tue serie in corso"),
                inProgress.isEmpty
                    ? const EmptySection(message: "Nessuna serie in corso")
                    : MovieGridDynamic(series: inProgress, onSeriesUpdated: _refreshSeries),
                const SizedBox(height: 24),
                
                // Sezione delle serie da guardare
                const SectionTitle(title: "🎬 Tutte le serie da guardare"),
                watchLater.isEmpty
                    ? const EmptySection(message: "Nessuna serie da guardare")
                    : MovieGridDynamic(series: watchLater, onSeriesUpdated: _refreshSeries),
                const SizedBox(height: 24),
                
                // Sezione delle serie completate
                const SectionTitle(title: "✅ Serie completate"),
                completed.isEmpty
                    ? const EmptySection(message: "Nessuna serie completata")
                    : MovieGridDynamic(series: completed, onSeriesUpdated: _refreshSeries),
                const SizedBox(height: 90),
              ],
            );
          },
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

// Il widget per il titolo delle sezioni
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
/*
Il footer personalizzato con le icone per la navigazione.
Questo widget contiene le icone per la navigazione tra le schermate principali dell'app.
*/
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
          // tasto per andare alla home
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white, size: 30),
            onPressed: () {
              // Se non siamo già sulla home, andiamo alla home
              if (ModalRoute.of(context)?.settings.name != DomflixHomePage.routeName) {
                // Rimuoviamo tutto lo stack di route
                Navigator.of(context).pushNamedAndRemoveUntil(
                  DomflixHomePage.routeName,
                  (route) => false, // Rimuove tutte le routes esistenti
                );
              }
            },
          ),
          // tasto per andare alla schermata di ricerca
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 30),
            onPressed: () async { 
              if (ModalRoute.of(context)?.settings.name != SearchScreen.routeName) {
                // Se non siamo già nella schermata di ricerca, andiamo lì
                final result = await Navigator.pushNamed( 
                  context,
                  SearchScreen.routeName,
                );
                
                // Si aggiorna la home quando si toran dalla ricerca con modifiche
                if (result == true) {
                  onSeriesAdded();
                }
              }
            },
          ),
          // tasto per andare alla schermata per aggiungere una nuova serie
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
          // tasto per andare alla schermata delle categorie
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white, size: 30),
            onPressed: () async { 
              // Se non siamo già nella schermata delle categorie, andiamo lì
              if (ModalRoute.of(context)?.settings.name != CategoriesScreen.routeName) {
                final result = await Navigator.pushNamed(
                  context,
                  CategoriesScreen.routeName,
                );
                
                // Si aggiorna la home quando si torna dalle categorie con modifiche
                if (result == true) {
                  onSeriesAdded();
                }
              }
            },
          ),
          // tasto per andare alla schermata di analytics
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white, size: 30),
            onPressed: () async { 
              if (ModalRoute.of(context)?.settings.name != AnalyticsScreen.routeName) {
                final result = await Navigator.pushNamed(
                  context,
                  AnalyticsScreen.routeName,
                );
                
                // Si aggiorna la home quando si torna da analytics con modifiche
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
