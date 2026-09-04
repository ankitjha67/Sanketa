/// D-pad assist typer (PRD FR-4.4).
///
/// Turns a target string into the arrow-key path over a [KeyboardLayout],
/// exploiting horizontal wrap to cut presses (roughly 3× fewer than manual
/// arrowing). The user still taps once per character; this computes the arrows
/// between them. Pure and fully tested — no device needed.
library;

import 'package:sanketa_core/sanketa_core.dart';

import 'keyboard_layout.dart';

class AssistPlan {
  const AssistPlan({required this.keys, required this.skipped});

  /// The arrow + OK sequence to emit.
  final List<Key> keys;

  /// Characters not present on the layout (skipped).
  final int skipped;
}

class AssistTyper {
  const AssistTyper(this.layout);

  final KeyboardLayout layout;

  /// Compute the key path to type [text], starting from cursor [startRow],
  /// [startCol]. Input is lower-cased to match the grid. Unknown characters are
  /// skipped and counted in [AssistPlan.skipped].
  AssistPlan planFor(String text, {int startRow = 0, int startCol = 0}) {
    final keys = <Key>[];
    var r = startRow;
    var c = startCol;
    var skipped = 0;

    for (final ch in text.toLowerCase().split('')) {
      final pos = layout.find(ch);
      if (pos == null) {
        skipped++;
        continue;
      }
      final (targetRow, targetCol) = pos;

      // Vertical: no wrap.
      final dr = targetRow - r;
      for (var i = 0; i < dr.abs(); i++) {
        keys.add(dr > 0 ? Key.down : Key.up);
      }

      // Horizontal: exploit wrap when it is shorter.
      final cols = layout.width;
      if (layout.wrapHorizontal && cols > 0) {
        final right = ((targetCol - c) % cols + cols) % cols;
        final left = (cols - right) % cols;
        if (left < right) {
          for (var i = 0; i < left; i++) {
            keys.add(Key.left);
          }
        } else {
          for (var i = 0; i < right; i++) {
            keys.add(Key.right);
          }
        }
      } else {
        final dc = targetCol - c;
        for (var i = 0; i < dc.abs(); i++) {
          keys.add(dc > 0 ? Key.right : Key.left);
        }
      }

      keys.add(Key.ok);
      r = targetRow;
      c = targetCol;
    }

    return AssistPlan(keys: keys, skipped: skipped);
  }
}
