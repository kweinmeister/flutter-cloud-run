import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tool/exec.dart "<command>" [--exclude=pkg1,pkg2]');
    exit(1);
  }

  String? command;
  final excluded = <String>{};

  for (final arg in args) {
    if (arg.startsWith('--exclude=')) {
      final parts = arg.substring('--exclude='.length).split(',');
      excluded.addAll(parts.map((e) => e.trim()));
    } else {
      command = arg;
    }
  }

  if (command == null) {
    print('Error: No command specified.');
    exit(1);
  }

  // Naive splitting, likely sufficient for "dart analyze ." etc.
  // For complex args, user might need to be careful with quoting.
  final parts = command.split(' ');
  final executable = parts.first;
  final arguments = parts.sublist(1);

  // Parse root pubspec to find workspace members
  final rootPubspec = File('pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    print('Error: pubspec.yaml not found in current directory.');
    exit(1);
  }

  final lines = await rootPubspec.readAsLines();
  final workspaceMembers = <String>[];
  bool inWorkspaceSection = false;

  for (final line in lines) {
    if (line.trim().startsWith('workspace:')) {
      inWorkspaceSection = true;
      continue;
    }
    if (inWorkspaceSection) {
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
      // If indent is gone or a new top-level key starts, we are done
      if (!line.startsWith('  ') && !line.startsWith('-')) {
        inWorkspaceSection = false;
        continue;
      }

      var member = line.trim();
      if (member.startsWith('-')) {
        member = member.substring(1).trim();
      }
      workspaceMembers.add(member);
    }
  }

  if (workspaceMembers.isEmpty) {
    print('No workspace members found in pubspec.yaml');
    exit(1);
  }

  final targetMembers = workspaceMembers
      .where((m) => !excluded.contains(m))
      .toList();

  if (targetMembers.isEmpty) {
    print('No packages selected to run command.');
    exit(0);
  }

  print('Executing "$command" in ${targetMembers.length} packages...');

  bool failed = false;

  for (final member in targetMembers) {
    final dir = Directory(member);
    if (!dir.existsSync()) {
      print(
        'Warning: Workspace member directory "$member" does not exist. Skipping.',
      );
      continue;
    }

    print('\n[$member] $command');
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: dir.path,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('[$member] FAILED (Exit Code: $exitCode)');
      failed = true;
    } else {
      print('[$member] SUCCESS');
    }
  }

  if (failed) {
    print('\nCommand failed in one or more packages.');
    exit(1);
  } else {
    print('\nSuccess!');
  }
}
