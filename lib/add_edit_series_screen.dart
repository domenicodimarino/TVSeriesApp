import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'series.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'widgets/series_image.dart';
import 'season_episode_screen.dart';

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
  bool _useLocalImage = false;
  bool _isLoading = false;
  Series? _currentEditingSeries;
  bool _isTemporarySeries = false; // Flag per identificare serie temporanee

  @override
  void initState() {
    super.initState();
    _currentEditingSeries = widget.existingSeries;
    
    if (_currentEditingSeries != null) {
      _titleController.text = _currentEditingSeries!.title;
      _tramaController.text = _currentEditingSeries!.trama;
      _genereController.text = _currentEditingSeries!.genere;
      _selectedPiattaforma = _currentEditingSeries!.piattaforma;
      _selectedStato = _currentEditingSeries!.stato;
      
      if (_currentEditingSeries!.isLocalImage) {
        _useLocalImage = true;
        _loadExistingLocalImage();
      } else {
        _urlController.text = _currentEditingSeries!.imageUrl;
      }
    } else {
      _selectedPiattaforma = _piattaforme.first;
      _selectedStato = _stati.first;
      _useLocalImage = false;
    }
  }

  Future<void> _loadExistingLocalImage() async {
    if (_currentEditingSeries == null) return;
    
    try {
      final String fullPath = await _currentEditingSeries!.getLocalImagePath();
      setState(() {
        _selectedImage = File(fullPath);
      });
    } catch (e) {
      print('Errore nel caricamento dell\'immagine: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento dell\'immagine: $e')),
      );
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
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String imagesDir = path.join(appDir.path, 'images');
        await Directory(imagesDir).create(recursive: true);
        
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String localPath = path.join(imagesDir, fileName);
        
        final File newImage = File(image.path);
        final File savedImage = await newImage.copy(localPath);
        
        setState(() {
          _selectedImage = savedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella selezione dell\'immagine: $e')),
      );
    }
  }

  Future<void> _saveSeries() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String imageUrl = '';
      
      if (_useLocalImage && _selectedImage != null) {
        imageUrl = path.basename(_selectedImage!.path);
      } else if (!_useLocalImage && _urlController.text.isNotEmpty) {
        imageUrl = _urlController.text;
      }

      final newSeries = Series(
        id: _currentEditingSeries?.id,
        title: _titleController.text,
        trama: _tramaController.text,
        genere: _genereController.text,
        stato: _selectedStato,
        piattaforma: _selectedPiattaforma,
        imageUrl: imageUrl,
        isFavorite: _currentEditingSeries?.isFavorite ?? false,
        seasons: _currentEditingSeries?.seasons ?? [],
        dateAdded: _currentEditingSeries?.dateAdded ?? DateTime.now(),
      );

      if (_currentEditingSeries != null) {
        await DatabaseHelper.instance.updateSeries(newSeries);
      } else {
        await DatabaseHelper.instance.insertSeries(newSeries);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel salvataggio: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _manageSeasons() async {
    // Se non c'è una serie esistente, crea una temporanea
    if (_currentEditingSeries == null) {
      if (!_formKey.currentState!.validate()) return;
      
      setState(() => _isLoading = true);
      try {
        String imageUrl = '';
        if (_useLocalImage && _selectedImage != null) {
          imageUrl = path.basename(_selectedImage!.path);
        } else if (!_useLocalImage) {
          imageUrl = _urlController.text;
        }

        final tempSeries = Series(
          title: _titleController.text,
          trama: _tramaController.text,
          genere: _genereController.text,
          stato: _selectedStato,
          piattaforma: _selectedPiattaforma,
          imageUrl: imageUrl,
          seasons: [],
          dateAdded: DateTime.now(),
        );
        
        final id = await DatabaseHelper.instance.insertSeries(tempSeries);
        setState(() {
          _currentEditingSeries = tempSeries.copyWith(id: id);
          _isTemporarySeries = true; // Contrassegna come temporanea
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella creazione temporanea: $e')),
        );
        return;
      } finally {
        setState(() => _isLoading = false);
      }
    }

    // Naviga alla schermata di gestione stagioni
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeasonEpisodeScreen(
          series: _currentEditingSeries!,
          onSave: (updatedSeries) {
            setState(() {
              _currentEditingSeries = updatedSeries;
              _isTemporarySeries = false; // Non è più temporanea
            });
          },
        ),
      ),
    );

    // Se l'utente annulla e la serie era temporanea, eliminala
    if (result == null && _isTemporarySeries) {
      try {
        await DatabaseHelper.instance.deleteSeries(_currentEditingSeries!.id!);
        setState(() {
          _currentEditingSeries = null;
          _isTemporarySeries = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella pulizia: $e')),
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
          if (!_isLoading) IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSeries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                    const SizedBox(height: 24),
                    if (_currentEditingSeries != null) 
                      _buildManageSeasonsButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildManageSeasonsButton() {
    return ElevatedButton.icon(
      onPressed: _manageSeasons,
      icon: const Icon(Icons.playlist_add),
      label: const Text("Gestisci Stagioni ed Episodi"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB71C1C),
        padding: const EdgeInsets.symmetric(vertical: 16),
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
                  onChanged: (value) => setState(() => _useLocalImage = value!),
                  activeColor: const Color(0xFFB71C1C),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Locale', style: TextStyle(color: Colors.white)),
                  value: true,
                  groupValue: _useLocalImage,
                  onChanged: (value) => setState(() => _useLocalImage = value!),
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
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Seleziona immagine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete),
                    label: const Text('Rimuovi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    Widget imageWidget;
    
    if (_useLocalImage && _selectedImage != null) {
      imageWidget = Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (!_useLocalImage && _urlController.text.isNotEmpty) {
      imageWidget = Image.network(
        _urlController.text,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (_currentEditingSeries != null && _currentEditingSeries!.imageUrl.isNotEmpty) {
      imageWidget = SeriesImage(
        series: _currentEditingSeries!,
        height: 200,
        width: double.infinity,
        borderRadius: BorderRadius.circular(8),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[900],
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 48, color: Colors.white70),
          SizedBox(height: 8),
          Text('Nessuna immagine selezionata', 
              style: TextStyle(color: Colors.white70)),
        ],
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
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB71C1C)),
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
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB71C1C)),
        ),
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