import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:taxi1/models/bus_stop.dart';
import 'package:taxi1/services/route_service.dart';
import 'package:taxi1/screens/main_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  LatLng? _currentPosition;
  bool _loadingLocation = true;
  bool _fetchingRoute = false;
  List<BusStop> _sortedStops = [];
  String _searchQuery = '';

  final routeService = RouteService.instance;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    routeService.addListener(_onRouteChanged);
    _initLocation();
  }

  @override
  void dispose() {
    routeService.removeListener(_onRouteChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return setState(() => _loadingLocation = false);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return setState(() => _loadingLocation = false);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      // Filtrar posiciones inválidas (NaN o 0,0 — común en emuladores).
      final lat = position.latitude;
      final lng = position.longitude;
      if (lat.isFinite && lng.isFinite && !(lat == 0.0 && lng == 0.0)) {
        _currentPosition = LatLng(lat, lng);
        routeService.setOrigin(_currentPosition!);
      }

      _sortedStops = List.from(quilpueBusStops);
      if (_currentPosition != null) {
        _sortedStops.sort(
          (a, b) => a
              .distanceFrom(_currentPosition!)
              .compareTo(b.distanceFrom(_currentPosition!)),
        );
      }
    } catch (_) {
      // Si falla la ubicación, igual mostramos los paraderos sin ordenar.
      _sortedStops = List.from(quilpueBusStops);
    }

    if (mounted) setState(() => _loadingLocation = false);
  }

  /// Selección + cálculo de ruta + cambio de tab al mapa.
  /// Antes solo seteaba el destino y abría un MapScreen nuevo, lo que
  /// dejaba la polilínea vacía y el mapa dibujaba una línea recta.
  Future<void> _selectStop(BusStop stop) async {
    if (_fetchingRoute) return;

    if (_currentPosition != null) {
      routeService.setOrigin(_currentPosition!);
    }
    routeService.setDestination(stop);

    // Si no tenemos origen válido, no podemos pedir la ruta.
    final origin = routeService.origin;
    if (origin == null ||
        !origin.latitude.isFinite ||
        !origin.longitude.isFinite) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu ubicación aún no está disponible. Activá el GPS o esperá '
            'unos segundos.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      routeService.clearDestination();
      return;
    }

    setState(() => _fetchingRoute = true);

    final ok = await routeService.fetchRoute(origin, stop);

    if (!mounted) return;
    setState(() => _fetchingRoute = false);

    if (ok) {
      // Cambiar de tab (no Navigator.push) para preservar el estado del mapa.
      MainNavigationController.instance.showMap();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            routeService.lastError ??
                'No se pudo calcular la ruta. Inténtalo de nuevo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _distanceLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  /// Etiqueta de cercanía para los chips.
  String _closenessLabel(double meters) {
    if (meters < 500) return 'Muy cerca';
    if (meters < 1500) return 'Cerca';
    if (meters < 3000) return 'A media distancia';
    return 'Lejos';
  }

  Color _closenessColor(double meters, ColorScheme scheme) {
    if (meters < 500) return Colors.green;
    if (meters < 1500) return scheme.primary;
    if (meters < 3000) return Colors.orange;
    return Colors.red.shade400;
  }

  List<BusStop> get _filteredStops {
    if (_searchQuery.isEmpty) return _sortedStops;
    final q = _searchQuery.toLowerCase();
    return _sortedStops
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calcular Ruta')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Origen
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Origen (Mi ubicación actual)',
                prefixIcon: const Icon(Icons.my_location),
                border: const OutlineInputBorder(),
                hintText: _currentPosition != null
                    ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}'
                    : 'Buscando ubicación…',
              ),
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar paradero por nombre o dirección…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '¿A dónde quieres ir?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          if (_loadingLocation)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: _filteredStops.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados para "$_searchQuery"',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      itemCount: _filteredStops.length,
                      itemBuilder: (context, index) {
                        final stop = _filteredStops[index];
                        final distMeters = _currentPosition != null
                            ? stop.distanceFrom(_currentPosition!)
                            : 0.0;
                        final isFetchingThis =
                            _fetchingRoute && routeService.destination == stop;
                        return _StopTile(
                          stop: stop,
                          distanceMeters: distMeters,
                          distanceLabel: _distanceLabel(distMeters),
                          closenessLabel: _closenessLabel(distMeters),
                          closenessColor: _closenessColor(distMeters, scheme),
                          onTap: () => _selectStop(stop),
                          showLoading: isFetchingThis,
                        );
                      },
                    ),
            ),

          // Acción: paradero más cercano
          if (!_loadingLocation && _sortedStops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.tonalIcon(
                onPressed: _fetchingRoute
                    ? null
                    : () => _selectStop(_sortedStops.first),
                icon: const Icon(Icons.near_me),
                label: const Text('Ir al paradero más cercano'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.distanceMeters,
    required this.distanceLabel,
    required this.closenessLabel,
    required this.closenessColor,
    required this.onTap,
    required this.showLoading,
  });

  final BusStop stop;
  final double distanceMeters;
  final String distanceLabel;
  final String closenessLabel;
  final Color closenessColor;
  final VoidCallback onTap;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: showLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Punto de color según cercanía.
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: closenessColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stop.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: closenessColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      closenessLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: closenessColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (showLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
