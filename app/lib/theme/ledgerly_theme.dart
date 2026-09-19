import 'package:flutter/material.dart';

/// Palette from the approved mockups: paper ground with a cool bias, ink text,
/// fountain-pen blue for focus and actions, green for money coming in
/// (receivable), rust for money going out (giveable).
class LedgerlyColors extends ThemeExtension<LedgerlyColors> {
  const LedgerlyColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.rule,
    required this.ruleSoft,
    required this.accent,
    required this.accentSoft,
    required this.receivable,
    required this.receivableSoft,
    required this.giveable,
    required this.giveableSoft,
    required this.selection,
    required this.keybar,
    required this.keybarInk,
  });

  final Color paper,
      surface,
      ink,
      ink2,
      ink3,
      rule,
      ruleSoft,
      accent,
      accentSoft;
  final Color receivable,
      receivableSoft,
      giveable,
      giveableSoft,
      selection,
      keybar,
      keybarInk;

  static const light = LedgerlyColors(
    paper: Color(0xFFF4F6F2),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1A2320),
    ink2: Color(0xFF4C5852),
    ink3: Color(0xFF7A867F),
    rule: Color(0xFFC9D0C8),
    ruleSoft: Color(0xFFE3E8E1),
    accent: Color(0xFF2456A4),
    accentSoft: Color(0xFFE4ECF9),
    receivable: Color(0xFF1F7A4D),
    receivableSoft: Color(0xFFE2F1E8),
    giveable: Color(0xFFB04A22),
    giveableSoft: Color(0xFFF7E7DE),
    selection: Color(0xFFEEF3FB),
    keybar: Color(0xFF1A2320),
    keybarInk: Color(0xFFE8EDE8),
  );

  static const dark = LedgerlyColors(
    paper: Color(0xFF151B1E),
    surface: Color(0xFF1C2428),
    ink: Color(0xFFE6EBE8),
    ink2: Color(0xFFB4BEB8),
    ink3: Color(0xFF7F8B85),
    rule: Color(0xFF33403C),
    ruleSoft: Color(0xFF26312E),
    accent: Color(0xFF7FA6E8),
    accentSoft: Color(0xFF1E2C41),
    receivable: Color(0xFF5FC08D),
    receivableSoft: Color(0xFF163024),
    giveable: Color(0xFFE58A63),
    giveableSoft: Color(0xFF3A2419),
    selection: Color(0xFF233042),
    keybar: Color(0xFF0E1214),
    keybarInk: Color(0xFFD6DDD8),
  );

  @override
  LedgerlyColors copyWith() => this;

  @override
  LedgerlyColors lerp(LedgerlyColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension LedgerlyThemeX on BuildContext {
  LedgerlyColors get colors => Theme.of(this).extension<LedgerlyColors>()!;
}

/// Numbers are set in the mono face with tabular digits so columns line up.
const TextStyle numberStyle = TextStyle(
  fontFamily: 'IBM Plex Mono',
  fontFeatures: [FontFeature.tabularFigures()],
);

ThemeData ledgerlyTheme(Brightness brightness) {
  final c = brightness == Brightness.light
      ? LedgerlyColors.light
      : LedgerlyColors.dark;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'IBM Plex Sans',
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: c.accent,
      surface: c.surface,
      onSurface: c.ink,
    ),
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    dividerColor: c.ruleSoft,
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: c.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: c.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
    ),
    extensions: [c],
  );
}
