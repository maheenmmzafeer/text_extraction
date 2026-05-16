import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pdfx/pdfx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../services/ocr_service.dart';
import '../widgets/app_action_button.dart';
import '../widgets/language_selector.dart';

enum _PdfAction {
  selectedRange,
  chunkSession,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _pageStartController =
      TextEditingController(text: '1');
  final TextEditingController _pageEndController =
      TextEditingController(text: '1');

  static const int _pagesPerBatch = 3;
  File? _selectedFile;
  bool _selectedFileIsPdf = false;
  String _extractedText = "";
  bool _isProcessing = false;
  int _pdfPagesProcessed = 0;
  int _pdfPagesTotal = 0;
  int _pdfRangeStart = 1;
  int _pdfRangeEnd = 1;
  OCRLanguage _selectedLanguage = OCRLanguage.urdu;
  bool _isChunkMode = false;
  int _currentChunkStart = 1;
  _PdfAction? _activePdfAction;

  @override
  void initState() {
    super.initState();
    // Dismiss the native splash screen once this widget is mounted
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageStartController.dispose();
    _pageEndController.dispose();
    super.dispose();
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

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final pdfFile = File(result.files.single.path!);
    final doc = await PdfDocument.openFile(pdfFile.path);
    final totalPages = doc.pagesCount;
    await doc.close();

    setState(() {
      _selectedFile = pdfFile;
      _selectedFileIsPdf = true;
      _extractedText = "";
      _pdfPagesProcessed = 0;
      _pdfPagesTotal = totalPages;
      _pdfRangeStart = 1;
      _pdfRangeEnd = totalPages;
      _pageStartController.text = '1';
      _pageEndController.text = totalPages.toString();
      _isChunkMode = false;
      _currentChunkStart = 1;
      _activePdfAction = null;
    });
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
      // User tapped RETRY / cancelled. Reopen the camera.
      _captureImage();
      return;
    }

    setState(() {
      _selectedFile = File(cropped.path);
      _selectedFileIsPdf = false;
      _extractedText = "";
      _pdfPagesProcessed = 0;
      _pdfPagesTotal = 0;
    });

    _processSelectedFile();
  }

  Future<String> _processPdfRangeInBatches({
    required int rangeStart,
    required int rangeEnd,
    required bool chunkSession,
  }) async {
    final buffer = StringBuffer();
    var batchStart = rangeStart;

    while (batchStart <= rangeEnd) {
      final batchEnd = math.min(batchStart + _pagesPerBatch - 1, rangeEnd);
      final currentBatchStart = batchStart;

      final text = await _ocrService.extractTextFromPdfChunk(
        _selectedFile!,
        _selectedLanguage,
        startPage: currentBatchStart,
        pageCount: batchEnd - batchStart + 1,
        onProgress: (processedPages, totalPages) {
          if (!mounted) {
            return;
          }

          setState(() {
            _pdfPagesProcessed = processedPages;
            _pdfPagesTotal = totalPages;
            _currentChunkStart = currentBatchStart;
          });
        },
      );

      final trimmedText = text.trim();
      if (trimmedText.isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.writeln(trimmedText);
      }

      if (!mounted) {
        return buffer.toString().trim();
      }

      setState(() {
        _extractedText = buffer.toString().trim();
        _isChunkMode = chunkSession;
        _currentChunkStart = batchEnd + 1;
      });

      batchStart = batchEnd + 1;
    }

    return buffer.toString().trim();
  }

  Future<void> _processSelectedFile() async {
    if (_selectedFile == null) return;

    if (_selectedFileIsPdf) {
      final startPage = int.tryParse(_pageStartController.text.trim()) ?? 1;
      final endPage =
          int.tryParse(_pageEndController.text.trim()) ?? _pdfPagesTotal;
      final clampedStart = startPage.clamp(1, _pdfPagesTotal);
      final clampedEnd = endPage.clamp(1, _pdfPagesTotal);

      if (clampedStart > clampedEnd) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page start must be less than or equal to page end.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
        return;
      }

      setState(() {
        _pdfRangeStart = clampedStart;
        _pdfRangeEnd = clampedEnd;
        _currentChunkStart = clampedStart;
        _activePdfAction = _PdfAction.selectedRange;
        _isChunkMode = false;
      });
    }

    setState(() {
      _isProcessing = true;
    });

    final text = _selectedFileIsPdf
        ? await _processPdfRangeInBatches(
            rangeStart: _pdfRangeStart,
            rangeEnd: _pdfRangeEnd,
            chunkSession: false,
          )
        : await _ocrService.extractText(_selectedFile!, _selectedLanguage);

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

  Future<void> _startChunkSession() async {
    if (!_selectedFileIsPdf || _selectedFile == null) return;

    final rangeStart = _pdfRangeStart.clamp(1, _pdfPagesTotal);
    final rangeEnd = _pdfRangeEnd.clamp(1, _pdfPagesTotal);
    if (rangeStart > rangeEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Page start must be less than or equal to page end.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _isChunkMode = true;
      _activePdfAction = _PdfAction.chunkSession;
      _currentChunkStart = rangeStart;
      _extractedText = '';
      _pdfPagesProcessed = 0;
    });

    try {
      final text = await _processPdfRangeInBatches(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        chunkSession: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _extractedText = text;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isChunkMode = false;
        });
      }
    }
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
      _selectedFile = null;
      _selectedFileIsPdf = false;
      _extractedText = "";
      _pdfPagesProcessed = 0;
      _pdfPagesTotal = 0;
      _pdfRangeStart = 1;
      _pdfRangeEnd = 1;
      _pageStartController.text = '1';
      _pageEndController.text = '1';
      _isChunkMode = false;
      _currentChunkStart = 1;
      _activePdfAction = null;
    });
  }

  Future<void> _exportText() async {
    if (_extractedText.trim().isEmpty) {
      return;
    }

    final exportedPath = await FilePicker.saveFile(
      dialogTitle: 'Save extracted text',
      fileName: 'extracted_text.txt',
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      bytes: Uint8List.fromList(utf8.encode(_extractedText)),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exportedPath == null
              ? 'Export canceled.'
              : 'Text exported successfully.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00BFA5),
      ),
    );
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFileIsPdf && _pdfPagesTotal > 0
                              ? 'Processing PDF page ${_pdfPagesProcessed < _pdfRangeStart ? _pdfRangeStart : _pdfPagesProcessed} of $_pdfRangeEnd'
                              : 'Processing image OCR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
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
        child: _selectedFile != null
            ? _selectedFileIsPdf
                ? _buildPdfPreview()
                : Image.file(_selectedFile!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search_rounded,
                      size: 64,
                      color: const Color(0xFF00BFA5).withOpacity(0.35)),
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

  Widget _buildPdfPreview() {
    final fileName = _selectedFile!.path.split(Platform.pathSeparator).last;

    return Container(
      color: const Color(0xFFF8FAFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 72,
              color: const Color(0xFF00BFA5).withOpacity(0.75),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                fileName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'PDF selected for OCR',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final topButtonWidth = isWide
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        final halfWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: topButtonWidth,
                  child: AppActionButton(
                    label: 'Capture Image',
                    icon: Icons.camera_alt_rounded,
                    onPressed: _isProcessing ? null : _captureImage,
                    compact: true,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(
                  width: topButtonWidth,
                  child: AppActionButton(
                    label: 'Import PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: _isProcessing ? null : _pickPdf,
                    compact: true,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(
                  width: topButtonWidth,
                  child: AppActionButton(
                    label: 'Clear',
                    onPressed: _isProcessing ? null : _clearAll,
                    compact: true,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            if (_selectedFileIsPdf && _selectedFile != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: halfWidth,
                    child: TextFormField(
                      controller: _pageStartController,
                      keyboardType: TextInputType.number,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        labelText: 'From page',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: halfWidth,
                    child: TextFormField(
                      controller: _pageEndController,
                      keyboardType: TextInputType.number,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        labelText: 'To page',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: halfWidth,
                    child: AppActionButton(
                      label: 'Process Selected Range',
                      onPressed: _isProcessing ? null : _processSelectedFile,
                      selected: _activePdfAction == _PdfAction.selectedRange,
                      filled: _activePdfAction == _PdfAction.selectedRange,
                      compact: true,
                      fontSize: 12.2,
                    ),
                  ),
                  SizedBox(
                    width: halfWidth,
                    child: AppActionButton(
                      label: 'Start Chunk Session',
                      onPressed: _isProcessing ? null : _startChunkSession,
                      selected: _activePdfAction == _PdfAction.chunkSession,
                      filled: _activePdfAction == _PdfAction.chunkSession,
                      compact: true,
                      fontSize: 12.2,
                    ),
                  ),
                ],
              ),
              if (_isChunkMode) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00BFA5).withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    'Chunk session active. Processing 3 pages per request with model-specific pacing. Next batch starts at page $_currentChunkStart.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
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
            Row(
              children: [
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_all_rounded,
                      color: Color(0xFF00BFA5)),
                  tooltip: "Copy to Clipboard",
                ),
                IconButton(
                  onPressed: _exportText,
                  icon: const Icon(Icons.download_rounded,
                      color: Color(0xFF00BFA5)),
                  tooltip: "Export TXT",
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFF00BFA5).withOpacity(0.15)),
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
      ],
    ).animate().slideY(begin: 0.1, end: 0);
  }
}
