import 'package:flutter/material.dart';

import 'package:taxi1/l10n/app_localizations.dart';
import 'package:taxi1/models/app_user.dart';
import 'package:taxi1/screens/auth/login_screen.dart';
import 'package:taxi1/screens/auth/register_screen.dart';
import 'package:taxi1/theme/app_spacing.dart';
import 'package:taxi1/utils/role_format.dart';

/// Presentación de los tres perfiles, en el primer arranque.
///
/// **No es una puerta.** El invitado no necesita cuenta, así que bloquear la
/// app detrás de un login contradiría el diseño; esta pantalla se apila encima
/// del mapa, que ya está funcionando debajo, y se descarta con un toque. Se
/// muestra una sola vez ([PreferencesService.seenWelcome]) porque su trabajo es
/// dar a conocer que existen los otros dos perfiles, no repetirlo cada día.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openLogin(BuildContext context, UserRole role) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(initialRole: role)),
    );
  }

  void _openRegister(BuildContext context, UserRole role) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(initialRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_filled,
                      size: 40,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Text(l10n.welcomeQuestion, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),

                // El invitado va primero y con el botón lleno: es el camino que
                // la mayoría va a tomar, y el que no cuesta nada.
                _RoleCard(
                  role: UserRole.invitado,
                  description: l10n.welcomeGuestDesc,
                  action: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.welcomeContinueGuest),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _RoleCard(
                  role: UserRole.colectivero,
                  description: l10n.welcomeDriverDesc,
                  action: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _openLogin(context, UserRole.colectivero),
                        child: Text(l10n.signIn),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () =>
                            _openRegister(context, UserRole.colectivero),
                        child: Text(l10n.createAccount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _RoleCard(
                  role: UserRole.administrador,
                  description: l10n.welcomeAdminDesc,
                  action: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _openLogin(context, UserRole.administrador),
                        child: Text(l10n.signIn),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () =>
                            _openRegister(context, UserRole.administrador),
                        child: Text(l10n.createAccount),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.welcomeChangeLater,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.description,
    required this.action,
  });

  final UserRole role;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final badge = roleBadgeColors(role, scheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: badge.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(roleIcon(role), color: badge.foreground),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    roleLabel(role, l10n),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            action,
          ],
        ),
      ),
    );
  }
}
