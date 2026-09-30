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

      // Best-effort migration from the pre-0.3 task name.
      await _shell.run('schtasks.exe', ['/Delete', '/TN', legacyTaskName, '/F']);
      return;
    }

    // Disabling autostart is intentionally idempotent and clears both names.
    await _shell.run('schtasks.exe', ['/Delete', '/TN', taskName, '/F']);
    await _shell.run('schtasks.exe', ['/Delete', '/TN', legacyTaskName, '/F']);
  }
}
