import 'dart:io';

import 'package:path/path.dart' as p;

const windowsRuntimeDllNames = [
  'msvcp140.dll',
  'vcruntime140.dll',
  'vcruntime140_1.dll',
];

Future<List<String>> copyWindowsDesktopRuntime(
  Directory outputDirectory, {
  Map<String, String>? environment,
}) async {
  final env = environment ?? Platform.environment;
  final sourceDirectory = _findRuntimeDirectory(env);
  if (sourceDirectory == null) {
    throw StateError(
      'Windows VC runtime DLLs not found. Install Microsoft VC++ redistributable '
      'or set FLCLASH_WINDOWS_VC_RUNTIME_DIR to the directory containing '
      '${windowsRuntimeDllNames.join(', ')}.',
    );
  }
  await outputDirectory.create(recursive: true);
  final copied = <String>[];
  for (final dllName in windowsRuntimeDllNames) {
    final source = File(p.join(sourceDirectory.path, dllName));
    if (!source.existsSync()) {
      throw StateError('Missing Windows runtime DLL: ${source.path}');
    }
    await source.copy(p.join(outputDirectory.path, dllName));
    copied.add(dllName);
  }
  return copied;
}

Directory? _findRuntimeDirectory(Map<String, String> environment) {
  final explicit = environment['FLCLASH_WINDOWS_VC_RUNTIME_DIR'];
  if (explicit != null && explicit.trim().isNotEmpty) {
    final directory = Directory(explicit);
    if (_hasRuntimeDlls(directory)) return directory;
  }
  for (final directory in _candidateRuntimeDirectories(environment)) {
    if (_hasRuntimeDlls(directory)) return directory;
  }
  return null;
}

List<Directory> _candidateRuntimeDirectories(Map<String, String> environment) {
  final candidates = <Directory>[];
  final systemRoot = environment['SystemRoot'] ?? environment['WINDIR'];
  if (systemRoot != null && systemRoot.isNotEmpty) {
    candidates.add(Directory(p.join(systemRoot, 'System32')));
  }
  final programFilesX86 = environment['ProgramFiles(x86)'];
  if (programFilesX86 != null && programFilesX86.isNotEmpty) {
    final visualStudioRoot = Directory(
      p.join(programFilesX86, 'Microsoft Visual Studio'),
    );
    candidates.addAll(_visualStudioRuntimeDirectories(visualStudioRoot));
  }
  return candidates;
}

List<Directory> _visualStudioRuntimeDirectories(Directory root) {
  if (!root.existsSync()) return const [];
  final directories = <Directory>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! Directory) continue;
    final normalized = entity.path.toLowerCase().replaceAll('\\', '/');
    if (normalized.endsWith('/x64/microsoft.vc143.crt') ||
        normalized.endsWith('/x64/microsoft.vc142.crt')) {
      directories.add(entity);
    }
  }
  directories.sort((a, b) => b.path.compareTo(a.path));
  return directories;
}

bool _hasRuntimeDlls(Directory directory) {
  return windowsRuntimeDllNames.every(
    (dllName) => File(p.join(directory.path, dllName)).existsSync(),
  );
}
