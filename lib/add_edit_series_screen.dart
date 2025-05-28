import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'series.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'widgets/series_image.dart'; // Aggiungi questo import
import 'package:image/image.dart' as img; // Assicurati che questo import sia presente
import 'dart:typed_data';

class AddEditSeriesScreen extends StatefulWidget {
  final Series? existingSeries;

  const AddEditSeriesScreen({super.key, this.existingSeries});

  static const routeName = '/add-edit-series';

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

  // Aggiungi la variabile _isFavorite se non c'è già
  bool _isFavorite = false; 

  @override
  void initState() {
    super.initState();
    
    if (widget.existingSeries != null) {
      _titleController.text = widget.existingSeries!.title;
      _tramaController.text = widget.existingSeries!.trama;
      _genereController.text = widget.existingSeries!.genere;
      _selectedPiattaforma = widget.existingSeries!.piattaforma;
      _selectedStato = widget.existingSeries!.stato;
      _isFavorite = widget.existingSeries!.isFavorite; // Assicurati che _isFavorite sia inizializzata
      
      if (widget.existingSeries!.isLocalImage) {
        _useLocalImage = true;
        // _loadExistingLocalImage() è corretto se imageUrl è già il path completo
        _loadExistingLocalImage(); 
      } else {
        _useLocalImage = false;
        _urlController.text = widget.existingSeries!.imageUrl;
      }
    } else {
      _selectedPiattaforma = _piattaforme.first;
      _selectedStato = _stati.first;
      _isFavorite = false; // Default per nuove serie
    }
  }

  Future<void> _loadExistingLocalImage() async {
    try {
      // Se widget.existingSeries!.isLocalImage è true, allora
      // widget.existingSeries!.imageUrl è già il path completo.
      if (widget.existingSeries != null && widget.existingSeries!.isLocalImage) {
        final String fullPath = widget.existingSeries!.imageUrl;
        final File imageFile = File(fullPath);
      
        if (await imageFile.exists()) {
          setState(() {
            _selectedImage = imageFile;
          });
        } else {
          print('File immagine locale esistente non trovato: $fullPath');
          // Potresti voler resettare _useLocalImage o _selectedImage qui
          // o mostrare un placeholder/errore all'utente.
        }
      }
    } catch (e) {
      print('Errore nel caricamento dell\'immagine locale esistente: $e');
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // Non impostiamo imageQuality qui, lasciamo che il package 'image' gestisca la conversione
      );

      if (pickedFile != null) {
        // Processa l'immagine per convertirla in JPEG e correggere i colori
        await _processAndSaveHeicAsJpeg(pickedFile);
      }
    } catch (e) {
      print('Errore durante la selezione dell\'immagine: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore selezione immagine: $e')),
      );
    }
  }

  Future<void> _processAndSaveHeicAsJpeg(XFile heicFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = path.join(appDir.path, 'images');
      await Directory(imageDir).create(recursive: true);

      // Crea un nome file univoco con estensione .jpg
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localJpegPath = path.join(imageDir, fileName);

      // Leggi i byte del file HEIC originale
      final Uint8List heicBytes = await heicFile.readAsBytes();

      // Decodifica l'immagine usando il package image
      // Questo package ha un supporto migliore per vari formati, incluso HEIC
      img.Image? originalImage = img.decodeImage(heicBytes);

      if (originalImage != null) {
        // Ricodifica l'immagine come JPEG
        // Questo passaggio è cruciale per la corretta conversione del formato e dei colori
        final List<int> jpegBytes = img.encodeJpg(originalImage, quality: 90); // Qualità 90 per buon compromesso

        // Salva i byte JPEG nel nuovo file
        final File jpegFile = File(localJpegPath);
        await jpegFile.writeAsBytes(jpegBytes);

        setState(() {
          _selectedImage = jpegFile;
        });
        print('Immagine HEIC convertita e salvata come JPEG: $localJpegPath');
      } else {
        // Se la decodifica fallisce, prova una copia diretta come fallback
        // (anche se questo probabilmente non risolverà i colori HEIC)
        print('Decodifica HEIC fallita. Tentativo di copia diretta.');
        await heicFile.saveTo(localJpegPath);
         setState(() {
          _selectedImage = File(localJpegPath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formato immagine non supportato per la conversione colori.')),
        );
      }
    } catch (e) {
      print('Errore durante la conversione HEIC->JPEG: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore conversione immagine: $e')),
      );
    }
  }

  Future<void> _saveSeries() async {
    if (_formKey.currentState!.validate()) {
      String imageUrlToSave = '';
      if (_useLocalImage && _selectedImage != null) {
        // Salva solo il nome file, non il path completo!
        imageUrlToSave = path.basename(_selectedImage!.path);
        print('Saving local image filename: $imageUrlToSave');
      } else if (!_useLocalImage && _urlController.text.isNotEmpty) {
        imageUrlToSave = _urlController.text; // URL di rete
        print('Saving network image URL: $imageUrlToSave');
      } else if (widget.existingSeries != null && widget.existingSeries!.imageUrl.isNotEmpty) {
        // Se non è stata selezionata una nuova immagine e non è stato fornito un nuovo URL,
        // mantieni l'immagine esistente.
        imageUrlToSave = widget.existingSeries!.imageUrl;
        print('Keeping existing image URL/path: $imageUrlToSave');
      }

      final newSeries = Series(
        id: widget.existingSeries?.id,
        title: _titleController.text,
        trama: _tramaController.text,
        genere: _genereController.text,
        stato: _selectedStato,
        piattaforma: _selectedPiattaforma,
        imageUrl: imageUrlToSave, // Questo sarà o un path locale o un URL
        isFavorite: _isFavorite, // Usa la variabile di stato _isFavorite
        // Assicurati di passare anche gli altri campi come seasons, dateAdded, ecc. se li usi
        // seasons: widget.existingSeries?.seasons ?? [], 
        // dateAdded: widget.existingSeries?.dateAdded ?? DateTime.now(),
        // dateCompleted: widget.existingSeries?.dateCompleted,
      );

      try {
        if (widget.existingSeries != null) {
          await DatabaseHelper.instance.updateSeries(newSeries);
        } else {
          await DatabaseHelper.instance.insertSeries(newSeries);
        }
        Navigator.pop(context, true); // Indica che le modifiche sono state salvate
      } catch (e) {
        print("Errore durante il salvataggio della serie: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio serie: $e')),
        );
      }
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