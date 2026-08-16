/// One entry from the bundled kanji deck.
///
/// The JSON uses short keys because the same file is parsed by the native
/// wallpaper and widget code; see `assets/data/kanji.json`.
class Kanji {
  const Kanji({
    required this.id,
    required this.character,
    required this.level,
    required this.strokes,
    required this.romaji,
    required this.kana,
    required this.meaning,
    required this.onyomi,
    required this.kunyomi,
    required this.example,
    required this.exampleKana,
    required this.exampleRomaji,
    required this.exampleMeaning,
  });

  final int id;

  /// The character itself, e.g. 駅.
  final String character;

  /// JLPT level: 5 is the easiest, 3 the hardest in the bundled deck.
  final int level;
  final int strokes;

  /// Primary reading in romaji, e.g. `eki`.
  final String romaji;

  /// Primary reading in kana, e.g. えき.
  final String kana;
  final String meaning;
  final String onyomi;
  final String kunyomi;

  /// Example compound, e.g. 駅前.
  final String example;
  final String exampleKana;
  final String exampleRomaji;
  final String exampleMeaning;

  /// The reading line as shown on the card: `eki・えき`.
  String get readingLine => '$romaji・$kana';

  /// The example line as shown on the card: `駅前・in front of station`.
  String get exampleLine => '$example・$exampleMeaning';

  /// Everything a search should match against.
  String get searchIndex => [
    character,
    romaji,
    kana,
    meaning,
    onyomi,
    kunyomi,
    example,
    exampleRomaji,
    exampleMeaning,
  ].join(' ').toLowerCase();

  factory Kanji.fromJson(Map<String, dynamic> json) => Kanji(
    id: json['id'] as int,
    character: json['c'] as String,
    level: json['l'] as int,
    strokes: (json['s'] as num?)?.toInt() ?? 0,
    romaji: json['r'] as String,
    kana: json['k'] as String,
    meaning: json['m'] as String,
    onyomi: json['on'] as String? ?? '',
    kunyomi: json['kun'] as String? ?? '',
    example: json['ex'] as String,
    exampleKana: json['exk'] as String? ?? '',
    exampleRomaji: json['exr'] as String? ?? '',
    exampleMeaning: json['exm'] as String,
  );
}
