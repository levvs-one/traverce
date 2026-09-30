import 'package:flutter_test/flutter_test.dart';
import 'package:traverce/src/platform/autostart.dart';
import 'package:traverce/src/platform/shell.dart';

class _FakeShell implements Shell {
  final calls = <({String executable, List<String> args})>[];
  final Map<String, ShellResult> results = {};
  ShellResult? forcedResult;

  @override
  Future<ShellResult> run(String executable, List<String> args) async {
    calls.add((executable: executable, args: List.of(args)));

    final forced = forcedResult;
    if (forced != null) {
      forcedResult = null;
      return forced;
    }

    final key = '$executable ${args.join(' ')}';
    return results[key] ?? const ShellResult(0, '', '');
  }

  @override
  Future<ShellResult> powershell(String script) async {
    throw UnimplementedError();
  }
}

void main() {
  test('creates Traverce task and removes legacy task', () async {
    final shell = _FakeShell();
    const exe = r'C:\Program Files\Traverce\traverce.exe';
    final autostart = Autostart(shell, exe);

    await autostart.setEnabled(true);

    expect(shell.calls.first.args, [
      '/Create',
      '/TN',
      'Traverce',
      '/TR',
      '"$exe" --background',
      '/SC',
      'ONLOGON',
      '/RL',
      'HIGHEST',
      '/F',
    ]);

    final deletedLegacy = shell.calls.any(
      (call) => call.args.join(' ') == '/Delete /TN Prosvet /F',
    );
    expect(deletedLegacy, isTrue);
  });

  test('disable clears current and legacy tasks', () async {
    final shell = _FakeShell();
    final autostart = Autostart(shell, r'C:\Traverce\traverce.exe');

    await autostart.setEnabled(false);

    final deletes = shell.calls
        .where((call) => call.args.first == '/Delete')
        .map((call) => call.args)
        .toList();

    expect(
      deletes,
      containsAll([
        ['/Delete', '/TN', 'Traverce', '/F'],
        ['/Delete', '/TN', 'Prosvet', '/F'],
      ]),
    );
  });

  test('legacy task is recognized during upgrade', () async {
    final shell = _FakeShell();
    const currentQuery = 'schtasks.exe /Query /TN Traverce';
    shell.results[currentQuery] = const ShellResult(1, '', 'not found');
    final autostart = Autostart(shell, r'C:\Traverce\traverce.exe');

    expect(await autostart.isEnabled(), isTrue);
  });

  test('create errors are surfaced', () async {
    final shell = _FakeShell();
    shell.forcedResult = const ShellResult(1, '', 'access denied');
    final autostart = Autostart(shell, r'C:\Traverce\traverce.exe');

    expect(
      () => autostart.setEnabled(true),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'access denied'),
      ),
    );
  });
}
