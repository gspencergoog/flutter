// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuBarController controller;
  String? currentPath;
  final List<String> activated = <String>[];
  final List<String> opened = <String>[];
  final List<String> closed = <String>[];
  void collectPath() {
    // ignore: avoid_dynamic_calls
    final dynamic openPath = (controller as dynamic).openPath;
    if (openPath == null) {
      currentPath = null;
      return;
    }
    // ignore: avoid_dynamic_calls
    currentPath = openPath.toString();
  }

  void onSelected(String item) {
    activated.add(item);
    collectPath();
  }

  void onOpen(String item) {
    opened.add(item);
    collectPath();
  }

  void onClose(String item) {
    closed.add(item);
    collectPath();
  }

  setUp(() {
    currentPath = null;
    activated.clear();
    opened.clear();
    closed.clear();
    controller = MenuBarController();
    collectPath();
  });

  Finder findDivider() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemDivider');
  }

  Finder findMenuBarMenu() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarMenu');
  }

  Finder findMenuAppBar() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuAppBar');
  }

  Finder findMenuBarItemLabel() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarItemLabel');
  }

  // Finds the mnemonic associated with the menu item that has the given label.
  Finder findMnemonic(String label) {
    return find
        .descendant(
            of: find.ancestor(of: find.text(label), matching: findMenuBarItemLabel()), matching: find.byType(Text))
        .last;
  }

  Material getMenuBarBackground(WidgetTester tester) {
    return tester.widget<Material>(
      find
          .descendant(
            of: findMenuAppBar(),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  group('MenuBar', () {
    testWidgets('basic menu structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(find.text(mainMenu[0]), findsOneWidget);
      expect(find.text(mainMenu[1]), findsOneWidget);
      expect(find.text(mainMenu[2]), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text(subMenu1[0]), findsNothing);
      expect(find.text(subSubMenu10[0]), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(find.text(mainMenu[0]), findsOneWidget);
      expect(find.text(mainMenu[1]), findsOneWidget);
      expect(find.text(mainMenu[2]), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text(subMenu1[0]), findsOneWidget);
      expect(find.text(subMenu1[1]), findsOneWidget);
      expect(find.text(subMenu1[2]), findsOneWidget);
      expect(find.text(subSubMenu10[0]), findsNothing);
      expect(find.text(subSubMenu10[1]), findsNothing);
      expect(find.text(subSubMenu10[2]), findsNothing);
      expect(opened.last, equals(mainMenu[1]));
      opened.clear();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(find.text(mainMenu[0]), findsOneWidget);
      expect(find.text(mainMenu[1]), findsOneWidget);
      expect(find.text(mainMenu[2]), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text(subMenu1[0]), findsOneWidget);
      expect(find.text(subMenu1[1]), findsOneWidget);
      expect(find.text(subMenu1[2]), findsOneWidget);
      expect(find.text(subSubMenu10[0]), findsOneWidget);
      expect(find.text(subSubMenu10[1]), findsOneWidget);
      expect(find.text(subSubMenu10[2]), findsOneWidget);
      expect(opened.last, equals(subMenu1[1]));
    });
    testWidgets('geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              body: const Center(child: Text('Body')),
              children: createTestMenus(onSelected: onSelected),
            ),
          ),
        ),
      );

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTWH(0, 0, 800, 600)));
      expect(tester.getRect(find.ancestor(of: find.text('Body'), matching: find.byType(Stack)).first),
          equals(const Rect.fromLTWH(0, 48, 800, 552)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTWH(0, 0, 800, 600)));
      expect(tester.getRect(find.ancestor(of: find.text('Body'), matching: find.byType(Stack)).first),
          equals(const Rect.fromLTWH(0, 48, 800, 552)));
      expect(tester.getRect(find.text(subMenu1[0])), equals(const Rect.fromLTRB(120.0, 73.0, 274.0, 87.0)));
      expect(tester.getRect(find.ancestor(of: find.text(subMenu1[0]), matching: findMenuBarMenu())),
          equals(const Rect.fromLTRB(108.0, 48.0, 322.0, 224.0)));
      expect(tester.getRect(findDivider()), equals(const Rect.fromLTRB(108.0, 104.0, 322.0, 120.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTWH(0, 0, 800, 600)));
      expect(tester.getRect(find.ancestor(of: find.text('Body'), matching: find.byType(Stack)).first),
          equals(const Rect.fromLTWH(0, 48, 800, 552)));
    });
    testWidgets('visual attributes can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              height: 50,
              elevation: 10,
              backgroundColor: MaterialStateProperty.all(Colors.red),
              body: const Center(child: Text('Body')),
              children: createTestMenus(onSelected: onSelected),
            ),
          ),
        ),
      );
      expect(tester.getRect(findMenuAppBar()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
      final Material material = getMenuBarBackground(tester);
      expect(material.elevation, equals(10));
      expect(material.color, equals(Colors.red));
    });
    testWidgets('open and close works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(onSelected: onSelected, onOpen: onOpen, onClose: onClose),
            ),
          ),
        ),
      );

      expect(currentPath, isNull);
      expect(opened, isEmpty);
      expect(closed, isEmpty);

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(currentPath, equals('1'));
      expect(opened, equals(<String>[mainMenu[1]]));
      expect(closed, isEmpty);

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      // Not 1 > 1 because of the divider.
      expect(currentPath, equals('1 > 2'));
      expect(opened, equals(<String>[mainMenu[1], subMenu1[1]]));
      expect(closed, isEmpty);

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(currentPath, equals('1 > 2'));
      expect(opened, equals(<String>[mainMenu[1], subMenu1[1]]));
      expect(closed, isEmpty);

      opened.clear();
      closed.clear();
      await tester.tap(find.text(mainMenu[0]));
      await tester.pump();

      expect(currentPath, equals('0'));
      expect(opened, equals(<String>[mainMenu[0]]));
      expect(closed, equals(<String>[mainMenu[1], subMenu1[1]]));
    });
    testWidgets('activate works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(onSelected: onSelected, onOpen: onOpen, onClose: onClose),
            ),
          ),
        ),
      );

      expect(currentPath, isNull);
      expect(currentPath, isNull);

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(currentPath, equals('1 > 2'));

      await tester.tap(find.text(subSubMenu10[0]));
      await tester.pump();

      expect(activated, equals(<String>[subSubMenu10[0]]));

      // Activating a non-submenu item should close all the menus.
      expect(currentPath, isNull);
      expect(find.text(subSubMenu10[0]), findsNothing);
      expect(find.text(subMenu1[1]), findsNothing);
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      const MenuBarItem item = MenuBarItem(
        label: 'label2',
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
      );
      final MenuBar menuBar = MenuBar(
        controller: MenuBarController(),
        enabled: false,
        backgroundColor: MaterialStateProperty.all(Colors.red),
        height: 40,
        elevation: 10,
        body: const SizedBox(),
        children: const <MenuItem>[item],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: menuBar,
          ),
        ),
      );
      await tester.pump();

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      menuBar.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
          description.join('\n'),
          equalsIgnoringHashCodes(<String>[
            'controller: _MenuBarController#00000',
            'DISABLED',
            'backgroundColor: MaterialStateProperty.all(MaterialColor(primary value: Color(0xfff44336)))',
            'height: 40.0',
            'elevation: 10.0',
          ].join('\n')));
    });
    testWidgets('activation via shortcut works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Focus(autofocus: true, child: Text('Body'))),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  ),
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(currentPath, equals('1'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);

      expect(activated, equals(<String>[subSubMenu10[0]]));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(currentPath, isNull);
    });
    testWidgets('Having the same shortcut assigned to more than one menu item invokes all.', (WidgetTester tester) async {
      const SingleActivator duplicateActivator = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Focus(autofocus: true, child: Text('Body'))),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: duplicateActivator,
                  subSubMenu10[1]: duplicateActivator,
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(currentPath, equals('1'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);

      expect(activated, equals(<String>[subSubMenu10[0], subSubMenu10[1]]));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(currentPath, isNull);
    });
  });
  group('MenuBarController', () {
    testWidgets('enable and disable works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Focus(autofocus: true, child: Text('Body'))),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();
      expect(opened, equals(<String>[mainMenu[1], subMenu1[1]]));
      opened.clear();
      expect(currentPath, equals('1 > 2'));

      // Disable the menu bar
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              enabled: false,
              body: const Center(child: Focus(autofocus: true, child: Text('Body'))),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The menu should go away,
      expect(currentPath, isNull);
      expect(closed, equals(<String>[mainMenu[1], subMenu1[1]]));
      expect(opened, isEmpty);
      closed.clear();

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      // The menu should not respond to the tap.
      expect(currentPath, isNull);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);

      // The menu should not handle shortcuts.
      expect(activated, isEmpty);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      // Re-enable the menu bar.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Focus(autofocus: true, child: Text('Body'))),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);

      // The menu should now handle shortcuts.
      expect(activated, equals(<String>[subSubMenu10[0]]));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      // The menu should again accept taps.
      await tester.tap(find.text(mainMenu[2]));
      await tester.pump();

      expect(currentPath, equals('2'));
      expect(closed, isEmpty);
      expect(opened, equals(<String>[mainMenu[2]]));
      // Item disabled by its parameter should still be disabled.
      final TextButton button =
          tester.widget(find.ancestor(of: find.text(subMenu2[0]), matching: find.byType(TextButton)));
      expect(button.onPressed, isNull);
      expect(button.onHover, isNull);
      closed.clear();
    });
    testWidgets('closing via controller works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();
      expect(opened, equals(<String>[mainMenu[1], subMenu1[1]]));
      opened.clear();
      expect(currentPath, equals('1 > 2'));

      // Close menus using the controller
      controller.closeAll();
      await tester.pump();

      // The menu should go away,
      expect(currentPath, isNull);
      expect(closed, equals(<String>[mainMenu[1], subMenu1[1]]));
      expect(opened, isEmpty);
    });
  });
  group('MenuBarItem', () {
    testWidgets('Shortcut mnemonics are displayed', (WidgetTester tester) async {
      final MenuBarController controller = MenuBarController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                  subSubMenu10[1]: const SingleActivator(LogicalKeyboardKey.keyB, shift: true),
                  subSubMenu10[2]: const SingleActivator(LogicalKeyboardKey.keyC, alt: true),
                  subSubMenu10[3]: const SingleActivator(LogicalKeyboardKey.keyD, meta: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      Text mnemonic0;
      Text mnemonic1;
      Text mnemonic2;
      Text mnemonic3;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
          expect(mnemonic3.data, equals('Meta D'));
          break;
        case TargetPlatform.windows:
          mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
          expect(mnemonic3.data, equals('Win D'));
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
          expect(mnemonic0.data, equals('⌃ A'));
          mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
          expect(mnemonic2.data, equals('⌥ C'));
          mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
          expect(mnemonic3.data, equals('⌘ D'));
          break;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.arrowRight),
                  subSubMenu10[1]: const SingleActivator(LogicalKeyboardKey.arrowLeft),
                  subSubMenu10[2]: const SingleActivator(LogicalKeyboardKey.arrowUp),
                  subSubMenu10[3]: const SingleActivator(LogicalKeyboardKey.arrowDown),
                },
              ),
            ),
          ),
        ),
      );

      mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
      expect(mnemonic0.data, equals('→'));
      mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
      expect(mnemonic1.data, equals('←'));
      mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
      expect(mnemonic2.data, equals('↑'));
      mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
      expect(mnemonic3.data, equals('↓'));

      // Try some weirder ones.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.escape),
                  subSubMenu10[1]: const SingleActivator(LogicalKeyboardKey.f11),
                  subSubMenu10[2]: const SingleActivator(LogicalKeyboardKey.enter),
                  subSubMenu10[3]: const SingleActivator(LogicalKeyboardKey.tab),
                },
              ),
            ),
          ),
        ),
      );

      mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
      expect(mnemonic0.data, equals('Esc'));
      mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
      expect(mnemonic1.data, equals('F11'));
      mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
      expect(mnemonic2.data, equals('↵'));
      mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
      expect(mnemonic3.data, equals('Tab'));

      // Try overriding the label with a LabeledShortcutActivator.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: createTestMenus(
                shortcuts: <String, ShortcutActivator>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.escape),
                },
              ),
            ),
          ),
        ),
      );

      mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
      expect(mnemonic0.data, equals('Escape Key'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('leadingIcon is used when set', (WidgetTester tester) async {
      final MenuBarController controller = MenuBarController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: <MenuItem>[
                MenuBarSubMenu(
                  label: mainMenu[0],
                  children: <MenuItem>[
                    MenuBarItem(
                      leadingIcon: const Text('leadingIcon'),
                      label: subMenu0[0],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(mainMenu[0]));
      await tester.pump();

      expect(find.text('leadingIcon'), findsOneWidget);
    });
    testWidgets('trailingIcon is used when set', (WidgetTester tester) async {
      final MenuBarController controller = MenuBarController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              body: const Center(child: Text('Body')),
              children: <MenuItem>[
                MenuBarSubMenu(
                  label: mainMenu[0],
                  children: <MenuItem>[
                    MenuBarItem(
                      label: subMenu0[0],
                      trailingIcon: const Text('trailingIcon'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(mainMenu[0]));
      await tester.pump();

      expect(find.text('trailingIcon'), findsOneWidget);
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      final MenuBarSubMenu childItem = MenuBarSubMenu(
        label: 'label',
        shape: const RoundedRectangleBorder(),
        elevation: 10.0,
        backgroundColor: MaterialStateProperty.all(Colors.red),
      );
      final MenuBarSubMenu item = MenuBarSubMenu(
        label: 'label',
        shape: const RoundedRectangleBorder(),
        elevation: 10.0,
        backgroundColor: MaterialStateProperty.all(Colors.red),
        children: <MenuItem>[childItem],
      );

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      item.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description, <String>[
        'label: "label"',
        'backgroundColor: MaterialStateProperty.all(MaterialColor(primary value: Color(0xfff44336)))',
        'shape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)',
        'elevation: 10.0'
      ]);
    });
  });
  group('LocalizedShortcutLabeler', () {
    testWidgets('getShortcutLabel returns the right labels', (WidgetTester tester) async {
      const MaterialLocalizations localizations = DefaultMaterialLocalizations();
      String expectedMeta;
      String expectedCtrl;
      String expectedAlt;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          expectedCtrl = 'Ctrl';
          expectedMeta = 'Meta';
          expectedAlt = 'Alt';
          break;
        case TargetPlatform.windows:
          expectedCtrl = 'Ctrl';
          expectedMeta = 'Win';
          expectedAlt = 'Alt';
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expectedCtrl = '⌃';
          expectedMeta = '⌘';
          expectedAlt = '⌥';
          break;
      }
      final Map<ShortcutActivator, String> tests = <ShortcutActivator, String>{
        const SingleActivator(
          LogicalKeyboardKey.keyA,
          control: true,
          meta: true,
          shift: true,
          alt: true,
        ): '$expectedAlt $expectedCtrl $expectedMeta ⇧ A',
        LogicalKeySet.fromSet(<LogicalKeyboardKey>{
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.meta,
        }): '$expectedAlt $expectedCtrl $expectedMeta ⇧ A',
        const CharacterActivator('ñ'): 'ñ',
      };
      for (final MapEntry<ShortcutActivator, String> test in tests.entries) {
        expect(
          LocalizedShortcutLabeler.instance.getShortcutLabel(test.key, localizations),
          equals(test.value),
        );
      }
    }, variant: TargetPlatformVariant.all());
  });
}

const List<String> mainMenu = <String>[
  'Menu 0',
  'Menu 1',
  'Menu 2',
];

const List<String> subMenu0 = <String>[
  'Sub Menu 00',
];

const List<String> subMenu1 = <String>[
  'Sub Menu 10',
  'Sub Menu 11',
  'Sub Menu 12',
];

const List<String> subSubMenu10 = <String>[
  'Sub Sub Menu 100',
  'Sub Sub Menu 101',
  'Sub Sub Menu 102',
  'Sub Sub Menu 103',
];

const List<String> subMenu2 = <String>[
  'Sub Menu 20',
];

List<MenuItem> createTestMenus({
  void Function(String)? onSelected,
  void Function(String)? onOpen,
  void Function(String)? onClose,
  Map<String, ShortcutActivator> shortcuts = const <String, ShortcutActivator>{},
  bool includeStandard = false,
}) {
  final List<MenuItem> result = <MenuItem>[
    MenuBarSubMenu(
      label: mainMenu[0],
      onOpen: onOpen != null ? () => onOpen(mainMenu[0]) : null,
      onClose: onClose != null ? () => onClose(mainMenu[0]) : null,
      children: <MenuItem>[
        MenuBarItem(
          label: subMenu0[0],
          onSelected: onSelected != null ? () => onSelected(subMenu0[0]) : null,
          shortcut: shortcuts[subMenu0[0]],
        ),
      ],
    ),
    MenuBarSubMenu(
      label: mainMenu[1],
      onOpen: onOpen != null ? () => onOpen(mainMenu[1]) : null,
      onClose: onClose != null ? () => onClose(mainMenu[1]) : null,
      children: <MenuItem>[
        MenuItemGroup(
          members: <MenuItem>[
            MenuBarItem(
              label: subMenu1[0],
              onSelected: onSelected != null ? () => onSelected(subMenu1[0]) : null,
              shortcut: shortcuts[subMenu1[0]],
            ),
          ],
        ),
        MenuBarSubMenu(
          label: subMenu1[1],
          onOpen: onOpen != null ? () => onOpen(subMenu1[1]) : null,
          onClose: onClose != null ? () => onClose(subMenu1[1]) : null,
          children: <MenuItem>[
            MenuItemGroup(
              members: <MenuItem>[
                MenuBarItem(
                  label: subSubMenu10[0],
                  onSelected: onSelected != null ? () => onSelected(subSubMenu10[0]) : null,
                  shortcut: shortcuts[subSubMenu10[0]],
                ),
              ],
            ),
            MenuBarItem(
              label: subSubMenu10[1],
              onSelected: onSelected != null ? () => onSelected(subSubMenu10[1]) : null,
              shortcut: shortcuts[subSubMenu10[1]],
            ),
            MenuBarItem(
              label: subSubMenu10[2],
              onSelected: onSelected != null ? () => onSelected(subSubMenu10[2]) : null,
              shortcut: shortcuts[subSubMenu10[2]],
            ),
            MenuBarItem(
              label: subSubMenu10[3],
              onSelected: onSelected != null ? () => onSelected(subSubMenu10[3]) : null,
              shortcut: shortcuts[subSubMenu10[3]],
            ),
          ],
        ),
        MenuBarItem(
          label: subMenu1[2],
          onSelected: onSelected != null ? () => onSelected(subMenu1[2]) : null,
          shortcut: shortcuts[subMenu1[2]],
        ),
      ],
    ),
    MenuBarSubMenu(
      label: mainMenu[2],
      onOpen: onOpen != null ? () => onOpen(mainMenu[2]) : null,
      onClose: onClose != null ? () => onClose(mainMenu[2]) : null,
      children: <MenuItem>[
        MenuBarItem(
          // Always disabled.
          label: subMenu2[0],
          shortcut: shortcuts[subMenu2[0]],
        ),
      ],
    ),
  ];
  return result;
}
