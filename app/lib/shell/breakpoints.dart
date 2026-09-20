/// Material 3's compact/medium width cutoff. Below this, screens switch to
/// touch-first stacked layouts; at or above it, the existing desktop
/// two-pane layout is used unchanged. Defined once here — every width check
/// in the app imports this instead of hardcoding 600.
const double kCompactBreakpoint = 600;
