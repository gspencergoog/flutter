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
  MenuSelection? lastSelection;
  ShortcutRegistryEntry? shortcutsEntry;

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
    shortcutsEntry?.dispose();
    final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
      for (final MenuSelection item in MenuSelection.values)
        if (item.shortcut != null) item.shortcut!: ActivateMenuItemIntent(item),
    };
    shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
  }

  @override
  void dispose() {
    shortcutsEntry?.dispose();
    super.dispose();
  }

  void _activate(ActivateMenuItemIntent intent) {
    final MenuSelection selection = intent.menu;
    setState(() {
      lastSelection = selection;
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
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateMenuItemIntent: CallbackAction<ActivateMenuItemIntent>(onInvoke: _activate),
      },
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: MenuBar(
                  children: <Widget>[
                    MenuButton(
                      autofocus: true,
                      label: const Text('Menu App'),
                      children: <Widget>[
                        MenuItemButton(
                          label: Text(MenuSelection.about.label),
                          onSelectedIntent: const ActivateMenuItemIntent(MenuSelection.about),
                        ),
                        // Toggles the message.
                        MenuItemButton(
                          onSelectedIntent: const ActivateMenuItemIntent(MenuSelection.showMessage),
                          shortcut: MenuSelection.showMessage.shortcut,
                          label:
                              Text(showingMessage ? MenuSelection.hideMessage.label : MenuSelection.showMessage.label),
                        ),
                        // Hides the message, but is only enabled if the message isn't already hidden.
                        MenuItemButton(
                          onSelectedIntent:
                              showingMessage ? const ActivateMenuItemIntent(MenuSelection.resetMessage) : null,
                          shortcut: MenuSelection.resetMessage.shortcut,
                          label: Text(MenuSelection.resetMessage.label),
                        ),
                        MenuButton(
                          label: const Text('Background Color'),
                          children: <Widget>[
                            MenuItemGroup(members: <Widget>[
                              MenuItemButton(
                                onSelectedIntent: const ActivateMenuItemIntent(MenuSelection.colorRed),
                                shortcut: MenuSelection.colorRed.shortcut,
                                label: Text(MenuSelection.colorRed.label),
                              ),
                              MenuItemButton(
                                onSelectedIntent: const ActivateMenuItemIntent(MenuSelection.colorGreen),
                                shortcut: MenuSelection.colorGreen.shortcut,
                                label: Text(MenuSelection.colorGreen.label),
                              ),
                            ]),
                            MenuItemButton(
                              onSelectedIntent: const ActivateMenuItemIntent(MenuSelection.colorBlue),
                              shortcut: MenuSelection.colorBlue.shortcut,
                              label: Text(MenuSelection.colorBlue.label),
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
                  Text(lastSelection != null ? 'Last Selected: ${lastSelection!.label}' : ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An intent that activates a menu item in our example app.
class ActivateMenuItemIntent extends Intent {
  const ActivateMenuItemIntent(this.menu);
  final MenuSelection menu;
}
