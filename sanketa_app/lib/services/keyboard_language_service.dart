import 'package:flutter/foundation.dart';

/// A keyboard layout definition for a single language/script.
class KeyboardLayout {
  const KeyboardLayout({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.rows,
    this.shiftRows,
    this.numRows = _defaultNumRows,
    this.rtl = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final List<String> rows;
  final List<String>? shiftRows;
  final List<String> numRows;
  final bool rtl;

  static const _defaultNumRows = ['1234567890', '-+*/#@&!?', '.,;:()'];
}

/// Manages the active keyboard language and provides layout switching.
class KeyboardLanguageService extends ChangeNotifier {
  int _activeIndex = 0;

  KeyboardLayout get active => layouts[_activeIndex];
  int get activeIndex => _activeIndex;
  String get activeCode => active.code;

  void select(int index) {
    if (index >= 0 && index < layouts.length && index != _activeIndex) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void selectByCode(String code) {
    final i = layouts.indexWhere((l) => l.code == code);
    if (i >= 0) select(i);
  }

  void cycleNext() {
    _activeIndex = (_activeIndex + 1) % layouts.length;
    notifyListeners();
  }

  static const List<KeyboardLayout> layouts = [
    // ── English (QWERTY) ──
    KeyboardLayout(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      rows: ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'],
    ),

    // ── Hindi (Devanagari) ──
    KeyboardLayout(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      rows: [
        'औऐआईऊभङघधझ',
        'ोे्िुपरकतच',
        'ॉॅंमनवलसय',
      ],
      shiftRows: [
        'ओएअइउफडठणछ',
        'ॊॆअिुपरकतच',
        'ऑृँणऩऴळशष',
      ],
    ),

    // ── Arabic ──
    KeyboardLayout(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      rows: [
        'ضصثقفغعهخح',
        'شسيبلاتنمك',
        'ئءؤرلىةوز',
      ],
      rtl: true,
    ),

    // ── French (AZERTY) ──
    KeyboardLayout(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      rows: ['AZERTYUIOP', 'QSDFGHJKLM', 'WXCVBN'],
      shiftRows: [
        'ÀÉÈÊËÏÎÔÙÛ',
        'ÇŒÆÜÑ¨«»€£',
        'ÀÉÈÊËÏ',
      ],
    ),

    // ── Spanish ──
    KeyboardLayout(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      rows: ['QWERTYUIOP', 'ASDFGHJKLÑ', 'ZXCVBNM'],
      shiftRows: [
        'ÁÉÍÓÚÜ¡¿€£',
        'ÀÈÌÒÙÑÇ«»·',
        'ÁÉÍÓÚÜÑ',
      ],
    ),

    // ── Russian (Cyrillic) ──
    KeyboardLayout(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      rows: [
        'ЙЦУКЕНГШЩЗ',
        'ФЫВАПРОЛДЖ',
        'ЯЧСМИТЬБЮ',
      ],
    ),

    // ── Korean (Hangul Jamo) ──
    KeyboardLayout(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      rows: [
        'ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ',
        'ㅁㄴㅇㄹㅎㅗㅓㅏㅣ',
        'ㅋㅌㅊㅍㅠㅜㅡㅘ',
      ],
      shiftRows: [
        'ㅃㅉㄸㄲㅆㅛㅕㅑㅐㅔ',
        'ㅁㄴㅇㄹㅎㅗㅓㅏㅣ',
        'ㅋㅌㅊㅍㅠㅜㅡㅘ',
      ],
    ),

    // ── Japanese (Hiragana) ──
    KeyboardLayout(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      rows: [
        'あいうえおかきくけこ',
        'さしすせそたちつてと',
        'なにぬねのはひふ',
      ],
      shiftRows: [
        'アイウエオカキクケコ',
        'サシスセソタチツテト',
        'ナニヌネノハヒフ',
      ],
    ),

    // ── Thai ──
    KeyboardLayout(
      code: 'th',
      name: 'Thai',
      nativeName: 'ไทย',
      rows: [
        'ๆไำพะัีรนย',
        'ฟหกดเ้่าสว',
        'ผปแอิืทมใ',
      ],
    ),

    // ── Portuguese ──
    KeyboardLayout(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      rows: ['QWERTYUIOP', 'ASDFGHJKLÇ', 'ZXCVBNM'],
      shiftRows: [
        'ÁÀÂÃÉÊÍÓÔÚ',
        'ÀÂÃÉÊÍÓÔÚÇ',
        'ÁÀÂÃÉÊÍ',
      ],
    ),

    // ── German ──
    KeyboardLayout(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      rows: ['QWERTZUIOP', 'ASDFGHJKLÖ', 'ÜÄYCXVBNM'],
      shiftRows: [
        'QWERTZUIOPÜ',
        'ASDFGHJKLÖÄ',
        'ẞYCXVBNM',
      ],
    ),

    // ── Turkish ──
    KeyboardLayout(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      rows: ['QWERTYÜİOP', 'ASDFGHJKLŞ', 'ZXCVBNMÖÇ'],
    ),

    // ── Bengali ──
    KeyboardLayout(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      rows: [
        'ঔঐআঈঊভঙঘধঝ',
        'োে্িুপরকতচ',
        '৉৅ংমনবলসয',
      ],
    ),

    // ── Tamil ──
    KeyboardLayout(
      code: 'ta',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      rows: [
        'ஔஐஆஈஊபரகதச',
        'ோே்ிுமநவலஸ',
        'எஒஅஇஉஞணன',
      ],
    ),

    // ── Telugu ──
    KeyboardLayout(
      code: 'te',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      rows: [
        'ఔఐఆఈఊభఙఘధఝ',
        'ోే్ిుపరకతచ',
        'ఎఒఅఇఉమనవ',
      ],
    ),
  ];
}
