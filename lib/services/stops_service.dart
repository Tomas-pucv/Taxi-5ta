import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:taxi1/models/bus_stop.dart';

/// Fuente única de paraderos para toda la app.
///
/// Reemplaza a las tres lecturas directas de la constante `quilpueBusStops`
/// (`map_screen`, `routes_screen` y `stop_history_service`), que era lo que
/// impedía que el administrador pudiera agregar un paradero: no había dónde
/// escribirlo.
///
/// **La lista se siembra en el constructor, de forma sincrónica.** No es un
/// detalle de estilo:
///
///  * la app dibuja paraderos en el primer frame, sin esperar a la red, y
///    sigue funcionando sin cobertura (RF-07-01);
///  * los tests que ya existían siguen pasando sin Firebase, porque abrir el
///    listener es una llamada aparte ([startListening]) que sólo hace `main()`.
class StopsService extends ChangeNotifier {
  StopsService._();
  static final StopsService instance = StopsService._();

  static const _collection = 'paraderos';

  /// Arranca con la semilla local; el primer snapshot no vacío la reemplaza.
  List<BusStop> _stops = List.unmodifiable(quilpueBusStops);
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _hasRemoteData = false;

  List<BusStop> get stops => _stops;

  /// Si lo que se está mostrando viene de Firestore o sigue siendo la semilla.
  bool get hasRemoteData => _hasRemoteData;

  BusStop? byId(String id) {
    for (final stop in _stops) {
      if (stop.id == id) return stop;
    }
    return null;
  }

  /// Búsqueda por nombre, sólo para migrar historiales guardados antes de que
  /// los paraderos tuvieran id.
  BusStop? byName(String name) {
    for (final stop in _stops) {
      if (stop.name == name) return stop;
    }
    return null;
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Abre el listener de Firestore. Se llama una sola vez, desde `main()`.
  void startListening() {
    if (_sub != null) return;
    _sub = _db
        .collection(_collection)
        .where('activo', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            // Una colección vacía **no** reemplaza la semilla: significa que
            // todavía nadie cargó los paraderos reales, y dejar al usuario sin
            // un solo paradero sería peor que mostrarle los de referencia.
            if (snapshot.docs.isEmpty) return;

            final remote = snapshot.docs
                .map((doc) => BusStop.fromMap(doc.id, doc.data()))
                .toList(growable: false);

            // Reemplazo, nunca fusión: mezclarlos duplicaría cada paradero que
            // exista tanto en la semilla como en Firestore.
            _stops = List.unmodifiable(remote);
            _hasRemoteData = true;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('StopsService: no se pudo leer paraderos: $e');
          },
        );
  }

  Future<void> stopListening() async {
    await _sub?.cancel();
    _sub = null;
  }

  // --- Escrituras del administrador ----------------------------------------

  /// Crea o actualiza un paradero. Devuelve el id resultante.
  Future<String> upsert(BusStop stop) async {
    final data = {...stop.toMap(), 'actualizadoEn': FieldValue.serverTimestamp()};

    // Un paradero semilla no existe en Firestore: editarlo crea el documento
    // real en vez de fallar con "no such document".
    if (stop.id.isEmpty || stop.id.startsWith('seed-')) {
      final ref = await _db.collection(_collection).add(data);
      return ref.id;
    }
    await _db.collection(_collection).doc(stop.id).set(data);
    return stop.id;
  }

  /// Baja lógica.
  ///
  /// No se borra el documento: el historial del pasajero y los recorridos del
  /// administrador guardan ids de paraderos, y eliminarlos dejaría referencias
  /// colgando.
  Future<void> desactivar(BusStop stop) async {
    if (stop.id.isEmpty || stop.id.startsWith('seed-')) return;
    await _db.collection(_collection).doc(stop.id).update({
      'activo': false,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Carga la semilla en Firestore. Pensado para el primer arranque de una
  /// garita nueva, disparado a mano por el administrador desde su panel.
  Future<int> importarSemilla(String garitaId) async {
    final batch = _db.batch();
    for (final stop in quilpueBusStops) {
      final ref = _db.collection(_collection).doc();
      batch.set(ref, {
        ...stop.copyWith(garitaId: garitaId).toMap(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return quilpueBusStops.length;
  }

  /// Sustituye la lista sin tocar la red. Sólo para tests.
  @visibleForTesting
  void debugSetStops(List<BusStop> stops) {
    _stops = List.unmodifiable(stops);
    notifyListeners();
  }
}
