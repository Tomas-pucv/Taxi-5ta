import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taxi1/models/bus_stop.dart';
import 'package:taxi1/services/preferences_service.dart';
import 'package:taxi1/services/stops_service.dart';

/// Historial de paraderos consultados.
///
/// Da contenido real a la preferencia "Guardar historial", que hasta ahora era
/// un interruptor que se guardaba en disco y no afectaba absolutamente nada.
///
/// Guarda **ids**, no nombres. Antes bastaba el nombre porque la lista de
/// paraderos era una constante inmutable; ahora la edita el administrador, y un
/// paradero al que se le corrige el nombre habría desaparecido del historial.
class StopHistoryService extends ChangeNotifier {
  StopHistoryService._();
  static final StopHistoryService instance = StopHistoryService._();

  static const _key = 'stop_history';

  /// Cuántos paraderos recientes se recuerdan. Cinco entra sin scroll en la
  /// fila de sugerencias y evita que el historial tape la lista completa.
  static const int maxEntries = 5;

  List<String> _recentIds = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const [];

    // Migración de las entradas guardadas por nombre. Se resuelven una vez
    // contra los paraderos conocidos y se vuelven a persistir como ids; lo que
    // ya no exista simplemente se cae del historial.
    final migrated = <String>[];
    var changed = false;
    for (final entry in stored) {
      if (StopsService.instance.byId(entry) != null) {
        migrated.add(entry);
        continue;
      }
      final byName = StopsService.instance.byName(entry);
      if (byName != null) {
        migrated.add(byName.id);
        changed = true;
      } else {
        changed = true;
      }
    }

    _recentIds = List.unmodifiable(migrated);
    if (changed) await prefs.setStringList(_key, migrated);

    _loaded = true;
    notifyListeners();
  }

  /// Paraderos recientes, del más reciente al más antiguo.
  ///
  /// Devuelve vacío si el usuario desactivó el historial, de modo que apagar la
  /// preferencia oculta el historial existente sin borrarlo. Los ids que ya no
  /// resuelven (paraderos dados de baja) se omiten en vez de mostrarse rotos.
  List<BusStop> get recentStops {
    if (!PreferencesService.instance.historyEnabled) return const [];
    final stops = <BusStop>[];
    for (final id in _recentIds) {
      final stop = StopsService.instance.byId(id);
      if (stop != null) stops.add(stop);
    }
    return stops;
  }

  bool get hasHistory => _recentIds.isNotEmpty;

  /// Registra una consulta. No hace nada si el historial está desactivado.
  Future<void> record(BusStop stop) async {
    if (!PreferencesService.instance.historyEnabled) return;

    final updated = [
      stop.id,
      ..._recentIds.where((id) => id != stop.id),
    ].take(maxEntries).toList(growable: false);

    if (listEquals(updated, _recentIds)) return;

    _recentIds = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
    notifyListeners();
  }

  Future<void> clear() async {
    if (_recentIds.isEmpty) return;
    _recentIds = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }
}
