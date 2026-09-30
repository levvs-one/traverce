import 'package:flutter_test/flutter_test.dart';
import 'package:traverce/src/platform/autostart.dart';
import 'package:traverce/src/platform/shell.dart';

class _FakeShell implements Shell {
  final calls = <({String executable, List<String> args})>[];
  final Map<String, ShellResult> results = {};

  @override
  Future<ShellResult> run(String executable, List<String> args) async {
    calls.add((executable: executable, args: List.of(args)));
    return results['$executable ${args.join(' ')}'] ??
        const ShellResult(0, '', '');
  }

  @override
  Future<ShellResult> powershell(String script) async {
    throw UnimplementedError();
  }
}

void main() {
  test('autostart creates Traverce task and removes legacy Prosvet task', () async {
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
    expect(
      shell.calls.any((c) => c.args.join(' ') == '/Delete /TN Prosvet /F'),
      isTrue,
    );
  });

  test('autostart disable clears current and legacy tasks', () async {
    final shell = _FakeShell();
    final autostart = Autostart(shell, r'C:\Traverce\traverce.exe');

    await autostart.setEnabled(false);

    expect(
      shell.calls.where((c) => c.args.first == '/Delete').map((c) => c.args),
      containsAll([
        ['/Delete', '/TN', 'Traverce', '/F'],
        ['/Delete', '/TN', 'Prosvet', '/F'],
      ]),
    );
  });

  test('isEnabled recognizes legacy task during upgrade', () async {
    final shell = _FakeShell();
    shell.results['schtasks.exe /Query /TN Traverce'] =
        const ShellResult(1, '', 'not found');
    final autostart = Autostart(shell, r'C:\Traverce\traverce.exe');

    expect(await autostart.isEnabled(), isTrue);
  });

  test('autostart surfaces Task Scheduler create errors', () async {
    final shell = _FakeShell();
    shell.results['schtasks.exe /Create /TN Traverce /TR "C:\\Traverce\\traverce.exe" --background /SC ONLOGON /RL HIGHEST /F'] =
        const ShellResult(1, '', 'access denied');
    final autostart = Autostart(shell, r'C:\Traverce\traverce.exe');

    expect(
      () => autostart.setEnabled(true),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'access denied'),
      ),
    );
  });
}
