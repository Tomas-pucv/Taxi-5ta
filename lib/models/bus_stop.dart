import 'package:latlong2/latlong.dart';
import 'package:taxi1/l10n/app_localizations.dart';

/// Representa un paradero de colectivo en el mapa.
class BusStop {
  /// Nombre específico del paradero, SIN el prefijo "Parada "
  /// (p.ej. "Plaza de Armas"). El prefijo genérico se añade localizado vía
  /// [displayName], así "Parada" / "Stop" se traduce según el idioma.
  final String name;
  final String address;
  final LatLng location;

  const BusStop({
    required this.name,
    required this.address,
    required this.location,
  });

  /// Nombre localizado para mostrar en la UI: antepone el prefijo traducido
  /// (p.ej. "Parada Plaza de Armas" / "Stop Plaza de Armas").
  String displayName(AppLocalizations l10n) => '$l10n.stopPrefix $name';

  /// Distancia en metros desde [point] hasta este paradero.
  double distanceFrom(LatLng point) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point, location);
  }

  @override
  String toString() =>
      'BusStop($name, $address, ${location.latitude}, ${location.longitude})';
}

/// Paraderos de Quilpué. Reemplazá / agregá los reales cuando los tengas.
///
/// Coordenadas aproximadas del centro de Quilpué:
///   LatLng(-33.0472, -71.4425)
const List<BusStop> quilpueBusStops = [
  BusStop(
    name: 'Plaza de Armas',
    address: 'Av. Valparaíso 700, Quilpué',
    location: LatLng(-33.0472, -71.4425),
  ),
  BusStop(
    name: 'Estación Quilpué',
    address: 'Av. Ramón Freire 1200, Quilpué',
    location: LatLng(-33.0438, -71.4390),
  ),
  BusStop(
    name: 'Hospital Quilpué',
    address: 'Av. Concepción 1650, Quilpué',
    location: LatLng(-33.0510, -71.4480),
  ),
  BusStop(
    name: 'Villa Olimpica',
    address: 'Av. Marga Marga 900, Quilpué',
    location: LatLng(-33.0390, -71.4500),
  ),
  BusStop(
    name: 'Belloto',
    address: 'Av. Los Carrera 1800, Quilpué',
    location: LatLng(-33.0580, -71.4400),
  ),
  BusStop(
    name: 'El Sol',
    address: 'Av. El Sol 500, Quilpué',
    location: LatLng(-33.0460, -71.4350),
  ),
  BusStop(
    name: 'Freire',
    address: 'Freire 200, Quilpué',
    location: LatLng(-33.0450, -71.4410),
  ),
  BusStop(
    name: 'Vicuña Mackenna',
    address: 'Vicuña Mackenna 1100, Quilpué',
    location: LatLng(-33.0490, -71.4360),
  ),
  BusStop(
    name: 'Claudio Arrau',
    address: 'Av. Claudio Arrau 400, Quilpué',
    location: LatLng(-33.0410, -71.4530),
  ),
  BusStop(
    name: 'Colon',
    address: 'Colón 350, Quilpué',
    location: LatLng(-33.0445, -71.4450),
  ),
];
