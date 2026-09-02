import 'package:latlong2/latlong.dart';

import 'package:taxi1/models/bus_stop.dart';
import 'package:taxi1/models/recorrido.dart';
import 'package:taxi1/services/recorridos_service.dart';
import 'package:taxi1/services/stops_service.dart';

/// Un paradero propuesto para llegar a un destino, con el porqué a la vista.
class StopSuggestion {
  const StopSuggestion({
    required this.stop,
    required this.metersToUser,
    required this.metersToDestination,
    required this.recorrido,
    required this.bajada,
  });

  final BusStop stop;

  /// Lo que camina el usuario **hasta** el paradero.
  final double metersToUser;

  /// Lo que camina **desde** donde se baja hasta el destino.
  final double metersToDestination;

  /// La línea que consigue esa bajada. `null` cuando la garita todavía no ha
  /// cargado recorridos y la sugerencia es sólo por cercanía.
  final Recorrido? recorrido;

  /// Paradero donde conviene bajarse. `null` en el mismo caso que [recorrido].
  final BusStop? bajada;

  /// Promedio de los dos tramos a pie, que es el criterio pedido: "el mejor
  /// promedio de (colectivo más cercano al destino + paradero más cercano al
  /// usuario)". Menor es mejor.
  ///
  /// Promediar metros en vez de puntuaciones normalizadas es deliberado: el
  /// número resultante sigue siendo metros, así que se puede enseñar y
  /// discutir. Como el promedio es proporcional a la suma, ordenar por él
  /// equivale a ordenar por el total caminado.
  double get score => (metersToUser + metersToDestination) / 2;

  /// Total real a pie, que es lo que se le muestra al usuario.
  double get metersTotales => metersToUser + metersToDestination;
}

/// Elige por dónde tomar el colectivo para llegar a un destino.
abstract final class StopPlanner {
  static const _distance = Distance();

  /// Cuántas sugerencias devolver. Más de cinco convierte una recomendación en
  /// otra lista que hay que leer entera.
  static const int maxSuggestions = 5;

  /// Ordena los paraderos por conveniencia para ir de [user] a [destino].
  ///
  /// Para cada paradero de subida se busca, entre las líneas que lo sirven, la
  /// que tiene alguna parada más cerca del destino; esa parada es la bajada. El
  /// paradero se puntúa con el promedio de los dos tramos caminando.
  ///
  /// **Simplificación conocida:** no se modela el sentido de marcha. Un
  /// recorrido se trata como el conjunto de sus paraderos, así que se asume que
  /// desde la subida se puede alcanzar cualquier otra parada de esa línea. Con
  /// los datos que hay (una lista ordenada, sin ida/vuelta ni horarios) es lo
  /// más que se puede afirmar con honestidad.
  static List<StopSuggestion> suggest({
    required LatLng user,
    required LatLng destino,
    List<BusStop>? stops,
    List<Recorrido>? recorridos,
  }) {
    final todosLosParaderos = stops ?? StopsService.instance.stops;
    final todosLosRecorridos =
        recorridos ?? RecorridosService.instance.recorridos;
    if (todosLosParaderos.isEmpty) return const [];

    final activos = todosLosRecorridos.where((r) => r.activo).toList();
    final porId = {for (final s in todosLosParaderos) s.id: s};

    final suggestions = <StopSuggestion>[];

    for (final subida in todosLosParaderos) {
      if (!subida.activo) continue;
      final metrosAlUsuario = _metros(user, subida.location);

      Recorrido? mejorRecorrido;
      BusStop? mejorBajada;
      var mejorDistancia = double.infinity;

      for (final recorrido in activos) {
        if (!recorrido.paraderoIds.contains(subida.id)) continue;

        for (final id in recorrido.paraderoIds) {
          final candidata = porId[id];
          if (candidata == null || !candidata.activo) continue;
          final d = _metros(destino, candidata.location);
          if (d < mejorDistancia) {
            mejorDistancia = d;
            mejorBajada = candidata;
            mejorRecorrido = recorrido;
          }
        }
      }

      if (mejorRecorrido == null || mejorBajada == null) continue;

      suggestions.add(
        StopSuggestion(
          stop: subida,
          metersToUser: metrosAlUsuario,
          metersToDestination: mejorDistancia,
          recorrido: mejorRecorrido,
          bajada: mejorBajada,
        ),
      );
    }

    // Sin recorridos cargados no se puede afirmar a dónde te lleva ningún
    // colectivo. En vez de no mostrar nada, se degrada a "paraderos entre tú y
    // el destino"; la interfaz avisa de que es una aproximación.
    if (suggestions.isEmpty) {
      for (final stop in todosLosParaderos) {
        if (!stop.activo) continue;
        suggestions.add(
          StopSuggestion(
            stop: stop,
            metersToUser: _metros(user, stop.location),
            metersToDestination: _metros(destino, stop.location),
            recorrido: null,
            bajada: null,
          ),
        );
      }
    }

    suggestions.sort((a, b) => a.score.compareTo(b.score));
    return suggestions.length > maxSuggestions
        ? suggestions.sublist(0, maxSuggestions)
        : suggestions;
  }

  static double _metros(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Meter, a, b);
}
