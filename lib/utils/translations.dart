class Lang {
  final String code;
  const Lang._(this.code);

  bool get isRu => code == 'ru';
  bool get isEn => code == 'en';

  String tr(String ru, String en) => isRu ? ru : en;
}

extension Translate on String {
  String get ru => this;
}
