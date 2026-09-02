import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Índice de una tesela (tile) en el esquema Web Mercator / slippy map.
typedef TileIndex = ({int x, int y, int z});

/// Convierte una coordenada geográfica al índice de tesela que la contiene.
///
/// Se usa para pedirle a MapTiler *una sola* tesela como miniatura de
/// previsualización en el selector de estilo de mapa, en vez de instanciar un
/// `FlutterMap` completo (que arrastraría controlador, gestos y varias
/// peticiones de red) solo para mostrar un cuadrado de 2 cm.
TileIndex tileIndexFor(LatLng point, int zoom) {
  final n = 1 << zoom;

  final x = ((point.longitude + 180.0) / 360.0 * n).floor();

  final latRad = point.latitude * math.pi / 180.0;
  final y =
      ((1.0 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
              2.0 *
              n)
          .floor();

  return (x: x.clamp(0, n - 1), y: y.clamp(0, n - 1), z: zoom);
}
