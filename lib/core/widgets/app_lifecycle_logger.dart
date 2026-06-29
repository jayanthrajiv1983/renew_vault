import 'package:flutter/widgets.dart';

import '../services/logging_service.dart';

/// Observes [AppLifecycleState] and logs lifecycle transitions via [LoggingService].
///
/// **App closed:** Flutter on mobile does not expose a reliable process-exit
/// callback. [AppLifecycleState.detached] and [dispose] are the closest proxies;
/// `Application closed` is logged when this observer is disposed.
class AppLifecycleLogger extends StatefulWidget {
  const AppLifecycleLogger({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleLogger> createState() => _AppLifecycleLoggerState();
}

class _AppLifecycleLoggerState extends State<AppLifecycleLogger>
    with WidgetsBindingObserver {
  static const _category = 'APP';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LoggingService.instance.logInfo(_category, 'Application closed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        LoggingService.instance.logInfo(_category, 'Application resumed');
      case AppLifecycleState.paused:
        LoggingService.instance.logInfo(_category, 'Application paused');
      case AppLifecycleState.detached:
        LoggingService.instance.logInfo(_category, 'Application detached');
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
