class AppSettings {
  String orgName;
  String orgAddress;
  String orgPhone;
  String orgEmail;
  String orgTaxId;
  String userName;
  String userRole;
  String themeMode; // 'light' or 'dark'
  String language; // 'ru', 'en'

  AppSettings({
    this.orgName = 'Моя организация',
    this.orgAddress = '',
    this.orgPhone = '',
    this.orgEmail = '',
    this.orgTaxId = '',
    this.userName = 'Пользователь',
    this.userRole = 'Кладовщик',
    this.themeMode = 'light',
    this.language = 'ru',
  });

  Map<String, String> toMap() {
    return {
      'org_name': orgName,
      'org_address': orgAddress,
      'org_phone': orgPhone,
      'org_email': orgEmail,
      'org_tax_id': orgTaxId,
      'user_name': userName,
      'user_role': userRole,
      'theme_mode': themeMode,
      'language': language,
    };
  }

  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      orgName: map['org_name'] ?? 'Моя организация',
      orgAddress: map['org_address'] ?? '',
      orgPhone: map['org_phone'] ?? '',
      orgEmail: map['org_email'] ?? '',
      orgTaxId: map['org_tax_id'] ?? '',
      userName: map['user_name'] ?? 'Пользователь',
      userRole: map['user_role'] ?? 'Кладовщик',
      themeMode: map['theme_mode'] ?? 'light',
      language: map['language'] ?? 'ru',
    );
  }
}
