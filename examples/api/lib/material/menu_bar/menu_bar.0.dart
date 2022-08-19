// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [MenuBar]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kMessage = '"Talk less. Smile more." - A. Burr';

void main() => runApp(const MenuBarApp());

enum MenuSelection {
  about('About'),
  showMessage('Show Message', SingleActivator(LogicalKeyboardKey.keyS, control: true)),
  resetMessage('Reset Message', SingleActivator(LogicalKeyboardKey.escape)),
  hideMessage('Hide Message'),
  colorMenu('Color Menu'),
  colorRed('Red Background', SingleActivator(LogicalKeyboardKey.keyR, control: true)),
  colorGreen('Green Background', SingleActivator(LogicalKeyboardKey.keyG, control: true)),
  colorBlue('Blue Background', SingleActivator(LogicalKeyboardKey.keyB, control: true));

  const MenuSelection(this.label, [this.shortcut]);
  final String label;
  final MenuSerializableShortcut? shortcut;
}

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MenuBar Sample',
      home: Scaffold(body: MyMenuBar()),
    );
  }
}

class MyMenuBar extends StatefulWidget {
  const MyMenuBar({super.key});

  @override
  State<MyMenuBar> createState() => _MyMenuBarState();
}

class _MyMenuBarState extends State<MyMenuBar> {
  MenuSelection? _lastSelection;
  ShortcutRegistryEntry? _shortcutsEntry;

  bool get showingMessage => _showMessage;
  bool _showMessage = false;
  set showingMessage(bool value) {
    if (_showMessage != value) {
      setState(() {
        _showMessage = value;
      });
    }
  }

  Color get backgroundColor => _backgroundColor;
  Color _backgroundColor = Colors.red;
  set backgroundColor(Color value) {
    if (_backgroundColor != value) {
      setState(() {
        _backgroundColor = value;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shortcutsEntry?.dispose();
    // Register the shortcuts with the ShortcutRegistry so that they are available
    // to the entire application.
    final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
      for (final MenuSelection item in MenuSelection.values)
        if (item.shortcut != null) item.shortcut!: VoidCallbackIntent(() => _activate(item)),
    };
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  void _activate(MenuSelection selection) {
    setState(() {
      _lastSelection = selection;
    });
    switch (selection) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Sample',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.showMessage:
        showingMessage = !showingMessage;
        break;
      case MenuSelection.resetMessage:
      case MenuSelection.hideMessage:
        showingMessage = false;
        break;
      case MenuSelection.colorMenu:
        break;
      case MenuSelection.colorRed:
        backgroundColor = Colors.red;
        break;
      case MenuSelection.colorGreen:
        backgroundColor = Colors.green;
        break;
      case MenuSelection.colorBlue:
        backgroundColor = Colors.blue;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: MenuBar(
                children: <Widget>[
                  MenuButton(
                    child: const Text('Menu App'),
                    children: <Widget>[
                      MenuItemButton(
                        child: Text(MenuSelection.about.label),
                        onPressed: () => _activate(MenuSelection.about),
                      ),
                      // Toggles the message.
                      MenuItemButton(
                        onPressed: () => _activate(MenuSelection.showMessage),
                        shortcut: MenuSelection.showMessage.shortcut,
                        child:
                            Text(showingMessage ? MenuSelection.hideMessage.label : MenuSelection.showMessage.label),
                      ),
                      // Hides the message, but is only enabled if the message isn't already hidden.
                      MenuItemButton(
                        onPressed:
                            showingMessage ? () => _activate(MenuSelection.resetMessage) : null,
                        shortcut: MenuSelection.resetMessage.shortcut,
                        child: Text(MenuSelection.resetMessage.label),
                      ),
                      MenuButton(
                        child: const Text('Background Color'),
                        children: <Widget>[
                          MenuItemGroup(members: <Widget>[
                            MenuItemButton(
                              onPressed: () => _activate(MenuSelection.colorRed),
                              shortcut: MenuSelection.colorRed.shortcut,
                              child: Text(MenuSelection.colorRed.label),
                            ),
                            MenuItemButton(
                              onPressed: () => _activate(MenuSelection.colorGreen),
                              shortcut: MenuSelection.colorGreen.shortcut,
                              child: Text(MenuSelection.colorGreen.label),
                            ),
                          ]),
                          MenuItemButton(
                            onPressed: () => _activate(MenuSelection.colorBlue),
                            shortcut: MenuSelection.colorBlue.shortcut,
                            child: Text(MenuSelection.colorBlue.label),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            color: backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    showingMessage ? kMessage : '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(_lastSelection != null ? 'Last Selected: ${_lastSelection!.label}' : ''),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// An intent that activates a menu item in our example app.
class ActivateMenuItemIntent extends Intent {
  const ActivateMenuItemIntent(this.menu);
  final MenuSelection menu;
}
