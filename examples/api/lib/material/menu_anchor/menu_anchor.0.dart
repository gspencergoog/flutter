// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [MenuAnchor].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MenuApp());

/// An enhanced enum to define the available menus and their shortcuts.
///
/// Using an enum for menu definition is not required, but this illustrates how
/// they could be used for simple menu systems.
enum MenuEntry {
  file('&File'),
  newDocument('&New', SingleActivator(LogicalKeyboardKey.keyN, control: true)),
  newWindow('New &window', SingleActivator(LogicalKeyboardKey.keyN, shift: true, control: true)),
  open('&Open', SingleActivator(LogicalKeyboardKey.keyO, control: true)),
  save('&Save', SingleActivator(LogicalKeyboardKey.keyS, control: true)),
  saveAs('Save &as...', SingleActivator(LogicalKeyboardKey.keyS, shift: true, control: true)),
  pageSetup('Page s&etup'),
  print('&Print', SingleActivator(LogicalKeyboardKey.keyP, control: true)),
  exit('E&xit', SingleActivator(LogicalKeyboardKey.keyQ, control: true)),
  edit('&Edit'),
  undo('&Undo', SingleActivator(LogicalKeyboardKey.keyZ, control: true)),
  cut('&Cut', SingleActivator(LogicalKeyboardKey.keyX, control: true)),
  copy('C&opy', SingleActivator(LogicalKeyboardKey.keyC, control: true)),
  paste('&Paste', SingleActivator(LogicalKeyboardKey.keyV, control: true)),
  view('&View'),
  fullScreen('&Full screen', SingleActivator(LogicalKeyboardKey.f10));

  const MenuEntry(this.label, [this.shortcut]);
  final String label;
  final MenuSerializableShortcut? shortcut;
  Widget getButton([VoidCallback? onPressed]) {
    return MenuItemButton(
      shortcut: shortcut,
      onPressed: onPressed,
      child: MenuAcceleratorLabel(label),
    );
  }

  Widget getSubmenu(List<Widget> menuChildren) {
    return SubmenuButton(
      menuChildren: menuChildren,
      child: MenuAcceleratorLabel(label),
    );
  }
}

class MyCascadingMenu extends StatefulWidget {
  const MyCascadingMenu({super.key, required this.message});

  final String message;

  @override
  State<MyCascadingMenu> createState() => _MyCascadingMenuState();
}

class _MyCascadingMenuState extends State<MyCascadingMenu> {
  ShortcutRegistryEntry? _shortcutsEntry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dispose of any previously registered shortcuts, since they are about to
    // be replaced.
    _shortcutsEntry?.dispose();
    // Collect the shortcuts from the different menu selections so that they can
    // be registered to apply to the entire app. Menus don't register their
    // shortcuts, they only display the shortcut hint text.
    final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
      for (final MenuEntry item in MenuEntry.values)
        if (item.shortcut != null) item.shortcut!: VoidCallbackIntent(() => _activate(item)),
    };
    // Register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application.
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Expanded(
              child: MenuBar(
                children: <Widget>[
                  MenuEntry.file.getSubmenu(
                    <Widget>[
                      MenuEntry.newDocument.getButton(() => _activate(MenuEntry.newDocument)),
                      MenuEntry.newWindow.getButton(() => _activate(MenuEntry.newWindow)),
                      MenuEntry.open.getButton(() => _activate(MenuEntry.open)),
                      MenuEntry.save.getButton(() => _activate(MenuEntry.save)),
                      MenuEntry.saveAs.getButton(() => _activate(MenuEntry.saveAs)),
                      const Divider(),
                      MenuEntry.pageSetup.getButton(() => _activate(MenuEntry.pageSetup)),
                      MenuEntry.print.getButton(() => _activate(MenuEntry.print)),
                      const Divider(),
                      MenuEntry.exit.getButton(() => _activate(MenuEntry.exit)),
                    ],
                  ),
                  MenuEntry.edit.getSubmenu(<Widget>[
                    MenuEntry.undo.getButton(() => _activate(MenuEntry.undo)),
                    const Divider(),
                    MenuEntry.cut.getButton(),
                    MenuEntry.copy.getButton(),
                    MenuEntry.paste.getButton(),
                  ]),
                  MenuEntry.view.getSubmenu(<Widget>[
                    MenuEntry.fullScreen.getButton(() => _activate(MenuEntry.fullScreen)),
                  ]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(),
      ],
    );
  }

  void _activate(MenuEntry selection) {
    debugPrint('Activated ${selection.name}');
  }
}

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  static const String kMessage = '"Talk less. Smile more." - A. Burr';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        visualDensity: const VisualDensity(
          horizontal: -2,
          vertical: -4,
        ),
      ),
      home: const Scaffold(body: MyCascadingMenu(message: kMessage)),
    );
  }
}
