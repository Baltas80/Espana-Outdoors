import 'package:flutter/foundation.dart';

/// Reference canvas used to remove layout interpretation from feature screens.
///
/// All positions are logical pixels at the canonical 390x844 portrait canvas.
/// Implementations may scale the canvas proportionally, but must preserve the
/// slot geometry and safe-area boundaries defined here.
abstract final class EOLayoutCanvas {
  static const width = 390.0;
  static const height = 844.0;
  static const safeTop = 24.0;
  static const safeBottom = 34.0;
  static const horizontal = 20.0;
  static const contentWidth = width - (horizontal * 2);
  static const appBarHeight = 64.0;
  static const bottomBarHeight = 76.0;
}

@immutable
class EOLayoutRect {
  const EOLayoutRect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
}

@immutable
class EOLayoutSlot {
  const EOLayoutSlot(this.name, this.rect, {this.anchor = 'top-left'});

  final String name;
  final EOLayoutRect rect;
  final String anchor;
}

@immutable
class EOScreenLayout {
  const EOScreenLayout({
    required this.id,
    required this.title,
    required this.slots,
    this.hasBottomNavigation = false,
  });

  final EOScreenId id;
  final String title;
  final List<EOLayoutSlot> slots;
  final bool hasBottomNavigation;

  EOLayoutSlot slot(String name) =>
      slots.firstWhere((candidate) => candidate.name == name);
}

enum EOScreenId {
  splash,
  map,
  menu,
  routeDetail,
  navigation,
  recording,
  myRoutes,
  offlineMaps,
  weather,
  instruments,
  naturePoi,
  settings,
}

abstract final class EOScreenLayouts {
  static const all = <EOScreenLayout>[
    splash,
    map,
    menu,
    routeDetail,
    navigation,
    recording,
    myRoutes,
    offlineMaps,
    weather,
    instruments,
    naturePoi,
    settings,
  ];

  static const splash = EOScreenLayout(
    id: EOScreenId.splash,
    title: 'Splash',
    slots: [
      EOLayoutSlot('hero', EOLayoutRect(0, 0, 390, 520)),
      EOLayoutSlot('logo', EOLayoutRect(95, 168, 200, 72)),
      EOLayoutSlot('tagline', EOLayoutRect(48, 270, 294, 48)),
      EOLayoutSlot('primaryAction', EOLayoutRect(20, 704, 350, 56)),
      EOLayoutSlot('legal', EOLayoutRect(40, 778, 310, 28)),
    ],
  );

  static const map = EOScreenLayout(
    id: EOScreenId.map,
    title: 'Mapa principal',
    hasBottomNavigation: true,
    slots: [
      EOLayoutSlot('map', EOLayoutRect(0, 0, 390, 844)),
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('search', EOLayoutRect(20, 88, 350, 52)),
      EOLayoutSlot('mapControls', EOLayoutRect(314, 604, 56, 128)),
      EOLayoutSlot('gps', EOLayoutRect(314, 548, 56, 56)),
      EOLayoutSlot('bottomSheet', EOLayoutRect(0, 644, 390, 124)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
  );

  static const menu = EOScreenLayout(
    id: EOScreenId.menu,
    title: 'Menú',
    slots: [
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 64)),
      EOLayoutSlot('profile', EOLayoutRect(20, 104, 350, 80)),
      EOLayoutSlot('primaryMenu', EOLayoutRect(20, 200, 350, 376)),
      EOLayoutSlot('secondaryMenu', EOLayoutRect(20, 592, 350, 116)),
      EOLayoutSlot('footer', EOLayoutRect(20, 744, 350, 54)),
    ],
  );

  static const routeDetail = EOScreenLayout(
    id: EOScreenId.routeDetail,
    title: 'Detalle de ruta',
    slots: [
      EOLayoutSlot('heroPhoto', EOLayoutRect(0, 0, 390, 300)),
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('title', EOLayoutRect(20, 246, 350, 54)),
      EOLayoutSlot('summary', EOLayoutRect(20, 324, 350, 92)),
      EOLayoutSlot('description', EOLayoutRect(20, 436, 350, 128)),
      EOLayoutSlot('primaryAction', EOLayoutRect(20, 696, 350, 56)),
      EOLayoutSlot('secondaryActions', EOLayoutRect(20, 768, 350, 56)),
    ],
  );

  static const navigation = EOScreenLayout(
    id: EOScreenId.navigation,
    title: 'Navegación',
    slots: [
      EOLayoutSlot('map', EOLayoutRect(0, 0, 390, 844)),
      EOLayoutSlot('instruction', EOLayoutRect(20, 24, 350, 88)),
      EOLayoutSlot('routeStats', EOLayoutRect(20, 124, 350, 64)),
      EOLayoutSlot('recenter', EOLayoutRect(314, 552, 56, 56)),
      EOLayoutSlot('navigationControls', EOLayoutRect(314, 616, 56, 112)),
      EOLayoutSlot('bottomPanel', EOLayoutRect(0, 652, 390, 192)),
    ],
  );

  static const recording = EOScreenLayout(
    id: EOScreenId.recording,
    title: 'Grabación',
    slots: [
      EOLayoutSlot('map', EOLayoutRect(0, 0, 390, 844)),
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('recordingStatus', EOLayoutRect(20, 96, 350, 72)),
      EOLayoutSlot('liveStats', EOLayoutRect(20, 184, 350, 96)),
      EOLayoutSlot('gps', EOLayoutRect(314, 560, 56, 56)),
      EOLayoutSlot('stopAction', EOLayoutRect(20, 696, 350, 64)),
      EOLayoutSlot('secondaryActions', EOLayoutRect(20, 776, 350, 48)),
    ],
  );

  static const myRoutes = EOScreenLayout(
    id: EOScreenId.myRoutes,
    title: 'Mis rutas',
    slots: [
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('filters', EOLayoutRect(20, 92, 350, 44)),
      EOLayoutSlot('routeList', EOLayoutRect(20, 152, 350, 548)),
      EOLayoutSlot('importAction', EOLayoutRect(20, 720, 168, 52)),
      EOLayoutSlot('createAction', EOLayoutRect(202, 720, 168, 52)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
    hasBottomNavigation: true,
  );

  static const offlineMaps = EOScreenLayout(
    id: EOScreenId.offlineMaps,
    title: 'Mapas offline',
    slots: [
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('storageSummary', EOLayoutRect(20, 96, 350, 88)),
      EOLayoutSlot('regionSelector', EOLayoutRect(20, 200, 350, 56)),
      EOLayoutSlot('downloadList', EOLayoutRect(20, 272, 350, 388)),
      EOLayoutSlot('downloadAction', EOLayoutRect(20, 680, 350, 56)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
    hasBottomNavigation: true,
  );

  static const weather = EOScreenLayout(
    id: EOScreenId.weather,
    title: 'Meteorología',
    slots: [
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('location', EOLayoutRect(20, 96, 350, 48)),
      EOLayoutSlot('currentWeather', EOLayoutRect(20, 160, 350, 176)),
      EOLayoutSlot('forecast', EOLayoutRect(20, 352, 350, 160)),
      EOLayoutSlot('alerts', EOLayoutRect(20, 528, 350, 124)),
      EOLayoutSlot('radar', EOLayoutRect(20, 668, 350, 84)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
    hasBottomNavigation: true,
  );

  static const instruments = EOScreenLayout(
    id: EOScreenId.instruments,
    title: 'Instrumentos',
    slots: [
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('primaryInstrument', EOLayoutRect(20, 96, 350, 260)),
      EOLayoutSlot('instrumentGrid', EOLayoutRect(20, 376, 350, 276)),
      EOLayoutSlot('quickTools', EOLayoutRect(20, 672, 350, 80)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
    hasBottomNavigation: true,
  );

  static const naturePoi = EOScreenLayout(
    id: EOScreenId.naturePoi,
    title: 'Naturaleza / POI',
    slots: [
      EOLayoutSlot('map', EOLayoutRect(0, 0, 390, 844)),
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('filters', EOLayoutRect(20, 92, 350, 48)),
      EOLayoutSlot('poiPanel', EOLayoutRect(0, 560, 390, 208)),
      EOLayoutSlot('mapControls', EOLayoutRect(314, 432, 56, 112)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
    hasBottomNavigation: true,
  );

  static const settings = EOScreenLayout(
    id: EOScreenId.settings,
    title: 'Ajustes',
    slots: [
      EOLayoutSlot('topBar', EOLayoutRect(20, 24, 350, 56)),
      EOLayoutSlot('account', EOLayoutRect(20, 96, 350, 88)),
      EOLayoutSlot('settingsList', EOLayoutRect(20, 200, 350, 500)),
      EOLayoutSlot('dangerZone', EOLayoutRect(20, 716, 350, 48)),
      EOLayoutSlot('bottomNavigation', EOLayoutRect(0, 768, 390, 76)),
    ],
    hasBottomNavigation: true,
  );
}
