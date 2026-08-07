import 'package:flutter/material.dart';

/// A reusable Text wrapper that applies the project's Poppins font by default.
///
/// Every piece of copy in the app goes through this widget, which is what keeps
/// typography consistent across screens: callers override only what they need
/// (size, weight, colour) and inherit sensible defaults for everything else.
class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.fontFamily = 'Poppins',
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.letterSpacing = 0,
    this.fontStyle = FontStyle.normal,
    this.color,
    this.maxLines,
    this.overflow,
  });

  /// The string to render.
  final String text;

  /// Font size in logical pixels (callers usually pass a `.sp` value).
  final double fontSize;

  /// Extra space between letters.
  final double letterSpacing;

  /// Maximum number of lines before [overflow] applies.
  final int? maxLines;

  /// How text that exceeds [maxLines] should be visually truncated.
  final TextOverflow? overflow;

  /// Thickness of the glyphs.
  final FontWeight fontWeight;

  /// Horizontal alignment of the text within its box.
  final TextAlign textAlign;

  /// Font family name as declared in pubspec.yaml.
  final String fontFamily;

  /// Normal or italic.
  final FontStyle fontStyle;

  /// Optional colour override. When null the text inherits the active theme's
  /// colour, so the same widget works in both light and dark mode.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }
}
