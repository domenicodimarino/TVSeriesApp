import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'series.dart';

class AddEditSeriesScreen extends StatefulWidget {
  final Series? existingSeries;

  const AddEditSeriesScreen({super.key, this.existingSeries});

  @override
  State<AddEditSeriesScreen> createState() => _AddEditSeriesScreenState();
}

class _AddEditSeriesScreenState extends State<AddEditSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _piattaforme = [
    'Netflix',
    'Prime Video',
    'Disney+',
    'HBO Max',
    'Apple TV+',
    'Altro'
  ];
  final List<String> _stati = ["In corso", "Completata", "Da guardare"];

  late String _selectedPiattaforma;
  late String _selectedStato;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tramaController = TextEditingController();
  final TextEditingController _genereController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    if (widget.existingSeries != null) {
      _titleController.text = widget.existingSeries!.title;
      _tramaController.text = widget.existingSeries!.trama;
      _genereController.text = widget.existingSeries!.genere;
      _imageController.text = widget.existingSeries!.imageUrl;
      _selectedPiattaforma = widget.existingSeries!.piattaforma;
      _selectedStato = widget.existingSeries!.stato;
    } else {
      _selectedPiattaforma = _piattaforme.first;
      _selectedStato = _stati.first;
    }
  }

  Future<void> _saveSeries() async {
    if (_formKey.currentState!.validate()) {
      final newSeries = Series(
        id: widget.existingSeries?.id,
        title: _titleController.text,
        trama: _tramaController.text,
        genere: _genereController.text,
        stato: _selectedStato,
        piattaforma: _selectedPiattaforma,
        imageUrl: _imageController.text,
        isFavorite: widget.existingSeries?.isFavorite ?? false,
      );

      if (widget.existingSeries != null) {
        await DatabaseHelper.instance.updateSeries(newSeries);
      } else {
        await DatabaseHelper.instance.insertSeries(newSeries);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: Text(
          widget.existingSeries != null 
              ? 'Modifica serie' 
              : 'Aggiungi nuova serie',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSeries,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePreview(),
              const SizedBox(height: 20),
              _buildTextField(_titleController, 'Titolo', maxLines: 1),
              const SizedBox(height: 16),
              _buildTextField(_tramaController, 'Trama', maxLines: 5),
              const SizedBox(height: 16),
              _buildTextField(_genereController, 'Genere', maxLines: 1),
              const SizedBox(height: 16),
              _buildDropdown('Piattaforma', _piattaforme, _selectedPiattaforma, 
                  (value) => setState(() => _selectedPiattaforma = value!)),
              const SizedBox(height: 16),
              _buildDropdown('Stato', _stati, _selectedStato, 
                  (value) => setState(() => _selectedStato = value!)),
              const SizedBox(height: 16),
              _buildTextField(_imageController, 'URL Immagine', maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int? maxLines}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obbligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF181c23),
          style: const TextStyle(color: Colors.white),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        if (_imageController.text.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _imageController.text,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white70),
              ),
            ),
          ),
        if (_imageController.text.isEmpty)
          Container(
            height: 200,
            color: Colors.grey[800],
            child: const Center(
              child: Text('Anteprima immagine', 
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
      ],
    );
  }
}