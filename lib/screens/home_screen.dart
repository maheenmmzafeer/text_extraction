import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../services/ocr_service.dart';
import '../widgets/language_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  File? _image;
  String _extractedText = "";
  bool _isProcessing = false;
  OCRLanguage _selectedLanguage = OCRLanguage.urdu;

  @override
  void initState() {
    super.initState();
    // Dismiss the native splash screen once this widget is mounted
    FlutterNativeSplash.remove();
  }

  /// Step 1: Open camera. Step 2: Open cropper. Cancel in cropper = retry camera.
  Future<void> _captureImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (pickedFile == null) return; // user cancelled camera

    // Step 2: Open the native crop/rotate editor
    await _openCropper(pickedFile.path);
  }

  /// Opens the native image cropper. If user cancels, re-opens the camera.
  Future<void> _openCropper(String imagePath) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      // Allow free-form crop with original aspect ratio as default
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Image',
          toolbarColor: const Color(0xFF00BFA5),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF00BFA5),
          backgroundColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          // Hide the bottom controls to remove messy rotate/scale options and simplify the UI
          hideBottomControls: true,
        ),
      ],
    );

    if (cropped == null) {
      // User tapped RETRY / cancelled — reopen the camera
      _captureImage();
      return;
    }

    setState(() {
      _image = File(cropped.path);
      _extractedText = "";
    });

    _processImage();
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    final text = await _ocrService.extractText(
      _image!, 
      _selectedLanguage,
    );

    setState(() {
      _extractedText = text;
      _isProcessing = false;
    });

    // Auto-scroll to text after processing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Text copied to clipboard!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    }
  }

  void _clearAll() {
    setState(() {
      _image = null;
      _extractedText = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "TextSnap OCR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blueGrey[800],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selector
              Center(
                child: LanguageSelector(
                  selectedLanguage: _selectedLanguage,
                  onLanguageChanged: (lang) {
                    setState(() {
                      _selectedLanguage = lang;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
  
              // Image Preview Area
              _buildImagePreview(),
  
              const SizedBox(height: 30),
  
              // Action Buttons
              _buildActionButtons(),
  
              const SizedBox(height: 30),
  
              // Extracted Text Area
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_extractedText.isNotEmpty)
                _buildExtractedTextArea(theme),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _image != null
            ? Image.file(_image!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search_rounded, size: 64, color: const Color(0xFF00BFA5).withOpacity(0.35)),
                  const SizedBox(height: 16),
                  Text(
                    "No image captured",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[300],
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _captureImage,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: Text(
              "Capture Image",
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 14, height: 1.0),
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _clearAll,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 14, height: 1.0),
              side: BorderSide(color: const Color(0xFF00BFA5).withOpacity(0.35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "Clear",
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedTextArea(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Extracted Text",
              style: GoogleFonts.notoNastaliqUrdu(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.blueGrey[800],
              ),
            ),
            IconButton(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF00BFA5)),
              tooltip: "Copy to Clipboard",
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00BFA5).withOpacity(0.15)),
          ),
          child: SelectableText(
            _extractedText,
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 13,
              height: 2.5,
              color: Colors.blueGrey[900],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(
            "Copy Text",
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 14, height: 1.0),
            backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
            foregroundColor: const Color(0xFF00BFA5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ).animate().slideY(begin: 0.1, end: 0);
  }
}
