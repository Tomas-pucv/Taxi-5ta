import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:taxi1/config/map_config.dart';
import 'package:taxi1/l10n/app_localizations.dart';
import 'package:taxi1/models/bus_stop.dart';
import 'package:taxi1/navigation/app_destination.dart';
import 'package:taxi1/services/auth_service.dart';
import 'package:taxi1/services/stops_service.dart';
import 'package:taxi1/theme/app_colors.dart';
import 'package:taxi1/theme/app_spacing.dart';
import 'package:taxi1/theme/breakpoints.dart';
import 'package:taxi1/widgets/setting_tile.dart';
import 'package:taxi1/widgets/state_views.dart';

/// CRUD de paraderos para el administrador de garita.
class ParaderosAdminScreen extends StatefulWidget {
  const ParaderosAdminScreen({super.key});

  @override
  State<ParaderosAdminScreen> createState() => _ParaderosAdminScreenState();
}

class _ParaderosAdminScreenState extends State<ParaderosAdminScreen> {
  final _stops = StopsService.instance;
  final _auth = AuthService.instance;
  final _searchController = TextEditingController();

  String _query = '';
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _stops.addListener(_onChanged);
  }

  @override
  void dispose() {
    _stops.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<BusStop> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _stops.stops;
    return _stops.stops
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(BusStop? stop) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ParaderoEditorScreen(
          stop: stop,
          garitaId: _auth.garitaId ?? '',
        ),
      ),
    );
    if (saved ?? false) _toast(l10n.stopSaved);
  }

  Future<void> _confirmDeactivate(BusStop stop) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.visibility_off_outlined),
        title: Text(l10n.stopDeleteTitle),
        content: Text(l10n.stopDeleteMessage(stop.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.stopDeactivate),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await _stops.desactivar(stop);
    _toast(l10n.stopDeleted);
  }

  Future<void> _importSeed() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _importing = true);
    try {
      final count = await _stops.importarSemilla(_auth.garitaId ?? '');
      _toast(l10n.stopsImported('$count'));
    } catch (_) {
      _toast(l10n.errAuthUnknown);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stops = _visible;

    return Scaffold(
      appBar: AppBar(title: Text(AppDestination.paraderos.label(l10n))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.stopAdd),
      ),
      body: !_auth.isAdmin
          ? StatusMessageView(
              icon: Icons.lock_outline,
              title: AppDestination.paraderos.label(l10n),
              message: l10n.adminOnly,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.maxContentWidth,
                ),
                child: Column(
                  children: [
                    // Mientras la garita no haya importado sus paraderos, lo
                    // que se ve son las semillas locales: editarlas sin avisar
                    // daría la impresión de que se guardó algo que no existe.
                    if (!_stops.hasRemoteData)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          0,
                        ),
                        child: InlineNotice(
                          icon: Icons.cloud_upload_outlined,
                          message: l10n.stopsSeedNotice,
                          actionLabel: _importing
                              ? null
                              : l10n.stopsImportSeed,
                          onAction: _importing ? null : _importSeed,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: l10n.stopSearchHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    Expanded(
                      child: stops.isEmpty
                          ? StatusMessageView(
                              icon: Icons.pin_drop_outlined,
                              title: l10n.stopsEmpty,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                96,
                              ),
                              itemCount: stops.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final stop = stops[index];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.pin_drop),
                                    title: Text(stop.name),
                                    subtitle: Text(
                                      stop.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.visibility_off_outlined,
                                      ),
                                      tooltip: l10n.stopDeactivate,
                                      onPressed: () =>
                                          _confirmDeactivate(stop),
                                    ),
                                    onTap: () => _edit(stop),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Editor de un paradero: mapa arriba, datos abajo.
///
/// La ubicación se elige **sobre el mapa** y no escribiendo coordenadas: quien
/// administra una garita conoce la esquina, no su latitud.
class ParaderoEditorScreen extends StatefulWidget {
  const ParaderoEditorScreen({
    super.key,
    required this.stop,
    required this.garitaId,
  });

  final BusStop? stop;
  final String garitaId;

  @override
  State<ParaderoEditorScreen> createState() => _ParaderoEditorScreenState();
}

class _ParaderoEditorScreenState extends State<ParaderoEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _direccion;
  late final MapController _mapController;

  late LatLng _location;
  late bool _activo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final stop = widget.stop;
    _nombre = TextEditingController(text: stop?.name ?? '');
    _direccion = TextEditingController(text: stop?.address ?? '');
    _location = stop?.location ?? kQuilpueCenter;
    _activo = stop?.activo ?? true;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final base =
        widget.stop ??
        BusStop(
          id: '',
          name: '',
          address: '',
          location: _location,
          garitaId: widget.garitaId,
        );

    try {
      await StopsService.instance.upsert(
        base.copyWith(
          name: _nombre.text.trim(),
          address: _direccion.text.trim(),
          location: _location,
          garitaId: widget.garitaId,
          activo: _activo,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.errAuthUnknown)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stop == null ? l10n.stopAdd : l10n.stopEdit),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _location,
                    initialZoom: 16,
                    onLongPress: (_, point) =>
                        setState(() => _location = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapTileUrlTemplate(
                        MapStyle.fromPref('normal'),
                        isDark: isDark,
                      ),
                      userAgentPackageName: 'com.example.taxi1',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _location,
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.pin_drop,
                            size: 40,
                            color: status.distanceVeryClose,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: InlineNotice(
                    icon: Icons.touch_app_outlined,
                    message: l10n.stopPickOnMap,
                    tone: StatusTone.neutral,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.stopName,
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.authRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _direccion,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.stopAddress,
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.authRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SettingSwitchTile(
                    title: l10n.stopActive,
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.coordsLabel(
                      _location.latitude.toStringAsFixed(5),
                      _location.longitude.toStringAsFixed(5),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
