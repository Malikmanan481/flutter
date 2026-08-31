library map;

// Core Map Components
export 'src/map.dart';
export 'src/provider.dart';
export '../lib_latlng/latlng.dart';

// ==========================================
// TRACCAR API BACKEND INTEGRATIONS NOTE:
// ==========================================
// - TraccarMapProvider (from src/provider.dart)
// - updateCenterFromTraccar() & moveToTraccarPosition() (from src/map.dart)
// - TraccarLatLngExtension (from ../lib_latlng/latlng.dart)
// Are all automatically exported and available through this library.
