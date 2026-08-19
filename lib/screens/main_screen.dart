import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxi1/screens/map_screen.dart';
import 'package:taxi1/screens/routes_screen.dart';
import 'package:taxi1/screens/preferences_screen.dart';

/// Controller ligero que permite cambiar de tab desde cualquier pantalla
/// (por ejemplo, desde [RoutesScreen] cuando se elige un paradero).
///
/// Se expone como singleton para no acoplar las pantallas con `BuildContext`
/// ni tener que pasar callbacks por todo el árbol de widgets.
class MainNavigationController extends ChangeNotifier {
  MainNavigationController._();
  static final MainNavigationController instance = MainNavigationController._();

  int _index = 0;
  int get index => _index;

  void setIndex(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  /// Atajo semántico: lleva al usuario a la pestaña del mapa.
  void showMap() => setIndex(0);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _nav = MainNavigationController.instance;

  late final List<Widget> _screens = const [
    MapScreen(),
    RoutesScreen(),
    PreferencesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _nav.addListener(_onNavChanged);
  }

  @override
  void dispose() {
    _nav.removeListener(_onNavChanged);
    super.dispose();
  }

  void _onNavChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Material 3 limpio: NO forzamos colores en los Icon. El NavigationBar
    // toma `indicatorColor`, `iconTheme` y `labelTextStyle` del theme y del
    // ColorScheme, por lo que el contraste se mantiene en claro y oscuro.
    //
    // El AnnotatedRegion asegura que la barra de navegación del sistema (la
    // del teléfono) use colores acordes al tema, incluso en pantallas sin
    // AppBar (como el mapa).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.surface,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarColor: Colors.transparent,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: IndexedStack(index: _nav.index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _nav.index,
          onDestinationSelected: _nav.setIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Rutas',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Preferencias',
            ),
          ],
        ),
      ),
    );
  }
}
