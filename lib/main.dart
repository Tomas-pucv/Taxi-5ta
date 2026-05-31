import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;

  LatLng currentPosition = const LatLng(-33.0472, -71.6127);

  StreamSubscription<Position>? _positionStream;

  bool _followUser = true;

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
          final newPos = LatLng(pos.latitude, pos.longitude);

          setState(() {
            currentPosition = newPos;
          });

          // Solo seguir al usuario si el modo seguimiento está activo
          if (_followUser) {
            _animatedMapController.mapController.move(
              newPos,
              _animatedMapController.mapController.camera.zoom,
            );
          }
        });
  }

  void _recenter() {
    setState(() {
      _followUser = true;
    });

    _animatedMapController.animateTo(dest: currentPosition, zoom: 16);
  }

  void _zoomIn() {
    _animatedMapController.animateTo(
      zoom: _animatedMapController.mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _animatedMapController.animateTo(
      zoom: _animatedMapController.mapController.camera.zoom - 1,
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: currentPosition,
              initialZoom: 16,

              // Cuando el usuario mueve el mapa,
              // desactivar seguimiento automático.
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() {
                    _followUser = false;
                  });
                }
              },

              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/streets-v4/{z}/{x}/{y}.png?key=twZDa0L757dpVwBfAbBr",
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentPosition,
                    radius: 30,
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderColor: Colors.blue.withValues(alpha: 0.5),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPosition,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.75),
                  foregroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.75),
                  foregroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Recenter button
          Positioned(
            right: 16,
            bottom: 170,
            child: FloatingActionButton(
              heroTag: "recenter",
              backgroundColor: const Color(0xFFE3F2FD),
              foregroundColor: const Color(0xFF1565C0),
              onPressed: _recenter,
              child: Icon(
                _followUser ? Icons.my_location : Icons.location_searching,
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            left: 16,
            right: 16,
            bottom: 50,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _followUser
                          ? "Siguiendo ubicación"
                          : "Seguimiento pausado",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _followUser ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Lat: ${currentPosition.latitude.toStringAsFixed(5)}"),
                    Text(
                      "Lng: ${currentPosition.longitude.toStringAsFixed(5)}",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
