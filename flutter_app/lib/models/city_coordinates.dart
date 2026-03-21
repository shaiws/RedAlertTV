import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Approximate coordinates for common Israeli cities and regions.
/// Used to place map markers when an alert is received.
/// Coordinates are (latitude, longitude).
const Map<String, LatLng> kCityCoordinates = {
  // Major cities
  'תל אביב - יפו': LatLng(32.0853, 34.7818),
  'ירושלים': LatLng(31.7683, 35.2137),
  'חיפה': LatLng(32.7940, 34.9896),
  'באר שבע': LatLng(31.2518, 34.7915),
  'נתניה': LatLng(32.3226, 34.8533),
  'אשדוד': LatLng(31.8044, 34.6553),
  'אשקלון': LatLng(31.6688, 34.5742),
  'פתח תקווה': LatLng(32.0870, 34.8878),
  'רמת גן': LatLng(32.0680, 34.8238),
  'ראשון לציון': LatLng(31.9730, 34.7925),
  'הרצליה': LatLng(32.1665, 34.8460),
  'כפר סבא': LatLng(32.1752, 34.9077),
  'רחובות': LatLng(31.8928, 34.8113),
  'בת ים': LatLng(32.0167, 34.7500),
  'הוד השרון': LatLng(32.1505, 34.8886),
  'גבעתיים': LatLng(32.0717, 34.8101),
  'חולון': LatLng(32.0167, 34.7667),
  'בני ברק': LatLng(32.0833, 34.8333),
  'אילת': LatLng(29.5577, 34.9519),
  'טבריה': LatLng(32.7960, 35.5311),
  'נצרת': LatLng(32.6996, 35.3030),
  'אום אל-פחם': LatLng(32.5166, 35.1523),
  'עכו': LatLng(32.9264, 35.0818),
  'נהריה': LatLng(33.0059, 35.0949),
  'קרית שמונה': LatLng(33.2075, 35.5700),
  'צפת': LatLng(32.9646, 35.4960),
  'דימונה': LatLng(31.0683, 35.0335),
  'ערד': LatLng(31.2578, 35.2125),
  'קריית גת': LatLng(31.6100, 34.7638),
  'לוד': LatLng(31.9521, 34.8955),
  'רמלה': LatLng(31.9269, 34.8695),
  'מודיעין-מכבים-רעות': LatLng(31.8987, 35.0103),
  'מודיעין עילית': LatLng(31.9306, 35.0433),
  'קרית ביאליק': LatLng(32.8367, 35.0867),
  'קרית מוצקין': LatLng(32.8403, 35.0747),
  'קרית ים': LatLng(32.8500, 35.0667),
  'קרית אתא': LatLng(32.8062, 35.1078),
  'טירת כרמל': LatLng(32.7620, 34.9716),
  'אור יהודה': LatLng(32.0286, 34.8556),
  'אלעד': LatLng(32.0530, 34.9513),
  'יבנה': LatLng(31.8776, 34.7432),
  'גדרה': LatLng(31.8117, 34.7802),
  'נס ציונה': LatLng(31.9306, 34.8000),
  'מגדל העמק': LatLng(32.6779, 35.2416),
  'שפרעם': LatLng(32.8082, 35.1713),
  'עפולה': LatLng(32.6077, 35.2898),
  'בית שמש': LatLng(31.7469, 35.0011),
  'מעלה אדומים': LatLng(31.7731, 35.2965),
  'רהט': LatLng(31.3955, 34.7547),
  'שדרות': LatLng(31.5236, 34.5970),
  'נתיבות': LatLng(31.4216, 34.5896),
  'אופקים': LatLng(31.3139, 34.6222),
  'מיתר': LatLng(31.3742, 34.8671),
  'ירוחם': LatLng(30.9874, 34.9275),
  'ערבה': LatLng(30.7500, 35.1333),
  // English transliterations
  'Tel Aviv - Jaffa': LatLng(32.0853, 34.7818),
  'Jerusalem': LatLng(31.7683, 35.2137),
  'Haifa': LatLng(32.7940, 34.9896),
  'Beer Sheva': LatLng(31.2518, 34.7915),
  'Netanya': LatLng(32.3226, 34.8533),
  'Ashdod': LatLng(31.8044, 34.6553),
  'Ashkelon': LatLng(31.6688, 34.5742),
  'Sderot': LatLng(31.5236, 34.5970),
  'Eilat': LatLng(29.5577, 34.9519),
};

/// Returns the LatLng for a city name, or null if not found.
LatLng? coordinatesForCity(String cityName) {
  return kCityCoordinates[cityName];
}

/// Attempts a fuzzy match: returns coordinate if any key contains [cityName]
/// (case-insensitive, partial match).
LatLng? fuzzyCoordinatesForCity(String cityName) {
  final lower = cityName.toLowerCase();
  for (final entry in kCityCoordinates.entries) {
    if (entry.key.toLowerCase().contains(lower) ||
        lower.contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return null;
}
