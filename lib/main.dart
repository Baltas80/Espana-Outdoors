import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:background_downloader/background_downloader.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<Map<dynamic, dynamic>>('route_records');
  await Hive.openBox<Map<dynamic, dynamic>>('offline_regions');
  await Hive.openBox<String>('weather_cache');

  // background_downloader is the mature native transfer layer for Android,
  // iOS, Windows, macOS and Linux. Web keeps its own browser download path.
  if (!kIsWeb) {
    await FileDownloader().start(autoCleanDatabase: true);
  }

  runApp(const ProviderScope(child: EspanaOutdoorApp()));
}
