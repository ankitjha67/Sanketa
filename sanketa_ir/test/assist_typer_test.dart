import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';
import 'package:test/test.dart';

void main() {
  const typer = AssistTyper(androidTvLowercaseGrid);

  test('typing across a row emits Right then OK', () {
    // 'a' is at (0,0); 'c' at (0,2). From start (0,0): a=OK, c=Right,Right,OK.
    final plan = typer.planFor('ac');
    expect(plan.keys, [Key.ok, Key.right, Key.right, Key.ok]);
  });

  test('horizontal wrap is used when shorter', () {
    // 'a'(0,0) then 'f'(0,5): direct is Right×5; wrap is Left×1.
    final plan = typer.planFor('af');
    expect(plan.keys, [Key.ok, Key.left, Key.ok]);
  });

  test('vertical moves use Down/Up (no wrap)', () {
    // 'a'(0,0) then 'g'(1,0): one Down.
    final plan = typer.planFor('ag');
    expect(plan.keys, [Key.ok, Key.down, Key.ok]);
  });

  test('one OK per typed character — the "N taps" guarantee (FR-4.4 AC)', () {
    final plan = typer.planFor('lofimusic'); // 9 chars, all on the grid
    final oks = plan.keys.where((k) => k == Key.ok).length;
    expect(oks, 9);
    expect(plan.skipped, 0);
  });

  test('unknown characters are skipped and counted', () {
    final plan = typer.planFor('a b'); // space not on the grid
    expect(plan.skipped, 1);
    expect(plan.keys.where((k) => k == Key.ok).length, 2); // a and b typed
  });

  test('a non-wrapping layout moves directly', () {
    const grid = KeyboardLayout(rows: ['abcdef'], wrapHorizontal: false);
    const t = AssistTyper(grid);
    final plan = t.planFor('af'); // must go Right×5, no wrap
    expect(plan.keys, [Key.ok, ...List.filled(5, Key.right), Key.ok]);
  });
}
