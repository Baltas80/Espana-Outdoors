import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Central Sentry bootstrap. The DSN is injected at build/run time and is
/// intentionally absent from source control.
final class SentryObservability {
  const SentryObservability._();

  static const dsn = String.fromEnvironment('SENTRY_DSN');
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static Future<void> run(Future<void> Function() appRunner) async {
    if (dsn.isEmpty) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = environment;
        options.sendDefaultPii = false;
        options.tracesSampleRate = kDebugMode ? 0.0 : 0.1;
        options.enableLogs = false;
        // Do not propagate tracing headers to third-party data providers by
        // default. Enable only for explicitly controlled first-party domains.
        options.tracePropagationTargets.clear();
      },
      appRunner: appRunner,
    );
  }
}
