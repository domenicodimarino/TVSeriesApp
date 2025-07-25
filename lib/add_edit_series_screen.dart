import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'series.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'widgets/series_image.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
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
    'Sky',
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
      // Se widget.existingSeries!.isLocalImage è true, allora
      // widget.existingSeries!.imageUrl è già il path completo.
      if (widget.existingSeries != null && widget.existingSeries!.isLocalImage) {
        final String fullPath = widget.existingSeries!.imageUrl;
        final File imageFile = File(fullPath);
      
        if (await imageFile.exists()) {
          setState(() {
            _selectedImage = imageFile;
          });
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
      );


      if (pickedFile != null) {
        // Processa l'immagine per convertirla in JPEG e correggere i colori del format HEIC
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

      // Vengono letti i byte del file HEIC originale
      final Uint8List heicBytes = await heicFile.readAsBytes();

      // Viene decodificata l'immagine usando il package image
      img.Image? originalImage = img.decodeImage(heicBytes);

      if (originalImage != null) {
        // Si ricodifica l'immagine come JPEG
        final List<int> jpegBytes = img.encodeJpg(originalImage, quality: 90);

        // Si salvano i byte JPEG nel nuovo file
        final File jpegFile = File(localJpegPath);
        await jpegFile.writeAsBytes(jpegBytes);

        setState(() {
          _selectedImage = jpegFile;
        });
        print('Immagine HEIC convertita e salvata come JPEG: $localJpegPath');
      } else {  
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
    setState(() => _isLoading = true);
    try {
      if (_formKey.currentState!.validate()) {
        String imageUrlToSave = '';
        if (_useLocalImage && _selectedImage != null) {
          imageUrlToSave = path.basename(_selectedImage!.path);
          print('Saving local image filename: $imageUrlToSave');
        } else if (!_useLocalImage && _urlController.text.isNotEmpty) {
          imageUrlToSave = _urlController.text;
          print('Saving network image URL: $imageUrlToSave');
        } else if (widget.existingSeries != null && widget.existingSeries!.imageUrl.isNotEmpty) {
          imageUrlToSave = widget.existingSeries!.imageUrl;
          print('Keeping existing image URL/path: $imageUrlToSave');
        }

        final newSeries = Series(
          id: _currentEditingSeries?.id,
          title: _titleController.text,
          trama: _tramaController.text,
          genere: _genereController.text,
          stato: _selectedStato,
          piattaforma: _selectedPiattaforma,
          imageUrl: imageUrlToSave,
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
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 8.0 : 16.0;
    final verticalPadding = screenWidth < 400 ? 8.0 : 16.0;
    final imageHeight = screenWidth < 400 ? 120.0 : (screenWidth < 600 ? 160.0 : 200.0);
    final fieldFontSize = screenWidth < 400 ? 13.0 : 16.0;
    final labelFontSize = screenWidth < 400 ? 14.0 : 16.0;
    final buttonFontSize = screenWidth < 400 ? 13.0 : 16.0;

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
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildImagePreview(imageHeight),
                    SizedBox(height: verticalPadding),
                    _buildTextField(_titleController, 'Titolo', maxLines: 1, fontSize: fieldFontSize, labelFontSize: labelFontSize),
                    SizedBox(height: verticalPadding),
                    _buildTextField(_tramaController, 'Trama', maxLines: 5, fontSize: fieldFontSize, labelFontSize: labelFontSize),
                    SizedBox(height: verticalPadding),
                    _buildTextField(_genereController, 'Genere', maxLines: 1, fontSize: fieldFontSize, labelFontSize: labelFontSize),
                    SizedBox(height: verticalPadding),
                    _buildDropdown('Piattaforma', _piattaforme, _selectedPiattaforma, 
                        (value) => setState(() => _selectedPiattaforma = value!), fontSize: fieldFontSize, labelFontSize: labelFontSize),
                    SizedBox(height: verticalPadding),
                    _buildDropdown('Stato', _stati, _selectedStato, 
                        (value) => setState(() => _selectedStato = value!), fontSize: fieldFontSize, labelFontSize: labelFontSize),
                    SizedBox(height: verticalPadding),
                    _buildImageSourceToggle(labelFontSize: labelFontSize, buttonFontSize: buttonFontSize, padding: horizontalPadding),
                    SizedBox(height: verticalPadding),
                    _useLocalImage 
                      ? _buildImageSelector(buttonFontSize: buttonFontSize, padding: horizontalPadding)
                      : _buildUrlField(fontSize: fieldFontSize, labelFontSize: labelFontSize),
                    SizedBox(height: verticalPadding + 8),
                    if (_currentEditingSeries != null) 
                      _buildManageSeasonsButton(buttonFontSize: buttonFontSize, padding: horizontalPadding),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePreview(double imageHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth < 400 ? 150.0 : (screenWidth < 600 ? 200.0 : 240.0);
    final imageHeightFixed = screenWidth < 400 ? 220.0 : (screenWidth < 600 ? 300.0 : 360.0);

    Widget imageWidget;
    if (_useLocalImage && _selectedImage != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          width: imageWidth,
          height: imageHeightFixed,
          fit: BoxFit.cover,
        ),
      );
    } else if (!_useLocalImage && _urlController.text.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _urlController.text,
          width: imageWidth,
          height: imageHeightFixed,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    } else if (_currentEditingSeries != null && _currentEditingSeries!.imageUrl.isNotEmpty) {
      imageWidget = SeriesImage(
        series: _currentEditingSeries!,
        width: imageWidth,
        height: imageHeightFixed,
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return Center(
      child: imageWidget,
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

  Widget _buildTextField(TextEditingController controller, String label, {int? maxLines, double? fontSize, double? labelFontSize}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70, fontSize: labelFontSize),
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

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged, {double? fontSize, double? labelFontSize}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70, fontSize: labelFontSize),
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
          style: TextStyle(color: Colors.white, fontSize: fontSize),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(fontSize: fontSize)),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildImageSourceToggle({double? labelFontSize, double? buttonFontSize, double? padding}) {
    return Container(
      padding: EdgeInsets.all(padding ?? 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo di immagine',
            style: TextStyle(color: Colors.white70, fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('URL', style: TextStyle(color: Colors.white, fontSize: buttonFontSize)),
                  value: false,
                  groupValue: _useLocalImage,
                  onChanged: (value) => setState(() => _useLocalImage = value!),
                  activeColor: const Color(0xFFB71C1C),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('Locale', style: TextStyle(color: Colors.white, fontSize: buttonFontSize)),
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

  Widget _buildImageSelector({double? buttonFontSize, double? padding}) {
    return Container(
      padding: EdgeInsets.all(padding ?? 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Immagine serie',
            style: TextStyle(color: Colors.white70, fontSize: buttonFontSize),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: Text('Seleziona immagine', style: TextStyle(fontSize: buttonFontSize)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
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
                    label: Text('Rimuovi', style: TextStyle(fontSize: buttonFontSize)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildUrlField({double? fontSize, double? labelFontSize}) {
    return _buildTextField(_urlController, 'URL Immagine', maxLines: 1, fontSize: fontSize, labelFontSize: labelFontSize);
  }

  Widget _buildManageSeasonsButton({double? buttonFontSize, double? padding}) {
    return ElevatedButton.icon(
      onPressed: _manageSeasons,
      icon: const Icon(
        Icons.playlist_add,
        color: Colors.white,
      ),
      label: Text(
        "Gestisci Stagioni ed Episodi",
        style: TextStyle(color: Colors.white, fontSize: buttonFontSize),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB71C1C),
        padding: EdgeInsets.symmetric(vertical: padding ?? 16),
      ),
    );
  }
}