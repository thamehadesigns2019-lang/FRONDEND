class UserSettings {
  bool enableNotifications;
  bool darkMode;
  String preferredCurrency;

  UserSettings({
    this.enableNotifications = true,
    this.darkMode = false,
    this.preferredCurrency = 'USD',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      darkMode: json['darkMode'] ?? false,
      preferredCurrency: json['preferredCurrency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'darkMode': darkMode,
      'preferredCurrency': preferredCurrency,
    };
  }
}
