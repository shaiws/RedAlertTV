/// Simple localization helper that does not require code generation.
/// Supports Hebrew (he), English (en), Russian (ru), Arabic (ar).
class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  static const _data = <String, Map<String, String>>{
    'app_name': {
      'he': 'התראות צבע אדום',
      'en': 'Tzeva Adom (Red Alerts)',
      'ru': 'Красный Цвет (Тревога)',
      'ar': 'تنبيهات اللون الأحمر',
    },
    'status_tab': {
      'he': 'סטטוס שרות',
      'en': 'Service Status',
      'ru': 'Статус Сервиса',
      'ar': 'حالة الخدمة',
    },
    'test_tab': {
      'he': 'בדיקה',
      'en': 'Test',
      'ru': 'Тест',
      'ar': 'اختبار',
    },
    'lang_tab': {
      'he': 'שפה',
      'en': 'Language',
      'ru': 'Язык',
      'ar': 'اللغة',
    },
    'map_tab': {
      'he': 'מפה',
      'en': 'Map',
      'ru': 'Карта',
      'ar': 'خريطة',
    },
    'service_active': {
      'he': 'מצב השירות: פעיל',
      'en': 'Service status: active',
      'ru': 'Статус сервиса: активен',
      'ar': 'حالة الخدمة: نشطة',
    },
    'service_inactive': {
      'he': 'מצב השירות: לא פעיל',
      'en': 'Service status: inactive',
      'ru': 'Статус сервиса: неактивен',
      'ar': 'حالة الخدمة: غير نشطة',
    },
    'enable_alerts': {
      'he': 'הפעל התראות',
      'en': 'Enable Alerts',
      'ru': 'Включить оповещения',
      'ar': 'تفعيل التنبيهات',
    },
    'run_test': {
      'he': 'הפעל בדיקה',
      'en': 'Run Test',
      'ru': 'Запустить тест',
      'ar': 'تشغيل الاختبار',
    },
    'test_title': {
      'he': 'זוהי בדיקה',
      'en': 'This is a test',
      'ru': 'Это тест',
      'ar': 'هذا اختبار',
    },
    'test_city_1': {
      'he': 'זוהי בדיקה 1',
      'en': 'Test city 1',
      'ru': 'Тестовый город 1',
      'ar': 'مدينة اختبار 1',
    },
    'test_city_2': {
      'he': 'זוהי בדיקה 2',
      'en': 'Test city 2',
      'ru': 'Тестовый город 2',
      'ar': 'مدينة اختبار 2',
    },
    'test_city_3': {
      'he': 'זוהי בדיקה 3',
      'en': 'Test city 3',
      'ru': 'Тестовый город 3',
      'ar': 'مدينة اختبار 3',
    },
    'best_activate_permissions': {
      'he': 'ליעילות מיטבית יש לאשר את ההרשאות הנדרשות',
      'en': 'For optimal performance, grant the necessary permissions',
      'ru': 'Для оптимальной работы предоставьте необходимые разрешения',
      'ar': 'للأداء الأمثل، امنح الأذونات اللازمة',
    },
    'no_active_alerts': {
      'he': 'אין התראות פעילות',
      'en': 'No active alerts',
      'ru': 'Нет активных оповещений',
      'ar': 'لا توجد تنبيهات نشطة',
    },
    'alert_active': {
      'he': 'התראה פעילה',
      'en': 'Alert Active',
      'ru': 'Активная тревога',
      'ar': 'تنبيه نشط',
    },
    'locations_on_map': {
      'he': 'מיקומים על המפה',
      'en': 'Locations on Map',
      'ru': 'Места на карте',
      'ar': 'المواقع على الخريطة',
    },
    'no_map_data': {
      'he': 'אין נתוני מפה זמינים',
      'en': 'No map data available',
      'ru': 'Нет данных для карты',
      'ar': 'لا توجد بيانات خريطة',
    },
    'dismiss': {
      'he': 'סגור',
      'en': 'Dismiss',
      'ru': 'Закрыть',
      'ar': 'إغلاق',
    },
    'choose_language': {
      'he': 'בחר שפה',
      'en': 'Choose Language',
      'ru': 'Выберите язык',
      'ar': 'اختر اللغة',
    },
    'hebrew': {
      'he': 'עברית',
      'en': 'Hebrew',
      'ru': 'Иврит',
      'ar': 'عبري',
    },
    'english': {
      'he': 'אנגלית',
      'en': 'English',
      'ru': 'Английский',
      'ar': 'إنجليزي',
    },
    'russian': {
      'he': 'רוסית',
      'en': 'Russian',
      'ru': 'Русский',
      'ar': 'روسي',
    },
    'arabic': {
      'he': 'ערבית',
      'en': 'Arabic',
      'ru': 'Арабский',
      'ar': 'عربي',
    },
    'seconds_remaining': {
      'he': 'שניות',
      'en': 'seconds',
      'ru': 'секунд',
      'ar': 'ثانية',
    },
    'affected_areas': {
      'he': 'אזורים מושפעים',
      'en': 'Affected Areas',
      'ru': 'Затронутые районы',
      'ar': 'المناطق المتضررة',
    },
  };

  String get(String key) {
    final map = _data[key];
    if (map == null) return key;
    return map[languageCode] ?? map['en'] ?? key;
  }

  // Convenience getters
  String get appName => get('app_name');
  String get statusTab => get('status_tab');
  String get testTab => get('test_tab');
  String get langTab => get('lang_tab');
  String get mapTab => get('map_tab');
  String get serviceActive => get('service_active');
  String get serviceInactive => get('service_inactive');
  String get enableAlerts => get('enable_alerts');
  String get runTest => get('run_test');
  String get testTitle => get('test_title');
  String get testCity1 => get('test_city_1');
  String get testCity2 => get('test_city_2');
  String get testCity3 => get('test_city_3');
  String get noActiveAlerts => get('no_active_alerts');
  String get alertActive => get('alert_active');
  String get locationsOnMap => get('locations_on_map');
  String get noMapData => get('no_map_data');
  String get dismiss => get('dismiss');
  String get chooseLanguage => get('choose_language');
  String get hebrew => get('hebrew');
  String get english => get('english');
  String get russian => get('russian');
  String get arabic => get('arabic');
  String get affectedAreas => get('affected_areas');
}
