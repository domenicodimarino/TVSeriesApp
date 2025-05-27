import 'package:flutter/material.dart';
import 'main.dart'; // Per CustomFooter
import 'series.dart'; // Per il modello Series

class SeriesScreen extends StatefulWidget {
  final Series series;

  const SeriesScreen({
    super.key,
    required this.series,
  });

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late String statoSelezionato;
  late bool isFavorite; // Aggiungi questa variabile

  final List<String> stati = [
    "In corso",
    "Completata",
    "Da guardare",
  ];

  @override
  void initState() {
    super.initState();
    statoSelezionato = stati.contains(widget.series.stato) ? widget.series.stato : stati[0];
    isFavorite = widget.series.isFavorite; // Inizializza lo stato preferiti
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    
    // Qui puoi aggiungere la logica per salvare nel database
    // DatabaseHelper.updateSeriesFavorite(widget.series.id, isFavorite);
    
    // Mostra un messaggio di conferma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite 
            ? '${widget.series.title} aggiunta ai preferiti!' 
            : '${widget.series.title} rimossa dai preferiti!'
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: isFavorite ? Colors.green : Colors.red,
      ),
    );
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.series.imageUrl,
                    height: 260,
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 260,
                      width: 180,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              
              // Titolo con bottone preferiti inline
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.series.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white70,
                      size: 32,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Text(
                "Genere: ${widget.series.genere}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    "Stato: ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  DropdownButton<String>(
                    value: statoSelezionato,
                    dropdownColor: const Color(0xFF181c23),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(),
                    items: stati.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          statoSelezionato = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Piattaforma: ${widget.series.piattaforma}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Trama:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                child: Text(
                  widget.series.trama,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }
}