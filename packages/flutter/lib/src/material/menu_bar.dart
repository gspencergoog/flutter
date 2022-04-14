// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'divider.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'menu_bar_theme.dart';
import 'text_button.dart';
import 'theme.dart';
import 'theme_data.dart';

// The default height for the menu bar.
const double _kDefaultMenuBarHeight = 32.0;
const Color _kDefaultMenuBarColor = Colors.white;
const double _kDefaultMenuBarElevation = 2.0;
const double _kDefaultMenuBarMenuElevation = 5.0;
const Duration _kMenuHoverOpenDelay = Duration(milliseconds: 100);
const Duration _kMenuHoverClickBanDelay = Duration(milliseconds: 500);
const double _kDefaultSubmenuIconSize = 24.0;

class _Node with Diagnosticable, DiagnosticableTreeMixin, Comparable<_Node> {
  _Node({required this.item, this.parent}) : children = <_Node>[] {
    parent?.children.add(this);
    if (item is PlatformMenu) {
      for (final MenuItem child in (item as PlatformMenu).menus) {
        // Will get automatically linked into the tree.
        _Node(item: child, parent: this);
      }
    }
  }

  final MenuItem item;
  FocusNode? focusNode;
  _Node? parent;
  List<_Node> children;
  WidgetBuilder? builder;

  bool get hasSubmenu => children.isNotEmpty;

  // Returns all the ancestors of this node, except for the root node.
  List<_Node> get ancestors {
    final List<_Node> result = <_Node>[];
    if (parent == null) {
      return result;
    }
    _Node? node = parent;
    while (node?.parent != null) {
      result.add(node!);
      node = node.parent;
    }
    return result;
  }

  _Node? get topLevel {
    if (parent == null) {
      // Root doesn't have a top level node.
      return null;
    }
    if (parent!.parent == null) {
      // Top level nodes are their own topLevel.
      return this;
    }
    return ancestors.first;
  }

  int get parentIndex {
    if (parent == null) {
      // Root node has no parent index.
      return -1;
    }
    final int result = parent!.children.indexOf(this);
    assert(result != -1, 'Child not found in parent.');
    return result;
  }

  _Node? get nextSibling {
    if (parent == null) {
      // No next sibling for root.
      return null;
    }
    final int thisIndex = parent!.children.indexOf(this);
    if (parent!.children.length > thisIndex + 1) {
      return parent!.children[thisIndex + 1];
    } else {
      return null;
    }
  }

  _Node? get previousSibling {
    final int thisIndex = parent?.children.indexOf(this) ?? -1;
    if (thisIndex > 0) {
      return parent!.children[thisIndex - 1];
    } else {
      return null;
    }
  }

   @override
  int compareTo(_Node other) {
    if (parent == null && other.parent == null) {
      // root menus are equal.
      return 0;
    } else {
      if (parent == null) {
        // Other menu has ancestors, but this one is the root.
        return 1;
      }
      if (other.parent == null) {
        // This menu has ancestors, but the other one is root.
        return -1;
      }
      int i = 0;
      final List<_Node> otherAncestors = other.ancestors;
      // For menus of the same length, sort each menu component by their index
      // in the parent.
      for (; i < ancestors.length && i < otherAncestors.length; i += 1) {
        final int result = ancestors[i].parentIndex.compareTo(otherAncestors[i].parentIndex);
        if (result != 0) {
          return result;
        }
      }
      // If components are equal up to here, then sort shorter list of ancestors first.
      return ancestors.length.compareTo(otherAncestors.length);
    }
  }

  // Returns the list of node ancestors with any of the ancestors that appear in
  // the other's ancestors removed. Includes this in the results.
  List<_Node> ancestorDifference(_Node? other) {
    final List<_Node> myAncestors = <_Node>[...ancestors, this];
    final List<_Node> otherAncestors = <_Node>[
      ...other?.ancestors ?? <_Node>[],
      if (other != null) other,
    ];
    int skip = 0;
    for (; skip < myAncestors.length && skip < otherAncestors.length; skip += 1) {
      if (myAncestors[skip] != otherAncestors[skip]) {
        break;
      }
    }
    return myAncestors.sublist(skip);
  }

  /// Get all of the registered children of the given menu that are focusable.
  /// Used for menu traversal.
  List<_Node> get focusableChildren {
    return children.where((_Node child) => child.focusNode?.canRequestFocus ?? false).toList();
  }

  // Used for testing.
  @override
  String toStringShort({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (item is PlatformMenuItem) {
      return (item as PlatformMenuItem).label;
    }
    if (item is PlatformMenu) {
      return (item as PlatformMenu).label;
    }
    return item.toStringShort();
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...children.map<DiagnosticsNode>((_Node item) => item.toDiagnosticsNode()),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MenuItem>('item', item));
    properties.add(DiagnosticsProperty<WidgetBuilder>('builder', builder, defaultValue: null));
    properties.add(DiagnosticsProperty<_Node>('parent', parent, defaultValue: null));
  }
}

/// A controller that allows control of, and communication with, a [MenuBar].
///
/// Normally, it's not necessary to create a `MenuBarController` to use a
/// [MenuBar], but if you need to be able to close any open menus with the
/// [closeAll] method in response to an event, you can create one and pass it to
/// the [MenuBar].
///
/// If the place you wish to close all the menus (for instance, when a control
/// in one of the icons is selected), you can call [closeAll] on the controller
/// to do so. If the control is a descendant of the [MenuBar], you don't need to
/// create a `MenuBarController`, since the [MenuBar] will create one
/// automatically. You can retrieve it with the [MenuBarController.of] method.
abstract class MenuBarController {
  /// A factory that constructs a [MenuBarController] for use with a [MenuBar].
  factory MenuBarController() {
    return _MenuBarController();
  }

  // Private constructor to prevent this class from being instantiated by
  // anything other than the factory constructor, and from being subclassed.
  MenuBarController._();

  /// Closes any menus that are currently open.
  void closeAll();

  /// Returns the active menu controller in the given context, and creates a
  /// dependency relationship that will rebuild the context when the controller
  /// changes.
  static MenuBarController of(BuildContext context) {
    final MenuBarController? found = context.dependOnInheritedWidgetOfExactType<_MenuBarControllerMarker>()?.notifier;
    if (found == null) {
      throw FlutterError('A ${context.widget.runtimeType} requested a '
          'MenuBarController, but was not a descendant of a MenuBar: $context');
    }
    return found;
  }

  /// A testing method used to provide access to a testing description of the
  /// currently open menu for tests.
  ///
  /// Only meant to be called by tests.
  @visibleForTesting
  String? get testingCurrentItem;

  /// A testing method used to provide access to a testing description of the
  /// currently focused menu item for tests.
  ///
  /// Only meant to be called by tests.
  @visibleForTesting
  String? get testingFocusedItem;
}

// A private implementation of MenuBarController, so that we can have a separate
// private API for the MenuBar internals to use. This is the class that gets
// instantiated when the MenuBarController factory constructor is called.
class _MenuBarController extends MenuBarController with ChangeNotifier, Diagnosticable {
  _MenuBarController() : super._();

  // The root of the menu tree.
  _Node root = _Node(item: const PlatformMenu(label: 'root', menus: <MenuItem>[]));
  // The map of focus nodes to menus. The reverse map of the
  // _registeredFocusNodes.
  final Map<FocusNode, _Node> _focusNodes = <FocusNode, _Node>{};

  // Keeps the previously focused widget when a main menu is opened, so that
  // when the last menu is dismissed, the focus can be restored.
  FocusNode? _previousFocus;
  // A menu that has been opened, but the menu hasn't been realized yet. Once it
  // is, then request focus on it.
  _Node? _pendingFocusedMenu;

  /// The context of the [MenuBar] that this controller serves.
  ///
  /// This context must be set by the menu bar in its initState method.
  BuildContext get menuBarContext => _menuBarContext;
  late BuildContext _menuBarContext;
  set menuBarContext(BuildContext rootContext) {
    assert(
      rootContext.widget is MenuBar,
      'A ${rootContext.widget.runtimeType} was registered with a '
      '$runtimeType, which is not a MenuBar.',
    );
    _menuBarContext = rootContext;
  }

  /// Whether or not the menu bar is enabled for input. This is set by setting
  /// [MenuBar.enabled] on the menu bar widget, and the menu children listen for
  /// it to change.
  ///
  /// If set to false, all menus are closed, shortcuts stop working, and the
  /// menu bar buttons are disabled.
  bool get enabled => _enabled;
  bool _enabled = true;
  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      if (!_enabled) {
        closeAll();
      }
      notifyListeners();
    }
  }

  /// Sets and gets currently open menu.
  ///
  /// When the menu is set, then it will notify all listeners that something has
  /// changed. It will cache the current [primaryFocus] when a non-null menu is
  /// set, and restore it when the menu is set to null. When the menu is set,
  /// the corresponding menu item button will be focused.
  _Node? get openMenu => _openMenu;
  _Node? _openMenu;
  set openMenu(_Node? value) {
    debugPrint('Attempting to set new menu to ${value?.toStringShort()}.');

    if (_openMenu == value) {
      // Nothing changed.
      return;
    }
    if (value != null && _openMenu == null) {
      // We're opening the first menu, so cache the primary focus so that we can
      // try to return to it when the menu is dismissed, but don't cache it if
      // the focus is one of the menu items.
      _previousFocus = FocusManager.instance.primaryFocus;
    }
    if (value == null && _openMenu != null && _previousFocus != null) {
      // Closing all menus, so restore the previous focus.
      SchedulerBinding.instance.addPostFrameCallback((Duration time) {
        // Schedule this post build because it isn't focusable until after this
        // build, due to the ExcludeFocus around the body of the app.
        _previousFocus?.requestFocus();
        _previousFocus = null;
      });
    }
    final _Node? oldMenu = _openMenu;
    debugPrint('Setting new menu to ${value?.toStringShort()}');
    _openMenu = value;
    oldMenu?.ancestorDifference(_openMenu).forEach((_Node node) {
      node.item.onClose?.call();
    });
    _openMenu?.ancestorDifference(oldMenu).forEach((_Node node) {
      node.item.onOpen?.call();
    });
    if (value != null && value.focusNode?.hasPrimaryFocus != true) {
      // Request focus on the new thing that is now open, if any, so that
      // focus traversal starts from that location.
      if (value.focusNode == null) {
        // If we don't have a focus node to ask yet, then keep the menu until it
        // gets registered, or something else sets the menu.
        _pendingFocusedMenu = value;
      } else {
        _pendingFocusedMenu = null;
        value.focusNode!.requestFocus();
      }
    }
    SchedulerBinding.instance.scheduleTask(notifyListeners, Priority.touch);
  }

  @override
  void closeAll() {
    debugPrint('Closing all Menus.');
    openMenu = null;
  }

  /// Closes the given menu, and any open descendant menus.
  ///
  /// Leaves ancestor menus alone.
  ///
  /// Notifies listeners if the menu changed.
  void close(_Node node) {
    if (openMenu == null) {
      // Everything is already closed.
      return;
    }
    if (openMenu == node) {
      debugPrint('Closing menu ${openMenu?.toStringShort()}.');
      // Don't call onClose, notifyListeners, etc, here, because set openMenu
      // will call them if needed.
      if (node.parent == root) {
        openMenu = null;
      } else {
        openMenu = node.parent;
      }
    }
  }

  // Build the node hierarchy for the static part of the menus (the widgets).
  void buildMenus(List<MenuItem> topLevel) {
    debugPrint('Rebuilding Menus');
    root.children.clear();
    _focusNodes.clear();
    _previousFocus = null;
    _pendingFocusedMenu = null;
    for (final MenuItem item in topLevel) {
      if (item is PlatformMenu) {
        _Node(
          item: item,
          parent: root,
        );
      }
    }
    assert(root.children.length == topLevel.length);
  }

  /// Registers or updates the given menu in the menu controller.
  ///
  /// If the given context corresponds to the currently open menu, then update
  /// it to the new menu to that context (if it changed).
  void registerMenu({
    required BuildContext menuContext,
    required _Node node,
    WidgetBuilder? menuBuilder,
    FocusNode? buttonFocus,
  }) {
    debugPrint('Registering ${node.toStringShort()}');

    if (menuBuilder != null) {
      node.builder = (BuildContext context) {
        // Capture the correct context for the menu.
        return _buildPositionedMenu(menuContext, node, menuBuilder);
      };
    } else {
      node.builder = null;
    }
    if (node.focusNode != buttonFocus) {
      node.focusNode?.removeListener(_handleItemFocus);
      node.focusNode = buttonFocus;
      node.focusNode?.addListener(_handleItemFocus);
      if (buttonFocus != null) {
        _focusNodes[buttonFocus] = node;
      }
    }

    if (node == _pendingFocusedMenu) {
      node.focusNode?.requestFocus();
      _pendingFocusedMenu = null;
    }
  }

  /// Unregisters the given context from the menu controller.
  ///
  /// If the given context corresponds to the currently open menu, then close
  /// it.
  void unregisterMenu(_Node node) {
    debugPrint('Unregistering ${node.toStringShort()}');
    node.focusNode?.removeListener(_handleItemFocus);
    node.focusNode = null;
    node.builder = null;
    _focusNodes.remove(node.focusNode);
    if (node == _pendingFocusedMenu) {
      _pendingFocusedMenu = null;
    }
    if (openMenu == node) {
      close(node);
    }
  }

  // Builder for a submenu that should be positioned relative to the menu
  // button whose context is given.
  Widget _buildPositionedMenu(BuildContext menuButtonContext, _Node menuButtonNode, WidgetBuilder menuBuilder) {
    final Rect menuSpacer = _calculateMenuRect(menuButtonContext, menuButtonNode);
    return Positioned.directional(
      textDirection: Directionality.of(menuButtonContext),
      top: menuSpacer.top,
      start: menuSpacer.width,
      child: Theme(
        data: Theme.of(menuButtonContext),
        child: _MenuNodeWrapper(
          menu: menuButtonNode,
          child: Builder(builder: menuBuilder),
        ),
      ),
    );
  }

  // Calculates the position of a submenu, given the menu button and the node it
  // is relative to.
  Rect _calculateMenuRect(BuildContext menuButtonContext, _Node menuButtonNode) {
    final TextDirection textDirection = Directionality.of(menuButtonContext);
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(menuButtonContext);
    final RenderBox button = menuButtonContext.findRenderObject()! as RenderBox;
    final RenderBox menuBar = menuBarContext.findRenderObject()! as RenderBox;
    final double verticalPadding = math.max(2, 8 + Theme.of(menuButtonContext).visualDensity.vertical * 2);
    Offset menuOrigin;
    Offset spacerCorner;
    switch (textDirection) {
      case TextDirection.rtl:
        spacerCorner = menuBar.paintBounds.bottomRight;
        if (menuButtonNode.parent == root) {
          menuOrigin = button.localToGlobal(button.paintBounds.bottomRight, ancestor: menuBar);
        } else {
          menuOrigin = button.localToGlobal(button.paintBounds.topLeft, ancestor: menuBar) +
              Offset(-(menuBarTheme.menuPadding?.right ?? 0), -(menuBarTheme.menuPadding?.top ?? verticalPadding));
        }
        break;
      case TextDirection.ltr:
        spacerCorner = menuBar.paintBounds.bottomLeft;
        if (menuButtonNode.parent == root) {
          menuOrigin = button.localToGlobal(button.paintBounds.bottomLeft, ancestor: menuBar);
        } else {
          menuOrigin = button.localToGlobal(button.paintBounds.topRight, ancestor: menuBar) +
              Offset(menuBarTheme.menuPadding?.left ?? 0, -(menuBarTheme.menuPadding?.top ?? verticalPadding));
        }
        break;
    }
    return Rect.fromPoints(menuOrigin, spacerCorner);
  }

  void _handleItemFocus() {
    if (openMenu == null) {
      // Don't traverse the menu hierarchy on focus unless the user opened a
      // menu already.
      return;
    }
    final _Node? focused = focusedItem;
    if (focused != null && openMenu != focused) {
      debugPrint('Switching opened menu to $openMenu because it is focused.');
      openMenu = focused;
    }
  }

  _Node? get focusedTopLevelItem {
    for (final _Node child in root.children) {
      if (child.focusNode?.hasFocus ?? false) {
        return child;
      }
    }
    return null;
  }

  _Node? get focusedItem {
    final Iterable<FocusNode> focusedItems = _focusNodes.keys.where((FocusNode node) => node.hasFocus);
    assert(
        focusedItems.length <= 1,
        'The same focus node is registered to more than one MenuBar '
        'menu:\n  ${focusedItems.first}');
    return focusedItems.isNotEmpty ? _focusNodes[focusedItems.first] : null;
  }

  // A testing method used to provide access to the currently open menu in
  // tests.
  @override
  String? get testingCurrentItem {
    if (openMenu == null) {
      return null;
    }
    return <String>[...openMenu!.ancestors.map<String>((_Node node) => node.toStringShort()), openMenu!.toStringShort()]
        .join(' > ');
  }

  // A testing method used to provide access to the currently focused menu in
  // tests.
  @override
  String? get testingFocusedItem {
    if (primaryFocus?.context == null) {
      return null;
    }
    return _focusNodes[primaryFocus]?.toStringShort();
  }
}

// The InheritedWidget marker for _MenuBarController, used to find the nearest
// ancestor _MenuBarController.
class _MenuBarControllerMarker extends InheritedNotifier<_MenuBarController> {
  const _MenuBarControllerMarker({
    Key? key,
    required _MenuBarController controller,
    required Widget child,
  }) : super(key: key, notifier: controller, child: child);
}

class _MenuDismissAction extends DismissAction {
  _MenuDismissAction({required this.controller});

  final _MenuBarController controller;

  @override
  bool isEnabled(DismissIntent intent) {
    return controller.openMenu != null;
  }

  @override
  Object? invoke(DismissIntent intent) {
    controller.closeAll();
    return null;
  }
}

class _MenuDirectionalFocusAction extends DirectionalFocusAction {
  /// Creates a [DirectionalFocusAction].
  _MenuDirectionalFocusAction({required this.controller, required this.textDirection});

  final _MenuBarController controller;
  final TextDirection textDirection;

  bool _moveForward() {
    if (controller.openMenu == null) {
      return false;
    }
    final _Node? focusedItem = controller.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    if (focusedItem.hasSubmenu && focusedItem.parent != controller.root) {
      // If no submenu is open, then arrow opens the submenu.
      if (focusedItem.children.isNotEmpty) {
        controller.openMenu = focusedItem.children.first;
      }
    } else {
      // If there's no submenu, then an arrow moves to the next top
      // level sibling, wrapping around if need be.
      final _Node? next = focusedItem.topLevel?.nextSibling;
      if (next != null) {
        controller.openMenu = next;
      } else {
        controller.openMenu = controller.root.children.isNotEmpty ? controller.root.children.first : null;
      }
    }
    return true;
  }

  bool _moveBackward() {
    if (controller.openMenu == null) {
      return false;
    }
    final _Node? focusedItem = controller.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    // Wraps around if there is no previous.
    final _Node? previous = focusedItem.previousSibling;
    if (previous != null) {
      controller.openMenu = previous;
    } else {
      controller.openMenu = controller.root.children.isNotEmpty ? controller.root.children.last : null;
    }
    return true;
  }

  bool _moveUp() {
    final _Node? focusedItem = controller.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    if (focusedItem.parent == controller.root) {
      // If you press up on a top level menu, then close all the menus.
      controller.openMenu = null;
      return true;
    }
    _Node? previousFocusable = focusedItem.previousSibling;
    while (previousFocusable != null && !previousFocusable.focusNode!.canRequestFocus) {
      previousFocusable = previousFocusable.previousSibling;
    }
    if (previousFocusable != null) {
      controller.openMenu = previousFocusable;
    }
    return true;
  }

  bool _moveDown() {
    final _Node? focusedItem = controller.focusedItem;
    if (focusedItem == null) {
      return false;
    }
    if (focusedItem.parent == controller.root) {
      if (controller.openMenu == null) {
        controller.openMenu = focusedItem;
        return true;
      }
      final List<_Node> children = focusedItem.focusableChildren;
      if (children.isNotEmpty) {
        controller.openMenu = children[0];
      }
      return true;
    }
    _Node? nextFocusable = focusedItem.nextSibling;
    while (nextFocusable != null && !nextFocusable.focusNode!.canRequestFocus) {
      nextFocusable = nextFocusable.nextSibling;
    }
    if (nextFocusable != null) {
      controller.openMenu = nextFocusable;
    }
    return true;
  }

  @override
  void invoke(DirectionalFocusIntent intent) {
    switch (intent.direction) {
      case TraversalDirection.up:
        if (_moveUp()) {
          return;
        }
        break;
      case TraversalDirection.down:
        if (_moveDown()) {
          return;
        }
        break;
      case TraversalDirection.left:
        switch (textDirection) {
          case TextDirection.rtl:
            if (_moveForward()) {
              return;
            }
            break;
          case TextDirection.ltr:
            if (_moveBackward()) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.right:
        switch (textDirection) {
          case TextDirection.rtl:
            if (_moveBackward()) {
              return;
            }
            break;
          case TextDirection.ltr:
            if (_moveForward()) {
              return;
            }
            break;
        }

        break;
    }
    super.invoke(intent);
  }
}

/// A menu bar with cascading child menus.
///
/// This is a Material Design menu bar that resides above the main body of an
/// application that defines a menu system for invoking callbacks in response to
/// user selection of the menu item.
///
/// The menu can be navigated by the user using the arrow keys, and can be
/// dismissed using the escape key, or by clicking away from the menu item
/// (anywhere on the modal barrier over the app body). Once a menu is open, the
/// menu hierarchy can be navigated by hovering over the menu with the mouse.
///
/// Menu items can have a [MenuBarItem.shortcut] assigned to them so that if the
/// shortcut sequence is pressed, the menu item that shortcut will be selected.
/// If multiple menu items have the same shortcut, they will all be selected.
///
/// Selecting a menu item causes the [MenuBarItem.onSelected] callback to be
/// called.
///
/// When a menu item with a submenu is clicked on, it toggles the visibility of
/// the submenu. When the menu item is hovered over, the submenu will open after
/// a slight delay, and hovering over other items will close that menu and open
/// the newly hovered one. When those occur, [MenuBarMenu.onOpen], and
/// [MenuBarMenu.onClose] are called, respectively.
///
/// The [body] is where the body of the application with the menu bar resides.
/// When a menu is open, the `MenuBar` places a [ModalBarrier] over the body so
/// that clicking away from the menu will close all menus.
///
/// It also excludes keyboard focus on the [body] with an [ExcludeFocus] while
/// menus are open. This means that anything that was focused when a menu is
/// opened is no longer focused. Once the last menu is closed, the previous
/// [FocusManager.instance.primaryFocus] is restored.
///
/// {@tool dartpad}
/// This example shows a [MenuBar] that contains a single top level menu,
/// containing three items for "About", a checkbox menu item for showing a
/// message, and "Quit". The items are identified with an enum value.
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.0.dart **
/// {@end-tool}
///
/// {@tool sample}
/// This example shows a [MenuBar] that contains a simple menu for a desktop
/// application.  It is set up to be adaptive, so that on macOS it will use the
/// system menu bar, and on other systems will use a Material [MenuBar].
///
/// On macOS, it will add the "About" and "Quit" system-provided menu items.
///
/// The menu items are all identified by an enum value (`MenuSelection`).
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [MenuBarMenu], a menu item which manages a submenu.
///  * [MenuItemGroup], a menu item which collects its members into a group
///    separated from other menu items by a divider.
///  * [MenuBarItem], a leaf menu item which displays the label, an optional
///    shortcut label, and optional leading and trailing icons.
///  * [MenuBarBuilderItem], a leaf menu item which allows customization of the
///    menu item by allowing a [MenuBarCustomItemBuilder] to generate the
///    contents of the menu item.
///  * [MenuBarController], a class that allows closing of menus from outside of
///    the menu bar.
///  * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///    platform instead of by Flutter (on macOS, for example).
class MenuBar extends PlatformMenuBar {
  /// Creates a const [MenuBar].
  ///
  /// The [body] parameter is required.
  const MenuBar({
    Key? key,
    this.controller,
    this.enabled = true,
    this.backgroundColor,
    this.height,
    this.elevation,
    this.isPlatformMenu = false,
    required Widget body,
    List<MenuItem> children = const <MenuItem>[],
  }) : super(key: key, menus: children, body: body);

  /// Creates an adaptive [MenuBar] that renders using platform APIs on
  /// platforms that support it, and using Flutter on platforms that don't.
  ///
  /// The [body] parameter is required.
  ///
  /// An optional `targetPlatform` argument can be used to override the actual
  /// target platform provided by [defaultTargetPlatform], which is the default.
  factory MenuBar.adaptive({
    Key? key,
    MenuBarController? controller,
    bool enabled = true,
    MaterialStateProperty<Color?>? backgroundColor,
    double? height,
    double? elevation,
    TargetPlatform? targetPlatform,
    required Widget body,
    List<MenuItem> children = const <MenuItem>[],
  }) {
    bool isPlatformMenu;
    switch (targetPlatform ?? defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        isPlatformMenu = false;
        break;
      case TargetPlatform.macOS:
        isPlatformMenu = true;
        break;
    }

    return MenuBar(
      key: key,
      controller: controller,
      enabled: enabled,
      backgroundColor: backgroundColor,
      height: height,
      elevation: elevation,
      isPlatformMenu: isPlatformMenu,
      body: body,
      children: children,
    );
  }

  /// An optional controller that allows outside control of the menu bar.
  ///
  /// Setting this controller will allow you to close any open menus from
  /// outside of the menu bar using [MenuBarController.closeAll].
  final MenuBarController? controller;

  /// Whether or not this menu bar is enabled.
  ///
  /// When disabled, all menus are closed, the menu bar buttons are disabled,
  /// and menu shortcuts are ignored.
  final bool enabled;

  /// The background color of the menu bar.
  ///
  /// Defaults to [MenuBarThemeData.menuBarColor] if not set.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The preferred minimum height of the menu bar.
  ///
  /// Defaults to the value of [MenuBarThemeData.menuBarHeight] if not set.
  final double? height;

  /// The Material elevation the menu bar (if any).
  ///
  /// Defaults to the [MenuBarThemeData.menuBarElevation] value of the ambient
  /// [MenuBarTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final double? elevation;

  /// The widget to be rendered under the [MenuBar].
  ///
  /// This is typically the body of the application's UI. When a menu is open,
  /// the [body] will be covered by a [ModalBarrier] and have focus excluded
  /// with an [ExcludeFocus], so that when the user is navigating the menu the
  /// focus remains on the menu, and when they click away from the menu, the
  /// menu will closed.
  @override
  // Overriding just to get a different docstring than the base class.
  Widget get body => super.body;

  /// The list of top-level menu items to show in the [MenuBar].
  ///
  /// Each entry in this list will become a top level menu item, and must have a
  /// [MenuBarItem] inside it somewhere containing the menu item's attributes.
  @override
  // Overriding just to get a different docstring than the base class.
  List<MenuItem> get menus => super.menus;

  /// Whether or not this should be rendered as a [PlatformMenuBar] or a
  /// Material [MenuBar].
  ///
  /// If true, then a [PlatformMenuBar] will be substituted with the same
  /// [children], [body], and [enabled] but none of the visual attributes will
  /// be passed along.
  ///
  /// See also:
  ///
  ///  * [MenuBar.adaptive], a factory constructor that uses the current
  ///    [defaultTargetPlatform] to automatically set this value.
  final bool isPlatformMenu;

  @override
  State<MenuBar> createState() => _MenuBarState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[...menus.map<DiagnosticsNode>((MenuItem item) => item.toDiagnosticsNode())];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MenuBarController>('controller', controller, defaultValue: null));
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED'));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
  }
}

class _MenuBarState extends State<MenuBar> {
  late Map<MenuSerializableShortcut, VoidCallback> shortcuts;
  _MenuBarController? _controller;
  _MenuBarController get controller {
    // Make our own controller if the user didn't provide one.
    if (widget.controller != null) {
      _controller = null;
      return widget.controller! as _MenuBarController;
    }
    return _controller ??= _MenuBarController();
  }

  @override
  void initState() {
    super.initState();
    controller.menuBarContext = context;
    controller.buildMenus(widget.menus);
    controller.addListener(_markDirty);
    _updateShortcuts();
  }

  @override
  void didUpdateWidget(MenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menus != oldWidget.menus) {
      controller.buildMenus(widget.menus);
    }
    _updateShortcuts();
    controller.enabled = widget.enabled;
  }

  void _doSelect(VoidCallback onSelected) {
    onSelected();
    controller.closeAll();
  }

  void _updateShortcuts() {
    shortcuts = <MenuSerializableShortcut, VoidCallback>{};
    _addChildShortcuts(widget.menus);
    // Now wrap each shortcut in a call to _doSelect so that selecting them
    // will close the menus. We didn't do this when building the map because it
    // would preclude duplicate testing.
    shortcuts = shortcuts.map((MenuSerializableShortcut key, VoidCallback value) {
      return MapEntry<MenuSerializableShortcut, VoidCallback>(key, () => _doSelect(value));
    });
  }

  void _addChildShortcuts(List<MenuItem> children) {
    for (final MenuItem child in children) {
      if (child is PlatformMenu) {
        _addChildShortcuts(child.menus);
      } else if (child is PlatformMenuItem) {
        if (child.shortcut != null && child.onSelected != null) {
          if (shortcuts.containsKey(child.shortcut) && shortcuts[child.shortcut!] != child.onSelected) {
            throw FlutterError(
              'More than one menu item is bound to ${child.shortcut}, and they have '
              'different callbacks.\n'
              "A ${child.runtimeType} (i.e. a MenuItem) can't contain the same "
              'shortcut as another menu item if it triggers a different callback. '
              'If your application needs to allow this, assign all the duplicated '
              'shortcuts to the same callback which can then disambiguate which '
              'action to take (or do them all).',
            );
          }
          shortcuts[child.shortcut!] = child.onSelected!;
        }
      } else if (child is PlatformMenuItemGroup) {
        _addChildShortcuts(child.members);
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_markDirty);
    _controller?.dispose();
    super.dispose();
  }

  // Called with the controller changes state.
  void _markDirty() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlatformMenu) {
      return PlatformMenuBar(body: widget.body, menus: widget.menus);
    }
    final List<_Node> components = <_Node>[
      if (controller.openMenu != null) controller.openMenu!,
      if (controller.openMenu != null) ...controller.openMenu!.ancestors,
    ];
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    return _MenuBarControllerMarker(
      controller: controller,
      child: Actions(
        actions: <Type, Action<Intent>>{
          DirectionalFocusIntent: _MenuDirectionalFocusAction(
            controller: controller,
            textDirection: Directionality.of(context),
          ),
          DismissIntent: _MenuDismissAction(controller: controller),
        },
        child: CallbackShortcuts(
          // Handles user shortcuts.
          bindings: controller.enabled ? shortcuts.cast<ShortcutActivator, VoidCallback>() : const <ShortcutActivator, VoidCallback>{},
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Shortcuts(
                      // Make sure that these override any shortcut bindings
                      // from the menu items when a menu is open. If someone
                      // wants to bind an arrow or tab to a menu item, it would
                      // otherwise override the default traversal keys. We want
                      // their shortcut to apply everywhere but in the menu
                      // itself, since there we have to do some special work for
                      // traversing menus.
                      shortcuts: const <ShortcutActivator, Intent>{
                        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                        SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
                        SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
                        SingleActivator(LogicalKeyboardKey.arrowDown):
                            DirectionalFocusIntent(TraversalDirection.down),
                        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
                        SingleActivator(LogicalKeyboardKey.arrowLeft):
                            DirectionalFocusIntent(TraversalDirection.left),
                        SingleActivator(LogicalKeyboardKey.arrowRight):
                            DirectionalFocusIntent(TraversalDirection.right),
                      },
                      child: AnimatedBuilder(
                          animation: controller,
                          builder: (BuildContext context, Widget? ignoredChild) {
                            return _MenuBarTopLevelBar(
                              elevation:
                              widget.elevation ?? menuBarTheme.menuBarElevation ?? _kDefaultMenuBarElevation,
                              height: widget.height ?? menuBarTheme.menuBarHeight,
                              enabled: controller.enabled,
                              color: widget.backgroundColor ??
                                  menuBarTheme.menuBarBackgroundColor ??
                                  MaterialStateProperty.all(Colors.white),
                              preferredHeight:
                              widget.height ?? menuBarTheme.menuBarHeight ?? _kDefaultMenuBarHeight,
                              children: widget.menus,
                            );
                          }),
                    ),
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          // Add an expanded box so that things don't move around
                          // when the ModalBarrier is added to the Stack when a menu
                          // is opened.
                          ConstrainedBox(constraints: const BoxConstraints.expand()),
                          ExcludeFocus(
                            excluding: controller.openMenu != null,
                            child: widget.body,
                          ),
                          if (controller.openMenu != null)
                            ModalBarrier(
                              onDismiss: controller.closeAll,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Build all of the visible submenus.
                ...components.where((_Node menu) => menu.builder != null).map<Widget>((_Node menu) {
                  return Builder(builder: menu.builder!);
                }).toList()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A menu item widget that displays a hierarchical cascading menu as part of a
/// [MenuBar].
///
/// This widget represents an entry in a [MenuBar]. It shows a label and an
/// arrow indicating that it has a submenu, with an optional leading or trailing
/// icon.
///
/// When activated (clicked, through keyboard navigation, or via hovering with
/// a mouse), it will open a submenu containing the children.
///
/// See also:
///
///  * [MenuBarItem], a widget that represents a leaf [MenuBar] item.
///  * [MenuBar], a widget that renders data in a menu hierarchy using
///    Flutter-rendered widgets in a Material Design style.
///  * [PlatformMenuBar], a widget that renders similar menu bar items from a
///    [PlatformMenuBarItem] using platform-native APIs.
class MenuBarMenu extends StatefulWidget implements PlatformMenu {
  /// Creates a const [MenuBarItem].
  ///
  /// The [label] attribute is required.
  const MenuBarMenu({
    Key? key,
    required this.label,
    this.labelWidget,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticLabel,
    this.autofocus = false,
    this.backgroundColor,
    this.shape,
    this.elevation,
    this.onOpen,
    this.onClose,
    this.menus = const <MenuItem>[],
  }) : super(key: key);

  /// A required label displayed on the entry for this item in the menu.
  ///
  /// This is typically a [Text] widget containing the name for the menu item.
  ///
  /// This label is also used as the default [semanticLabel].
  ///
  /// The label appearance can be overridden by using a [labelWidget].
  @override
  final String label;

  /// An optional widget that will be displayed instead of the default label
  /// widget.
  final Widget? labelWidget;

  /// An optional icon to display before the label text.
  final Widget? leadingIcon;

  /// An optional icon to display after the label text.
  final Widget? trailingIcon;

  /// The semantic label to use for this menu item for its [Semantics].
  final String? semanticLabel;

  /// If true, will request focus when first built if nothing else has focus.
  final bool autofocus;

  /// The background color of the cascading menu, if there are [children]
  /// specified.
  ///
  /// Defaults to the value of [MenuBarThemeData.color] value of the
  /// ambient [MenuBarTheme].
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The shape of the cascading menu, if there are [children] specified.
  ///
  /// Defaults to the value of [MenuBarThemeData.menuShape] value of the
  /// ambient [MenuBarTheme].
  final ShapeBorder? shape;

  /// The Material elevation of the submenu (if any).
  ///
  /// Defaults to the [MenuBarThemeData.menuBarElevation] value of the ambient
  /// [MenuBarTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final double? elevation;

  @override
  final VoidCallback? onOpen;

  @override
  final VoidCallback? onClose;

  @override
  VoidCallback? get onSelected => null;

  @override
  final List<MenuItem> menus;

  @override
  State<MenuBarMenu> createState() => _MenuBarMenuState();

  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate, {required int Function(MenuItem) getId}) {
    return <Map<String, Object?>>[PlatformMenu.serialize(this, delegate, getId)];
  }

  @override
  List<MenuItem> get descendants => PlatformMenu.getDescendants(this);

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...menus.map<DiagnosticsNode>((MenuItem child) {
        return child.toDiagnosticsNode();
      })
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(StringProperty('label', label));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
  }
}

class _MenuBarMenuState extends State<MenuBarMenu> {
  _Node? menu;
  bool get isOpen => controller!.openMenu == menu! || (controller!.openMenu?.ancestors.contains(menu) ?? false);
  _MenuBarController? controller;
  bool registered = false;
  Timer? hoverTimer;
  Timer? clickBanTimer;
  bool clickBan = false;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(debugLabel: 'MenuBarMenu(${widget.label})');
  }

  @override
  void dispose() {
    if (menu != null) {
      controller?.unregisterMenu(menu!);
    }
    focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    final _Node newMenu = _MenuNodeWrapper.of(context);
    final _MenuBarController newController = MenuBarController.of(context) as _MenuBarController;
    if (newMenu != menu || newController != controller) {
      controller = newController;
      menu = newMenu;
      newController.registerMenu(
        menuContext: context,
        node: _MenuNodeWrapper.of(context),
        menuBuilder: widget.menus.isNotEmpty ? _buildMenu : null,
        buttonFocus: focusNode,
      );
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MenuBarMenu oldWidget) {
    final _Node newMenu = _MenuNodeWrapper.of(context);
    final _MenuBarController newController = MenuBarController.of(context) as _MenuBarController;
    if (newMenu != menu || newController != controller) {
      controller = newController;
      menu = newMenu;
      controller!.registerMenu(
        menuContext: context,
        node: newMenu,
        menuBuilder: widget.menus.isNotEmpty ? _buildMenu : null,
        buttonFocus: focusNode,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  List<Widget> _expandGroups() {
    final List<Widget> expanded = <Widget>[];
    bool lastWasGroup = false;
    for (final MenuItem item in widget.menus) {
      if (lastWasGroup) {
        expanded.add(const _MenuItemDivider());
      }
      if (item is PlatformMenuItemGroup) {
        expanded.addAll(item.members.cast<Widget>());
        lastWasGroup = true;
      } else {
        expanded.add(item as Widget);
        lastWasGroup = false;
      }
    }
    return expanded;
  }

  // Used as the builder function to register with the controller.
  Widget _buildMenu(BuildContext context) {
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    final double verticalPadding = math.max(2, 8 + Theme.of(context).visualDensity.vertical * 2);
    return _MenuBarMenuList(
      elevation: widget.elevation ?? menuBarTheme.menuElevation ?? _kDefaultMenuBarMenuElevation,
      shape: widget.shape ??
          menuBarTheme.menuShape ??
          const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      backgroundColor: widget.backgroundColor,
      menuPadding: menuBarTheme.menuPadding ?? EdgeInsets.symmetric(vertical: verticalPadding),
      semanticLabel: widget.semanticLabel ?? MaterialLocalizations.of(context).popupMenuLabel,
      textDirection: Directionality.of(context),
      verticalDirection: VerticalDirection.down,
      children: _expandGroups(),
    );
  }

  bool get enabled => controller!.enabled && widget.menus.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: _MenuFocusOrder(menu!),
      child: TextButton(
        autofocus: widget.autofocus,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        focusNode: focusNode,
        onHover: enabled ? _handleMenuHover : null,
        onPressed: enabled ? _maybeToggleShowMenu : null,
        child: _MenuBarItemLabel(
          enabled: enabled,
          leadingIcon: widget.leadingIcon,
          label: widget.labelWidget ?? Text(widget.label),
          trailingIcon: widget.trailingIcon,
          hasSubmenu: widget.menus.isNotEmpty,
        ),
      ),
    );
  }

  // Shows the submenu if there is one, and it wasn't visible. Hides the menu if
  // it was already visible.
  void _maybeToggleShowMenu() {
    if (clickBan) {
      // If we just opened the menu because the user is hovering, then ignore
      // clicks for a bit.
      return;
    }

    if (isOpen) {
      controller!.close(menu!);
    } else {
      controller!.openMenu = menu;
    }
  }

  // Called when the pointer is hovering over the menu button.
  void _handleMenuHover(bool hovering) {
    // Cancel any click ban in place if hover changes.
    clickBanTimer?.cancel();
    clickBanTimer = null;
    clickBan = false;

    // Don't open the top level menu bar buttons on hover unless something else
    // is already open. This means that the user has to first open the menu bar
    // before hovering allows them to traverse it.
    if (menu!.parent == controller!.root && controller!.openMenu == null) {
      return;
    }

    hoverTimer?.cancel();
    if (hovering && !(controller!.openMenu?.ancestors.contains(menu) ?? false) && controller!.openMenu != menu) {
      // Introduce a small delay in switching to a new sub menu, to prevent menus
      // from flashing up and down crazily as the user traverses them.
      hoverTimer = Timer(_kMenuHoverOpenDelay, () {
        controller!.openMenu = menu;
        // If we just opened the menu because the user is hovering, then just
        // ignore any clicks for a bit. Otherwise, the user hovers to the
        // submenu, and sometimes clicks to open it just after the hover timer
        // has run out, causing the menu to open briefly, then immediately
        // close, which is surprising to the user.
        clickBan = true;
        clickBanTimer = Timer(_kMenuHoverClickBanDelay, () {
          clickBan = false;
          clickBanTimer = null;
        });
      });
    } else {
      hoverTimer = null;
    }
  }
}

/// A menu item widget that displays a hierarchical cascading menu as part of a
/// [MenuBar].
///
/// This widget represents a leaf entry in a menu that is part of a menu bar. It
/// shows a label and a hint for an associated shortcut, if any. When clicked it
/// will call its [MenuBar.onSelected] callback.
///
/// See also:
///
///  * [MenuBarMenu], a class that represents a sub menu in a [MenuBar] that
///    contains other [MenuItem]s.
///  * [MenuBar], a class that renders data in a [MenuBarItem] using
///    Flutter-rendered widgets in a Material Design style.
///  * [PlatformMenuBar], a class that renders similar menu bar items from a
///    [PlatformMenuBarItem] using platform-native APIs.
class MenuBarItem extends StatefulWidget implements PlatformMenuItem {
  /// Creates a const [MenuBarItem].
  ///
  /// The [label] attribute is required.
  const MenuBarItem({
    Key? key,
    required this.label,
    this.labelWidget,
    this.shortcut,
    this.onSelected,
    this.autofocus = false,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticLabel,
  }) : super(key: key);

  @override
  final String label;

  /// An optional widget that will be displayed in place of the default [Text]
  /// widget containing the [label].
  final Widget? labelWidget;

  @override
  final MenuSerializableShortcut? shortcut;

  @override
  final VoidCallback? onSelected;

  @override
  VoidCallback? get onOpen => null;

  @override
  VoidCallback? get onClose => null;

  @override
  List<MenuItem> get descendants => const <MenuItem>[];

  /// If true, will request focus when first built if nothing else has focus.
  final bool autofocus;

  /// An optional icon to display before the label text.
  final Widget? leadingIcon;

  /// An optional icon to display after the label text.
  final Widget? trailingIcon;

  /// The semantic label to use for this menu item for its [Semantics].
  final String? semanticLabel;

  @override
  State<MenuBarItem> createState() => _MenuBarItemState();

  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate, {required int Function(MenuItem) getId}) {
    return <Map<String, Object?>>[PlatformMenuItem.serialize(this, delegate, getId)];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: onSelected != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(StringProperty('label', label));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

class _MenuBarItemState extends State<MenuBarItem> {
  bool get isOpen => controller.openMenu == menu;
  late _Node menu;
  late _MenuBarController controller;
  bool registered = false;
  Timer? hoverTimer;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(debugLabel: 'MenuBarItem(${widget.label})');
  }

  @override
  void dispose() {
    hoverTimer?.cancel();
    hoverTimer = null;
    controller.unregisterMenu(menu);
    focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    debugPrint('MenuBarItem.didChangeDependencies(${menu.toStringShort()})');
    final _Node newMenu = _MenuNodeWrapper.of(context);
    final _MenuBarController newController = MenuBarController.of(context) as _MenuBarController;
    if (newMenu != menu || newController != controller) {
      menu = newMenu;
      controller = newController;
      controller.registerMenu(
        menuContext: context,
        node: menu,
        buttonFocus: focusNode,
      );
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MenuBarItem oldWidget) {
    final _Node newMenu = _MenuNodeWrapper.of(context);
    final _MenuBarController newController = MenuBarController.of(context) as _MenuBarController;
    if (newMenu != menu || newController != controller) {
      menu = newMenu;
      controller = newController;
      controller.registerMenu(
        menuContext: context,
        node: menu,
        buttonFocus: focusNode,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  bool get enabled {
    return widget.onSelected != null && controller.enabled;
  }

  void _handleSelect() {
    widget.onSelected?.call();
    controller.closeAll();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      // Define a sort order described by _MenuFocusOrder.
      order: _MenuFocusOrder(menu),
      child: TextButton(
        autofocus: widget.autofocus,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        focusNode: focusNode,
        onHover: enabled ? _handleMenuHover : null,
        onPressed: enabled ? _handleSelect : null,
        child: _MenuBarItemLabel(
          enabled: enabled,
          leadingIcon: widget.leadingIcon,
          label: widget.labelWidget ?? Text(widget.label),
          shortcut: widget.shortcut,
          trailingIcon: widget.trailingIcon,
          hasSubmenu: false,
        ),
      ),
    );
  }

  // Called when the pointer is hovering over the menu button.
  void _handleMenuHover(bool hovering) {
    // Don't open the top level menu bar buttons on hover unless something else
    // is already open. This means that the user has to first open the menu bar
    // before hovering allows them to traverse it.
    if (menu.parent == controller.root && controller.openMenu == null) {
      return;
    }

    hoverTimer?.cancel();
    if (hovering && !(controller.openMenu?.ancestors.contains(menu) ?? false) && controller.openMenu != menu) {
      // Introduce a small delay in switching to a new sub menu, to prevent menus
      // from flashing up and down crazily as the user traverses them.
      hoverTimer = Timer(_kMenuHoverOpenDelay, () {
        controller.openMenu = menu;
      });
    } else {
      hoverTimer = null;
    }
  }
}

class _MenuItemDivider extends StatelessWidget implements PlatformMenuItem {
  /// Creates a [_MenuItemDivider].
  const _MenuItemDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(height: math.max(2, 16 + Theme.of(context).visualDensity.vertical * 4));
  }

  @override
  String get label => '';

  @override
  VoidCallback? get onSelected => null;

  @override
  VoidCallback? get onOpen => null;

  @override
  VoidCallback? get onClose => null;

  @override
  List<MenuItem> get descendants => const <MenuItem>[];

  @override
  MenuSerializableShortcut? get shortcut => null;

  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate, {required int Function(MenuItem) getId}) {
    // This method shouldn't get called, since DefaultPlatformMenuDelegate._expandGroups in
    // platform_menu_bar.dart should skip it.
    throw UnimplementedError('Unexpected call of toChannelRepresentation for _MenuItemDivider');
  }
}

/// A widget that groups [MenuItem]s (e.g. [MenuBarItem]s and [MenuBarMenu]s)
/// into sections delineated by a [Divider].
///
/// It inserts dividers as necessary before and after the group, only inserting
/// them if there are other menu items before or after this group.
class MenuItemGroup extends StatelessWidget implements PlatformMenuItemGroup {
  /// Creates a const [MenuItemGroup].
  ///
  /// The [members] attribute is required.
  const MenuItemGroup({Key? key, required this.members}) : super(key: key);

  @override
  VoidCallback? get onSelected => null;

  @override
  VoidCallback? get onOpen => null;

  @override
  VoidCallback? get onClose => null;

  @override
  List<MenuItem> get descendants => const <MenuItem>[];

  /// The members of this [MenuItemGroup].
  ///
  /// It empty, then this group will not appear in the menu.
  @override
  final List<MenuItem> members;

  /// Converts this [MenuItemGroup] into a data structure accepted by the
  /// 'flutter/menu' method channel method 'Menu.SetMenu'.
  ///
  /// This is used by [PlatformMenuBar] (or when [MenuBar.isPlatformMenu] is
  /// true) when rendering this [MenuItemGroup] using platform APIs.
  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(PlatformMenuDelegate delegate, {required int Function(MenuItem) getId}) {
    // This method shouldn't get called, since DefaultPlatformMenuDelegate._expandGroups in
    // platform_menu_bar.dart should skip it.
    throw UnimplementedError('Unexpected call of toChannelRepresentation for MenuItemGroup');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...members.cast<Widget>(),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<MenuItem>('members', members));
  }
}

/// A widget that manages the top level of menu buttons in a bar.
class _MenuBarTopLevelBar extends StatelessWidget implements PreferredSizeWidget {
  _MenuBarTopLevelBar({
    Key? key,
    required this.enabled,
    required this.elevation,
    required this.height,
    required this.color,
    required double preferredHeight,
    required this.children,
  })  : preferredSize = Size.fromHeight(preferredHeight),
        super(key: key);

  /// Whether or not this [_MenuBarTopLevelBar] is enabled.
  final bool enabled;

  /// The elevation to give the material behind the menu bar.
  final double elevation;

  /// The height to give the menu bar.
  final double? height;

  /// The background color of the menu app bar.
  final MaterialStateProperty<Color?> color;

  @override
  final Size preferredSize;

  /// The list of widgets to use as children of this menu bar.
  ///
  /// These are the top level [MenuBarMenu]s.
  final List<MenuItem> children;

  @override
  Widget build(BuildContext context) {
    final Set<MaterialState> disabled = <MaterialState>{if (!enabled) MaterialState.disabled};
    final Color resolvedColor = color.resolve(disabled) ?? _kDefaultMenuBarColor;
    final _MenuBarController controller = MenuBarController.of(context) as _MenuBarController;
    int index = 0;
    final Widget appBar = Material(
      elevation: elevation,
      color: resolvedColor,
      child: Row(
          children: children.map<Widget>((MenuItem child) {
        final Widget result = _MenuNodeWrapper(
          menu: controller.root.children[index],
          child: child as Widget,
        );
        index += 1;
        return result;
      }).toList()),
    );

    if (height != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: height!),
        child: appBar,
      );
    }
    return appBar;
  }
}

/// A label widget that is used as the default label for a [MenuBarItem] or
/// [MenuBarMenu].
///
/// It not only shows the [MenuBarMenu.label] or [MenuBarItem.label], but if
/// there is a shortcut associated with the [MenuBarItem], it will display a
/// mnemonic for the shortcut. For [MenuBarMenu]s, it will display a visual
/// indicator that there is a submenu.
class _MenuBarItemLabel extends StatelessWidget {
  /// Creates a const [_MenuBarItemLabel].
  ///
  /// The [menuBarItem] argument is required.
  const _MenuBarItemLabel({
    Key? key,
    this.leadingIcon,
    required this.label,
    this.trailingIcon,
    this.shortcut,
    required this.enabled,
    required this.hasSubmenu,
  }) : super(key: key);

  /// The optional icon that comes before the [label].
  final Widget? leadingIcon;

  /// The required label widget.
  final Widget label;

  /// The optional icon that comes after the [label].
  final Widget? trailingIcon;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// Whether or not this menu item should appear to be enabled.
  final bool enabled;

  /// Whether or not this menu has a submenu.
  final bool hasSubmenu;

  @override
  Widget build(BuildContext context) {
    final _MenuBarController controller = MenuBarController.of(context) as _MenuBarController;
    final bool isTopLevelItem = _MenuNodeWrapper.of(context).parent == controller.root;
    final VisualDensity density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(4, 12 + density.horizontal * 2);
    final double verticalPadding = math.max(2, 8 + density.vertical * 2);
    return DefaultTextStyle.merge(
      style: MenuBarTheme.of(context).textStyle?.resolve(<MaterialState>{
        if (!enabled) MaterialState.disabled,
      }),
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: horizontalPadding, top: verticalPadding, bottom: verticalPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 32.0 + density.vertical * 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (leadingIcon != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                      child: leadingIcon,
                    ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                    child: label,
                  ),
                ],
              ),
              if (trailingIcon != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                  child: trailingIcon,
                ),
              if (shortcut != null && !isTopLevelItem)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                  child: Text(
                    LocalizedShortcutLabeler.instance.getShortcutLabel(
                      shortcut!,
                      MaterialLocalizations.of(context),
                    ),
                  ),
                ),
              if (hasSubmenu && !isTopLevelItem)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                  child: const Icon(
                    Icons.arrow_right, // Automatically switches with text direction.
                    size: _kDefaultSubmenuIconSize,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A focus order that sorts items in the order of their place in the menu
/// hierarchy.
///
/// This overrides the default focus order so that hitting "Tab" will not just
/// move in reading order.
class _MenuFocusOrder extends FocusOrder {
  const _MenuFocusOrder(this.menu);

  final _Node menu;

  @override
  int doCompare(_MenuFocusOrder other) => menu.compareTo(other.menu);
}

/// A helper class used to generate shortcut labels for a [ShortcutActivator]
/// that appear in a [MenuBarItem].
///
/// This helper class is typically used by the [MenuBar] class to display a
/// label for the assigned shortcut for a [MenuBarItem].
///
/// Call [getShortcutLabel] with the [ShortcutActivator] you wish to get a label
/// for.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
///
/// To override the label for a [MenuBarItem], pass a [LabeledShortcutActivator]
/// wrapping the original [ShortcutActivator] with the desired shortcut label.
class LocalizedShortcutLabeler {
  /// Creates a [LocalizedShortcutLabeler] from the given
  /// [localizations].
  LocalizedShortcutLabeler._();

  /// Return the instance for this singleton.
  static LocalizedShortcutLabeler get instance {
    return _instance ??= LocalizedShortcutLabeler._();
  }

  static LocalizedShortcutLabeler? _instance;

  // Caches the created shortcut key maps so that creating one of these isn't
  // expensive after the first time for each unique localizations object.
  final Map<MaterialLocalizations, Map<LogicalKeyboardKey, String>> _cachedShortcutKeys =
      <MaterialLocalizations, Map<LogicalKeyboardKey, String>>{};

  static final Map<LogicalKeyboardKey, String> _shortcutGraphicEquivalents = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.arrowLeft: '←',
    LogicalKeyboardKey.arrowRight: '→',
    LogicalKeyboardKey.arrowUp: '↑',
    LogicalKeyboardKey.arrowDown: '↓',
    LogicalKeyboardKey.enter: '↵',
    LogicalKeyboardKey.shift: '⇧',
    LogicalKeyboardKey.shiftLeft: '⇧',
    LogicalKeyboardKey.shiftRight: '⇧',
  };

  static final Set<LogicalKeyboardKey> _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.shiftRight,
  };

  // Tries to look up the key in an internal table, and if it can't find it,
  // then fall back to the key's keyLabel.
  String _getLocalizedName(LogicalKeyboardKey key, MaterialLocalizations localizations) {
    // Since this is an expensive table to build, we cache it based on the
    // localization object. There's currently no way to clear the cache, but
    // it's unlikely that more than one or two will be cached for each run, and
    // they're not huge.
    _cachedShortcutKeys[localizations] ??= <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.altGraph: localizations.keyboardKeyAltGraph,
      LogicalKeyboardKey.backspace: localizations.keyboardKeyBackspace,
      LogicalKeyboardKey.capsLock: localizations.keyboardKeyCapsLock,
      LogicalKeyboardKey.channelDown: localizations.keyboardKeyChannelDown,
      LogicalKeyboardKey.channelUp: localizations.keyboardKeyChannelUp,
      LogicalKeyboardKey.delete: localizations.keyboardKeyDelete,
      LogicalKeyboardKey.eisu: localizations.keyboardKeyEisu,
      LogicalKeyboardKey.eject: localizations.keyboardKeyEject,
      LogicalKeyboardKey.end: localizations.keyboardKeyEnd,
      LogicalKeyboardKey.escape: localizations.keyboardKeyEscape,
      LogicalKeyboardKey.fn: localizations.keyboardKeyFn,
      LogicalKeyboardKey.hangulMode: localizations.keyboardKeyHangulMode,
      LogicalKeyboardKey.hanjaMode: localizations.keyboardKeyHanjaMode,
      LogicalKeyboardKey.hankaku: localizations.keyboardKeyHankaku,
      LogicalKeyboardKey.hiragana: localizations.keyboardKeyHiragana,
      LogicalKeyboardKey.hiraganaKatakana: localizations.keyboardKeyHiraganaKatakana,
      LogicalKeyboardKey.home: localizations.keyboardKeyHome,
      LogicalKeyboardKey.insert: localizations.keyboardKeyInsert,
      LogicalKeyboardKey.kanaMode: localizations.keyboardKeyKanaMode,
      LogicalKeyboardKey.kanjiMode: localizations.keyboardKeyKanjiMode,
      LogicalKeyboardKey.katakana: localizations.keyboardKeyKatakana,
      LogicalKeyboardKey.numLock: localizations.keyboardKeyNumLock,
      LogicalKeyboardKey.numpad1: localizations.keyboardKeyNumpad1,
      LogicalKeyboardKey.numpad2: localizations.keyboardKeyNumpad2,
      LogicalKeyboardKey.numpad3: localizations.keyboardKeyNumpad3,
      LogicalKeyboardKey.numpad4: localizations.keyboardKeyNumpad4,
      LogicalKeyboardKey.numpad5: localizations.keyboardKeyNumpad5,
      LogicalKeyboardKey.numpad6: localizations.keyboardKeyNumpad6,
      LogicalKeyboardKey.numpad7: localizations.keyboardKeyNumpad7,
      LogicalKeyboardKey.numpad8: localizations.keyboardKeyNumpad8,
      LogicalKeyboardKey.numpad9: localizations.keyboardKeyNumpad9,
      LogicalKeyboardKey.numpad0: localizations.keyboardKeyNumpad0,
      LogicalKeyboardKey.numpadAdd: localizations.keyboardKeyNumpadAdd,
      LogicalKeyboardKey.numpadComma: localizations.keyboardKeyNumpadComma,
      LogicalKeyboardKey.numpadDecimal: localizations.keyboardKeyNumpadDecimal,
      LogicalKeyboardKey.numpadDivide: localizations.keyboardKeyNumpadDivide,
      LogicalKeyboardKey.numpadEnter: localizations.keyboardKeyNumpadEnter,
      LogicalKeyboardKey.numpadEqual: localizations.keyboardKeyNumpadEqual,
      LogicalKeyboardKey.numpadMultiply: localizations.keyboardKeyNumpadMultiply,
      LogicalKeyboardKey.numpadParenLeft: localizations.keyboardKeyNumpadParenLeft,
      LogicalKeyboardKey.numpadParenRight: localizations.keyboardKeyNumpadParenRight,
      LogicalKeyboardKey.numpadSubtract: localizations.keyboardKeyNumpadSubtract,
      LogicalKeyboardKey.pageDown: localizations.keyboardKeyPageDown,
      LogicalKeyboardKey.pageUp: localizations.keyboardKeyPageUp,
      LogicalKeyboardKey.power: localizations.keyboardKeyPower,
      LogicalKeyboardKey.powerOff: localizations.keyboardKeyPowerOff,
      LogicalKeyboardKey.printScreen: localizations.keyboardKeyPrintScreen,
      LogicalKeyboardKey.romaji: localizations.keyboardKeyRomaji,
      LogicalKeyboardKey.scrollLock: localizations.keyboardKeyScrollLock,
      LogicalKeyboardKey.select: localizations.keyboardKeySelect,
      LogicalKeyboardKey.space: localizations.keyboardKeySpace,
      LogicalKeyboardKey.zenkaku: localizations.keyboardKeyZenkaku,
      LogicalKeyboardKey.zenkakuHankaku: localizations.keyboardKeyZenkakuHankaku,
    };
    return _cachedShortcutKeys[localizations]![key] ?? key.keyLabel;
  }

  String _getModifierLabel(LogicalKeyboardKey modifier, MaterialLocalizations localizations) {
    assert(_modifiers.contains(modifier), '${modifier.keyLabel} is not a modifier key');
    if (modifier == LogicalKeyboardKey.meta ||
        modifier == LogicalKeyboardKey.metaLeft ||
        modifier == LogicalKeyboardKey.metaRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          return localizations.keyboardKeyMeta;
        case TargetPlatform.windows:
          return localizations.keyboardKeyMetaWindows;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌘';
      }
    }
    if (modifier == LogicalKeyboardKey.alt ||
        modifier == LogicalKeyboardKey.altLeft ||
        modifier == LogicalKeyboardKey.altRight) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyAlt;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌥';
      }
    }
    if (modifier == LogicalKeyboardKey.control ||
        modifier == LogicalKeyboardKey.controlLeft ||
        modifier == LogicalKeyboardKey.controlRight) {
      // '⎈' (a boat helm wheel, not an asterisk) is apparently the standard
      // icon for "control", but only seems to appear on the French Canadian
      // keyboard. A '✲' (an open center asterisk) appears on some Microsoft
      // keyboards. For all but macOS (which has standardized on "⌃", it seems),
      // we just return the local translation of "Ctrl".
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return localizations.keyboardKeyControl;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return '⌃';
      }
    }
    if (modifier == LogicalKeyboardKey.shift ||
        modifier == LogicalKeyboardKey.shiftLeft ||
        modifier == LogicalKeyboardKey.shiftRight) {
      return _shortcutGraphicEquivalents[LogicalKeyboardKey.shift]!;
    }
    throw ArgumentError('Keyboard key ${modifier.keyLabel} is not a modifier.');
  }

  /// Returns the label to be shown to the user in the UI when a
  /// [ShortcutActivator] is used as a keyboard shortcut.
  ///
  /// To keep the representation short, this will return graphical key
  /// representations when it can. For instance, the default
  /// [LogicalKeyboardKey.shift] will return '⇧', and the arrow keys will return
  /// arrows.
  ///
  /// When [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], [LogicalKeyboardKey.meta] the default implementation
  /// will show as '⌘', [LogicalKeyboardKey.control] will show as '˄', and
  /// [LogicalKeyboardKey.alt] will show as '⌥'.
  String getShortcutLabel(MenuSerializableShortcut shortcut, MaterialLocalizations localizations) {
    final MenuSerializableShortcut localShortcut = shortcut;
    if (localShortcut is SingleActivator) {
      final List<String> modifiers = <String>[];
      final LogicalKeyboardKey trigger = localShortcut.trigger;
      // These should be in this order, to match the LogicalKeySet version.
      if (localShortcut.alt) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.alt, localizations));
      }
      if (localShortcut.control) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.control, localizations));
      }
      if (localShortcut.meta) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.meta, localizations));
      }
      if (localShortcut.shift) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.shift, localizations));
      }
      String shortcutTrigger = '';
      final int logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger]!;
      } else if (logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
        // If the trigger is a Unicode-character-producing key, then use the character.
        shortcutTrigger = String.fromCharCode(logicalKeyId & LogicalKeyboardKey.valueMask).toUpperCase();
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger.isNotEmpty) shortcutTrigger,
      ].join(' ');
    }
    if (localShortcut is CharacterActivator) {
      return localShortcut.character;
    }
    throw UnimplementedError('Shortcut labels for ShortcutActivators that are not '
        'SingleActivator, CharacterActivator, or LogicalKeySet are not yet supported.');
  }
}

/// A menu container for [MenuBarItem]s.
///
/// This widget contains a column of widgets, and sizes its width to the widest
/// child, and then forces all the other children to be that same width. It
/// adopts a height large enough to accommodate all the children.
///
/// It is used by [MenuBarMenu] to render its child items.
class _MenuBarMenuList extends StatefulWidget {
  /// Create a const [_MenuBarMenuList].
  ///
  /// All parameters except `key` and [shape] are required.
  const _MenuBarMenuList({
    Key? key,
    this.backgroundColor,
    this.shape,
    required this.elevation,
    required this.menuPadding,
    required this.semanticLabel,
    required this.textDirection,
    required this.verticalDirection,
    required this.children,
  }) : super(key: key);

  /// The background color of this submenu.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The shape of the border on this submenu.
  ///
  /// Defaults to a rectangle.
  final ShapeBorder? shape;

  /// The Material elevation for the menu's shadow.
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final double elevation;

  /// The padding around the inside of the menu panel.
  final EdgeInsets menuPadding;

  /// The semantic label for this submenu.
  final String semanticLabel;

  /// The text direction to use for rendering this menu.
  final TextDirection textDirection;

  /// The vertical direction to use for rendering this menu.
  final VerticalDirection verticalDirection;

  /// The menu items that fill this submenu.
  final List<Widget> children;

  @override
  State<_MenuBarMenuList> createState() => _MenuBarMenuListState();
}

class _MenuBarMenuListState extends State<_MenuBarMenuList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MenuBarMenuList oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    int index = 0;
    final _Node parentMenu = _MenuNodeWrapper.of(context);
    final MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    return Material(
      color: (widget.backgroundColor ?? menuBarTheme.menuBackgroundColor)?.resolve(<MaterialState>{}),
      shape: widget.shape ??
          menuBarTheme.menuShape ??
          const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      elevation: widget.elevation,
      child: _MenuBarMenuRenderWidget(
        padding: widget.menuPadding,
        semanticLabel: widget.semanticLabel,
        textDirection: widget.textDirection,
        verticalDirection: widget.verticalDirection,
        children: widget.children.map<Widget>((Widget child) {
          if (child is _MenuItemDivider) {
            // Don't increment the index for dividers: they're not represented
            // in the node tree.
            return child;
          }
          final Widget result = _MenuNodeWrapper(menu: parentMenu.children[index], child: child);
          index += 1;
          return result;
        }).toList(),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', widget.backgroundColor));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', widget.shape, defaultValue: null));
    properties.add(DoubleProperty('elevation', widget.elevation));
    properties.add(DiagnosticsProperty<EdgeInsets>('menuPadding', widget.menuPadding));
    properties.add(StringProperty('semanticLabel', widget.semanticLabel));
    properties.add(EnumProperty<TextDirection>('textDirection', widget.textDirection));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', widget.verticalDirection));
  }
}

/// A render widget for laying out menu bar items.
///
/// It finds the widest child, and then forces all of the other children to be
/// that width.
class _MenuBarMenuRenderWidget extends MultiChildRenderObjectWidget {
  /// Creates a const [_MenuBarMenuRenderWidget].
  ///
  /// The `children` and [padding] arguments are required.
  _MenuBarMenuRenderWidget({
    Key? key,
    required List<Widget> children,
    required this.padding,
    this.semanticLabel,
    this.textDirection,
    this.verticalDirection,
  }) : super(key: key, children: children);

  final EdgeInsets padding;

  /// The semantic label for this menu.
  ///
  /// Defaults to [MaterialLocalizations.popupMenuLabel].
  // TODO(gspencergoog): this should probably use its own label, not popupMenuLabel.
  final String? semanticLabel;

  /// The text direction to use for rendering this menu.
  ///
  /// Defaults to the ambient text direction from [Directionality.of].
  final TextDirection? textDirection;

  /// The vertical direction to use for rendering this menu.
  ///
  /// Defaults to [VerticalDirection.down].
  final VerticalDirection? verticalDirection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuBarMenu(
      padding: padding,
      semanticLabel: semanticLabel ?? MaterialLocalizations.of(context).popupMenuLabel,
      textDirection: textDirection ?? Directionality.of(context),
      verticalDirection: verticalDirection ?? VerticalDirection.down,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderMenuBarMenu renderObject) {
    renderObject
      ..padding = padding
      ..semanticLabel = semanticLabel ?? MaterialLocalizations.of(context).popupMenuLabel
      ..textDirection = textDirection ?? Directionality.of(context)
      ..verticalDirection = verticalDirection ?? VerticalDirection.down;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

class _RenderMenuBarMenuParentData extends ContainerBoxParentData<RenderBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

class _LayoutSizes {
  const _LayoutSizes({
    required this.crossSize,
    required this.allocatedSize,
  });

  final double crossSize;
  final double allocatedSize;
}

class _RenderMenuBarMenu extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RenderMenuBarMenuParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RenderMenuBarMenuParentData>,
        DebugOverflowIndicatorMixin {
  _RenderMenuBarMenu({
    required EdgeInsets padding,
    required String semanticLabel,
    required TextDirection textDirection,
    required VerticalDirection verticalDirection,
  })  : _padding = padding,
        _semanticLabel = semanticLabel,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection;

  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (_padding != value) {
      _padding = value;
      markNeedsLayout();
    }
  }

  String get semanticLabel => _semanticLabel;
  String _semanticLabel;
  set semanticLabel(String value) {
    if (value != _semanticLabel) {
      _semanticLabel = value;
      markNeedsLayout();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RenderMenuBarMenuParentData) {
      child.parentData = _RenderMenuBarMenuParentData();
    }
  }

  double _getIntrinsicSize({
    required Axis sizingDirection,
    required double extent, // the extent in the direction that isn't the sizing direction
    required _ChildSizingFunction childSize, // a method to find the size in the sizing direction
  }) {
    if (sizingDirection == Axis.vertical) {
      double inflexibleSpace = 0.0;
      RenderBox? child = firstChild;
      while (child != null) {
        inflexibleSpace += childSize(child, extent) + padding.vertical;
        final _RenderMenuBarMenuParentData childParentData = child.parentData! as _RenderMenuBarMenuParentData;
        child = childParentData.nextSibling;
      }
      return inflexibleSpace;
    } else {
      double maxCrossSize = 0.0;
      RenderBox? child = firstChild;
      while (child != null) {
        final double mainSize = child.getMaxIntrinsicHeight(double.infinity);
        final double crossSize = childSize(child, mainSize) + padding.horizontal;
        maxCrossSize = math.max(maxCrossSize, crossSize);
        final _RenderMenuBarMenuParentData childParentData = child.parentData! as _RenderMenuBarMenuParentData;
        child = childParentData.nextSibling;
      }
      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  _LayoutSizes _computeSizes({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
    assert(constraints != null);

    double crossSize = 0.0;
    double allocatedSize = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      final _RenderMenuBarMenuParentData childParentData = child.parentData! as _RenderMenuBarMenuParentData;
      final BoxConstraints innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
      final Size childSize = layoutChild(child, innerConstraints);
      allocatedSize += childSize.height;
      crossSize = math.max(crossSize, childSize.width);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    // Make a second pass, fixing the width of the children at the size of the
    // widest one.
    child = firstChild;
    final BoxConstraints innerConstraints = BoxConstraints.tightFor(width: crossSize);
    while (child != null) {
      final _RenderMenuBarMenuParentData childParentData = child.parentData! as _RenderMenuBarMenuParentData;
      layoutChild(child, innerConstraints);
      child = childParentData.nextSibling;
    }

    return _LayoutSizes(
      crossSize: crossSize + padding.horizontal,
      allocatedSize: allocatedSize + padding.vertical,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final _LayoutSizes sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      constraints: constraints,
    );

    return constraints.constrain(Size(sizes.crossSize, sizes.allocatedSize));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    final _LayoutSizes sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.layoutChild,
      constraints: constraints,
    );

    double actualSize = sizes.allocatedSize;
    double crossSize = sizes.crossSize;

    // Align items along the main axis.
    size = constraints.constrain(Size(crossSize, actualSize));
    actualSize = size.height;
    crossSize = size.width;
    late final double leadingSpace;
    // flipMainAxis is used to decide whether to lay out
    // left-to-right/top-to-bottom (false), or right-to-left/bottom-to-top
    // (true). The _startIsTopLeft will return null if there's only one child
    // and the relevant direction is null, in which case we arbitrarily decide
    // not to flip, but that doesn't have any detectable effect.
    final bool flipMainAxis = !(_startIsTopLeft(Axis.vertical, textDirection, verticalDirection) ?? true);
    leadingSpace = padding.top;

    // Position elements
    double childMainPosition = flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    RenderBox? child = firstChild;
    while (child != null) {
      final _RenderMenuBarMenuParentData childParentData = child.parentData! as _RenderMenuBarMenuParentData;
      final double childCrossPosition;
      childCrossPosition = padding.left;
      if (flipMainAxis) {
        childMainPosition -= child.size.height;
      }
      childParentData.offset = Offset(childCrossPosition, childMainPosition);
      if (!flipMainAxis) {
        childMainPosition += child.size.height;
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  static bool? _startIsTopLeft(Axis direction, TextDirection? textDirection, VerticalDirection? verticalDirection) {
    assert(direction != null);
    // If the relevant value of textDirection or verticalDirection is null, this returns null too.
    switch (direction) {
      case Axis.horizontal:
        switch (textDirection) {
          case TextDirection.ltr:
            return true;
          case TextDirection.rtl:
            return false;
          case null:
            return null;
        }
      case Axis.vertical:
        switch (verticalDirection) {
          case VerticalDirection.down:
            return true;
          case VerticalDirection.up:
            return false;
          case null:
            return null;
        }
    }
  }
}

/// An inherited widget used to provide its subtree with a [_Node], so that the
/// children of a [MenuBar] can find their associated [_Node]s without having to
/// be stateful widgets.
///
/// This is how a [MenuBarItem] knows what it's location in the menu tree is: it
/// looks up the nearest [_MenuNodeWrapper] and asks for the [_Node].
@immutable
class _MenuNodeWrapper extends InheritedWidget {
  const _MenuNodeWrapper({
    Key? key,
    required this.menu,
    required Widget child,
  }) : super(key: key, child: child);

  final _Node menu;

  static _Node of(BuildContext context) {
    final _MenuNodeWrapper? wrapper = context.dependOnInheritedWidgetOfExactType<_MenuNodeWrapper>();
    assert(wrapper != null, 'Missing _MenuNodeWrapper for $context');
    return wrapper!.menu;
  }

  @override
  bool updateShouldNotify(_MenuNodeWrapper oldWidget) {
    return oldWidget.menu != menu || oldWidget.child != child;
  }
}
