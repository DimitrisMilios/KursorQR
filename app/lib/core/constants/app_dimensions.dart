/// Centralized spacing, sizing, radii, and typography scale tokens for KursorQR.
class AppDimensions {
  const AppDimensions._();

  // Layout
  static const double navbarHeight = 72.0;
  static const double maxContentWidth = 1160.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;
  static const double spacingSection = 48.0;

  // Cards
  static const double cardPadding = 22.0;

  // Generic radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;

  // Clay radii & lighting geometry
  static const double radiusClaySm = 16.0; // inputs, wells, rows, tiles
  static const double radiusClay = 24.0; // buttons, toasts, compact cards
  static const double radiusClayLg = 32.0; // panels, dialogs, feature/link cards
  static const double radiusClayXl = 40.0; // floating navbars, hero showcase
  static const double clayDepth = 6.0; // default inner shadow offset
  static const double clayLift = 18.0; // default outer shadow y-offset

  // Font sizes
  static const double fontXs = 10.5;
  static const double fontSm = 12.0;
  static const double fontBody = 13.5;
  static const double fontMd = 14.5;
  static const double fontLg = 16.0;
  static const double fontXl = 20.0;
  static const double fontDisplay = 48.0;
}
