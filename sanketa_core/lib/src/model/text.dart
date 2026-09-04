/// Text-injection model — the hero feature's data type (PRD FR-4).
///
/// A [TextOp] is a single operation against the *TV's* focused text field. The
/// keyboard surface streams these; adapters translate them to each platform's
/// native mechanism (Android TV text events, Tizen text channel, webOS IME
/// insert/delete, Roku literal keys, BRAVIA text-form).
///
/// PRIVACY RED LINE (CONTEXT.md §9.1): the payload in [TextOp.insert] is never
/// logged, never analysed, and never leaves the phone except to the target TV.
/// Do not add toString()/logging that echoes [text].
library;

enum TextOpKind { insert, delete, clear, submit }

/// How much text a target can accept at once (PRD FR-4.1 capability flag).
/// - [live]: per-keystroke streaming (Android TV, Tizen, webOS, Roku).
/// - [bulk]: compose-then-send; UI shows a single Send action.
/// - [none]: no injection path; UI offers D-pad assist mode (FR-4.4) instead.
enum TextInjectionMode { live, bulk, none }

/// A single text operation against the TV's focused field.
class TextOp {
  const TextOp._(this.kind, {this.text, this.count = 1});

  /// Insert a string. For [TextInjectionMode.live] adapters this is typically a
  /// single grapheme; for [TextInjectionMode.bulk] it is the whole composed query.
  const TextOp.insert(String text) : this._(TextOpKind.insert, text: text);

  /// Delete [count] characters backwards (default 1). Where a platform only
  /// supports select-all-delete, the adapter maps this to its best equivalent.
  const TextOp.delete([int count = 1]) : this._(TextOpKind.delete, count: count);

  /// Clear the entire field (select-all-delete or repeated delete per platform).
  const TextOp.clear() : this._(TextOpKind.clear);

  /// Submit / confirm the field (Enter, search-go).
  const TextOp.submit() : this._(TextOpKind.submit);

  final TextOpKind kind;

  /// Present only for [TextOpKind.insert]. Never log this.
  final String? text;

  /// Character count for [TextOpKind.delete].
  final int count;

  @override
  String toString() =>
      // Deliberately does NOT echo `text` — see privacy red line above.
      switch (kind) {
        TextOpKind.insert => 'TextOp.insert(len=${text?.length ?? 0})',
        TextOpKind.delete => 'TextOp.delete($count)',
        TextOpKind.clear => 'TextOp.clear()',
        TextOpKind.submit => 'TextOp.submit()',
      };
}
