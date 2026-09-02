import 'package:latlong2/latlong.dart';

import 'package:taxi1/utils/tile_coords.dart';

/// Clave de MapTiler. Sobreescribible con
/// `flutter run --dart-define=MAPTILER_KEY=...` para no tener que tocar el
/// código fuente.
const String kMapTilerKey = String.fromEnvironment(
  'MAPTILER_KEY',
  defaultValue: 'twZDa0L757dpVwBfAbBr',
);

/// Centro de Quilpué: punto de partida del mapa y de las miniaturas.
const LatLng kQuilpueCenter = LatLng(-33.0472, -71.4425);

const double kInitialZoom = 14;

/// Estilo cartográfico elegible por el usuario.
enum MapStyle {
  normal,
  satellite;

  /// Valor persistido en [PreferencesService.mapType].
  String get prefValue => this == MapStyle.satellite ? 'satellite' : 'normal';

  static MapStyle fromPref(String value) =>
      value == 'satellite' ? MapStyle.satellite : MapStyle.normal;
}

/// Identificador del estilo en MapTiler.
///
/// El basemap claro y el oscuro son estilos distintos: usar siempre el claro
/// dejaba el mapa blanco brillante debajo de una interfaz oscura. El satelital
/// no tiene variante, la fotografía aérea se ve igual en ambos temas.
String _styleId(MapStyle style, bool isDark) => switch (style) {
  MapStyle.satellite => 'hybrid',
  MapStyle.normal => isDark ? 'basic-v2-dark' : 'basic-v2',
};

String _extension(MapStyle style) =>
    style == MapStyle.satellite ? 'jpg' : 'png';

/// Plantilla de URL para el `TileLayer` de flutter_map.
String mapTileUrlTemplate(MapStyle style, {required bool isDark}) =>
    'https://api.maptiler.com/maps/${_styleId(style, isDark)}'
    '/{z}/{x}/{y}.${_extension(style)}?key=$kMapTilerKey';

/// URL de una tesela concreta, para usarla como miniatura de vista previa.
///
/// Pedir una sola imagen es mucho más barato que instanciar un `FlutterMap`
/// completo solo para mostrar un recuadro de previsualización.
String mapTileThumbnailUrl(
  MapStyle style, {
  required bool isDark,
  LatLng center = kQuilpueCenter,
  int zoom = 14,
}) {
  final tile = tileIndexFor(center, zoom);
  return 'https://api.maptiler.com/maps/${_styleId(style, isDark)}'
      '/${tile.z}/${tile.x}/${tile.y}.${_extension(style)}?key=$kMapTilerKey';
}
