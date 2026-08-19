import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'ColeTotal'**
  String get appName;

  /// No description provided for @navMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navMap;

  /// No description provided for @navRoutes.
  ///
  /// In es, this message translates to:
  /// **'Rutas'**
  String get navRoutes;

  /// No description provided for @navPreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get navPreferences;

  /// No description provided for @calculatingRoute.
  ///
  /// In es, this message translates to:
  /// **'Calculando ruta…'**
  String get calculatingRoute;

  /// No description provided for @hideStops.
  ///
  /// In es, this message translates to:
  /// **'Ocultar paraderos'**
  String get hideStops;

  /// No description provided for @showStops.
  ///
  /// In es, this message translates to:
  /// **'Mostrar paraderos'**
  String get showStops;

  /// No description provided for @searchingLocation.
  ///
  /// In es, this message translates to:
  /// **'Buscando ubicación…'**
  String get searchingLocation;

  /// No description provided for @closeRoute.
  ///
  /// In es, this message translates to:
  /// **'Cerrar ruta'**
  String get closeRoute;

  /// No description provided for @tapToGoStop.
  ///
  /// In es, this message translates to:
  /// **'Tocar para ir al paradero'**
  String get tapToGoStop;

  /// No description provided for @viaProvider.
  ///
  /// In es, this message translates to:
  /// **'vía {provider}'**
  String viaProvider(String provider);

  /// No description provided for @coordsLabel.
  ///
  /// In es, this message translates to:
  /// **'Lat: {lat}, Lng: {lng}'**
  String coordsLabel(String lat, String lng);

  /// No description provided for @routeErrorDefault.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la ruta. Inténtalo de nuevo.'**
  String get routeErrorDefault;

  /// No description provided for @calculateRouteTitle.
  ///
  /// In es, this message translates to:
  /// **'Calcular Ruta'**
  String get calculateRouteTitle;

  /// No description provided for @originLabel.
  ///
  /// In es, this message translates to:
  /// **'Origen (Mi ubicación actual)'**
  String get originLabel;

  /// No description provided for @searchStopHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar paradero por nombre o dirección…'**
  String get searchStopHint;

  /// No description provided for @whereToGo.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde quieres ir?'**
  String get whereToGo;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para \"{query}\"'**
  String noResults(String query);

  /// No description provided for @goToNearestStop.
  ///
  /// In es, this message translates to:
  /// **'Ir al paradero más cercano'**
  String get goToNearestStop;

  /// No description provided for @locationUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Tu ubicación aún no está disponible. Activá el GPS o esperá unos segundos.'**
  String get locationUnavailable;

  /// No description provided for @routeCalcErrorDefault.
  ///
  /// In es, this message translates to:
  /// **'No se pudo calcular la ruta. Inténtalo de nuevo.'**
  String get routeCalcErrorDefault;

  /// No description provided for @veryClose.
  ///
  /// In es, this message translates to:
  /// **'Muy cerca'**
  String get veryClose;

  /// No description provided for @closeDistance.
  ///
  /// In es, this message translates to:
  /// **'Cerca'**
  String get closeDistance;

  /// No description provided for @mediumDistance.
  ///
  /// In es, this message translates to:
  /// **'A media distancia'**
  String get mediumDistance;

  /// No description provided for @far.
  ///
  /// In es, this message translates to:
  /// **'Lejos'**
  String get far;

  /// No description provided for @preferencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get preferencesTitle;

  /// No description provided for @sectionMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get sectionMap;

  /// No description provided for @mapNormal.
  ///
  /// In es, this message translates to:
  /// **'Mapa normal'**
  String get mapNormal;

  /// No description provided for @satellite.
  ///
  /// In es, this message translates to:
  /// **'Satélite'**
  String get satellite;

  /// No description provided for @sectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get sectionAppearance;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Tema claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Tema oscuro'**
  String get themeDark;

  /// No description provided for @fontSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de fuente'**
  String get fontSize;

  /// No description provided for @compactMode.
  ///
  /// In es, this message translates to:
  /// **'Modo compacto'**
  String get compactMode;

  /// No description provided for @animations.
  ///
  /// In es, this message translates to:
  /// **'Animaciones'**
  String get animations;

  /// No description provided for @sectionNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get sectionNotifications;

  /// No description provided for @enableNotifications.
  ///
  /// In es, this message translates to:
  /// **'Habilitar notificaciones'**
  String get enableNotifications;

  /// No description provided for @sectionPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get sectionPrivacy;

  /// No description provided for @locationTracking.
  ///
  /// In es, this message translates to:
  /// **'Rastreo de ubicación'**
  String get locationTracking;

  /// No description provided for @disableTrackingTitle.
  ///
  /// In es, this message translates to:
  /// **'Deshabilitar rastreo'**
  String get disableTrackingTitle;

  /// No description provided for @disableTrackingMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro? El mapa necesita tu ubicación para funcionar correctamente.'**
  String get disableTrackingMessage;

  /// No description provided for @saveHistory.
  ///
  /// In es, this message translates to:
  /// **'Guardar historial'**
  String get saveHistory;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @sectionLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get sectionLanguage;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @infoTitle.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get infoTitle;

  /// No description provided for @infoBody.
  ///
  /// In es, this message translates to:
  /// **'Tus preferencias se guardan automáticamente. Todos los cambios se aplican inmediatamente.'**
  String get infoBody;

  /// No description provided for @errInvalidCoords.
  ///
  /// In es, this message translates to:
  /// **'Origen o destino inválido (coordenadas fuera de rango).'**
  String get errInvalidCoords;

  /// No description provided for @errNoRoute.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la ruta. Verifica tu conexión.'**
  String get errNoRoute;

  /// No description provided for @errProvider.
  ///
  /// In es, this message translates to:
  /// **'El servicio de rutas no respondió correctamente.'**
  String get errProvider;

  /// No description provided for @errGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error al calcular la ruta.'**
  String get errGeneric;

  /// No description provided for @distanceKm.
  ///
  /// In es, this message translates to:
  /// **'{value} km'**
  String distanceKm(String value);

  /// No description provided for @distanceM.
  ///
  /// In es, this message translates to:
  /// **'{value} m'**
  String distanceM(String value);

  /// No description provided for @durationMin.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String durationMin(String minutes);

  /// No description provided for @durationHour.
  ///
  /// In es, this message translates to:
  /// **'{h} h'**
  String durationHour(String h);

  /// No description provided for @durationHourMin.
  ///
  /// In es, this message translates to:
  /// **'{h} h {m} min'**
  String durationHourMin(String h, String m);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
