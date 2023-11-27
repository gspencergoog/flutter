// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=20210721"
@Tags(<String>['no-shuffle'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AutomatedTestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();

  group(TestViewConfiguration, () {
    test('is initialized with top-level window if one is not provided', () {
      // The code below will throw without the default.
      TestViewConfiguration(size: const Size(1280.0, 800.0));
    });
  });

  group(AutomatedTestWidgetsFlutterBinding, () {
    test('allows setting defaultTestTimeout to 5 minutes', () {
      binding.defaultTestTimeout = const Timeout(Duration(minutes: 5));
      expect(binding.defaultTestTimeout.duration, const Duration(minutes: 5));
    });
  });

  // The next three tests must run in order -- first using `test`, then `testWidgets`, then `test` again.

  int order = 0;

  test('Initializes httpOverrides and testTextInput', () async {
    assert(order == 0);
    expect(binding.testTextInput, isNotNull);
    expect(binding.testTextInput.isRegistered, isFalse);
    expect(HttpOverrides.current, isNotNull);
    order += 1;
  });

  testWidgets('Registers testTextInput', (WidgetTester tester) async {
    assert(order == 1);
    expect(tester.testTextInput.isRegistered, isTrue);
    order += 1;
  });

  test('Unregisters testTextInput', () async {
    assert(order == 2);
    expect(binding.testTextInput.isRegistered, isFalse);
    order += 1;
  });

  testWidgets('HardwareKeyboard gets reset after each widget test (setup)', (WidgetTester tester) async {
    assert(order == 3);
    binding.debugSetTestKeyboard(FakeHardwareKeyboard(isAltPressed: true, isMetaPressed: true, isControlPressed: true, isShiftPressed: true));
    expect(HardwareKeyboard.instance.isAltPressed, isTrue);
    expect(HardwareKeyboard.instance.isControlPressed, isTrue);
    expect(HardwareKeyboard.instance.isMetaPressed, isTrue);
    expect(HardwareKeyboard.instance.isShiftPressed, isTrue);
    order += 1;
  });

  testWidgets('HardwareKeyboard gets reset after each widget test (check)', (WidgetTester tester) async {
    assert(order == 4);
    expect(HardwareKeyboard.instance.isAltPressed, isFalse);
    expect(HardwareKeyboard.instance.isControlPressed, isFalse);
    expect(HardwareKeyboard.instance.isMetaPressed, isFalse);
    expect(HardwareKeyboard.instance.isShiftPressed, isFalse);
    order += 1;
  });

  testWidgets('timeStamp should be accurate to microsecond precision', (WidgetTester tester) async {
    final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(const CircularProgressIndicator());

    final Duration timeStampBefore = widgetsBinding.currentSystemFrameTimeStamp;
    await tester.pump(const Duration(microseconds: 12345));
    final Duration timeStampAfter = widgetsBinding.currentSystemFrameTimeStamp;

    expect(timeStampAfter - timeStampBefore, const Duration(microseconds: 12345));
  });

  group('elapseBlocking', () {
    testWidgets('timer is not called', (WidgetTester tester) async {
      bool timerCalled = false;
      Timer.run(() => timerCalled = true);

      binding.elapseBlocking(const Duration(seconds: 1));

      expect(timerCalled, false);
      binding.idle();
    });

    testWidgets('can use to simulate slow build', (WidgetTester tester) async {
      final DateTime beforeTime = binding.clock.now();

      await tester.pumpWidget(Builder(builder: (_) {
        bool timerCalled = false;
        Timer.run(() => timerCalled = true);

        binding.elapseBlocking(const Duration(seconds: 1));

        // if we use `delayed` instead of `elapseBlocking`, such as
        // binding.delayed(const Duration(seconds: 1));
        // the timer will be called here. Surely, that violates how
        // a flutter widget build works
        expect(timerCalled, false);

        return Container();
      }));

      expect(binding.clock.now(), beforeTime.add(const Duration(seconds: 1)));
      binding.idle();
    });
  });

  testWidgets('Assets in the tester can be loaded without turning event loop', (WidgetTester tester) async {
    bool responded = false;
    // The particular asset does not matter, as long as it exists.
    rootBundle.load('AssetManifest.json').then((ByteData data) {
      responded = true;
    });
    expect(responded, true);
  });
}

class FakeHardwareKeyboard extends HardwareKeyboard {
  FakeHardwareKeyboard({
    this.isAltPressed = false,
    this.isControlPressed = false,
    this.isMetaPressed = false,
    this.isShiftPressed = false,
  });

  @override
  bool isMetaPressed;
  @override
  bool isControlPressed;
  @override
  bool isAltPressed;
  @override
  bool isShiftPressed;

  @override
  bool isLogicalKeyPressed(LogicalKeyboardKey key) {
    return switch (key) {
      LogicalKeyboardKey.shift || LogicalKeyboardKey.shiftLeft || LogicalKeyboardKey.shiftRight => isShiftPressed,
      LogicalKeyboardKey.alt || LogicalKeyboardKey.altLeft || LogicalKeyboardKey.altRight => isAltPressed,
      LogicalKeyboardKey.control || LogicalKeyboardKey.controlLeft || LogicalKeyboardKey.controlRight => isControlPressed,
      LogicalKeyboardKey.meta || LogicalKeyboardKey.metaLeft || LogicalKeyboardKey.metaRight => isMetaPressed,
      _ => HardwareKeyboard.instance.isLogicalKeyPressed(key)
    };
  }
}
