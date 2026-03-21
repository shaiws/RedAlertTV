class Alert {
  final String id;
  final String cat;
  final String title;
  final List<String> data;
  final String desc;

  Alert({
    required this.id,
    required this.cat,
    required this.title,
    required this.data,
    required this.desc,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id']?.toString() ?? '',
      cat: json['cat']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      data: List<String>.from(json['data'] ?? []),
      desc: json['desc']?.toString() ?? '',
    );
  }

  /// Returns a human-readable category label.
  String get categoryLabel {
    switch (cat) {
      case '1':
        return 'Rocket / Missile Fire';
      case '2':
        return 'Hostile Aircraft Intrusion';
      case '3':
        return 'Earthquake';
      case '13':
        return 'System Test';
      default:
        return 'Alert (cat $cat)';
    }
  }

  bool get isTest => cat == '13';

  @override
  bool operator ==(Object other) =>
      other is Alert && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a dummy (test) alert for UI testing.
class DummyAlert {
  static Alert create({String language = 'en'}) {
    const titles = {
      'en': 'This is a test',
      'he': 'זוהי בדיקה',
      'ru': 'Это тест',
      'ar': 'هذا اختبار',
    };
    const cities = {
      'en': ['Test city 1', 'Test city 2', 'Test city 3'],
      'he': ['זוהי בדיקה 1', 'זוהי בדיקה 2', 'זוהי בדיקה 3'],
      'ru': ['Тест 1', 'Тест 2', 'Тест 3'],
      'ar': ['اختبار 1', 'اختبار 2', 'اختبار 3'],
    };
    return Alert(
      id: 'dummy-test',
      cat: '13',
      title: titles[language] ?? titles['en']!,
      data: cities[language] ?? cities['en']!,
      desc: '',
    );
  }
}
