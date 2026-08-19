import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/colectivo_activo.dart';

class FirebaseTelemetriaService {
  FirebaseTelemetriaService._privateConstructor();
  static final FirebaseTelemetriaService instance = FirebaseTelemetriaService._privateConstructor();

  final _db = FirebaseDatabase.instance.ref('colectivos_activos');
  StreamSubscription<Position>? _positionSubscription;
  String? _idUnico;

  Stream<List<ColectivoActivo>> get telemetriaStream {
    return _db.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((e) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(e.value as Map);
        return ColectivoActivo.fromJson(item);
      }).toList();
    });
  }

  Future<void> iniciarTrackingReal() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _idUnico = DateTime.now().millisecondsSinceEpoch.toString();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_idUnico == null) return;
      
      final colectivo = ColectivoActivo(
        idVehiculo: _idUnico!,
        latitud: position.latitude,
        longitud: position.longitude,
      );

      _db.child(_idUnico!).set(colectivo.toJson());
    });
  }

  void detenerTrackingReal() {
    _positionSubscription?.cancel();
    if (_idUnico != null) {
      _db.child(_idUnico!).remove();
    }
  }
}
