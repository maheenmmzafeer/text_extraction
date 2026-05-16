import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ocr_service.dart';

class LanguageSelector extends StatelessWidget {
  final OCRLanguage selectedLanguage;
  final Function(OCRLanguage) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildLanguageChip(
            label: "English",
            language: OCRLanguage.english,
            isSelected: selectedLanguage == OCRLanguage.english,
          ),
          _buildLanguageChip(
            label: "اردو",
            language: OCRLanguage.urdu,
            isSelected: selectedLanguage == OCRLanguage.urdu,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip({
    required String label,
    required OCRLanguage language,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onLanguageChanged(language),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
