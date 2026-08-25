import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:taxi1/l10n/app_localizations.dart';
import 'package:taxi1/services/preferences_service.dart';
import 'package:taxi1/models/bus_stop.dart';
import 'package:taxi1/services/route_service.dart';
import 'package:taxi1/models/colectivo_activo.dart';
import 'package:taxi1/services/firebase_telemetria_service.dart';

String _routeErrorMessage(String errorCode, AppLocalizations l10n) {
  return switch (errorCode) {
    'provider_error' => l10n.errProvider,
    'no_route' => l10n.errNoRoute,
    _ => l10n.routeErrorDefault,
  };
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _mapController;
  StreamSubscription<Position>? _positionStream;
  bool _followUser = true;
  LatLng? _currentPosition;
  bool _showBusStops = true;

  final routeService = RouteService.instance;
  final prefs = PreferencesService.instance;

  late final AnimationController _centerBtnController;
  late final Animation<double> _centerScale;

  @override
  void initState() {
    super.initState();
    _updateTrackingState();
    _mapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    prefs.addListener(_onPrefsChanged);
    routeService.addListener(_onRouteChanged);

    _centerBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _centerScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _centerBtnController, curve: Curves.easeOut),
    );

    _initLocationTracking();
  }

  @override
  void dispose() {
    FirebaseTelemetriaService.instance.detenerTrackingReal();
    prefs.removeListener(_onPrefsChanged);
    routeService.removeListener(_onRouteChanged);
    _centerBtnController.dispose();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    _updateTrackingState();
    final tracking = prefs.locationTracking;
    if (!tracking) {
      _positionStream?.cancel();
      _positionStream = null;
      if (mounted) setState(() => _followUser = false);
    }
    if (mounted) setState(() {});
  }

  void _updateTrackingState() {
    if (prefs.isChofer && prefs.locationTracking) {
      FirebaseTelemetriaService.instance.iniciarTrackingReal(prefs.driverId);
    } else {
      FirebaseTelemetriaService.instance.detenerTrackingReal();
    }
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initLocationTracking() async {
    if (!prefs.locationTracking) {
      _followUser = false;
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Validar que las coordenadas sean finitas. En emuladores o antes del
      // primer fix real del GPS, Geolocator puede devolver 0,0 o NaN, lo que
      // rompe flutter_map ("LatLng is not finite").
      final lat = position.latitude;
      final lng = position.longitude;
      if (!lat.isFinite || !lng.isFinite) return;
      if (lat == 0.0 && lng == 0.0) return; // fix fantasma del emulador

      setState(() {
        _currentPosition = LatLng(lat, lng);
        if (routeService.origin == null) {
          routeService.setOrigin(_currentPosition!);
        }
        if (_followUser) {
          _mapController.mapController.move(
            _currentPosition!,
            _mapController.mapController.camera.zoom,
          );
        }
      });
    });
  }

  Future<void> _recenter() async {
    if (_currentPosition != null) {
      _centerBtnController.forward(from: 0);
      await _mapController.centerOnPoint(_currentPosition!, zoom: 16.0);
      _centerBtnController.reverse();
      setState(() => _followUser = true);
    }
  }

  Future<void> _reorient() async {
    await _mapController.animatedRotateReset();
  }

  /// Toca un paradero del mapa: setea destino y pide la ruta.
  Future<void> _onTapStop(BusStop stop) async {
    routeService.setDestination(stop);
    final origin = routeService.origin ?? _currentPosition;
    if (origin == null) return;

    final ok = await routeService.fetchRoute(origin, stop);
    if (!mounted) return;

    await _mapController.centerOnPoint(stop.location, zoom: 16.0);

    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            routeService.lastError != null
                ? _routeErrorMessage(routeService.lastError!, l10n)
                : l10n.routeErrorDefault,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _stopColor(BusStop stop) {
    final origin = routeService.origin ?? _currentPosition;
    if (origin == null) return Colors.grey;
    final d = stop.distanceFrom(origin);
    if (d < 500) return Colors.green;
    if (d < 1500) return Colors.blue;
    if (d < 3000) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final destination = routeService.destination;
    final origin = routeService.origin ?? _currentPosition;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Padding superior para no chocar con la status bar / notch /
    // notificaciones flotantes del sistema.
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController.mapController,
            options: MapOptions(
              initialCenter: const LatLng(-33.0472, -71.4425),
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.rotate,
                enableMultiFingerGestureRace: true,
                rotationThreshold: 30.0,
              ),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: prefs.mapType == 'satellite'
                    ? 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=twZDa0L757dpVwBfAbBr'
                    : 'https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}.png?key=twZDa0L757dpVwBfAbBr',
              ),

              // Polilínea de la ruta real.
              // Va PRIMERO (después de los tiles) para que los marcadores
              // se dibujen encima y la ruta no los tape.
              if (destination != null &&
                  origin != null &&
                  routeService.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeService.routePoints,
                      strokeWidth: 5.0,
                      color: scheme.primary,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Halo de precisión alrededor del usuario pasajero (local y privado)
              if (_currentPosition != null && !prefs.isChofer)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentPosition!,
                      radius: 50,
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderColor: scheme.primary.withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // Colectivos / Choferes Reales (Firebase Telemetría en Vivo)
              StreamBuilder<List<ColectivoActivo>>(
                stream: FirebaseTelemetriaService.instance.telemetriaStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  return MarkerLayer(
                    markers: snapshot.data!.map((colectivo) {
                      final isMe = prefs.isChofer && colectivo.idVehiculo == prefs.driverId;
                      return Marker(
                        point: LatLng(colectivo.latitud, colectivo.longitud),
                        width: isMe ? 46 : 40,
                        height: isMe ? 46 : 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue.shade900 : Colors.blue.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMe ? Colors.amberAccent : Colors.white,
                              width: isMe ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: isMe ? Colors.amberAccent : Colors.white,
                            size: isMe ? 24 : 20,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // Marcador del Pasajero (Punto azul clásico personal)
              if (_currentPosition != null && !prefs.isChofer)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Paraderos. El seleccionado se destaca dentro del propio pin
              // (anillo + tamaño mayor + sombra) — sin agregar otro marcador.
              if (_showBusStops)
                MarkerLayer(
                  markers: [
                    for (final stop in quilpueBusStops)
                      Marker(
                        point: stop.location,
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _onTapStop(stop),
                          child: _BusStopPin(
                            color: _stopColor(stop),
                            selected:
                                destination != null && destination == stop,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Indicador flotante de "calculando ruta…"
          if (routeService.loadingRoute)
            Positioned(
              top: topPadding,
              left: 16,
              right: 16,
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.calculatingRoute,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Botón de reorientado (norte arriba).
          Positioned(
            top: topPadding,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'reorient',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: _reorient,
              child: const Icon(Icons.explore),
            ),
          ),

          // Toggle de paraderos. Debajo del botón de reorientar.
          Positioned(
            top: topPadding + 56,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'toggle_stops',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: () => setState(() => _showBusStops = !_showBusStops),
              tooltip: _showBusStops
                  ? AppLocalizations.of(context)!.hideStops
                  : AppLocalizations.of(context)!.showStops,
              child: Icon(_showBusStops
                  ? Icons.location_on
                  : Icons.location_off_outlined),
            ),
          ),

          // Botón flotante de recentrado.
          // Cuando hay una ruta activa, sube para no quedar tapado por la
          // tarjeta de estado inferior (que crece con la info de ruta).
          Positioned(
            right: 16,
            bottom: destination != null ? 155 : 85,
            child: ScaleTransition(
              scale: _centerScale,
              child: FloatingActionButton(
                heroTag: 'recenter',
                // Color contrario al tema: blanco en oscuro, oscuro en claro.
                backgroundColor:
                    isDark ? Colors.white : Colors.grey.shade900,
                foregroundColor: isDark ? Colors.black87 : Colors.white,
                onPressed: _recenter,
                child: Icon(_followUser
                    ? Icons.my_location
                    : Icons.location_searching),
              ),
            ),
          ),

          // Tarjeta de estado inferior con info de ruta.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _StatusCard(
              destination: destination,
              currentPosition: _currentPosition,
              followUser: _followUser,
              routeInfo: routeService.routeInfo,
              provider: routeService.activeProvider,
              onClose: () => routeService.clearDestination(),
              onTap: destination != null
                  ? () {
                      _mapController.centerOnPoint(
                        destination.location,
                        zoom: 16.0,
                      );
                      setState(() => _followUser = false);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _BusStopPin extends StatefulWidget {
  const _BusStopPin({required this.color, required this.selected});
  final Color color;
  final bool selected;

  @override
  State<_BusStopPin> createState() => _BusStopPinState();
}

class _BusStopPinState extends State<_BusStopPin>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // El pulso crece de 1x a 2.2x mientras se desvanece de 0.55 a 0.
    _pulseScale = Tween<double>(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeIn));

    if (widget.selected) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _BusStopPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cuando está seleccionado, agrandamos el pin y le agregamos un anillo
    // blanco exterior + sombra más pronunciada para que destaque sobre los
    // demás sin necesidad de un marcador aparte. Encima, una animación de
    // pulso tipo radar indica que es el destino activo.
    final selected = widget.selected;
    final size = selected ? 40.0 : 28.0;
    final iconSize = selected ? 22.0 : 16.0;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Pulso tipo radar (solo cuando está seleccionado).
          if (selected)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Pin principal.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: selected ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? 0.4 : 0.25),
                  blurRadius: selected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_bus,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.destination,
    required this.currentPosition,
    required this.followUser,
    required this.routeInfo,
    required this.provider,
    required this.onClose,
    this.onTap,
  });

  final BusStop? destination;
  final LatLng? currentPosition;
  final bool followUser;
  final RouteResult? routeInfo;
  final String? provider;
  final VoidCallback onClose;

  /// Al tocar la tarjeta con destino, el mapa se centra en el paradero.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Sin destino: mostrar ubicación / estado del GPS.
    if (destination == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                followUser ? Icons.gps_fixed : Icons.gps_off,
                color: followUser ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentPosition != null
                      ? l10n.coordsLabel(
                          currentPosition!.latitude.toStringAsFixed(5),
                          currentPosition!.longitude.toStringAsFixed(5),
                        )
                      : l10n.searchingLocation,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Con destino: mostrar nombre, distancia y duración si hay ruta.
    // Tocar la tarjeta centra el mapa en el paradero de destino.
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${destination!.name} — ${destination!.address}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                    tooltip: l10n.closeRoute,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (routeInfo != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MetricChip(
                      icon: Icons.straighten,
                      label: routeInfo!.distanceLabel,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _MetricChip(
                      icon: Icons.schedule,
                      label: routeInfo!.durationLabel,
                      color: scheme.tertiary,
                    ),
                    const Spacer(),
                    if (provider != null)
                      Text(
                        l10n.viaProvider(provider!),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.tapToGoStop,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
