// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TestMenu {
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  mainMenu3('Menu 3'),
  mainMenu4('Menu 4'),
  subMenu1('Sub Menu 1'),
  subMenu2('Sub Menu 2'),
  subMenu3('Sub Menu 3'),
  subMenu4('Sub Menu 4'),
  subMenu5('Sub Menu 5'),
  subMenu6('Sub Menu 6'),
  subMenu7('Sub Menu 7'),
  subMenu8('Sub Menu 8'),
  subSubMenu1('Sub Sub Menu 1'),
  subSubMenu2('Sub Sub Menu 2'),
  subSubMenu3('Sub Sub Menu 3');

  const TestMenu(this.label);
  final String label;
}

void main() {
  runApp(const MaterialApp(
    title: 'Menu Tester',
    home: Material(child: Home()),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MenuController _controller = MenuController();
  VisualDensity _density = VisualDensity.standard;
  TextDirection _textDirection = TextDirection.ltr;
  double _extraPadding = 0;
  bool _addItem = false;
  bool _transparent = false;
  bool _funkyTheme = false;

  void _itemSelected(TestMenu item) {
    debugPrint('App: Selected item ${item.label}');
  }

  void _openItem(TestMenu item) {
    debugPrint('App: Opened item ${item.label}');
  }

  void _closeItem(TestMenu item) {
    debugPrint('App: Closed item ${item.label}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    MenuThemeData menuTheme = MenuTheme.of(context);
    MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    MenuButtonThemeData menuButtonTheme = MenuButtonTheme.of(context);
    if (_funkyTheme) {
      menuTheme = const MenuThemeData(
        style: MenuStyle(
          shape: MaterialStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
          backgroundColor: MaterialStatePropertyAll<Color?>(Colors.blue),
          elevation: MaterialStatePropertyAll<double?>(10),
          padding: MaterialStatePropertyAll<EdgeInsetsDirectional>(EdgeInsetsDirectional.all(20)),
        ),
      );
      menuButtonTheme = const MenuButtonThemeData(
          style: ButtonStyle(
        shape: MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        backgroundColor: MaterialStatePropertyAll<Color?>(Colors.green),
        foregroundColor: MaterialStatePropertyAll<Color?>(Colors.white),
      ));
      menuBarTheme = const MenuBarThemeData(
          style: MenuStyle(
        shape: MaterialStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder()),
        backgroundColor: MaterialStatePropertyAll<Color?>(Colors.blue),
        elevation: MaterialStatePropertyAll<double?>(10),
        padding: MaterialStatePropertyAll<EdgeInsetsDirectional>(EdgeInsetsDirectional.all(20)),
      ));
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(_extraPadding),
        child: Directionality(
          textDirection: _textDirection,
          child: Builder(builder: (BuildContext context) {
            return Theme(
              data: theme.copyWith(
                visualDensity: _density,
                menuTheme: _transparent
                    ? MenuThemeData(
                        style: MenuStyle(
                          backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue.withOpacity(0.12)),
                          elevation: const MaterialStatePropertyAll<double>(0),
                        ),
                      )
                    : menuTheme,
                menuBarTheme: menuBarTheme,
                menuButtonTheme: menuButtonTheme,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          controller: _controller,
                          children: <Widget>[
                            MenuButton(
                              child: Text(TestMenu.mainMenu1.label),
                              onOpen: () {
                                _openItem(TestMenu.mainMenu1);
                              },
                              onClose: () {
                                _closeItem(TestMenu.mainMenu1);
                              },
                              children: <Widget>[
                                MenuItemButton(
                                  shortcut: const SingleActivator(
                                    LogicalKeyboardKey.keyB,
                                    control: true,
                                  ),
                                  leadingIcon: _addItem
                                      ? const Icon(Icons.check_box)
                                      : const Icon(Icons.check_box_outline_blank),
                                  trailingIcon: const Icon(Icons.assessment),
                                  onPressed: () {
                                    _itemSelected(TestMenu.subMenu1);
                                    setState(() {
                                      _addItem = !_addItem;
                                    });
                                  },
                                  child: Text(TestMenu.subMenu1.label),
                                ),
                                MenuItemButton(
                                  leadingIcon: const Icon(Icons.send),
                                  trailingIcon: const Icon(Icons.mail),
                                  onPressed: () {
                                    _itemSelected(TestMenu.subMenu2);
                                  },
                                  child: Text(TestMenu.subMenu2.label),
                                ),
                              ],
                            ),
                            MenuItemGroup(
                              members: <Widget>[
                                MenuButton(
                                  child: Text(TestMenu.mainMenu2.label),
                                  onOpen: () {
                                    _openItem(TestMenu.mainMenu2);
                                  },
                                  onClose: () {
                                    _closeItem(TestMenu.mainMenu2);
                                  },
                                  children: <Widget>[
                                    TextButton(
                                      child: const Text('TEST'),
                                      onPressed: () {
                                        debugPrint('App: Selected item TEST button');
                                        _controller.closeAll();
                                      },
                                    ),
                                    MenuItemButton(
                                      shortcut: const SingleActivator(
                                        LogicalKeyboardKey.enter,
                                        control: true,
                                      ),
                                      onPressed: () {
                                        _itemSelected(TestMenu.subMenu3);
                                      },
                                      child: Text(TestMenu.subMenu3.label),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            MenuButton(
                              child: Text(TestMenu.mainMenu3.label),
                              onOpen: () {
                                _openItem(TestMenu.mainMenu3);
                              },
                              onClose: () {
                                _closeItem(TestMenu.mainMenu3);
                              },
                              children: <Widget>[
                                MenuItemButton(
                                  child: Text(TestMenu.subMenu8.label),
                                  onPressed: () {
                                    _itemSelected(TestMenu.subMenu8);
                                  },
                                ),
                              ],
                            ),
                            MenuButton(
                              child: Text(TestMenu.mainMenu4.label),
                              onOpen: () {
                                _openItem(TestMenu.mainMenu4);
                              },
                              onClose: () {
                                _closeItem(TestMenu.mainMenu4);
                              },
                              children: <Widget>[
                                MenuItemGroup(members: <Widget>[
                                  Actions(
                                    actions: <Type, Action<Intent>>{
                                      ActivateIntent: CallbackAction<ActivateIntent>(
                                        onInvoke: (ActivateIntent? intent) {
                                          debugPrint('Activated!');
                                          return;
                                        },
                                      )
                                    },
                                    child: MenuItemButton(
                                      shortcut: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                                      onPressed: () {},
                                      child: const SizedBox(width: 200, child: TextField()),
                                    ),
                                  ),
                                ]),
                                MenuButton(
                                  child: Text(TestMenu.subMenu5.label),
                                  onOpen: () {
                                    _openItem(TestMenu.subMenu5);
                                  },
                                  onClose: () {
                                    _closeItem(TestMenu.subMenu5);
                                  },
                                  children: <Widget>[
                                    MenuItemButton(
                                      shortcut: _addItem
                                          ? const SingleActivator(
                                              LogicalKeyboardKey.f11,
                                              control: true,
                                            )
                                          : const SingleActivator(
                                              LogicalKeyboardKey.f10,
                                              control: true,
                                            ),
                                      onPressed: () {
                                        _itemSelected(TestMenu.subSubMenu1);
                                      },
                                      child: Text(TestMenu.subSubMenu1.label),
                                    ),
                                    MenuItemButton(
                                      child: Text(TestMenu.subSubMenu2.label),
                                      onPressed: () {
                                        _itemSelected(TestMenu.subSubMenu2);
                                      },
                                    ),
                                    if (_addItem)
                                      MenuItemButton(
                                        child: Text(TestMenu.subSubMenu3.label),
                                        onPressed: () {
                                          _itemSelected(TestMenu.subSubMenu3);
                                        },
                                      ),
                                  ],
                                ),
                                MenuItemButton(
                                  shortcut: const SingleActivator(
                                    LogicalKeyboardKey.tab,
                                    control: true,
                                  ),
                                  child: Text(TestMenu.subMenu6.label),
                                ),
                                MenuItemButton(
                                  child: Text(TestMenu.subMenu7.label),
                                  onPressed: () {
                                    _itemSelected(TestMenu.subMenu7);
                                  },
                                ),
                                MenuItemButton(
                                  child: Text(TestMenu.subMenu7.label),
                                  onPressed: () {
                                    _itemSelected(TestMenu.subMenu7);
                                  },
                                ),
                                MenuItemButton(
                                  child: Text(TestMenu.subMenu8.label),
                                  onPressed: () {
                                    _itemSelected(TestMenu.subMenu8);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _Controls(
                        menuController: _controller,
                        density: _density,
                        addItem: _addItem,
                        transparent: _transparent,
                        funkyTheme: _funkyTheme,
                        extraPadding: _extraPadding,
                        textDirection: _textDirection,
                        onDensityChanged: (VisualDensity value) {
                          setState(() {
                            _density = value;
                          });
                        },
                        onTextDirectionChanged: (TextDirection value) {
                          setState(() {
                            _textDirection = value;
                          });
                        },
                        onExtraPaddingChanged: (double value) {
                          setState(() {
                            _extraPadding = value;
                          });
                        },
                        onAddItemChanged: (bool value) {
                          setState(() {
                            _addItem = value;
                          });
                        },
                        onTransparentChanged: (bool value) {
                          setState(() {
                            _transparent = value;
                          });
                        },
                        onFunkyThemeChanged: (bool value) {
                          setState(() {
                            _funkyTheme = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.density,
    required this.textDirection,
    required this.extraPadding,
    this.addItem = false,
    this.transparent = false,
    this.funkyTheme = false,
    required this.onDensityChanged,
    required this.onTextDirectionChanged,
    required this.onExtraPaddingChanged,
    required this.onAddItemChanged,
    required this.onTransparentChanged,
    required this.onFunkyThemeChanged,
    required this.menuController,
  });

  final VisualDensity density;
  final TextDirection textDirection;
  final double extraPadding;
  final bool addItem;
  final bool transparent;
  final bool funkyTheme;
  final ValueChanged<VisualDensity> onDensityChanged;
  final ValueChanged<TextDirection> onTextDirectionChanged;
  final ValueChanged<double> onExtraPaddingChanged;
  final ValueChanged<bool> onAddItemChanged;
  final ValueChanged<bool> onTransparentChanged;
  final ValueChanged<bool> onFunkyThemeChanged;
  final MenuController menuController;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  final GlobalKey buttonKey = GlobalKey();
  late FocusNode focusNode;
  MenuEntry? menuEntry;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(debugLabel: 'Floating');
  }

  @override
  void dispose() {
    focusNode.dispose();
    menuEntry?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (menuEntry == null) {
      _createMenuEntry();
    }
  }

  @override
  void didUpdateWidget(_Controls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menuController != oldWidget.menuController) {
      _createMenuEntry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlueAccent,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TapRegion(
            groupId: widget.menuController,
            child: TextButton(
              key: buttonKey,
              focusNode: focusNode,
              onPressed: () {
                if (menuEntry!.isOpen) {
                  menuEntry!.close();
                } else {
                  menuEntry!.open();
                }
              },
              child: const Text('Open Menu'),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text('Extra Padding: ${widget.extraPadding.toStringAsFixed(1)}'),
                Slider(
                  value: widget.extraPadding,
                  max: 40,
                  divisions: 20,
                  onChanged: (double value) {
                    widget.onExtraPaddingChanged(value);
                  },
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text('Horizontal Density: ${widget.density.horizontal.toStringAsFixed(1)}'),
                Slider(
                  value: widget.density.horizontal,
                  max: 4,
                  min: -4,
                  divisions: 12,
                  onChanged: (double value) {
                    widget.onDensityChanged(
                      VisualDensity(
                        horizontal: value,
                        vertical: widget.density.vertical,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text('Vertical Density: ${widget.density.vertical.toStringAsFixed(1)}'),
                Slider(
                  value: widget.density.vertical,
                  max: 4,
                  min: -4,
                  divisions: 12,
                  onChanged: (double value) {
                    widget.onDensityChanged(
                      VisualDensity(
                        horizontal: widget.density.horizontal,
                        vertical: value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.textDirection == TextDirection.rtl,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onTextDirectionChanged(TextDirection.rtl);
                      } else {
                        widget.onTextDirectionChanged(TextDirection.ltr);
                      }
                    },
                  ),
                  const Text('RTL Text')
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.addItem,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onAddItemChanged(true);
                      } else {
                        widget.onAddItemChanged(false);
                      }
                    },
                  ),
                  const Text('Add Item')
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.transparent,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onTransparentChanged(true);
                      } else {
                        widget.onTransparentChanged(false);
                      }
                    },
                  ),
                  const Text('Transparent')
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.funkyTheme,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onFunkyThemeChanged(true);
                      } else {
                        widget.onFunkyThemeChanged(false);
                      }
                    },
                  ),
                  const Text('Funky Theme')
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createMenuEntry() {
    menuEntry?.dispose();
    menuEntry = createMaterialMenu(
      focusNode,
      alignment: AlignmentDirectional.topEnd,
      alignmentOffset: const Offset(0, -8),
      controller: widget.menuController,
      children: <Widget>[
        MenuItemButton(
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyB,
            control: true,
          ),
          onPressed: () {},
          child: Text(TestMenu.subMenu1.label),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.send),
          trailingIcon: const Icon(Icons.mail),
          onPressed: () {},
          child: Text(TestMenu.subMenu2.label),
        ),
      ],
    );
  }
}
