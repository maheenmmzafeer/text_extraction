import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import 'app_action_button.dart';

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
          Expanded(
            child: AppActionButton(
              label: 'English',
              onPressed: () => onLanguageChanged(OCRLanguage.english),
              selected: selectedLanguage == OCRLanguage.english,
              compact: true,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: AppActionButton(
              label: 'اردو',
              onPressed: () => onLanguageChanged(OCRLanguage.urdu),
              selected: selectedLanguage == OCRLanguage.urdu,
              compact: true,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
