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
  showMessage('Show Message'),
  resetMessage('Reset Message'),
  hideMessage('Hide Message'),
  colorMenu('Color Menu'),
  colorRed('Red Background'),
  colorGreen('Green Background'),
  colorBlue('Blue Background');

  const MenuSelection(this.label);
  final String label;
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

  void _activate(MenuSelection selection) {
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
        showingMessage = true;
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
        MenuBar(
          children: <Widget>[
            MenuButton(
              autofocus: true,
              label: const Text('Menu App'),
              children: <Widget>[
                MenuItemButton(
                  child: Text(MenuSelection.about.label),
                  onSelected: () => _activate(MenuSelection.about),
                ),
                // Toggles the message.
                MenuItemButton(
                  onSelected: () => _activate(showingMessage ? MenuSelection.hideMessage : MenuSelection.showMessage),
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
                  child: Text(showingMessage ? MenuSelection.hideMessage.label : MenuSelection.showMessage.label),
                ),
                // Hides the message, but is only enabled if the message isn't already hidden.
                MenuItemButton(
                  onSelected: showingMessage ? () => _activate(MenuSelection.resetMessage) : null,
                  shortcut: const SingleActivator(LogicalKeyboardKey.escape),
                  child: Text(MenuSelection.resetMessage.label),
                ),
                MenuButton(
                  label: const Text('Background Color'),
                  children: <Widget>[
                    MenuItemGroup(members: <Widget>[
                      MenuItemButton(
                        onSelected: () => _activate(MenuSelection.colorRed),
                        shortcut: const SingleActivator(LogicalKeyboardKey.keyR, control: true),
                        child: Text(MenuSelection.colorRed.label),
                      ),
                      MenuItemButton(
                        onSelected: () => _activate(MenuSelection.colorGreen),
                        shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
                        child: Text(MenuSelection.colorGreen.label),
                      ),
                    ]),
                    MenuItemButton(
                      onSelected: () => _activate(MenuSelection.colorBlue),
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
                      child: Text(MenuSelection.colorBlue.label),
                    ),
                  ],
                ),
              ],
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
                  child: Text(showingMessage ? kMessage : '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(lastSelection != null ? 'Last Selected: ${lastSelection!.label}' : ''),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
