// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'ColeTotal';

  @override
  String get navMap => 'Mapa';

  @override
  String get navRoutes => 'Rutas';

  @override
  String get navPreferences => 'Preferencias';

  @override
  String get calculatingRoute => 'Calculando ruta…';

  @override
  String get hideStops => 'Ocultar paraderos';

  @override
  String get showStops => 'Mostrar paraderos';

  @override
  String get searchingLocation => 'Buscando ubicación…';

  @override
  String get closeRoute => 'Cerrar ruta';

  @override
  String get tapToGoStop => 'Tocar para ir al paradero';

  @override
  String viaProvider(String provider) {
    return 'vía $provider';
  }

  @override
  String coordsLabel(String lat, String lng) {
    return 'Lat: $lat, Lng: $lng';
  }

  @override
  String get routeErrorDefault =>
      'No se pudo obtener la ruta. Inténtalo de nuevo.';

  @override
  String get calculateRouteTitle => 'Calcular Ruta';

  @override
  String get originLabel => 'Origen (Mi ubicación actual)';

  @override
  String get searchStopHint => 'Buscar paradero por nombre o dirección…';

  @override
  String get whereToGo => '¿A dónde quieres ir?';

  @override
  String noResults(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get goToNearestStop => 'Ir al paradero más cercano';

  @override
  String get locationUnavailable =>
      'Tu ubicación aún no está disponible. Activá el GPS o esperá unos segundos.';

  @override
  String get routeCalcErrorDefault =>
      'No se pudo calcular la ruta. Inténtalo de nuevo.';

  @override
  String get veryClose => 'Muy cerca';

  @override
  String get closeDistance => 'Cerca';

  @override
  String get mediumDistance => 'A media distancia';

  @override
  String get far => 'Lejos';

  @override
  String get preferencesTitle => 'Preferencias';

  @override
  String get sectionMap => 'Mapa';

  @override
  String get mapNormal => 'Mapa normal';

  @override
  String get satellite => 'Satélite';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get themeLight => 'Tema claro';

  @override
  String get themeDark => 'Tema oscuro';

  @override
  String get fontSize => 'Tamaño de fuente';

  @override
  String get compactMode => 'Modo compacto';

  @override
  String get animations => 'Animaciones';

  @override
  String get sectionNotifications => 'Notificaciones';

  @override
  String get enableNotifications => 'Habilitar notificaciones';

  @override
  String get sectionPrivacy => 'Privacidad';

  @override
  String get locationTracking => 'Rastreo de ubicación';

  @override
  String get disableTrackingTitle => 'Deshabilitar rastreo';

  @override
  String get disableTrackingMessage =>
      '¿Estás seguro? El mapa necesita tu ubicación para funcionar correctamente.';

  @override
  String get saveHistory => 'Guardar historial';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get infoTitle => 'Información';

  @override
  String get infoBody =>
      'Tus preferencias se guardan automáticamente. Todos los cambios se aplican inmediatamente.';

  @override
  String get errInvalidCoords =>
      'Origen o destino inválido (coordenadas fuera de rango).';

  @override
  String get errNoRoute => 'No se pudo obtener la ruta. Verifica tu conexión.';

  @override
  String get errProvider => 'El servicio de rutas no respondió correctamente.';

  @override
  String get errGeneric => 'Ocurrió un error al calcular la ruta.';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String durationMin(String minutes) {
    return '$minutes min';
  }

  @override
  String durationHour(String h) {
    return '$h h';
  }

  @override
  String durationHourMin(String h, String m) {
    return '$h h $m min';
  }
}
