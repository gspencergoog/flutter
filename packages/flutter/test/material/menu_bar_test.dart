// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuController controller;
  String? focusedMenu;
  final List<TestMenu> selected = <TestMenu>[];
  final List<TestMenu> opened = <TestMenu>[];
  final List<TestMenu> closed = <TestMenu>[];

  void onSelected(TestMenu item) {
    selected.add(item);
  }

  void onOpen(TestMenu item) {
    opened.add(item);
  }

  void onClose(TestMenu item) {
    closed.add(item);
  }

  void handleFocusChange() {
    focusedMenu = primaryFocus?.debugLabel ?? primaryFocus?.toString();
  }

  setUp(() {
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuController();
    focusedMenu = null;
  });

  tearDown(() {
    controller.closeAll();
  });

  void listenForFocusChanges() {
    FocusManager.instance.addListener(handleFocusChange);
    addTearDown(() => FocusManager.instance.removeListener(handleFocusChange));
  }

  Finder findDividers() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemDivider');
  }

  Finder findMenuPanels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuPanel');
  }

  Finder findMenuBarItemLabels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemLabel');
  }

  // Finds the mnemonic associated with the menu item that has the given label.
  Finder findMnemonic(String label) {
    return find
        .descendant(
            of: find.ancestor(of: find.text(label), matching: findMenuBarItemLabels()), matching: find.byType(Text))
        .last;
  }

  Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    return gesture;
  }

  Material getMenuBarMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(of: findMenuPanels(), matching: find.byType(Material)).first,
    );
  }

  group('MenuBar', () {
    testWidgets('basic menu structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu100.label), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu100.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu101.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu102.label), findsNothing);
      expect(opened.last, equals(TestMenu.mainMenu1));
      opened.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu100.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu101.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu102.label), findsOneWidget);
      expect(opened.last, equals(TestMenu.subMenu11));
    });
    testWidgets('geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        children: createTestMenus(onSelected: onSelected),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(160.0, 73.0, 314.0, 87.0)),
      );
      expect(
          tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
          equals(const Rect.fromLTRB(136.0, 48.0, 398.0, 224.0)));
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(136.0, 104.0, 398.0, 120.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
    });
    testWidgets('geometry with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          children: createTestMenus(onSelected: onSelected),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(486.0, 73.0, 640.0, 87.0)),
      );
      expect(
          tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
          equals(const Rect.fromLTRB(402.0, 48.0, 664.0, 224.0)));
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(402.0, 104.0, 664.0, 120.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Test menu bar size when not expanded.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  children: createTestMenus(onSelected: onSelected),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(198.0, 0.0, 602.0, 48.0)));
    });

    testWidgets('menu alignment and offset in LTR', (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode(debugLabel: 'Test');
      final MenuEntry menuEntry = createMaterialMenu(
        focusNode,
        children: <Widget>[
          MenuItemButton(
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
            ),
            onSelected: () {},
            label: Text(TestMenu.subMenu00.label),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.send),
            trailingIcon: const Icon(Icons.mail),
            onSelected: () {},
            label: Text(TestMenu.subMenu00.label),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: ElevatedButton(
                focusNode: focusNode,
                onPressed: () {
                  if (menuEntry.isOpen) {
                    menuEntry.close();
                  } else {
                    menuEntry.open();
                  }
                },
                child: const Text('Press Me'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      // We have to pump two frames, one because there is a one frame delay in
      // the notification because the menu is in the overlay, and once to react
      // to the notification.
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(328.0, 318.0, 650.0, 430.0)));

      menuEntry.alignment = AlignmentDirectional.topStart;
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(328.0, 282.0, 650.0, 394.0)));

      menuEntry.alignment = AlignmentDirectional.center;
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(400.0, 300.0, 722.0, 412.0)));

      menuEntry.alignment = AlignmentDirectional.bottomEnd;
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(454.0, 318.0, 776.0, 430.0)));

      menuEntry.alignment = AlignmentDirectional.topStart;
      await tester.pump();
      await tester.pump();

      final Rect menuRect = tester.getRect(findMenuScope);
      menuEntry.alignmentOffset = const Offset(10, 20);
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope).topLeft - menuRect.topLeft, equals(const Offset(10.0, 20.0)));
    });
    testWidgets('menu alignment and offset in RTL direction', (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode(debugLabel: 'Test');
      final MenuEntry menuEntry = createMaterialMenu(
        focusNode,
        children: <Widget>[
          MenuItemButton(
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
            ),
            onSelected: () {},
            label: Text(TestMenu.subMenu00.label),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.send),
            trailingIcon: const Icon(Icons.mail),
            onSelected: () {},
            label: Text(TestMenu.subMenu00.label),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: Center(
                child: ElevatedButton(
                  focusNode: focusNode,
                  onPressed: () {
                    if (menuEntry.isOpen) {
                      menuEntry.close();
                    } else {
                      menuEntry.open();
                    }
                  },
                  child: const Text('Press Me'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      // We have to pump two frames, one because there is a one frame delay in
      // the notification because the menu is in the overlay, and once to react
      // to the notification.
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(150.0, 318.0, 472.0, 430.0)));

      menuEntry.alignment = AlignmentDirectional.topStart;
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(150.0, 282.0, 472.0, 394.0)));

      menuEntry.alignment = AlignmentDirectional.center;
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(78.0, 300.0, 400.0, 412.0)));

      menuEntry.alignment = AlignmentDirectional.bottomEnd;
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(24.0, 318.0, 346.0, 430.0)));

      menuEntry.alignment = AlignmentDirectional.topStart;
      await tester.pump();
      await tester.pump();

      final Rect menuRect = tester.getRect(findMenuScope);
      menuEntry.alignmentOffset = const Offset(10, 20);
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(findMenuScope).topLeft - menuRect.topLeft, equals(const Offset(-10, 20)));
    });
    testWidgets('works with Padding around menu and overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: MenuBar(
                            children: createTestMenus(onSelected: onSelected),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(182.0, 95.0, 336.0, 109.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(158.0, 70.0, 420.0, 246.0)),
      );
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(158.0, 126.0, 420.0, 142.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });
    testWidgets('works with Padding around menu and overlay with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: MenuBar(
                              children: createTestMenus(onSelected: onSelected),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: Placeholder()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(464.0, 95.0, 618.0, 109.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(380.0, 70.0, 642.0, 246.0)),
      );
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(380.0, 126.0, 642.0, 142.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });
    testWidgets('visual attributes can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        elevation: MaterialStateProperty.all<double?>(10),
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        children: createTestMenus(onSelected: onSelected),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      expect(tester.getRect(findMenuPanels()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 48.0)));
      final Material material = getMenuBarMaterial(tester);
      expect(material.elevation, equals(10));
      expect(material.color, equals(Colors.red));
    });
    testWidgets('open and close works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(onSelected: onSelected, onOpen: onOpen, onClose: onClose),
            ),
          ),
        ),
      );

      expect(opened, isEmpty);
      expect(closed, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.subMenu11]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu0]));
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu1]));
    });
    testWidgets('select works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(onSelected: onSelected, onOpen: onOpen, onClose: onClose),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      await tester.tap(find.text(TestMenu.subSubMenu100.label));
      await tester.pump();

      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu100]));

      // Selecting a non-submenu item should close all the menus.
      expect(opened, isEmpty);
      expect(find.text(TestMenu.subSubMenu100.label), findsNothing);
      expect(find.text(TestMenu.subMenu11.label), findsNothing);
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      const MenuItemButton item = MenuItemButton(
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
        label: Text('label2'),
      );
      final MenuBar menuBar = MenuBar(
        controller: MenuController(),
        backgroundColor: MaterialStateProperty.all(Colors.red),
        elevation: MaterialStateProperty.all<double?>(10.0),
        children: const <Widget>[item],
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
        equalsIgnoringHashCodes(
          'controller: MenuController#00000(open: [], previousFocus: null)\n'
          'backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336)))\n'
          'elevation: MaterialStatePropertyAll(10.0)',
        ),
      );
    });
    testWidgets('keyboard tab traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  children: createTestMenus(
                    onSelected: onSelected,
                    onOpen: onOpen,
                    onClose: onClose,
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      expect(focusedMenu, equals('MenuButton(Text("Menu 0"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 1"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 2"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 0"))'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 2"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 1"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 0"))'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      opened.clear();
      closed.clear();

      // Test closing a menu with enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, isEmpty);
      expect(closed, <TestMenu>[TestMenu.mainMenu0]);
    });
    testWidgets('keyboard directional traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 100"))'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 100"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 101"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 102"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 103"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 103"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 2"))'));
    });
    testWidgets('keyboard directional traversal works in RTL mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: MenuBar(
                controller: controller,
                children: createTestMenus(
                  onSelected: onSelected,
                  onOpen: onOpen,
                  onClose: onClose,
                ),
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusedMenu, equals('MenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 100"))'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 100"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 101"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 102"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 103"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 103"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 2"))'));
    });
    testWidgets('hover traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Hovering when the menu is not yet open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, isNull);

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();
      expect(focusedMenu, equals('MenuButton(Text("Menu 0"))'));

      // Hovering when the menu is already  open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 0"))'));

      // Hovering over the other main menu items opens them now.
      await hoverOver(tester, find.text(TestMenu.mainMenu2.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 2"))'));

      await hoverOver(tester, find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Menu 1"))'));

      // Hovering over the menu items focuses them.
      await hoverOver(tester, find.text(TestMenu.subMenu10.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await hoverOver(tester, find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuButton(Text("Sub Menu 11"))'));

      await hoverOver(tester, find.text(TestMenu.subSubMenu100.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 100"))'));
    });
  });
  group('MenuItemGroup', () {
    testWidgets('Top level menu groups have appropriate dividers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(findDividers(), findsNWidgets(2));
      // Children of the top level menu bar should be in the right order (with
      // the dividers between the right items).
      final Finder topLevelMenuPanel = findMenuPanels().first;
      // ignore: avoid_dynamic_calls
      final List<Widget> children = (tester.widget(topLevelMenuPanel) as dynamic).children as List<Widget>;
      expect(
        children.map<String>((Widget child) => child.runtimeType.toString()),
        equals(
          <String>[
            'FocusTraversalOrder',
            'FocusTraversalOrder',
            'FocusTraversalOrder',
            '_MenuItemDivider',
            'FocusTraversalOrder',
            '_MenuItemDivider',
            'FocusTraversalOrder'
          ],
        ),
      );
    });
    testWidgets('Submenus have appropriate dividers', (WidgetTester tester) async {
      final GlobalKey menuKey = GlobalKey(debugLabel: 'MenuBar');
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: menuKey,
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      expect(findDividers(), findsNWidgets(4));

      // The menu item that is open.
      final Finder firstMenuList = find
          .descendant(
            of: find.byWidget(Navigator.of(menuKey.currentContext!).overlay!.widget),
            matching: findMenuPanels(),
          )
          .at(1);
      // ignore: avoid_dynamic_calls
      final List<Widget> children = (tester.widget(firstMenuList) as dynamic).children as List<Widget>;
      expect(
        children.map<String>((Widget child) => child.runtimeType.toString()),
        equals(
          <String>[
            'FocusTraversalOrder',
            '_MenuItemDivider',
            'FocusTraversalOrder',
            '_MenuItemDivider',
            'FocusTraversalOrder'
          ],
        ),
      );
    });
  });
  group('MenuController', () {
    testWidgets("disposed controllers don't notify listeners", (WidgetTester tester) async {
      final MenuController controller = MenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      // Now pump a new menu with a different UniqueKey to dispose of the opened
      // menu's node.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.arrowRight),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('closing via controller works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(
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
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(opened, unorderedEquals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      // Close menus using the controller
      controller.closeAll();
      await tester.pump();

      // The menu should go away,
      expect(closed, unorderedEquals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(opened, isEmpty);
    });
  });
  group('MenuItemButton', () {
    testWidgets('Shortcut mnemonics are displayed', (WidgetTester tester) async {
      final MenuController controller = MenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                  TestMenu.subSubMenu101: const SingleActivator(LogicalKeyboardKey.keyB, shift: true),
                  TestMenu.subSubMenu102: const SingleActivator(LogicalKeyboardKey.keyC, alt: true),
                  TestMenu.subSubMenu103: const SingleActivator(LogicalKeyboardKey.keyD, meta: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      Text mnemonic0;
      Text mnemonic1;
      Text mnemonic2;
      Text mnemonic3;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
          expect(mnemonic3.data, equals('Meta D'));
          break;
        case TargetPlatform.windows:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
          expect(mnemonic3.data, equals('Win D'));
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
          expect(mnemonic0.data, equals('⌃ A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
          expect(mnemonic2.data, equals('⌥ C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
          expect(mnemonic3.data, equals('⌘ D'));
          break;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.arrowRight),
                  TestMenu.subSubMenu101: const SingleActivator(LogicalKeyboardKey.arrowLeft),
                  TestMenu.subSubMenu102: const SingleActivator(LogicalKeyboardKey.arrowUp),
                  TestMenu.subSubMenu103: const SingleActivator(LogicalKeyboardKey.arrowDown),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
      expect(mnemonic0.data, equals('→'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
      expect(mnemonic1.data, equals('←'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
      expect(mnemonic2.data, equals('↑'));
      mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
      expect(mnemonic3.data, equals('↓'));

      // Try some weirder ones.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.escape),
                  TestMenu.subSubMenu101: const SingleActivator(LogicalKeyboardKey.fn),
                  TestMenu.subSubMenu102: const SingleActivator(LogicalKeyboardKey.enter),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
      expect(mnemonic0.data, equals('Esc'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
      expect(mnemonic1.data, equals('Fn'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
      expect(mnemonic2.data, equals('↵'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('leadingIcon is used when set', (WidgetTester tester) async {
      final MenuController controller = MenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                MenuButton(
                  label: Text(TestMenu.mainMenu0.label),
                  children: <Widget>[
                    MenuItemButton(
                      leadingIcon: const Text('leadingIcon'),
                      label: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('leadingIcon'), findsOneWidget);
    });
    testWidgets('trailingIcon is used when set', (WidgetTester tester) async {
      final MenuController controller = MenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                MenuButton(
                  label: Text(TestMenu.mainMenu0.label),
                  children: <Widget>[
                    MenuItemButton(
                      trailingIcon: const Text('trailingIcon'),
                      label: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('trailingIcon'), findsOneWidget);
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                MenuButton(
                  shape: MaterialStateProperty.all<OutlinedBorder?>(const RoundedRectangleBorder()),
                  label: Text(TestMenu.mainMenu0.label),
                  elevation: MaterialStateProperty.all<double?>(10.0),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  children: <Widget>[
                    MenuItemGroup(
                      members: <Widget>[
                        MenuItemButton(
                          semanticsLabel: 'semanticLabel',
                          label: Text(TestMenu.subMenu00.label),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      final MenuButton submenu = tester.widget(find.byType(MenuButton));
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      submenu.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description, <String>[
        'label: Text("Menu 0")',
        'backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336)))',
        'shape: MaterialStatePropertyAll(RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero))',
        'elevation: MaterialStatePropertyAll(10.0)'
      ]);
    });
  });
  group('Layout', () {
    List<Rect> collectMenuRects() {
      final List<Rect> menuRects = <Rect>[];
      final List<Element> candidates = find.byType(MenuButton).evaluate().toList();
      for (final Element candidate in candidates) {
        final RenderBox box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        final Offset bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
        menuRects.add(Rect.fromPoints(topLeft, bottomRight));
      }
      return menuRects;
    }

    testWidgets('unconstrained menus show up in the right place in LTR', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        children: createTestMenus(onSelected: onSelected),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(MenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(4.0, 0.0, 136.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(136.0, 0.0, 268.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(268.0, 0.0, 400.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(136.0, 120.0, 398.0, 168.0)));
    });
    testWidgets('unconstrained menus show up in the right place in RTL', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          children: createTestMenus(onSelected: onSelected),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(MenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(664.0, 0.0, 796.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(532.0, 0.0, 664.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(400.0, 0.0, 532.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(402.0, 120.0, 664.0, 168.0)));
    });
    testWidgets('constrained menus show up in the right place in LTR', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 300));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        children: createTestMenus(onSelected: onSelected),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(MenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(4.0, 0.0, 136.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(136.0, 0.0, 268.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(268.0, 0.0, 400.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(24.0, 120.0, 286.0, 168.0)));
    });
    testWidgets('constrained menus show up in the right place in RTL', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 300));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        children: createTestMenus(onSelected: onSelected),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(MenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(164.0, 0.0, 296.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(32.0, 0.0, 164.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(-100.0, 0.0, 32.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(24.0, 120.0, 286.0, 168.0)));
    });
  });
  group('LocalizedShortcutLabeler', () {
    testWidgets('getShortcutLabel returns the right labels', (WidgetTester tester) async {
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

      const SingleActivator allModifiers = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
        meta: true,
        shift: true,
        alt: true,
      );
      final String allExpected = '$expectedAlt $expectedCtrl $expectedMeta ⇧ A';
      const CharacterActivator charShortcuts = CharacterActivator('ñ');
      const String charExpected = 'ñ';
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                MenuButton(
                  label: Text(TestMenu.mainMenu0.label),
                  children: <Widget>[
                    MenuItemButton(
                      shortcut: allModifiers,
                      label: Text(TestMenu.subMenu10.label),
                    ),
                    MenuItemButton(
                      shortcut: charShortcuts,
                      label: Text(TestMenu.subMenu11.label),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text(allExpected), findsOneWidget);
      expect(find.text(charExpected), findsOneWidget);
    }, variant: TargetPlatformVariant.all());
  });
}

enum TestMenu {
  mainMenu0('Menu 0'),
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  mainMenu3('Menu 3'),
  mainMenu4('Menu 4'),
  subMenu00('Sub Menu 00'),
  subMenu01('Sub Menu 01'),
  subMenu02('Sub Menu 02'),
  subMenu10('Sub Menu 10'),
  subMenu11('Sub Menu 11'),
  subMenu12('Sub Menu 12'),
  subMenu20('Sub Menu 20'),
  subMenu30('Sub Menu 30'),
  subMenu40('Sub Menu 40'),
  subMenu41('Sub Menu 41'),
  subMenu42('Sub Menu 42'),
  subSubMenu100('Sub Sub Menu 100'),
  subSubMenu101('Sub Sub Menu 101'),
  subSubMenu102('Sub Sub Menu 102'),
  subSubMenu103('Sub Sub Menu 103');

  const TestMenu(this.label);
  final String label;
}

List<Widget> createTestMenus({
  void Function(TestMenu)? onSelected,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeStandard = false,
  bool includeExtraGroups = false,
}) {
  final List<Widget> result = <Widget>[
    MenuButton(
      label: Text(TestMenu.mainMenu0.label),
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      children: <Widget>[
        MenuItemButton(
          onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu00) : null,
          shortcut: shortcuts[TestMenu.subMenu00],
          label: Text(TestMenu.subMenu00.label),
        ),
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu01) : null,
              shortcut: shortcuts[TestMenu.subMenu01],
              label: Text(TestMenu.subMenu01.label),
            ),
          ],
        ),
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu02) : null,
              shortcut: shortcuts[TestMenu.subMenu02],
              label: Text(TestMenu.subMenu02.label),
            ),
          ],
        ),
      ],
    ),
    MenuButton(
      label: Text(TestMenu.mainMenu1.label),
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu1) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu1) : null,
      children: <Widget>[
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu10) : null,
              shortcut: shortcuts[TestMenu.subMenu10],
              label: Text(TestMenu.subMenu10.label),
            ),
          ],
        ),
        MenuButton(
          label: Text(TestMenu.subMenu11.label),
          onOpen: onOpen != null ? () => onOpen(TestMenu.subMenu11) : null,
          onClose: onClose != null ? () => onClose(TestMenu.subMenu11) : null,
          children: <Widget>[
            MenuItemGroup(
              members: <Widget>[
                MenuItemButton(
                  key: UniqueKey(),
                  onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu100) : null,
                  shortcut: shortcuts[TestMenu.subSubMenu100],
                  label: Text(TestMenu.subSubMenu100.label),
                ),
              ],
            ),
            MenuItemButton(
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu101) : null,
              shortcut: shortcuts[TestMenu.subSubMenu101],
              label: Text(TestMenu.subSubMenu101.label),
            ),
            MenuItemButton(
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu102) : null,
              shortcut: shortcuts[TestMenu.subSubMenu102],
              label: Text(TestMenu.subSubMenu102.label),
            ),
            MenuItemButton(
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu103) : null,
              shortcut: shortcuts[TestMenu.subSubMenu103],
              label: Text(TestMenu.subSubMenu103.label),
            ),
          ],
        ),
        MenuItemButton(
          onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu12) : null,
          shortcut: shortcuts[TestMenu.subMenu12],
          label: Text(TestMenu.subMenu12.label),
        ),
      ],
    ),
    MenuButton(
      label: Text(TestMenu.mainMenu2.label),
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu2) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu2) : null,
      children: <Widget>[
        MenuItemButton(
          // Always disabled.
          shortcut: shortcuts[TestMenu.subMenu20],
          label: Text(TestMenu.subMenu20.label),
        ),
      ],
    ),
    if (includeExtraGroups)
      MenuItemGroup(members: <Widget>[
        MenuButton(
          label: Text(TestMenu.mainMenu3.label),
          onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu3) : null,
          onClose: onClose != null ? () => onClose(TestMenu.mainMenu3) : null,
          children: <Widget>[
            MenuItemButton(
              // Always disabled.
              shortcut: shortcuts[TestMenu.subMenu30],
              // Always disabled.
              label: Text(TestMenu.subMenu30.label),
            ),
          ],
        ),
      ]),
    if (includeExtraGroups)
      MenuItemGroup(
        members: <Widget>[
          MenuButton(
            label: Text(TestMenu.mainMenu4.label),
            onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu4) : null,
            onClose: onClose != null ? () => onClose(TestMenu.mainMenu4) : null,
            children: <Widget>[
              MenuItemButton(
                // Always disabled.
                shortcut: shortcuts[TestMenu.subMenu40],
                // Always disabled.
                label: Text(TestMenu.subMenu40.label),
              ),
              MenuItemGroup(
                members: <Widget>[
                  MenuItemButton(
                    // Always disabled.
                    shortcut: shortcuts[TestMenu.subMenu41],
                    // Always disabled.
                    label: Text(TestMenu.subMenu41.label),
                  ),
                ],
              ),
              MenuItemGroup(
                members: <Widget>[
                  MenuItemButton(
                    // Always disabled.
                    shortcut: shortcuts[TestMenu.subMenu42],
                    // Always disabled.
                    label: Text(TestMenu.subMenu42.label),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
  ];
  return result;
}
