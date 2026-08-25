import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/colectivo_activo.dart';

class FirebaseTelemetriaService {
  FirebaseTelemetriaService._privateConstructor();
  static final FirebaseTelemetriaService instance =
      FirebaseTelemetriaService._privateConstructor();

  final _db = FirebaseDatabase.instance.ref('colectivos_activos');
  StreamSubscription<Position>? _positionSubscription;
  String? _idVehiculo;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  String? get currentVehicleId => _idVehiculo;

  Stream<List<ColectivoActivo>> get telemetriaStream {
    return _db.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      try {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((e) {
          final Map<String, dynamic> item =
              Map<String, dynamic>.from(e.value as Map);
          return ColectivoActivo.fromJson(item);
        }).toList();
      } catch (e) {
        debugPrint('Error parseando telemetria: $e');
        return [];
      }
    });
  }

  Future<void> iniciarTrackingReal(String idVehiculo) async {
    // Si ya está transmitiendo con el mismo ID, no reiniciar innecesariamente
    if (_isTracking && _idVehiculo == idVehiculo) return;

    // Detener tracking previo si había uno
    await detenerTrackingReal();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _idVehiculo = idVehiculo;
    _isTracking = true;

    // Configurar onDisconnect: si la app se cierra o pierde conexión,
    // Firebase eliminará automáticamente el vehículo del mapa
    final vehicleRef = _db.child(_idVehiculo!);
    await vehicleRef.onDisconnect().remove();

    // Configuración para permitir rastreo continuo en segundo plano en Android
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Modo Conductor Activo',
          notificationText: 'Transmitiendo ubicación a los pasajeros en tiempo real',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!_isTracking || _idVehiculo == null) return;

      final lat = position.latitude;
      final lng = position.longitude;
      if (!lat.isFinite || !lng.isFinite || (lat == 0.0 && lng == 0.0)) return;

      final colectivo = ColectivoActivo(
        idVehiculo: _idVehiculo!,
        latitud: lat,
        longitud: lng,
      );

      vehicleRef.set(colectivo.toJson());
    }, onError: (e) {
      debugPrint('Error en stream de ubicación en vivo: $e');
    });
  }

  Future<void> detenerTrackingReal() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (_idVehiculo != null) {
      try {
        await _db.child(_idVehiculo!).remove();
      } catch (e) {
        debugPrint('Error al remover vehículo de Firebase: $e');
      }
      _idVehiculo = null;
    }
  }
}
