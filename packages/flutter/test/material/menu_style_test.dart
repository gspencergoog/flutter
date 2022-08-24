// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuController controller;

  setUp(() {
    controller = MenuController();
  });

  tearDown(() {
    controller.closeAll();
  });

  Finder findMenuPanels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuPanel');
  }

  group('MenuStyle', () {
    testWidgets('fixedSize affects geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBarTheme(
                  data: const MenuBarThemeData(
                    style: MenuStyle(
                      fixedSize: MaterialStatePropertyAll<Size>(Size(600, 60)),
                    ),
                  ),
                  child: MenuTheme(
                    data: const MenuThemeData(
                      style: MenuStyle(
                        fixedSize: MaterialStatePropertyAll<Size>(Size(100, 100)),
                      ),
                    ),
                    child: MenuBar(
                      children: createTestMenus(onPressed: (TestMenu menu) {}),
                    ),
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      // MenuBarTheme affects MenuBar.
      expect(tester.getRect(findMenuPanels().first), equals(const Rect.fromLTRB(100.0, 0.0, 700.0, 60.0)));
      expect(tester.getRect(findMenuPanels().first).size, equals(const Size(600.0, 60.0)));

      // MenuTheme affects menus.
      expect(tester.getRect(findMenuPanels().at(1)), equals(const Rect.fromLTRB(104.0, 48.0, 204.0, 148.0)));
      expect(tester.getRect(findMenuPanels().at(1)).size, equals(const Size(100.0, 100.0)));
    });

    testWidgets('maximumSize affects geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBarTheme(
                  data: const MenuBarThemeData(
                    style: MenuStyle(
                      maximumSize: MaterialStatePropertyAll<Size>(Size(250, 40)),
                    ),
                  ),
                  child: MenuTheme(
                    data: const MenuThemeData(
                      style: MenuStyle(
                        maximumSize: MaterialStatePropertyAll<Size>(Size(100, 100)),
                      ),
                    ),
                    child: MenuBar(
                      children: createTestMenus(onPressed: (TestMenu menu) {}),
                    ),
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      // MenuBarTheme affects MenuBar.
      expect(tester.getRect(findMenuPanels().first), equals(const Rect.fromLTRB(275.0, 0.0, 525.0, 40.0)));
      expect(tester.getRect(findMenuPanels().first).size, equals(const Size(250.0, 40.0)));

      // MenuTheme affects menus.
      expect(tester.getRect(findMenuPanels().at(1)), equals(const Rect.fromLTRB(279.0, 48.0, 379.0, 148.0)));
      expect(tester.getRect(findMenuPanels().at(1)).size, equals(const Size(100.0, 100.0)));
    });
    testWidgets('minimumSize affects geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBarTheme(
                  data: const MenuBarThemeData(
                    style: MenuStyle(
                      minimumSize: MaterialStatePropertyAll<Size>(Size(400, 60)),
                    ),
                  ),
                  child: MenuTheme(
                    data: const MenuThemeData(
                      style: MenuStyle(
                        minimumSize: MaterialStatePropertyAll<Size>(Size(300, 300)),
                      ),
                    ),
                    child: MenuBar(
                      children: createTestMenus(onPressed: (TestMenu menu) {}),
                    ),
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      // MenuBarTheme affects MenuBar.
      expect(tester.getRect(findMenuPanels().first), equals(const Rect.fromLTRB(200.0, 0.0, 600.0, 60.0)));
      expect(tester.getRect(findMenuPanels().first).size, equals(const Size(400.0, 60.0)));

      // MenuTheme affects menus.
      expect(tester.getRect(findMenuPanels().at(1)), equals(const Rect.fromLTRB(204.0, 48.0, 504.0, 348.0)));
      expect(tester.getRect(findMenuPanels().at(1)).size, equals(const Size(300.0, 300.0)));
    });
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
  void Function(TestMenu)? onPressed,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeStandard = false,
  bool includeExtraGroups = false,
}) {
  final List<Widget> result = <Widget>[
    MenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu00) : null,
          shortcut: shortcuts[TestMenu.subMenu00],
          child: Text(TestMenu.subMenu00.label),
        ),
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu01) : null,
              shortcut: shortcuts[TestMenu.subMenu01],
              child: Text(TestMenu.subMenu01.label),
            ),
          ],
        ),
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu02) : null,
              shortcut: shortcuts[TestMenu.subMenu02],
              child: Text(TestMenu.subMenu02.label),
            ),
          ],
        ),
      ],
      child: Text(TestMenu.mainMenu0.label),
    ),
    MenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu1) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu1) : null,
      menuChildren: <Widget>[
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu10) : null,
              shortcut: shortcuts[TestMenu.subMenu10],
              child: Text(TestMenu.subMenu10.label),
            ),
          ],
        ),
        MenuButton(
          onOpen: onOpen != null ? () => onOpen(TestMenu.subMenu11) : null,
          onClose: onClose != null ? () => onClose(TestMenu.subMenu11) : null,
          menuChildren: <Widget>[
            MenuItemGroup(
              members: <Widget>[
                MenuItemButton(
                  key: UniqueKey(),
                  onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu100) : null,
                  shortcut: shortcuts[TestMenu.subSubMenu100],
                  child: Text(TestMenu.subSubMenu100.label),
                ),
              ],
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu101) : null,
              shortcut: shortcuts[TestMenu.subSubMenu101],
              child: Text(TestMenu.subSubMenu101.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu102) : null,
              shortcut: shortcuts[TestMenu.subSubMenu102],
              child: Text(TestMenu.subSubMenu102.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu103) : null,
              shortcut: shortcuts[TestMenu.subSubMenu103],
              child: Text(TestMenu.subSubMenu103.label),
            ),
          ],
          child: Text(TestMenu.subMenu11.label),
        ),
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu12) : null,
          shortcut: shortcuts[TestMenu.subMenu12],
          child: Text(TestMenu.subMenu12.label),
        ),
      ],
      child: Text(TestMenu.mainMenu1.label),
    ),
    MenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu2) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu2) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          // Always disabled.
          shortcut: shortcuts[TestMenu.subMenu20],
          child: Text(TestMenu.subMenu20.label),
        ),
      ],
      child: Text(TestMenu.mainMenu2.label),
    ),
    if (includeExtraGroups)
      MenuItemGroup(members: <Widget>[
        MenuButton(
          onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu3) : null,
          onClose: onClose != null ? () => onClose(TestMenu.mainMenu3) : null,
          menuChildren: <Widget>[
            MenuItemButton(
              // Always disabled.
              shortcut: shortcuts[TestMenu.subMenu30],
              // Always disabled.
              child: Text(TestMenu.subMenu30.label),
            ),
          ],
          child: Text(TestMenu.mainMenu3.label),
        ),
      ]),
    if (includeExtraGroups)
      MenuItemGroup(
        members: <Widget>[
          MenuButton(
            onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu4) : null,
            onClose: onClose != null ? () => onClose(TestMenu.mainMenu4) : null,
            menuChildren: <Widget>[
              MenuItemButton(
                // Always disabled.
                shortcut: shortcuts[TestMenu.subMenu40],
                // Always disabled.
                child: Text(TestMenu.subMenu40.label),
              ),
              MenuItemGroup(
                members: <Widget>[
                  MenuItemButton(
                    // Always disabled.
                    shortcut: shortcuts[TestMenu.subMenu41],
                    // Always disabled.
                    child: Text(TestMenu.subMenu41.label),
                  ),
                ],
              ),
              MenuItemGroup(
                members: <Widget>[
                  MenuItemButton(
                    // Always disabled.
                    shortcut: shortcuts[TestMenu.subMenu42],
                    // Always disabled.
                    child: Text(TestMenu.subMenu42.label),
                  ),
                ],
              ),
            ],
            child: Text(TestMenu.mainMenu4.label),
          ),
        ],
      ),
  ];
  return result;
}
