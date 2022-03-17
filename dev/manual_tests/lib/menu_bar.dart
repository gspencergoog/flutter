// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const List<String> mainMenu = <String>[
  'Menu 1',
  'Menu 2',
  'Menu 3',
  'Menu 4',
];

const List<String> subMenu = <String>[
  'Sub Menu 1',
  'Sub Menu 2',
  'Sub Menu 3',
  'Sub Menu 4',
  'Sub Menu 5',
  'Sub Menu 6',
  'Sub Menu 7',
];

const List<String> subSubMenu = <String>[
  'Sub Sub Menu 1',
  'Sub Sub Menu 2',
];

void main() {
  debugFocusChanges = false;
  runApp(const MaterialApp(
    title: 'Menu Tester',
    home: Material(child: Home()),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late MenuBarController controller;
  bool isPlatformMenu = false;
  VisualDensity density = VisualDensity.standard;
  TextDirection textDirection = TextDirection.ltr;
  bool enabled = true;
  bool checked = false;

  void _activateItem(String item) {
    debugPrint('Activated item $item');
  }

  void _openItem(String item) {
    debugPrint('Opened item $item');
  }

  void _closeItem(String item) {
    debugPrint('Closed item $item');
  }

  @override
  void initState() {
    super.initState();
    controller = MenuBarController();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Directionality(
      textDirection: textDirection,
      child: Builder(builder: (BuildContext context) {
        return Theme(
          data: theme.copyWith(visualDensity: density),
          child: MenuBar.adaptive(
            targetPlatform: isPlatformMenu ? TargetPlatform.macOS : TargetPlatform.windows,
            enabled: enabled,
            controller: controller,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Checkbox(
                        value: isPlatformMenu,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value ?? false) {
                              isPlatformMenu = true;
                            } else {
                              isPlatformMenu = false;
                            }
                          });
                        },
                      ),
                      const Text('Platform Menus')
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text('Horizontal Density: ${density.horizontal.toStringAsFixed(1)}'),
                        Slider(
                            value: density.horizontal,
                            max: 4,
                            min: -4,
                            divisions: 10,
                            onChanged: !isPlatformMenu
                                ? (double value) {
                                    setState(() {
                                      density = VisualDensity(horizontal: value, vertical: density.vertical);
                                    });
                                  }
                                : null),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text('Vertical Density: ${density.vertical.toStringAsFixed(1)}'),
                        Slider(
                            value: density.vertical,
                            max: 4,
                            min: -4,
                            divisions: 10,
                            onChanged: !isPlatformMenu
                                ? (double value) {
                                    setState(() {
                                      density = VisualDensity(horizontal: density.horizontal, vertical: value);
                                    });
                                  }
                                : null),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Checkbox(
                        value: textDirection == TextDirection.rtl,
                        onChanged: !isPlatformMenu
                            ? (bool? value) {
                                setState(() {
                                  if (value ?? false) {
                                    textDirection = TextDirection.rtl;
                                  } else {
                                    textDirection = TextDirection.ltr;
                                  }
                                });
                              }
                            : null,
                      ),
                      const Text('RTL Text')
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Checkbox(
                        value: enabled,
                        onChanged: !isPlatformMenu
                            ? (bool? value) {
                                setState(() {
                                  if (value ?? false) {
                                    enabled = true;
                                  } else {
                                    enabled = false;
                                  }
                                });
                              }
                            : null,
                      ),
                      const Text('Enabled')
                    ],
                  ),
                ],
              ),
            ),
            children: <MenuItem>[
              MenuBarSubMenu(
                label: mainMenu[0],
                onOpen: () {
                  _openItem(mainMenu[0]);
                },
                onClose: () {
                  _closeItem(mainMenu[0]);
                },
                children: <MenuItem>[
                  MenuBarItem(
                      label: subMenu[0],
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyA,
                        control: true,
                      ),
                      leadingIcon: checked ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                      trailingIcon: const Icon(Icons.assessment),
                      onSelected: () {
                        _activateItem(subMenu[0]);
                        setState(() {
                          checked = !checked;
                        });
                      }),
                  MenuBarItem(
                    label: subMenu[1],
                    leadingIcon: const Icon(Icons.check_box),
                    trailingIcon: const Icon(Icons.mail),
                    onSelected: () {
                      _activateItem(subMenu[1]);
                    },
                  ),
                ],
              ),
              MenuBarSubMenu(
                label: mainMenu[1],
                onOpen: () {
                  _openItem(mainMenu[1]);
                },
                onClose: () {
                  _closeItem(mainMenu[1]);
                },
                children: <MenuItem>[
                  MenuBarItem(
                    label: subMenu[2],
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.enter,
                      control: true,
                    ),
                    onSelected: () {
                      _activateItem(subMenu[2]);
                    },
                  ),
                ],
              ),
              MenuBarSubMenu(
                label: mainMenu[2],
                onOpen: () {
                  _openItem(mainMenu[2]);
                },
                onClose: () {
                  _closeItem(mainMenu[2]);
                },
                children: <MenuItem>[
                  PlatformMenuItemGroup(members: <MenuItem>[
                    MenuBarItem(
                      label: subMenu[3],
                      onSelected: () {
                        _activateItem(subMenu[3]);
                      },
                    ),
                  ]),
                  MenuBarSubMenu(
                    label: subMenu[4],
                    onOpen: () {
                      _openItem(subMenu[4]);
                    },
                    onClose: () {
                      _closeItem(subMenu[4]);
                    },
                    children: <MenuItem>[
                      PlatformMenuItemGroup(
                        members: <MenuItem>[
                          MenuBarItem(
                            label: subSubMenu[0],
                            shortcut: const SingleActivator(
                              LogicalKeyboardKey.f11,
                              control: true,
                            ),
                            onSelected: () {
                              _activateItem(subSubMenu[0]);
                            },
                          )
                        ],
                      ),
                      MenuBarItem(
                        label: subSubMenu[1],
                        onSelected: () {
                          _activateItem(subSubMenu[1]);
                        },
                      ),
                    ],
                  ),
                  MenuBarItem(
                    label: subMenu[5],
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.tab,
                      control: true,
                    ),
                  ),
                  MenuBarItem(
                    label: subMenu[6],
                  ),
                ],
              ),
            ],
            // child: const Center(child: Text('Body')),
          ),
        );
      }),
    );
  }
}
