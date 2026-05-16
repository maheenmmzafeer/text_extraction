import 'package:flutter/material.dart';

class AppActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;
  final bool filled;
  final bool compact;
  final double fontSize;

  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
    this.filled = false,
    this.compact = false,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00BFA5);
    final enabled = onPressed != null;
    final isHighlighted = selected || filled;
    final backgroundColor = isHighlighted ? accent : Colors.white;
    final foregroundColor = isHighlighted ? Colors.white : accent;
    final borderColor = isHighlighted ? accent : accent.withOpacity(0.35);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: backgroundColor,
        elevation: isHighlighted ? 0 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 10 : 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 16 : 18, color: foregroundColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: fontSize,
                      fontWeight:
                          isHighlighted ? FontWeight.w700 : FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}