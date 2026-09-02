import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:taxi1/models/bus_stop.dart';
import 'package:taxi1/models/recorrido.dart';
import 'package:taxi1/services/osrm_client.dart';
import 'package:taxi1/services/stop_planner.dart';

/// Tests del recomendador de paraderos y de las utilidades de ruteo.
///
/// Todo con datos inyectados: `StopPlanner.suggest` acepta las listas por
/// parámetro justamente para poder verificar el criterio sin Firestore ni red.
void main() {
  // Una malla simple sobre Quilpué. A esta latitud, 0.001° ≈ 111 m en latitud
  // y ≈ 93 m en longitud, suficiente para razonar sobre las distancias.
  BusStop stop(String id, double lat, double lng) =>
      BusStop(id: id, name: id, address: id, location: LatLng(lat, lng));

  final cerca = stop('cerca', -33.0470, -71.4425);
  final lejos = stop('lejos', -33.0700, -71.4425);
  final juntoAlDestino = stop('junto-destino', -33.0800, -71.4425);
  final aMedias = stop('a-medias', -33.0600, -71.4425);

  const usuario = LatLng(-33.0472, -71.4425);
  const destino = LatLng(-33.0805, -71.4425);

  group('StopPlanner', () {
    test('prefiere el paradero cuya línea deja más cerca del destino', () {
      // Las dos subidas están a la misma distancia del usuario, pero sólo una
      // pertenece a una línea que pasa junto al destino.
      final sinSalida = stop('sin-salida', -33.0471, -71.4425);

      final recorridos = [
        Recorrido(
          id: 'r-buena',
          garitaId: 'g1',
          nombre: 'Línea buena',
          colorValue: 0xFF4A3F9E,
          paraderoIds: [cerca.id, juntoAlDestino.id],
        ),
        Recorrido(
          id: 'r-mala',
          garitaId: 'g1',
          nombre: 'Línea mala',
          colorValue: 0xFF4A3F9E,
          paraderoIds: [sinSalida.id, aMedias.id],
        ),
      ];

      final result = StopPlanner.suggest(
        user: usuario,
        destino: destino,
        stops: [cerca, sinSalida, aMedias, juntoAlDestino],
        recorridos: recorridos,
      );

      expect(result.first.stop, cerca);
      expect(result.first.recorrido?.id, 'r-buena');
      expect(result.first.bajada, juntoAlDestino);
    });

    test('el promedio equilibra los dos tramos a pie', () {
      // Una subida lejísimos que deja pegado al destino no debería ganarle a
      // una razonable en ambos tramos: es el punto del promedio.
      final recorridos = [
        Recorrido(
          id: 'r1',
          garitaId: 'g1',
          nombre: 'A',
          colorValue: 0,
          paraderoIds: [cerca.id, aMedias.id],
        ),
        Recorrido(
          id: 'r2',
          garitaId: 'g1',
          nombre: 'B',
          colorValue: 0,
          paraderoIds: [lejos.id, juntoAlDestino.id],
        ),
      ];

      final result = StopPlanner.suggest(
        user: usuario,
        destino: destino,
        stops: [cerca, lejos, aMedias, juntoAlDestino],
        recorridos: recorridos,
      );

      for (final s in result) {
        expect(
          s.score,
          closeTo((s.metersToUser + s.metersToDestination) / 2, 0.001),
        );
      }
      // Ordenado de mejor a peor, sin excepciones.
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].score, lessThanOrEqualTo(result[i].score));
      }
    });

    test('ignora los paraderos que ninguna línea sirve', () {
      final huerfano = stop('huerfano', -33.0473, -71.4426);
      final recorridos = [
        Recorrido(
          id: 'r1',
          garitaId: 'g1',
          nombre: 'A',
          colorValue: 0,
          paraderoIds: [cerca.id, juntoAlDestino.id],
        ),
      ];

      final result = StopPlanner.suggest(
        user: usuario,
        destino: destino,
        stops: [cerca, huerfano, juntoAlDestino],
        recorridos: recorridos,
      );

      // `huerfano` está más cerca del usuario que nada, pero no lleva a ningún
      // lado: proponerlo sería mentir.
      expect(result.map((s) => s.stop.id), isNot(contains('huerfano')));
    });

    test('sin recorridos cargados degrada a cercanía en vez de no dar nada', () {
      final result = StopPlanner.suggest(
        user: usuario,
        destino: destino,
        stops: [cerca, aMedias, juntoAlDestino],
        recorridos: const [],
      );

      expect(result, isNotEmpty);
      // Se marca como aproximación: sin línea no se puede prometer un viaje.
      expect(result.every((s) => s.recorrido == null), isTrue);
      expect(result.first.stop, juntoAlDestino);
    });

    test('un recorrido desactivado no se propone', () {
      final recorridos = [
        Recorrido(
          id: 'r1',
          garitaId: 'g1',
          nombre: 'Suspendida',
          colorValue: 0,
          paraderoIds: [cerca.id, juntoAlDestino.id],
          activo: false,
        ),
      ];

      final result = StopPlanner.suggest(
        user: usuario,
        destino: destino,
        stops: [cerca, juntoAlDestino],
        recorridos: recorridos,
      );

      expect(result.every((s) => s.recorrido == null), isTrue);
    });

    test('no devuelve más sugerencias de las que se pueden leer', () {
      final muchos = [
        for (var i = 0; i < 30; i++) stop('p$i', -33.05 - i * 0.001, -71.44),
      ];
      final result = StopPlanner.suggest(
        user: usuario,
        destino: destino,
        stops: muchos,
        recorridos: const [],
      );
      expect(result.length, StopPlanner.maxSuggestions);
    });

    test('sin paraderos no revienta', () {
      expect(
        StopPlanner.suggest(
          user: usuario,
          destino: destino,
          stops: const [],
          recorridos: const [],
        ),
        isEmpty,
      );
    });
  });

  group('OsrmClient', () {
    test('decodifica una polilínea de ida y vuelta', () {
      // Referencia clásica del algoritmo de Google, con precisión 5.
      final points = OsrmClient.decodePolyline(
        '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        precision: 5,
      );
      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 0.001));
      expect(points[0].longitude, closeTo(-120.2, 0.001));
      expect(points[2].latitude, closeTo(43.252, 0.001));
      expect(points[2].longitude, closeTo(-126.453, 0.001));
    });

    test('descarta coordenadas que romperían flutter_map', () {
      expect(OsrmClient.isValidLatLng(const LatLng(-33.05, -71.44)), isTrue);
      expect(OsrmClient.isValidLatLng(LatLng(double.nan, -71.44)), isFalse);
      expect(
        OsrmClient.isValidLatLng(LatLng(double.infinity, 0)),
        isFalse,
      );
    });
  });

  group('Recorrido', () {
    test('necesita al menos dos paraderos para describir un trayecto', () {
      const uno = Recorrido(
        id: 'r',
        garitaId: 'g',
        nombre: 'A',
        colorValue: 0,
        paraderoIds: ['a'],
      );
      expect(uno.isValid, isFalse);
      expect(
        uno.copyWith(paraderoIds: ['a', 'b']).isValid,
        isTrue,
      );
    });

    test('sin nombre no es válido aunque tenga paraderos', () {
      const sinNombre = Recorrido(
        id: 'r',
        garitaId: 'g',
        nombre: '   ',
        colorValue: 0,
        paraderoIds: ['a', 'b'],
      );
      expect(sinNombre.isValid, isFalse);
    });

    test('sobrevive al viaje por Firestore', () {
      const original = Recorrido(
        id: 'r1',
        garitaId: 'g1',
        nombre: 'Línea 5',
        colorValue: 0xFF4A3F9E,
        paraderoIds: ['a', 'b', 'c'],
      );
      final restaurado = Recorrido.fromMap('r1', original.toMap());
      expect(restaurado, original);
      expect(restaurado.nombre, 'Línea 5');
      expect(restaurado.paraderoIds, ['a', 'b', 'c']);
      expect(restaurado.colorValue, 0xFF4A3F9E);
    });
  });
}
