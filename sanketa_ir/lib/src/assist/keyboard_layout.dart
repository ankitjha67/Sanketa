/// A model of a TV's on-screen keyboard grid, for D-pad assist typing (FR-4.4).
///
/// The assist typer converts a target string into the shortest arrow-key path
/// over this grid, so the user taps once per character on their phone and the
/// app drives the arrows. Honest framing in the UI: "assisted arrows," not magic.
library;

class KeyboardLayout {
  const KeyboardLayout({required this.rows, this.wrapHorizontal = true});

  /// Each string is one row; each character is one cell. Rows are assumed to be
  /// the same width (a rectangular grid).
  final List<String> rows;

  /// Whether moving off the left/right edge wraps to the other side (common on
  /// Android TV / Google TV keyboards), which the path planner exploits.
  final bool wrapHorizontal;

  int get height => rows.length;
  int get width => rows.isEmpty ? 0 : rows.first.length;

  /// Grid position of [ch] (row, col), or null if the character is not present.
  (int, int)? find(String ch) {
    for (var r = 0; r < rows.length; r++) {
      final i = rows[r].indexOf(ch);
      if (i >= 0) return (r, i);
    }
    return null;
  }
}

/// A common Android TV lowercase + digits grid (6×6), horizontally wrapping.
const androidTvLowercaseGrid = KeyboardLayout(rows: [
  'abcdef',
  'ghijkl',
  'mnopqr',
  'stuvwx',
  'yz1234',
  '567890',
]);
