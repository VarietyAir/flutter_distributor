import 'dart:io';

import 'package:flutter_app_builder/src/builders/windows/windows_runtime_bundle.dart';
import 'package:test/test.dart';

void main() {
  test('copies Windows desktop runtime dlls into release output', () async {
    final temp = await Directory.systemTemp.createTemp('flclash-runtime-test-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final source = Directory('${temp.path}/runtime')..createSync();
    final output = Directory('${temp.path}/Release')..createSync();

    for (final dll in windowsRuntimeDllNames) {
      File('${source.path}/$dll').writeAsStringSync('runtime:$dll');
    }

    final copied = await copyWindowsDesktopRuntime(
      output,
      environment: {'FLCLASH_WINDOWS_VC_RUNTIME_DIR': source.path},
    );

    expect(copied, windowsRuntimeDllNames);
    for (final dll in windowsRuntimeDllNames) {
      expect(File('${output.path}/$dll').readAsStringSync(), 'runtime:$dll');
    }
  });
}
