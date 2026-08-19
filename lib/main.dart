import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taxi1/l10n/app_localizations.dart';
import 'package:taxi1/screens/main_screen.dart';
import 'package:taxi1/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa Firebase (descomenta la línea de abajo cuando tengas el
  // google-services.json configurado):
  // await Firebase.initializeApp();
  

  await PreferencesService.instance.load();
  runApp(const ColeTotalApp());
}

class ColeTotalApp extends StatefulWidget {
  const ColeTotalApp({super.key});

  @override
  State<ColeTotalApp> createState() => _ColeTotalAppState();
}

class _ColeTotalAppState extends State<ColeTotalApp> {
  final prefs = PreferencesService.instance;

  @override
  void initState() {
    super.initState();
    prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() => setState(() {});

  ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scheme.surface,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Barra del sistema (iconos y fondo) contrastando con tema claro:
        // fondo claro, iconos oscuros.
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // El indicador usa secondaryContainer: el icono seleccionado cae
        // automáticamente a onSecondaryContainer => buen contraste en ambos temas.
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12 * prefs.fontSizeMultiplier,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Barra del sistema (iconos y fondo) contrastando con tema oscuro:
        // fondo oscuro, iconos claros.
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12 * prefs.fontSizeMultiplier,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColeTotal',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: prefs.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      home: const MainScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        // '/login': (context) => const LoginScreen(),
      },
    );
  }
}
