import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/colectivo_activo.dart';

class MockTelemetriaService {
  MockTelemetriaService._privateConstructor();
  static final MockTelemetriaService instance = MockTelemetriaService._privateConstructor();

  final _streamController = StreamController<List<ColectivoActivo>>.broadcast();
  Timer? _timer;

  // Ruta simulada a lo largo de Avenida Los Carrera, Quilpué
  // Coordenadas consecutivas simulando un avance por Los Carrera hacia el este
  final List<LatLng> _rutaMock = [
    const LatLng(-33.0455, -71.4420),
    const LatLng(-33.0456, -71.4410),
    const LatLng(-33.0457, -71.4400),
    const LatLng(-33.0458, -71.4390),
    const LatLng(-33.0459, -71.4380),
  ];
  

  // Índices para cada vehículo para que no estén todos en el mismo lugar
  int _indiceVehiculo1 = 0;
  int _indiceVehiculo2 = 2;
  int _indiceVehiculo3 = 4;

  List<ColectivoActivo> _colectivos = [];

  Stream<List<ColectivoActivo>> get telemetriaStream => _streamController.stream;

  void iniciarSimulacion() {
    _actualizarPosiciones();
    
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Avanzar el índice de cada vehículo
      _indiceVehiculo1 = (_indiceVehiculo1 + 1) % _rutaMock.length;
      _indiceVehiculo2 = (_indiceVehiculo2 + 1) % _rutaMock.length;
      _indiceVehiculo3 = (_indiceVehiculo3 + 1) % _rutaMock.length;

      _actualizarPosiciones();
    });
  }

  void _actualizarPosiciones() {
    _colectivos = [
      ColectivoActivo(idVehiculo: 'AA-BB-11', latitud: _rutaMock[_indiceVehiculo1].latitude, longitud: _rutaMock[_indiceVehiculo1].longitude),
      ColectivoActivo(idVehiculo: 'CC-DD-22', latitud: _rutaMock[_indiceVehiculo2].latitude, longitud: _rutaMock[_indiceVehiculo2].longitude),
      ColectivoActivo(idVehiculo: 'EE-FF-33', latitud: _rutaMock[_indiceVehiculo3].latitude, longitud: _rutaMock[_indiceVehiculo3].longitude),
    ];

    if (!_streamController.isClosed) {
      _streamController.add(_colectivos);
    }
  }

  void detenerSimulacion() {
    _timer?.cancel();
  }
}
