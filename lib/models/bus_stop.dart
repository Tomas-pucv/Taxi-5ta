import 'package:latlong2/latlong.dart';

/// Representa un paradero de colectivo en el mapa.
class BusStop {
  /// Identidad estable del paradero.
  ///
  /// **Es el campo que hace que `==` funcione**, y no es un detalle menor:
  /// hasta que los paraderos vinieron de Firestore, la igualdad la daba de
  /// regalo la canonicalización de constantes de Dart, porque todos salían de
  /// la lista `const` [quilpueBusStops]. Cada snapshot de Firestore construye
  /// instancias nuevas, así que sin `id` + [operator ==] las comparaciones de
  /// `map_screen` (paradero resaltado) y `routes_screen` (spinner de la fila)
  /// dejarían de funcionar **en silencio**, sin error de compilación.
  final String id;

  /// Nombre específico del paradero, SIN el prefijo "Parada "
  /// (p.ej. "Plaza de Armas").
  final String name;
  final String address;
  final LatLng location;

  /// Garita dueña del paradero. Vacío en las semillas locales.
  final String garitaId;

  /// Los paraderos desactivados se conservan pero no se muestran: borrarlos
  /// rompería el historial y las rutas que los referencian.
  final bool activo;

  const BusStop({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.garitaId = '',
    this.activo = true,
  });

  /// Distancia en metros desde [point] hasta este paradero.
  double distanceFrom(LatLng point) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point, location);
  }

  factory BusStop.fromMap(String id, Map<String, dynamic> data) => BusStop(
    id: id,
    name: (data['nombre'] as String?) ?? '',
    address: (data['direccion'] as String?) ?? '',
    location: LatLng(
      (data['lat'] as num?)?.toDouble() ?? 0,
      (data['lng'] as num?)?.toDouble() ?? 0,
    ),
    garitaId: (data['garitaId'] as String?) ?? '',
    activo: (data['activo'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'garitaId': garitaId,
    'nombre': name,
    'direccion': address,
    'lat': location.latitude,
    'lng': location.longitude,
    'activo': activo,
  };

  BusStop copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? location,
    String? garitaId,
    bool? activo,
  }) => BusStop(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    location: location ?? this.location,
    garitaId: garitaId ?? this.garitaId,
    activo: activo ?? this.activo,
  );

  /// Identidad por `id`, no por contenido: mover un paradero unos metros o
  /// corregirle una tilde al nombre no lo convierte en otro paradero, y el
  /// destino que el pasajero tenía seleccionado debe seguir siéndolo.
  @override
  bool operator ==(Object other) => other is BusStop && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BusStop($id, $name, $address, ${location.latitude}, ${location.longitude})';
}

/// Paraderos de Quilpué usados como **semilla**.
///
/// Ya no son la fuente de verdad —esa es la colección `paraderos` de
/// Firestore, que el administrador edita—, pero siguen aquí y siguen siendo
/// `const` por dos razones concretas:
///
///  * En la primera ejecución, y sin conexión, la app muestra paraderos igual
///    (RF-07-01). `StopsService` los siembra de forma **sincrónica**.
///  * Los tests de historial y de distancias funcionan sin Firebase.
///
/// Los ids llevan prefijo `seed-` para que nunca choquen con los que genera
/// Firestore y para que se note de dónde salió cada uno.
///
/// Coordenadas aproximadas del centro de Quilpué:
///   LatLng(-33.0472, -71.4425)
const List<BusStop> quilpueBusStops = [
  BusStop(
    id: 'seed-plaza-de-armas',
    name: 'Plaza de Armas',
    address: 'Av. Valparaíso 700, Quilpué',
    location: LatLng(-33.0472, -71.4425),
  ),
  BusStop(
    id: 'seed-estacion-quilpue',
    name: 'Estación Quilpué',
    address: 'Av. Ramón Freire 1200, Quilpué',
    location: LatLng(-33.0438, -71.4390),
  ),
  BusStop(
    id: 'seed-hospital-quilpue',
    name: 'Hospital Quilpué',
    address: 'Av. Concepción 1650, Quilpué',
    location: LatLng(-33.0510, -71.4480),
  ),
  BusStop(
    id: 'seed-villa-olimpica',
    name: 'Villa Olimpica',
    address: 'Av. Marga Marga 900, Quilpué',
    location: LatLng(-33.0390, -71.4500),
  ),
  BusStop(
    id: 'seed-belloto',
    name: 'Belloto',
    address: 'Av. Los Carrera 1800, Quilpué',
    location: LatLng(-33.0580, -71.4400),
  ),
  BusStop(
    id: 'seed-el-sol',
    name: 'El Sol',
    address: 'Av. El Sol 500, Quilpué',
    location: LatLng(-33.0460, -71.4350),
  ),
  BusStop(
    id: 'seed-freire',
    name: 'Freire',
    address: 'Freire 200, Quilpué',
    location: LatLng(-33.0450, -71.4410),
  ),
  BusStop(
    id: 'seed-vicuna-mackenna',
    name: 'Vicuña Mackenna',
    address: 'Vicuña Mackenna 1100, Quilpué',
    location: LatLng(-33.0490, -71.4360),
  ),
  BusStop(
    id: 'seed-claudio-arrau',
    name: 'Claudio Arrau',
    address: 'Av. Claudio Arrau 400, Quilpué',
    location: LatLng(-33.0410, -71.4530),
  ),
  BusStop(
    id: 'seed-colon',
    name: 'Colon',
    address: 'Colón 350, Quilpué',
    location: LatLng(-33.0445, -71.4450),
  ),
];
