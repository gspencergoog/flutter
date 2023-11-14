// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'flutter_information.dart';

const FileSystem filesystem = LocalFileSystem();
const Platform platform = LocalPlatform();
const ProcessManager processManager = LocalProcessManager();

FutureOr<int> main(List<String> arguments) async {
  final ArgResults args = parseArguments(arguments);
  checkKeygenFiles(filesystem.directory(args['engine-root']! as String));
  return 0;
}

Future<bool> checkKeygenFiles(Directory engineSource) async {
  final List<String> modified = await parseGitStatusPorcelain(engineSource);
  if (modified.isNotEmpty) {
    stderr.writeln('There are modified files in the repo at ${engineSource.path}');
    return false;
  }
  return true;
}

Future<List<String>> parseGitStatusPorcelain(Directory workingDirectory) async {
  final RegExp modifiedFilePattern = RegExp(r'^\s*(?<flag>[MADRT]+) (?<file>.*)$');
  final ProcessResult process = await Process.run(
    'git',
    <String>['status', '--porcelain'],
    workingDirectory: workingDirectory.absolute.path,
  );
  final List<String> lines = (process.stdout as String).split('\n');
  final List<String> modifiedFiles = <String>[];
  for (final String line in lines) {
    final RegExpMatch? match = modifiedFilePattern.matchAsPrefix(line) as RegExpMatch?;
    if (match != null && match.namedGroup('flag')!.contains('M')) {
      modifiedFiles.add(match.namedGroup('file')!);
    }
  }
  return modifiedFiles;
}

ArgResults parseArguments(List<String> args) {
  final Directory flutterRoot = FlutterInformation.instance.getFlutterRoot();
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    'engine-root',
    defaultsTo: flutterRoot.parent.childDirectory('engine').childDirectory('src').childDirectory('flutter').path,
    help: 'The path to the root of the flutter/engine repository. This is used '
        'to find the generated engine mapping files. If --engine-root is not '
        r'specified, it will assume the engine .gclient folder is placed in the '
        'same folder as the flutter/flutter repository.',
  );
  return argParser.parse(args);
}
