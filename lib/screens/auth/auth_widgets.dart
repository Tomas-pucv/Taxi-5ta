import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taxi1/l10n/app_localizations.dart';
import 'package:taxi1/models/app_user.dart';
import 'package:taxi1/theme/app_spacing.dart';
import 'package:taxi1/utils/patente.dart';
import 'package:taxi1/utils/role_format.dart';

/// Elige entre los dos roles que requieren cuenta.
///
/// El invitado no aparece: no se "inicia sesión como invitado", se *es*
/// invitado por no haber iniciado sesión. Ofrecerlo acá sugeriría lo contrario.
class AuthRoleSelector extends StatelessWidget {
  const AuthRoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<UserRole>(
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: UserRole.colectivero,
          icon: Icon(roleIcon(UserRole.colectivero), size: 18),
          label: Text(l10n.roleColectivero),
        ),
        ButtonSegment(
          value: UserRole.administrador,
          icon: Icon(roleIcon(UserRole.administrador), size: 18),
          label: Text(l10n.roleAdmin),
        ),
      ],
    );
  }
}

/// Fuerza mayúsculas mientras se escribe.
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Campo de patente.
///
/// Normaliza mientras se escribe a propósito: la patente se convierte en el
/// correo con el que Firebase identifica la cuenta, así que si el chofer la
/// tipea distinta a como la registró, no entra. Corregirlo acá es más barato
/// que explicárselo después, sobre todo porque no hay recuperación por correo.
class PatenteField extends StatelessWidget {
  const PatenteField({
    super.key,
    required this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
        LengthLimitingTextInputFormatter(8),
        const _UpperCaseFormatter(),
      ],
      decoration: InputDecoration(
        labelText: l10n.authPatente,
        hintText: l10n.authPatenteHint,
        prefixIcon: const Icon(Icons.directions_car_outlined),
      ),
      validator: (value) {
        final v = (value ?? '').trim();
        if (v.isEmpty) return l10n.authRequired;
        if (!isValidPatente(v)) return l10n.authPatenteInvalid;
        return null;
      },
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  static final _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: l10n.authEmail,
        prefixIcon: const Icon(Icons.alternate_email),
      ),
      validator: (value) {
        final v = (value ?? '').trim();
        if (v.isEmpty) return l10n.authRequired;
        if (!_pattern.hasMatch(v)) return l10n.authEmailInvalid;
        return null;
      },
    );
  }
}

/// Campo de contraseña con interruptor de visibilidad.
///
/// El ojo no es decorativo: sin recuperación por correo para los choferes,
/// poder releer lo que se escribió es la única red de seguridad que hay antes
/// de confirmar.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label ?? l10n.authPassword,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          tooltip: _obscure ? l10n.authShowPassword : l10n.authHidePassword,
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator:
          widget.validator ??
          (value) => (value ?? '').isEmpty ? l10n.authRequired : null,
    );
  }
}

/// Contenedor común de las pantallas de autenticación: ancho legible, scroll y
/// respiro inferior para que el teclado no tape el botón de envío.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
