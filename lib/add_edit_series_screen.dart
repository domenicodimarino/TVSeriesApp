import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'series.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'widgets/series_image.dart'; // Aggiungi questo import

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
  final TextEditingController _urlController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _useLocalImage = false; // Toggle tra URL e immagine locale

  @override
  void initState() {
    super.initState();
    
    if (widget.existingSeries != null) {
      _titleController.text = widget.existingSeries!.title;
      _tramaController.text = widget.existingSeries!.trama;
      _genereController.text = widget.existingSeries!.genere;
      _selectedPiattaforma = widget.existingSeries!.piattaforma;
      _selectedStato = widget.existingSeries!.stato;
      
      // Determina se l'immagine esistente è locale o remota
      if (widget.existingSeries!.isLocalImage) {
        _useLocalImage = true;
        _loadExistingLocalImage(); // Carica l'immagine locale in modo asincrono
      } else {
        _useLocalImage = false;
        _urlController.text = widget.existingSeries!.imageUrl;
      }
    } else {
      _selectedPiattaforma = _piattaforme.first;
      _selectedStato = _stati.first;
    }
  }

  // Aggiungi questo metodo per caricare correttamente l'immagine esistente
  Future<void> _loadExistingLocalImage() async {
    try {
      final String fullPath = await widget.existingSeries!.getLocalImagePath();
      final File imageFile = File(fullPath);
      
      if (await imageFile.exists()) {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      print('Errore nel caricamento dell\'immagine esistente: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Copia l'immagine nella directory dell'app
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String localPath = path.join(appDir.path, 'images', fileName);
        
        // Crea la directory se non esiste
        await Directory(path.dirname(localPath)).create(recursive: true);
        
        // Copia il file
        final File localFile = await File(image.path).copy(localPath);
        
        setState(() {
          _selectedImage = localFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella selezione dell\'immagine: $e')),
      );
    }
  }

  Future<void> _saveSeries() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl = '';
      
      if (_useLocalImage && _selectedImage != null) {
        // Salva solo il nome del file, non il percorso completo
        imageUrl = path.basename(_selectedImage!.path);
      } else if (!_useLocalImage) {
        imageUrl = _urlController.text;
      }

      final newSeries = Series(
        id: widget.existingSeries?.id,
        title: _titleController.text,
        trama: _tramaController.text,
        genere: _genereController.text,
        stato: _selectedStato,
        piattaforma: _selectedPiattaforma,
        imageUrl: imageUrl,
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
              _buildImageSourceToggle(),
              const SizedBox(height: 16),
              _useLocalImage ? _buildImageSelector() : _buildUrlField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo di immagine',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('URL', style: TextStyle(color: Colors.white)),
                  value: false,
                  groupValue: _useLocalImage,
                  onChanged: (value) {
                    setState(() {
                      _useLocalImage = value!;
                      if (!_useLocalImage) {
                        _selectedImage = null;
                      } else {
                        _urlController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFFB71C1C),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Locale', style: TextStyle(color: Colors.white)),
                  value: true,
                  groupValue: _useLocalImage,
                  onChanged: (value) {
                    setState(() {
                      _useLocalImage = value!;
                      if (!_useLocalImage) {
                        _selectedImage = null;
                      } else {
                        _urlController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFFB71C1C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField() {
    return _buildTextField(_urlController, 'URL Immagine', maxLines: 1);
  }

  Widget _buildImageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Immagine serie',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Seleziona', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Rimuovi', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        if (_useLocalImage && _selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (!_useLocalImage && _urlController.text.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _urlController.text,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white70),
              ),
            ),
          )
        else if (widget.existingSeries != null && widget.existingSeries!.imageUrl.isNotEmpty)
          // Usa SeriesImage che gestisce automaticamente i percorsi corretti
          SeriesImage(
            series: widget.existingSeries!,
            height: 200,
            width: double.infinity,
            borderRadius: BorderRadius.circular(8),
          )
        else
          Container(
            height: 200,
            color: Colors.grey[800],
            child: const Center(
              child: Text('Nessuna immagine selezionata', 
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
      ],
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
}