// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuController controller;
  void onSelected(TestMenu item) {}

  setUp(() {
    controller = MenuController();
  });

  tearDown(() {
    controller.closeAll();
  });

  Finder findMenuPanels(Axis orientation) {
    return find.byWidgetPredicate((Widget widget) {
      // ignore: avoid_dynamic_calls
      return widget.runtimeType.toString() == '_MenuPanel' && (widget as dynamic).orientation == orientation;
    });
  }

  Finder findMenuBarPanel() {
    return findMenuPanels(Axis.horizontal);
  }

  Finder findSubmenuPanel() {
    return findMenuPanels(Axis.vertical);
  }

  Finder findSubMenuItem() {
    return find.descendant(of: findSubmenuPanel().last, matching: find.byType(MenuItemButton));
  }

  Material getMenuBarPanelMaterial(WidgetTester tester) {
    return tester.widget<Material>(find.descendant(of: findMenuBarPanel(), matching: find.byType(Material)).first);
  }

  Material getSubmenuPanelMaterial(WidgetTester tester) {
    return tester.widget<Material>(find.descendant(of: findSubmenuPanel(), matching: find.byType(Material)).first);
  }

  DefaultTextStyle getLabelStyle(WidgetTester tester, String labelText) {
    return tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(labelText),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
  }

  testWidgets('theme is honored', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(builder: (BuildContext context) {
            return MenuTheme(
              data: MenuTheme.of(context).copyWith(
                barBackgroundColor: MaterialStateProperty.all<Color?>(Colors.green),
                barElevation: MaterialStateProperty.all<double?>(20.0),
                menuBackgroundColor: MaterialStateProperty.all<Color?>(Colors.red),
                menuElevation: MaterialStateProperty.all<double?>(15.0),
                menuShape: MaterialStateProperty.all<OutlinedBorder?>(const StadiumBorder()),
                menuPadding: const EdgeInsetsDirectional.all(10.0),
              ),
              child: Column(
                children: <Widget>[
                  MenuBar(
                    children: createTestMenus(onSelected: onSelected),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            );
          }),
        ),
      ),
    );

    // Open a test menu.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();
    expect(tester.getRect(findMenuBarPanel().first), equals(const Rect.fromLTRB(180.0, 0.0, 620.0, 48.0)));
    final Material menuBarMaterial = getMenuBarPanelMaterial(tester);
    expect(menuBarMaterial.elevation, equals(20));
    expect(menuBarMaterial.color, equals(Colors.green));

    final Material subMenuMaterial = getSubmenuPanelMaterial(tester);
    expect(tester.getRect(findSubmenuPanel()), equals(const Rect.fromLTRB(318.0, 48.0, 622.0, 228.0)));
    expect(subMenuMaterial.elevation, equals(15));
    expect(subMenuMaterial.color, equals(Colors.red));
  });

  testWidgets('Constructor parameters override theme parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(builder: (BuildContext context) {
            return MenuTheme(
              data: MenuTheme.of(context).copyWith(
                barBackgroundColor: MaterialStateProperty.all<Color?>(Colors.green),
                barElevation: MaterialStateProperty.all<double?>(20.0),
                menuBackgroundColor: MaterialStateProperty.all<Color?>(Colors.red),
                menuElevation: MaterialStateProperty.all<double?>(15.0),
                menuShape: MaterialStateProperty.all<OutlinedBorder?>(const StadiumBorder()),
                menuPadding: const EdgeInsetsDirectional.all(10.0),
              ),
              child: Column(
                children: <Widget>[
                  MenuBar(
                    backgroundColor: MaterialStateProperty.all<Color?>(Colors.blue),
                    elevation: MaterialStateProperty.all<double?>(10.0),
                    padding: const EdgeInsetsDirectional.all(12.0),
                    children: createTestMenus(
                      onSelected: onSelected,
                      menuBackground: Colors.cyan,
                      menuElevation: 18.0,
                      menuPadding: const EdgeInsetsDirectional.all(14.0),
                      menuShape: const BeveledRectangleBorder(),
                      itemBackground: Colors.amber,
                      itemForeground: Colors.grey,
                      itemOverlay: Colors.blueGrey,
                      itemPadding: const EdgeInsetsDirectional.all(11.0),
                      itemShape: const BeveledRectangleBorder(),
                    ),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            );
          }),
        ),
      ),
    );

    // Open a test menu.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    expect(tester.getRect(findMenuBarPanel().first), equals(const Rect.fromLTRB(182.0, 0.0, 618.0, 72.0)));
    final Material menuBarMaterial = getMenuBarPanelMaterial(tester);
    expect(menuBarMaterial.elevation, equals(10.0));
    expect(menuBarMaterial.color, equals(Colors.blue));

    final Material subMenuMaterial = getSubmenuPanelMaterial(tester);
    expect(tester.getRect(findSubmenuPanel()), equals(const Rect.fromLTRB(324.0, 60.0, 628.0, 240.0)));
    expect(subMenuMaterial.elevation, equals(15));
    expect(subMenuMaterial.color, equals(Colors.red)); // TODO: verify this.
    expect(subMenuMaterial.shape, equals(const StadiumBorder())); // TODO: verify this.

    final Finder menuItem = findSubMenuItem();
    expect(tester.getRect(menuItem.first), equals(const Rect.fromLTRB(334.0, 70.0, 618.0, 118.0)));  // TODO: verify this.
    final Material menuItemMaterial = tester.widget<Material>(
        find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).first);
    expect(menuItemMaterial.color, equals(Colors.amber));
    expect(menuItemMaterial.elevation, equals(0.0));
    expect(menuItemMaterial.shape, equals(const BeveledRectangleBorder()));
    expect(getLabelStyle(tester, TestMenu.subMenu10.label).style.color, equals(Colors.grey));
    final ButtonStyle? textButtonStyle = tester
        .widget<TextButton>(find
            .ancestor(
              of: find.text(TestMenu.subMenu10.label),
              matching: find.byType(TextButton),
            )
            .first)
        .style;
    expect(textButtonStyle?.overlayColor?.resolve(<MaterialState>{MaterialState.hovered}), equals(Colors.blueGrey));
  });
}

enum TestMenu {
  mainMenu0('Menu 0'),
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  subMenu00('Sub Menu 00'),
  subMenu10('Sub Menu 10'),
  subMenu11('Sub Menu 11'),
  subMenu12('Sub Menu 12'),
  subMenu20('Sub Menu 20'),
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
  Color? itemOverlay,
  Color? itemBackground,
  Color? itemForeground,
  EdgeInsetsDirectional? itemPadding,
  Color? menuBackground,
  EdgeInsetsDirectional? menuPadding,
  OutlinedBorder? menuShape,
  double? menuElevation,
  OutlinedBorder? itemShape,
}) {
  final ButtonStyle menuStyle = ButtonStyle(
    padding: menuPadding != null ? MaterialStatePropertyAll<EdgeInsetsGeometry>(menuPadding) : null,
    backgroundColor: menuBackground != null ? MaterialStatePropertyAll<Color>(menuBackground) : null,
    elevation: menuElevation != null ? MaterialStatePropertyAll<double>(menuElevation) : null,
    shape: menuShape != null ? MaterialStatePropertyAll<OutlinedBorder>(menuShape) : null,
  );
  final ButtonStyle itemStyle = ButtonStyle(
    padding: itemPadding != null ? MaterialStatePropertyAll<EdgeInsetsGeometry>(itemPadding) : null,
    shape: itemShape != null ? MaterialStatePropertyAll<OutlinedBorder>(itemShape) : null,
    foregroundColor: itemForeground != null ? MaterialStatePropertyAll<Color>(itemForeground) : null,
    backgroundColor: itemBackground != null ? MaterialStatePropertyAll<Color>(itemBackground) : null,
    overlayColor: itemOverlay != null ? MaterialStatePropertyAll<Color>(itemOverlay) : null,
  );
  final List<Widget> result = <Widget>[
    MenuButton(
      child: Text(TestMenu.mainMenu0.label),
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      children: <Widget>[
        MenuItemButton(
          onPressed: onSelected != null ? () => onSelected(TestMenu.subMenu00) : null,
          shortcut: shortcuts[TestMenu.subMenu00],
          child: Text(TestMenu.subMenu00.label),
        ),
      ],
    ),
    MenuButton(
      child: Text(TestMenu.mainMenu1.label),
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu1) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu1) : null,
      style: menuStyle,
      children: <Widget>[
        MenuItemGroup(
          members: <Widget>[
            MenuItemButton(
              onPressed: onSelected != null ? () => onSelected(TestMenu.subMenu10) : null,
              shortcut: shortcuts[TestMenu.subMenu10],
              style: itemStyle,
              child: Text(TestMenu.subMenu10.label),
            ),
          ],
        ),
        MenuButton(
          child: Text(TestMenu.subMenu11.label),
          onOpen: onOpen != null ? () => onOpen(TestMenu.subMenu11) : null,
          onClose: onClose != null ? () => onClose(TestMenu.subMenu11) : null,
          children: <Widget>[
            MenuItemGroup(
              members: <Widget>[
                MenuItemButton(
                  onPressed: onSelected != null ? () => onSelected(TestMenu.subSubMenu100) : null,
                  shortcut: shortcuts[TestMenu.subSubMenu100],
                  child: Text(TestMenu.subSubMenu100.label),
                ),
              ],
            ),
            MenuItemButton(
              onPressed: onSelected != null ? () => onSelected(TestMenu.subSubMenu101) : null,
              shortcut: shortcuts[TestMenu.subSubMenu101],
              child: Text(TestMenu.subSubMenu101.label),
            ),
            MenuItemButton(
              onPressed: onSelected != null ? () => onSelected(TestMenu.subSubMenu102) : null,
              shortcut: shortcuts[TestMenu.subSubMenu102],
              child: Text(TestMenu.subSubMenu102.label),
            ),
            MenuItemButton(
              onPressed: onSelected != null ? () => onSelected(TestMenu.subSubMenu103) : null,
              shortcut: shortcuts[TestMenu.subSubMenu103],
              child: Text(TestMenu.subSubMenu103.label),
            ),
          ],
        ),
        MenuItemButton(
          onPressed: onSelected != null ? () => onSelected(TestMenu.subMenu12) : null,
          shortcut: shortcuts[TestMenu.subMenu12],
          child: Text(TestMenu.subMenu12.label),
        ),
      ],
    ),
    MenuButton(
      child: Text(TestMenu.mainMenu2.label),
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu2) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu2) : null,
      children: <Widget>[
        MenuItemButton(
          // Always disabled.
          shortcut: shortcuts[TestMenu.subMenu20],
          // Always disabled.
          child: Text(TestMenu.subMenu20.label),
        ),
      ],
    ),
  ];
  return result;
}
