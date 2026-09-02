import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi1/models/bus_stop.dart';

/// Resultado de un cálculo de ruta. Agrupa los puntos + métricas para que
/// la UI pueda mostrar distancia y duración sin parsear de nuevo.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String provider; // 'ORS' | 'OSRM' | 'fallback'

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.provider,
  });

  // El formateo de distancia y duración vive en `utils/distance_format.dart`,
  // que además localiza las unidades. Tenerlo acá obligaba a que el servicio
  // conociera el idioma y duplicaba la lógica que ya existía en las pantallas.
}

/// Servicio de ruteo.
///
/// Estrategia:
/// 1. Si hay API key de OpenRouteService (vía `--dart-define=ORS_API_KEY=...`
///    o guardada en SharedPreferences), usar ORS (mejor calidad).
/// 2. Si no, caer al demo público de OSRM (sin key, sin garantía de SLA).
/// 3. Si todo falla, devolver `false` y dejar que la UI muestre el error.
class RouteService extends ChangeNotifier {
  RouteService._internal();
  static final RouteService instance = RouteService._internal();

  LatLng? _origin;
  BusStop? _destination;
  List<LatLng> _routePoints = [];
  RouteResult? _routeInfo;
  bool _loadingRoute = false;
  String? _lastError;
  String? _activeProvider;

  LatLng? get origin => _origin;
  BusStop? get destination => _destination;
  List<LatLng> get routePoints => _routePoints;
  RouteResult? get routeInfo => _routeInfo;
  bool get loadingRoute => _loadingRoute;
  String? get lastError => _lastError;
  String? get activeProvider => _activeProvider;

  void setOrigin(LatLng origin) {
    // Filtrar coordenadas inválidas para que no se propaguen a la polilínea
    // ni a los marcadores (causa del error "LatLng is not finite").
    if (!_isValidLatLng(origin)) return;
    _origin = origin;
    notifyListeners();
  }

  /// `true` si [p] tiene coordenadas finitas y dentro de rangos válidos.
  static bool _isValidLatLng(LatLng p) {
    final lat = p.latitude;
    final lng = p.longitude;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  void setDestination(BusStop destination) {
    _destination = destination;
    notifyListeners();
  }

  void clearDestination() {
    _destination = null;
    _routePoints = [];
    _routeInfo = null;
    _lastError = null;
    _activeProvider = null;
    notifyListeners();
  }

  /// Vuelve a resolver el destino contra la lista viva de paraderos.
  ///
  /// El destino se guarda **por valor**, así que si el administrador mueve o da
  /// de baja el paradero que el pasajero tiene seleccionado, la polilínea
  /// seguiría apuntando a un fantasma: al punto viejo, con el nombre viejo. Se
  /// llama desde `main()` cada vez que cambian los paraderos.
  void refreshDestination(BusStop? Function(String id) resolve) {
    final current = _destination;
    if (current == null) return;

    final fresh = resolve(current.id);
    if (fresh == null) {
      // El paradero ya no existe: mejor cerrar la ruta que dibujarla hacia un
      // lugar que la garita eliminó.
      clearDestination();
      return;
    }
    if (fresh.location == current.location && fresh.name == current.name) {
      return;
    }
    _destination = fresh;
    notifyListeners();
  }

  Future<String> _resolveApiKey() async {
    // 1) Compile-time (preferido): --dart-define=ORS_API_KEY=xxx
    const compileKey = String.fromEnvironment('ORS_API_KEY', defaultValue: '');
    if (compileKey.isNotEmpty) return compileKey;

    // 2) SharedPreferences (seteado programáticamente, sin UI).
    final sp = await SharedPreferences.getInstance();
    return sp.getString('ors_api_key') ?? '';
  }

  /// Calcula la ruta entre [origin] y [dest]. Devuelve `true` si se obtuvo
  /// una polilínea válida (de ORS o de OSRM). `false` en caso contrario.
  Future<bool> fetchRoute(LatLng origin, BusStop dest) async {
    // No llamar a las APIs si el origen o el destino son inválidos.
    if (!_isValidLatLng(origin) || !_isValidLatLng(dest.location)) {
      _lastError = 'invalid_coords';
      _loadingRoute = false;
      _routePoints = [];
      _routeInfo = null;
      notifyListeners();
      return false;
    }

    _loadingRoute = true;
    _lastError = null;
    notifyListeners();

    try {
      final apiKey = await _resolveApiKey();

      // Intentar ORS primero si hay key.
      if (apiKey.isNotEmpty) {
        final ok = await _fetchFromORS(origin, dest, apiKey);
        if (ok) return true;
        // Si ORS falló, caemos a OSRM abajo (no cortamos acá).
      }

      // Fallback público: OSRM demo server.
      final okOsm = await _fetchFromOSRM(origin, dest);
      if (okOsm) return true;

      // Si llegamos acá, todo falló.
      _lastError ??= 'no_route';
      _loadingRoute = false;
      _routePoints = [];
      _routeInfo = null;
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('fetchRoute error: $e\n$st');
      _lastError = 'generic_error';
      _loadingRoute = false;
      _routePoints = [];
      _routeInfo = null;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // OpenRouteService
  // ---------------------------------------------------------------------------

  Future<bool> _fetchFromORS(LatLng origin, BusStop dest, String apiKey) async {
    try {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
      );
      final payload = json.encode({
        'coordinates': [
          [origin.longitude, origin.latitude],
          [dest.location.longitude, dest.location.latitude],
        ],
        'instructions': false,
      });

      final res = await http.post(
        url,
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        debugPrint('ORS ${res.statusCode}: ${res.body}');
        _lastError = 'provider_error';
        return false;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) {
        _lastError = 'provider_error';
        return false;
      }

      // Tomar la primera alternativa (ORS ya devuelve la óptima por defecto).
      final feature = features.first as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null || geometry['coordinates'] == null) {
        _lastError = 'provider_error';
        return false;
      }

      final coords = _parseGeoJsonCoordinates(geometry).where(_isValidLatLng).toList();
      if (coords.isEmpty) {
        _lastError = 'provider_error';
        return false;
      }

      // Métricas
      double dist = 0;
      double dur = 0;
      final props = feature['properties'] as Map<String, dynamic>?;
      final summary = props?['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        final d = summary['distance'];
        final t = summary['duration'];
        if (d is num) dist = d.toDouble();
        if (t is num) dur = t.toDouble();
      }

      _routePoints = coords;
      _routeInfo = RouteResult(
        points: coords,
        distanceMeters: dist,
        durationSeconds: dur,
        provider: 'ORS',
      );
      _activeProvider = 'ORS';
      _loadingRoute = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ORS exception: $e');
      _lastError = 'provider_error';
      return false;
    }
  }

  List<LatLng> _parseGeoJsonCoordinates(Map<String, dynamic> geometry) {
    final coords = <LatLng>[];
    final dynamic coordsRaw = geometry['coordinates'];
    final geomType = (geometry['type'] as String?)?.toLowerCase() ?? '';

    try {
      if (geomType == 'linestring' && coordsRaw is List) {
        for (final c in coordsRaw) {
          if (c is List && c.length >= 2) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            coords.add(LatLng(lat, lon));
          }
        }
      } else if (geomType == 'multilinestring' && coordsRaw is List) {
        for (final seg in coordsRaw) {
          if (seg is! List) continue;
          for (final c in seg) {
            if (c is List && c.length >= 2) {
              final lon = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              coords.add(LatLng(lat, lon));
            }
          }
        }
      }
    } catch (_) {
      return const [];
    }
    return coords;
  }

  // ---------------------------------------------------------------------------
  // OSRM (demo público, sin API key)
  // ---------------------------------------------------------------------------

  Future<bool> _fetchFromOSRM(LatLng origin, BusStop dest) async {
    try {
      // OSRM pide lon,lat en la URL. profile driving.
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${dest.location.longitude},${dest.location.latitude}'
        '?overview=full&geometries=polyline6',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        debugPrint('OSRM ${res.statusCode}');
        _lastError = 'provider_error';
        return false;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final code = data['code'] as String?;
      if (code != 'Ok') {
        debugPrint('OSRM code: $code');
        _lastError = 'provider_error';
        return false;
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        _lastError = 'no_route';
        return false;
      }

      final route = routes.first as Map<String, dynamic>;
      final encoded = route['geometry'] as String?;
      if (encoded == null || encoded.isEmpty) {
        _lastError = 'provider_error';
        return false;
      }

      final coords = _decodePolyline(encoded, precision: 6).where(_isValidLatLng).toList();
      if (coords.isEmpty) {
        _lastError = 'provider_error';
        return false;
      }

      final d = route['distance'];
      final t = route['duration'];

      _routePoints = coords;
      _routeInfo = RouteResult(
        points: coords,
        distanceMeters: d is num ? d.toDouble() : 0,
        durationSeconds: t is num ? t.toDouble() : 0,
        provider: 'OSRM',
      );
      _activeProvider = 'OSRM';
      _loadingRoute = false;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('OSRM exception: $e');
      _lastError = 'provider_error';
      return false;
    }
  }

  /// Decodifica una polyline encoded (Google algorithm). OSRM usa precision=6
  /// por defecto cuando se pide `polyline6`.
  List<LatLng> _decodePolyline(String encoded, {int precision = 6}) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final factor = _pow10(precision);
      points.add(LatLng(lat / factor, lng / factor));
    }
    return points;
  }

  double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
