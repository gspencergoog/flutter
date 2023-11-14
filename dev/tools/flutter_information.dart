// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:pub_semver/pub_semver.dart';

/// An exception class used to indicate problems when collecting information.
class FlutterInformationException implements Exception {
  FlutterInformationException(this.message);
  final String message;

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}

/// A singleton used to consolidate the way in which information about the
/// Flutter repo and environment is collected.
///
/// Collects the information once, and caches it for any later access.
///
/// The singleton instance can be overridden by tests by setting [instance].
class FlutterInformation {
  FlutterInformation({
    this.platform = const LocalPlatform(),
    this.processManager = const LocalProcessManager(),
    this.filesystem = const LocalFileSystem(),
  });

  final Platform platform;
  final ProcessManager processManager;
  final FileSystem filesystem;

  static FlutterInformation? _instance;

  static FlutterInformation get instance => _instance ??= FlutterInformation();

  @visibleForTesting
  static set instance(FlutterInformation? value) => _instance = value;

  /// The path to the Dart binary in the Flutter repo.
  ///
  /// This is probably a shell script.
  File getDartBinaryPath() {
    return getFlutterRoot().childDirectory('bin').childFile('dart');
  }

  /// The path to the Dart binary in the Flutter repo.
  ///
  /// This is probably a shell script.
  File getFlutterBinaryPath() {
    return getFlutterRoot().childDirectory('bin').childFile('flutter');
  }

  /// The path to the Flutter repo root directory.
  ///
  /// If the environment variable `FLUTTER_ROOT` is set, will use that instead
  /// of looking for it.
  ///
  /// Otherwise, uses the output of `flutter --version --machine` to find the
  /// Flutter root.
  Directory getFlutterRoot() {
    if (platform.environment['FLUTTER_ROOT'] != null) {
      return filesystem.directory(platform.environment['FLUTTER_ROOT']);
    }
    return getFlutterInformation()['flutterRoot']! as Directory;
  }

  /// Gets the semver version of the Flutter framework in the repo.
  Version getFlutterVersion() => getFlutterInformation()['frameworkVersion']! as Version;

  /// Gets the git hash of the engine used by the Flutter framework in the repo.
  String getEngineRevision() => getFlutterInformation()['engineRevision']! as String;

  /// Gets the value stored in bin/internal/engine.realm used by the Flutter
  /// framework repo.
  String getEngineRealm() => getFlutterInformation()['engineRealm']! as String;

  /// Gets the git hash of the Flutter framework in the repo.
  String getFlutterRevision() => getFlutterInformation()['flutterGitRevision']! as String;

  /// Gets the name of the current branch in the Flutter framework in the repo.
  String getBranchName() => getFlutterInformation()['branchName']! as String;

  Map<String, Object>? _cachedFlutterInformation;

  /// Gets a Map of various kinds of information about the Flutter repo.
  Map<String, Object> getFlutterInformation() {
    if (_cachedFlutterInformation != null) {
      return _cachedFlutterInformation!;
    }

    String flutterVersionJson;
    if (platform.environment['FLUTTER_VERSION'] != null) {
      flutterVersionJson = platform.environment['FLUTTER_VERSION']!;
    } else {
      // Determine which flutter command to run, which will determine which
      // flutter root is eventually used. If the FLUTTER_ROOT is set, then use
      // that flutter command, otherwise use the first one in the PATH.
      String flutterCommand;
      if (platform.environment['FLUTTER_ROOT'] != null) {
        flutterCommand = filesystem
            .directory(platform.environment['FLUTTER_ROOT'])
            .childDirectory('bin')
            .childFile('flutter')
            .absolute
            .path;
      } else {
        flutterCommand = 'flutter';
      }
      ProcessResult result;
      try {
        result = processManager.runSync(
          <String>[flutterCommand, '--version', '--machine'],
          stdoutEncoding: utf8,
        );
      } on ProcessException catch (e) {
        throw FlutterInformationException(
            'Unable to determine Flutter information. Either set FLUTTER_ROOT, or place the '
            'flutter command in your PATH.\n$e');
      }
      if (result.exitCode != 0) {
        throw FlutterInformationException(
            'Unable to determine Flutter information, because of abnormal exit of flutter command.');
      }
      // Strip out any non-JSON that might be printed along with the command
      // output.
      flutterVersionJson = (result.stdout as String)
          .replaceAll('Waiting for another flutter command to release the startup lock...', '');
    }

    final Map<String, dynamic> flutterVersion = json.decode(flutterVersionJson) as Map<String, dynamic>;
    if (flutterVersion['flutterRoot'] == null ||
        flutterVersion['frameworkVersion'] == null ||
        flutterVersion['dartSdkVersion'] == null) {
      throw FlutterInformationException(
          'Flutter command output has unexpected format, unable to determine flutter root location.');
    }

    final Map<String, Object> info = <String, Object>{};
    final Directory flutterRoot = filesystem.directory(flutterVersion['flutterRoot']! as String);
    info['flutterRoot'] = flutterRoot;
    info['frameworkVersion'] = Version.parse(flutterVersion['frameworkVersion'] as String);
    info['engineRevision'] = flutterVersion['engineRevision'] as String;
    final File engineRealm = flutterRoot.childDirectory('bin').childDirectory('internal').childFile('engine.realm');
    info['engineRealm'] = engineRealm.existsSync() ? engineRealm.readAsStringSync().trim() : '';

    final RegExpMatch? dartVersionRegex = RegExp(r'(?<base>[\d.]+)(?:\s+\(build (?<detail>[-.\w]+)\))?')
        .firstMatch(flutterVersion['dartSdkVersion'] as String);
    if (dartVersionRegex == null) {
      throw FlutterInformationException(
          'Flutter command output has unexpected format, unable to parse dart SDK version ${flutterVersion['dartSdkVersion']}.');
    }
    info['dartSdkVersion'] =
        Version.parse(dartVersionRegex.namedGroup('detail') ?? dartVersionRegex.namedGroup('base')!);

    info['branchName'] = _getBranchName();
    info['flutterGitRevision'] = _getFlutterGitRevision();
    _cachedFlutterInformation = info;

    return info;
  }

  // Get the name of the release branch.
  //
  // On LUCI builds, the git HEAD is detached, so first check for the env
  // variable "LUCI_BRANCH"; if it is not set, fall back to calling git.
  String _getBranchName() {
    final String? luciBranch = platform.environment['LUCI_BRANCH'];
    if (luciBranch != null && luciBranch.trim().isNotEmpty) {
      return luciBranch.trim();
    }
    final ProcessResult gitResult = processManager.runSync(<String>['git', 'status', '-b', '--porcelain']);
    if (gitResult.exitCode != 0) {
      throw 'git status exit with non-zero exit code: ${gitResult.exitCode}';
    }
    final RegExp gitBranchRegexp = RegExp(r'^## (.*)');
    final RegExpMatch? gitBranchMatch =
        gitBranchRegexp.firstMatch((gitResult.stdout as String).trim().split('\n').first);
    return gitBranchMatch == null ? '' : gitBranchMatch.group(1)!.split('...').first;
  }

  // Get the git revision for the repo.
  String _getFlutterGitRevision() {
    const int kGitRevisionLength = 10;

    final ProcessResult gitResult = processManager.runSync(<String>['git', 'rev-parse', 'HEAD']);
    if (gitResult.exitCode != 0) {
      throw 'git rev-parse exit with non-zero exit code: ${gitResult.exitCode}';
    }
    final String gitRevision = (gitResult.stdout as String).trim();

    return gitRevision.length > kGitRevisionLength ? gitRevision.substring(0, kGitRevisionLength) : gitRevision;
  }
}
