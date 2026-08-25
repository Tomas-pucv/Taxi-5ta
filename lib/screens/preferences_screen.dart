import 'package:flutter/material.dart';
import 'package:taxi1/l10n/app_localizations.dart';
import 'package:taxi1/services/preferences_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with SingleTickerProviderStateMixin {
  final prefs = PreferencesService.instance;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    prefs.load().then((_) => setState(() {}));
    prefs.addListener(_onPrefsChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (prefs.animationsEnabled) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    prefs.removeListener(_onPrefsChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() => setState(() {});

  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!prefs.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.preferencesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesTitle)),
      body: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modo de Usuario (Chofer vs Pasajero)
              _buildSectionCard(
                icon: Icons.badge_outlined,
                title: 'Modo de Usuario',
                children: [
                  _buildRadioOption(
                    'Pasajero (Ubicación privada y local)',
                    'pasajero',
                    prefs.userRole,
                    (v) => prefs.setUserRole(v!),
                  ),
                  _buildDivider(),
                  _buildRadioOption(
                    'Chofer / Conductor (Transmisión en vivo)',
                    'chofer',
                    prefs.userRole,
                    (v) => prefs.setUserRole(v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mapa
              _buildSectionCard(
                icon: Icons.map_outlined,
                title: l10n.sectionMap,
                children: [
                  _buildRadioOption(
                    l10n.mapNormal,
                    'normal',
                    prefs.mapType,
                    (v) => prefs.setMapType(v!),
                  ),
                  _buildDivider(),
                  _buildRadioOption(
                    l10n.satellite,
                    'satellite',
                    prefs.mapType,
                    (v) => prefs.setMapType(v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Apariencia
              _buildSectionCard(
                icon: Icons.palette_outlined,
                title: l10n.sectionAppearance,
                children: [
                  _buildRadioOption(
                    l10n.themeLight,
                    'light',
                    prefs.themeMode == ThemeMode.light ? 'light' : 'dark',
                    (v) => prefs.setTheme(v!),
                  ),
                  _buildDivider(),
                  _buildRadioOption(
                    l10n.themeDark,
                    'dark',
                    prefs.themeMode == ThemeMode.light ? 'light' : 'dark',
                    (v) => prefs.setTheme(v!),
                  ),
                  _buildDivider(),
                  _buildSliderOption(
                    l10n.fontSize,
                    prefs.fontSizeMultiplier,
                    0.8,
                    1.4,
                    (value) => prefs.setFontSizeMultiplier(value),
                  ),
                  _buildDivider(),
                  _buildSwitchOption(
                    l10n.compactMode,
                    prefs.compactMode,
                    (value) => prefs.setCompactMode(value),
                  ),
                  _buildDivider(),
                  _buildSwitchOption(
                    l10n.animations,
                    prefs.animationsEnabled,
                    (value) => prefs.setAnimationsEnabled(value),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notificaciones
              _buildSectionCard(
                icon: Icons.notifications_outlined,
                title: l10n.sectionNotifications,
                children: [
                  _buildSwitchOption(
                    l10n.enableNotifications,
                    prefs.notificationsEnabled,
                    (value) => prefs.setNotificationsEnabled(value),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Privacidad
              _buildSectionCard(
                icon: Icons.privacy_tip_outlined,
                title: l10n.sectionPrivacy,
                children: [
                  _buildSwitchOption(
                    l10n.locationTracking,
                    prefs.locationTracking,
                    (value) {
                      if (!value) {
                        _showConfirmationDialog(
                          l10n.disableTrackingTitle,
                          l10n.disableTrackingMessage,
                          () => prefs.setLocationTracking(false),
                        );
                      } else {
                        prefs.setLocationTracking(true);
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchOption(
                    l10n.saveHistory,
                    prefs.historyEnabled,
                    (value) => prefs.setHistoryEnabled(value),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Información
              _buildInfoCard(l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Componentes de UI — estilo outlined minimalista y elegante
  // ---------------------------------------------------------------------------

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cabecera elegante
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5 * prefs.fontSizeMultiplier,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(children: [for (final child in children) child]),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 0.8,
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    String selectedValue,
    void Function(String?) onSelected,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedValue == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14 * prefs.fontSizeMultiplier,
                  color: scheme.onSurface,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14 * prefs.fontSizeMultiplier,
                color: scheme.onSurface,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderOption(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14 * prefs.fontSizeMultiplier,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12 * prefs.fontSizeMultiplier,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 6,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 1.2),
        color: scheme.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.infoTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13 * prefs.fontSizeMultiplier,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.infoBody,
                  style: TextStyle(
                    fontSize: 12 * prefs.fontSizeMultiplier,
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
