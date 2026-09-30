import 'shell.dart';

/// Starts Traverce at logon with administrator rights through Task Scheduler,
/// so there is no UAC prompt on every boot.
///
/// Versions 0.1–0.2 used the legacy task name "Prosvet". The migration keeps
/// detecting and removing it so an upgrade cannot leave two startup entries.
class Autostart {
  const Autostart(this._shell, this._exe);

  final Shell _shell;
  final String _exe;

  static const taskName = 'Traverce';
  static const legacyTaskName = 'Prosvet';

  Future<bool> _exists(String name) async =>
      (await _shell.run('schtasks.exe', ['/Query', '/TN', name])).ok;

  Future<bool> isEnabled() async =>
      await _exists(taskName) || await _exists(legacyTaskName);

  Future<void> _deleteIfPresent(String name, {bool bestEffort = false}) async {
    if (!await _exists(name)) return;
    final result = await _shell.run('schtasks.exe', [
      '/Delete',
      '/TN',
      name,
      '/F',
    ]);
    if (!result.ok && !bestEffort) {
      throw StateError(
        result.stderr.trim().isEmpty
            ? result.stdout.trim()
            : result.stderr.trim(),
      );
    }
  }

  Future<void> setEnabled(bool on) async {
    if (on) {
      final created = await _shell.run('schtasks.exe', [
        '/Create',
        '/TN',
        taskName,
        '/TR',
        '"$_exe" --background',
        '/SC',
        'ONLOGON',
        '/RL',
        'HIGHEST',
        '/F',
      ]);
      if (!created.ok) {
        throw StateError(
          created.stderr.trim().isEmpty
              ? created.stdout.trim()
              : created.stderr.trim(),
        );
      }

      await _deleteIfPresent(legacyTaskName, bestEffort: true);
      return;
    }

    await _deleteIfPresent(taskName);
    await _deleteIfPresent(legacyTaskName);
  }
}
