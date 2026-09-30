import 'dart:io';

import 'package:path/path.dart' as p;

class AppPaths {
  const AppPaths({required this.engineDir, required this.stateDir});

  /// Bundled next to the executable by the installer or CI.
  final String engineDir;

  /// Local application state: settings, strategy memory and logs.
  final String stateDir;

  String get settingsFile => p.join(stateDir, 'settings.json');
  String get logFile => p.join(stateDir, 'traverce.log');
  String get winws => p.join(engineDir, 'winws2.exe');

  static AppPaths resolve() {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final base =
        Platform.environment['LOCALAPPDATA'] ??
        p.join(Platform.environment['HOME'] ?? exeDir, '.local', 'share');

    final preferred = p.join(base, 'Traverce');
    final legacy = p.join(base, 'Prosvet');
    var state = preferred;

    final preferredDir = Directory(preferred);
    final legacyDir = Directory(legacy);

    if (!preferredDir.existsSync() && legacyDir.existsSync()) {
      try {
        legacyDir.renameSync(preferred);
      } on FileSystemException {
        // Upgrade must never lose access to 0.1/0.2 settings merely because
        // another process or security product temporarily blocks the rename.
        state = legacy;
      }
    }

    Directory(state).createSync(recursive: true);
    return AppPaths(engineDir: p.join(exeDir, 'engine'), stateDir: state);
  }
}
