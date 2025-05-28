import 'package:flutter/material.dart';
import 'main.dart';
import 'series.dart';
import 'database_helper.dart';
import 'add_edit_series_screen.dart'; // Aggiungi questo import
import 'widgets/series_image.dart';

class SeriesScreen extends StatefulWidget {
  final Series series;
  final VoidCallback onSeriesUpdated;

  const SeriesScreen({
    super.key,
    required this.series,
    required this.onSeriesUpdated,
  });

      static const routeName = '/series';

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late String statoSelezionato;
  late bool isFavorite;
  final List<String> stati = ["In corso", "Completata", "Da guardare"];

  @override
  void initState() {
    super.initState();
    statoSelezionato = widget.series.stato;
    isFavorite = widget.series.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    setState(() => isFavorite = !isFavorite);
    
    await DatabaseHelper.instance.updateFavoriteStatus(
      widget.series.id!,
      isFavorite,
    );

    _showSnackBar(
      isFavorite 
        ? '${widget.series.title} aggiunta ai preferiti!'
        : '${widget.series.title} rimossa dai preferiti!',
      isFavorite ? Colors.green : Colors.red,
    );

    widget.onSeriesUpdated();
  }

  Future<void> _updateSeriesState(String newState) async {
    setState(() => statoSelezionato = newState);
    
    final updatedSeries = widget.series.copyWith(stato: newState);
    await DatabaseHelper.instance.updateSeries(updatedSeries);
    
    widget.onSeriesUpdated();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: CustomFooter(
        onSeriesAdded: widget.onSeriesUpdated,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFB71C1C),
      title: Image.asset("assets/domflix_logo.jpeg", height: 38),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (String result) {
            switch (result) {
              case 'edit':
                _editSeries();
                break;
              case 'delete':
                _showDeleteConfirmation();
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifica'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Elimina', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Metodo per modificare la serie
  void _editSeries() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSeriesScreen(existingSeries: widget.series),
      ),
    );

    if (result == true) {
      widget.onSeriesUpdated();
      Navigator.pop(context); // Torna alla schermata principale dopo la modifica
    }
  }

  // Metodo per mostrare la conferma di eliminazione
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Conferma eliminazione',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Sei sicuro di voler eliminare "${widget.series.title}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSeries();
              },
              child: const Text(
                'Elimina',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Metodo per eliminare la serie
  void _deleteSeries() async {
    try {
      await DatabaseHelper.instance.deleteSeries(widget.series.id!);
      
      _showSnackBar(
        '${widget.series.title} eliminata con successo!',
        Colors.green,
      );

      widget.onSeriesUpdated();
      Navigator.pop(context); // Torna alla schermata principale
    } catch (e) {
      _showSnackBar(
        'Errore durante l\'eliminazione: $e',
        Colors.red,
      );
    }
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeriesImage(),
            const SizedBox(height: 18),
            _buildTitleRow(),
            const SizedBox(height: 8),
            _buildInfoRow("Genere:", widget.series.genere),
            const SizedBox(height: 8),
            _buildStateDropdown(),
            const SizedBox(height: 8),
            _buildInfoRow("Piattaforma:", widget.series.piattaforma),
            const SizedBox(height: 16),
            _buildPlotSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesImage() {
    return Center(
      child: SeriesImage(
        series: widget.series,
        height: 260,
        width: 180,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Row(
      children: [
        const Text(
          "Stato:",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: statoSelezionato,
          dropdownColor: const Color(0xFF181c23),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          underline: Container(),
          items: stati.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) _updateSeriesState(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildPlotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trama:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.series.trama,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}