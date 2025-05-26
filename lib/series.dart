import 'package:flutter/material.dart';
import 'main.dart'; // Per riutilizzare CustomFooter

class SeriesScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String trama;
  final String genere;
  final String stato; // "In corso", "Completata", "Da guardare", "Nessuno stato"
  final String piattaforma;

  const SeriesScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.trama,
    required this.genere,
    required this.stato,
    required this.piattaforma,
  });

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late String statoSelezionato;

  final List<String> stati = [
    "In corso",
    "Completata",
    "Da guardare",
  ];

  @override
  void initState() {
    super.initState();
    statoSelezionato = stati.contains(widget.stato) ? widget.stato : stati[0];
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrl,
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
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Genere: ${widget.genere}",
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
              "Piattaforma: ${widget.piattaforma}",
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
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.trama,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }
}