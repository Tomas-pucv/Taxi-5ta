import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:taxi1/config/map_config.dart';

/// Una dirección encontrada por el buscador.
class PlaceResult {
  const PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });

  final String id;

  /// Lo primero de la dirección: "Av. Valparaíso 700".
  final String name;

  /// El resto, para desambiguar: "Quilpué, Valparaíso, Chile".
  final String address;

  final LatLng location;

  @override
  bool operator ==(Object other) => other is PlaceResult && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Búsqueda de direcciones contra la API de geocodificación de MapTiler.
///
/// Se usa MapTiler y no otro proveedor porque la clave ya está en el proyecto
/// para las teselas (`config/map_config.dart`): no añade ninguna credencial ni
/// dependencia nueva.
///
/// No es un [ChangeNotifier]: cada buscador tiene su propio estado y su propio
/// texto, así que el servicio es sin estado a propósito y sólo resuelve
/// consultas.
abstract final class GeocodingService {
  /// Sesga los resultados a la Quinta Región. Sin esto, "Freire" devuelve
  /// primero la comuna de Freire en la Araucanía, a 700 km.
  static const _proximity = kQuilpueCenter;

  /// Caja que cubre el Gran Valparaíso (Quilpué, Villa Alemana, Viña, Valpo).
  /// Recorta el ruido antes de que llegue a la lista.
  static const _bbox = '-71.75,-33.20,-71.20,-32.90';

  static const Duration timeout = Duration(seconds: 12);

  /// Busca [query]. Devuelve lista vacía ante cualquier fallo: el buscador
  /// muestra "sin resultados", que es más honesto que un error rojo cuando lo
  /// único que pasó es que no hay red.
  static Future<List<PlaceResult>> search(String query) async {
    final q = query.trim();
    // Menos de tres caracteres devuelve medio Chile y gasta cuota.
    if (q.length < 3) return const [];

    try {
      final url = Uri.parse(
        'https://api.maptiler.com/geocoding/${Uri.encodeComponent(q)}.json'
        '?key=$kMapTilerKey'
        '&country=cl'
        '&language=es'
        '&limit=6'
        '&bbox=$_bbox'
        '&proximity=${_proximity.longitude},${_proximity.latitude}',
      );

      final res = await http.get(url).timeout(timeout);
      if (res.statusCode != 200) {
        debugPrint('Geocoding ${res.statusCode}');
        return const [];
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>?;
      if (features == null) return const [];

      final results = <PlaceResult>[];
      for (final raw in features) {
        if (raw is! Map<String, dynamic>) continue;
        final place = _parseFeature(raw);
        if (place != null) results.add(place);
      }
      return results;
    } catch (e) {
      debugPrint('GeocodingService.search: $e');
      return const [];
    }
  }

  static PlaceResult? _parseFeature(Map<String, dynamic> feature) {
    final center = feature['center'];
    if (center is! List || center.length < 2) return null;

    final lon = center[0];
    final lat = center[1];
    if (lon is! num || lat is! num) return null;
    if (!lat.isFinite || !lon.isFinite) return null;

    // MapTiler devuelve "Calle 123, Comuna, Región, País" en `place_name`.
    // Se parte en dos para que la primera línea sea el dato y la segunda el
    // contexto, en vez de una sola línea larga y truncada.
    final placeName = (feature['place_name'] as String?)?.trim() ?? '';
    final text = (feature['text'] as String?)?.trim() ?? '';
    if (placeName.isEmpty && text.isEmpty) return null;

    final partes = placeName.split(',');
    final name = text.isNotEmpty
        ? text
        : (partes.isNotEmpty ? partes.first.trim() : placeName);
    final address = partes.length > 1
        ? partes.sublist(1).map((p) => p.trim()).join(', ')
        : '';

    return PlaceResult(
      id: (feature['id'] as String?) ?? '$placeName@$lat,$lon',
      name: name,
      address: address,
      location: LatLng(lat.toDouble(), lon.toDouble()),
    );
  }
}
