import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  stdout.writeln('====================================================');
  stdout.writeln(' Starting Flutter App with Auto-Reload Watcher...  ');
  stdout.writeln('====================================================');

  final deviceId =
      _deviceIdFrom(args) ?? Platform.environment['FLUTTER_DEVICE_ID'];
  final flutterArgs = [
    'run',
    if (deviceId != null && deviceId.trim().isNotEmpty) ...[
      '-d',
      deviceId.trim(),
    ],
  ];
  final flutterExecutable =
      Platform.environment['FLUTTER_BIN']?.trim().isNotEmpty == true
          ? Platform.environment['FLUTTER_BIN']!.trim()
          : 'flutter';

  if (deviceId != null && deviceId.trim().isNotEmpty) {
    stdout.writeln(' Target device: ${deviceId.trim()}');
  }
  stdout.writeln(' Flutter executable: $flutterExecutable');

  // Start the flutter run process
  final process = await Process.start(
    flutterExecutable,
    flutterArgs,
    runInShell: true,
  );

  // Pipe stdout and stderr
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  // Forward stdin to the process so user can still type 'r', 'R', 'q', etc.
  try {
    stdin.lineMode = false;
    stdin.echoMode = false;
  } catch (_) {
    // Ignore terminal errors if running in non-interactive environment
  }

  stdin.listen((data) {
    process.stdin.add(data);
  });

  // Watch the lib directory
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    stderr.writeln('Error: lib/ directory not found!');
    exit(1);
  }

  Timer? debounceTimer;
  DateTime lastReload = DateTime.now();

  libDir.watch(recursive: true).listen((event) {
    // Only reload for .dart file changes
    if (!event.path.endsWith('.dart')) return;

    // Ignore modifications very close to each other
    if (debounceTimer?.isActive ?? false) {
      debounceTimer!.cancel();
    }

    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Don't reload too frequently (e.g. within 1.5 seconds of the last reload)
      if (DateTime.now().difference(lastReload) <
          const Duration(milliseconds: 1500)) {
        return;
      }

      stdout.writeln('\n[Watcher] Change detected: ${event.path}');
      stdout.writeln('[Watcher] Triggering Hot Restart...');
      process.stdin.write('R');
      lastReload = DateTime.now();
    });
  });

  // Handle process exit
  final exitCode = await process.exitCode;
  stdout.writeln('\nFlutter process exited with code $exitCode');
  exit(exitCode);
}

String? _deviceIdFrom(List<String> args) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if ((arg == '-d' || arg == '--device-id') && index + 1 < args.length) {
      return args[index + 1];
    }
    if (arg.startsWith('--device-id=')) {
      return arg.substring('--device-id='.length);
    }
  }

  return null;
}
