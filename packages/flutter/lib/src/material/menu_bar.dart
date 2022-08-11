// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'color_scheme.dart';
import 'divider.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'menu_theme.dart';
import 'text_button.dart';
import 'text_button_theme.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

// Enable if you want verbose logging about menu changes.
const bool _kDebugMenus = false;

bool _menuDebug(String message, [Iterable<String>? details]) {
  if (_kDebugMenus) {
    debugPrint('MENU: $message');
    if (details != null && details.isNotEmpty) {
      for (final String detail in details) {
        debugPrint('    $detail');
      }
    }
  }
  // Return true so that it can be easily used inside of an assert.
  return true;
}

// The default size of the arrow in _MenuItemLabel that indicates that a menu
// has a submenu.
const double _kDefaultSubmenuIconSize = 24.0;

// The default spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 18.0;

// The minimum spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4.0;

// The minimum horizontal spacing on the outside of the top level menu.
const double _kTopLevelMenuHorizontalMinPadding = 4.0;

// Navigation shortcuts that we need to make sure are active when menus are
// open.
const Map<ShortcutActivator, Intent> _kMenuTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
};

/// A menu bar that manages cascading child menus.
///
/// This is a Material Design menu bar that typically resides above the main
/// body of an application (but can go anywhere) that defines a menu system for
/// invoking callbacks or firing [Intent]s in response to user selection of a
/// menu item.
///
/// The menus can be opened with a click or tap. Once a menu is opened, it can
/// be navigated by using the arrow and tab keys or via mouse hover. Selecting a
/// menu item can be done by pressing enter, or by clicking or tapping on the
/// menu item. Clicking or tapping on any part of the user interface that isn't
/// part of the menu system controlled by the same controller will cause all of
/// the menus controlled by that controller to close, as will pressing the
/// escape key.
///
/// {@template flutter.material.menu_bar.shortcuts_note}
/// Menu items using [MenuItemButton] can have a [SingleActivator] or
/// [CharacterActivator] assigned to them as their [MenuItemButton.shortcut],
/// which will display an appropriate shortcut hint. Shortcuts are not
/// automatically registered, they must be available in the context that the
/// [MenuBar] resides in, and registered via another mechanism.
///
/// If shortcuts should be generally enabled, but are not easily defined in the
/// context surrounding the menu bar, consider using a [ShortcutRegistry] to
/// register them. To be sure that selecting a menu item and triggering the
/// shortcut do the same thing, it is recommended that they trigger the same
/// [Intent] or call the same callback.
/// {@endtemplate}
///
/// Selecting a menu item causes the [MenuItemButton.onSelected] callback to be
/// called, or the [MenuItemButton.onSelectedIntent] intent to be fired,
/// depending on which is set.
///
/// When a menu item with a submenu is clicked on, it toggles the visibility of
/// the submenu. When the menu item is hovered over, the submenu will open, and
/// hovering over other items will close the previous menu and open the newly
/// hovered one. When those occur, [MenuButton.onOpen], and
/// [MenuButton.onClose] are called on the corresponding [MenuButton] child of
/// the menu bar.
///
/// {@tool dartpad}
/// This example shows a [MenuBar] that contains a single top level menu,
/// containing three items for "About", a checkbox menu item for showing a
/// message, and "Quit". The items are identified with an enum value.
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [MenuButton], a menu item which manages a submenu.
/// * [MenuItemGroup], a menu item which collects its members into a group
///   separated from other menu items by a divider.
/// * [MenuItemButton], a leaf menu item which displays the label, an optional
///   shortcut label, and optional leading and trailing icons.
/// * [createCascadingMenu], a function that creates a [MenuEntry] that allows
///   creation and management of a cascading menu anywhere.
/// * [MenuController], a class that allows controlling and connecting menus.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent] to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that simply call a callback and
///   don't involve using [Actions].
class MenuBar extends StatefulWidget with DiagnosticableTreeMixin {
  /// Creates a const [MenuBar].
  const MenuBar({
    super.key,
    this.controller,
    this.backgroundColor,
    this.minimumHeight,
    this.padding,
    this.elevation,
    this.shape,
    this.expand = true,
    this.children = const <Widget>[],
  });

  /// An optional controller that allows outside control of the menu bar.
  ///
  /// You can use a controller to close any open menus from outside of the menu
  /// bar using [MenuController.closeAll].
  final MenuController? controller;

  /// The background color of the menu bar.
  ///
  /// This is a [MaterialStateProperty], but [MenuBar] doesn't currently have
  /// any states for it to respond to. Use [MaterialStatePropertyAll] to
  /// initialize it.
  ///
  /// Defaults to [MenuThemeData.barBackgroundColor] if null.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The preferred minimum height of the menu bar.
  ///
  /// Defaults to the value of [MenuThemeData.barMinimumHeight] if null.
  final double? minimumHeight;

  /// The padding around the contents of the menu bar itself.
  ///
  /// Defaults to the value of [MenuThemeData.barPadding] if null.
  final EdgeInsetsDirectional? padding;

  /// The shape of the [MenuBar]'s border.
  ///
  /// This is a [MaterialStateProperty], but [MenuBar] doesn't currently have
  /// any states for it to respond to. Use [MaterialStatePropertyAll] to
  /// initialize it.
  ///
  /// Default to [MenuThemeData.barShape] if null.
  final MaterialStateProperty<ShapeBorder?>? shape;

  /// If true, the menu bar expands horizontally to fill available space.
  ///
  /// Defaults to true.
  final bool expand;

  /// The Material elevation of the menu bar (if any).
  ///
  /// This is a [MaterialStateProperty], but [MenuBar] doesn't currently have
  /// any states for it to respond to. Use [MaterialStatePropertyAll] to
  /// initialize it.
  ///
  /// Defaults to the [MenuThemeData.barElevation] value of the ambient
  /// [MenuTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation implies.
  final MaterialStateProperty<double?>? elevation;

  /// The list of menu items that are the top level children of the
  /// [MenuBar].
  ///
  /// A Widget in Flutter is immutable, so directly modifying the `children`
  /// with [List] APIs such as `someMenuBarWidget.menus.add(...)` will result in
  /// incorrect behaviors. Whenever the menus list is modified, a new list
  /// object should be provided.
  ///
  /// {@macro flutter.material.menu_bar.shortcuts_note}
  final List<Widget> children;

  @override
  State<MenuBar> createState() => _MenuBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MenuController?>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<double?>('minimumHeight', minimumHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>?>('elevation', elevation, defaultValue: null));
  }
}

class _MenuBarState extends State<MenuBar> with DiagnosticableTreeMixin {
  MenuController? _internalController;
  MenuController get controller {
    return widget.controller ?? (_internalController ??= MenuController());
  }

  @override
  void initState() {
    super.initState();
    assert(() {
      controller._root.menuScopeNode.debugLabel = 'MenuBar';
      return true;
    }());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant MenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    final MenuThemeData menuTheme = MenuTheme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? ignoredChild) {
        return ExcludeFocus(
          excluding: !controller.menuIsOpen,
          child: TapRegion(
            groupId: controller,
            onTapOutside: (PointerDownEvent event) {
              controller.closeAll();
            },
            child: _MenuControllerMarker(
              controller: controller,
              child: FocusScope(
                node: controller._root.menuScopeNode,
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    DirectionalFocusIntent: _MenuDirectionalFocusAction(controller: controller),
                    DismissIntent: _MenuDismissAction(controller: controller),
                  },
                  child: Shortcuts(
                    shortcuts: _kMenuTraversalShortcuts,
                    child: _MenuPanel(
                      elevation: (widget.elevation ?? menuTheme.barElevation ?? _TokenDefaultsM3(context).barElevation)
                          .resolve(const <MaterialState>{})!,
                      crossAxisMinSize: widget.minimumHeight ??
                          menuTheme.barMinimumHeight ??
                          _TokenDefaultsM3(context).barMinimumHeight,
                      color: (widget.backgroundColor ??
                              menuTheme.barBackgroundColor ??
                              _TokenDefaultsM3(context).barBackgroundColor)
                          .resolve(const <MaterialState>{})!,
                      padding: widget.padding ?? menuTheme.barPadding ?? _TokenDefaultsM3(context).barPadding,
                      orientation: Axis.horizontal,
                      shape: (widget.shape ?? menuTheme.barShape ?? _TokenDefaultsM3(context).barShape)!
                          .resolve(const <MaterialState>{})!,
                      expand: widget.expand,
                      children: MenuItemGroup._expandGroups(widget.children, Axis.horizontal),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[...widget.children.map<DiagnosticsNode>((Widget item) => item.toDiagnosticsNode())];
  }
}

/// An button for use in a [MenuBar] that can be activated by click or keyboard
/// navigation that displays a shortcut hint and optional leading/trailing
/// icons.
///
/// This widget represents a leaf entry in a menu that is part of a [MenuBar].
/// It shows a hint for an associated shortcut, if any. When selected via click,
/// hitting enter while focused, or activating the associated [shortcut], it
/// will call its [onSelected] callback or fire its [onSelectedIntent] intent,
/// depending on which is defined. If neither is defined, then this item will be
/// disabled.
///
/// {@macro flutter.material.menu_bar.shortcuts_note}
///
/// See also:
///
/// * [MenuBar], a class that creates a top level menu bar in a Material Design
///   style.
/// * [MenuButton], a menu item which manages a submenu.
/// * [MenuItemGroup], a menu item which collects its members into a group
///   separated from other menu items by a divider.
/// * [MenuItemButton], a leaf menu item which displays the label, an optional
///   shortcut label, and optional leading and trailing icons.
/// * [createCascadingMenu], a function that creates a [MenuEntry] that allows
///   creation and management of a cascading menu anywhere.
/// * [MenuController], a class that allows controlling and connecting menus.
/// * [PlatformMenuBar], which creates a menu bar that is rendered by the host
///   platform instead of by Flutter (on macOS, for example).
/// * [ShortcutRegistry], a registry of shortcuts that apply for the entire
///   application.
/// * [VoidCallbackIntent] to define intents that will call a [VoidCallback] and
///   work with the [Actions] and [Shortcuts] system.
/// * [CallbackShortcuts] to define shortcuts that simply call a callback and
///   don't involve using [Actions].
/// * [PlatformMenuBar], a class that renders similar menu bar items from a
///   [PlatformMenuItem] using platform-native APIs.
class MenuItemButton extends StatefulWidget {
  /// Creates a const [MenuItemButton].
  ///
  /// The [label] attribute is required.
  const MenuItemButton({
    super.key,
    this.shortcut,
    this.onSelected,
    this.onSelectedIntent,
    this.onHover,
    this.focusNode,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticsLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.textStyle,
    this.padding,
    this.shape,
    required this.label,
  }) : assert(onSelected == null || onSelectedIntent == null,
            'Only one of onSelected or onSelectedIntent may be specified');

  /// A required widget displaying the label for this item in the menu.
  final Widget label;

  /// The optional shortcut that selects this [MenuItemButton].
  ///
  /// This shortcut is only enabled when [onSelected] is set.
  final MenuSerializableShortcut? shortcut;

  /// The function called when the mouse leaves or enters this menu item's
  /// button.
  final ValueChanged<bool>? onHover;

  /// Returns a callback, if any, to be invoked if the platform menu receives a
  /// "Menu.selectedCallback" method call from the platform for this item.
  ///
  /// Only items that do not have submenus will have this callback invoked.
  ///
  /// Only one of [onSelected] or [onSelectedIntent] may be specified.
  ///
  /// If neither [onSelected] nor [onSelectedIntent] are specified, then this
  /// menu item is considered to be disabled.
  ///
  /// The default implementation returns null.
  final VoidCallback? onSelected;

  /// Returns an intent, if any, to be invoked if the platform receives a
  /// "Menu.selectedCallback" method call from the platform for this item.
  ///
  /// Only items that do not have submenus will have this intent invoked.
  ///
  /// Only one of [onSelected] or [onSelectedIntent] may be specified.
  ///
  /// If neither [onSelected] nor [onSelectedIntent] are specified, then this
  /// menu item is considered to be disabled.
  ///
  /// The default implementation returns null.
  final Intent? onSelectedIntent;

  /// The focus node to use for the menu item button.
  final FocusNode? focusNode;

  /// An optional icon to display before the [label] label.
  final Widget? leadingIcon;

  /// An optional icon to display after the [label] label.
  final Widget? trailingIcon;

  /// The semantic label of the menu item used by accessibility frameworks to
  /// announce its label when the menu is focused.
  ///
  /// This semantics information will take precedence over semantics information
  /// provided in [label].
  final String? semanticsLabel;

  /// The background color for this [MenuItemButton].
  ///
  /// Defaults to the ambient [Theme]'s [ColorScheme.surface] if null.
  ///
  /// See also:
  ///
  /// * [MenuThemeData.itemBackgroundColor], for the value in the [MenuTheme]
  ///   that can be set instead of this property.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The foreground color for this [MenuItemButton].
  ///
  /// Defaults to the ambient [Theme]'s [ColorScheme.primary] if null.
  ///
  /// See also:
  ///
  /// * [MenuThemeData.itemForegroundColor], for the value in the [MenuTheme]
  ///   that can be set instead of this property.
  final MaterialStateProperty<Color?>? foregroundColor;

  /// The overlay color for this [MenuItemButton].
  ///
  /// Defaults to the ambient [Theme]'s [ColorScheme.primary] (with appropriate
  /// state-dependent opacity) if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemOverlayColor], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<Color?>? overlayColor;

  /// The padding around the contents of the [MenuItemButton].
  ///
  /// Defaults to zero in the vertical direction, and 24 pixels on each side in
  /// the horizontal direction.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemPadding], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final EdgeInsetsDirectional? padding;

  /// The text style for the text in this menu bar item.
  ///
  /// May be overridden inside of [label].
  ///
  /// Defaults to the ambient [ThemeData.textTheme]'s [TextTheme.labelLarge] if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemTextStyle], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<TextStyle?>? textStyle;

  /// The shape of this menu bar item.
  ///
  /// Defaults to a [RoundedRectangleBorder] with a border radius of zero (i.e.
  /// a rectangle) if null.
  ///
  /// See also:
  ///
  ///  * [MenuThemeData.itemShape], for the value in the [MenuTheme] that
  ///    can be set instead of this property.
  final MaterialStateProperty<OutlinedBorder?>? shape;

  @override
  State<MenuItemButton> createState() => _MenuItemButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', label.toString(), defaultValue: null));
    properties.add(FlagProperty('enabled', value: onSelected != null || onSelectedIntent != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticsLabel', semanticsLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('foregroundColor', foregroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('overlayColor', overlayColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('textStyle', textStyle, defaultValue: null));
  }
}

class _MenuItemButtonState extends State<MenuItemButton> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode {
    final FocusNode result = widget.focusNode ?? (_internalFocusNode ??= FocusNode());
    assert(() {
      if (_internalFocusNode != null) {
        _internalFocusNode!.debugLabel = '$MenuItemButton(${widget.label})';
      }
      return true;
    }());
    return result;
  }

  bool get _enabled {
    return widget.onSelected != null || widget.onSelectedIntent != null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(MenuItemButton oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      _MenuNode.maybeOf(context)?.closeChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MenuThemeData menuTheme = MenuTheme.of(context);
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(context);
    final Size densityAdjustedSize = const Size(64, 48) + Theme.of(context).visualDensity.baseSizeAdjustment;
    final MaterialStateProperty<EdgeInsetsDirectional?> resolvedPadding =
        MaterialStateProperty.all<EdgeInsetsDirectional?>(
            widget.padding ?? menuTheme.itemPadding ?? defaultTheme.itemPadding);
    return Semantics(
      enabled: _enabled,
      label: widget.semanticsLabel,
      child: TextButton(
        style: (TextButtonTheme.of(context).style ?? const ButtonStyle()).copyWith(
          minimumSize: MaterialStateProperty.all<Size?>(densityAdjustedSize),
          backgroundColor: widget.backgroundColor ?? menuTheme.itemBackgroundColor ?? defaultTheme.itemBackgroundColor,
          foregroundColor: widget.foregroundColor ?? menuTheme.itemForegroundColor ?? defaultTheme.itemForegroundColor,
          overlayColor: widget.overlayColor ?? menuTheme.itemOverlayColor ?? defaultTheme.itemOverlayColor,
          padding: resolvedPadding,
          shape: widget.shape ?? menuTheme.itemShape ?? defaultTheme.itemShape,
          textStyle: widget.textStyle ?? menuTheme.itemTextStyle ?? defaultTheme.itemTextStyle,
        ),
        focusNode: _focusNode,
        onHover: _enabled ? _handleHover : null,
        onPressed: _enabled ? _handleSelect : null,
        child: _MenuItemLabel(
          key: ValueKey<MenuSerializableShortcut?>(widget.shortcut),
          leadingIcon: widget.leadingIcon,
          shortcut: widget.shortcut,
          trailingIcon: widget.trailingIcon,
          hasSubmenu: false,
          child: widget.label,
        ),
      ),
    );
  }

  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);
    if (hovering) {
      setState(() {
        assert(_menuDebug('Requesting focus for $_focusNode from hover'));
        _focusNode.requestFocus();
      });
    }
  }

  void _handleSelect() {
    assert(_menuDebug('Selected ${widget.label} menu'));
    if (widget.onSelectedIntent != null) {
      Actions.invoke<Intent>(context, widget.onSelectedIntent!);
    } else {
      widget.onSelected?.call();
    }
    MenuController.of(context).closeAll();
  }
}

/// A menu item widget that displays a hierarchical cascading menu as part of a
/// [MenuBar].
///
/// This widget represents an item in a [MenuBar] that has a submenu. Like the
/// leaf [MenuItemButton], it shows a label with an optional leading or trailing
/// icon.
///
/// By default the submenu will appear to the side of the controlling button.
/// The alignment and offset of the submenu can be controlled by setting
/// [alignment] and [alignmentOffset], respectively.
///
/// When activated (clicked, through keyboard navigation, or via hovering with a
/// mouse), it will open a submenu containing the [children].
///
/// See also:
///
/// * [MenuItemButton], a widget that represents a leaf [MenuBar] item that does
///   not host a submenu.
/// * [MenuBar], a widget that renders data in a menu hierarchy using
///   Flutter-rendered widgets in a Material Design style.
/// * [PlatformMenuBar], a widget that renders similar menu bar items from a
///   [PlatformMenuItem] using platform-native APIs.
class MenuButton extends StatefulWidget {
  /// Creates a const [MenuButton].
  ///
  /// The [label] attribute is required.
  const MenuButton({
    super.key,
    required this.label,
    this.alignment,
    this.alignmentOffset,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticsLabel,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.shape,
    this.elevation,
    this.padding,
    this.buttonPadding,
    this.buttonBackgroundColor,
    this.buttonForegroundColor,
    this.buttonOverlayColor,
    this.buttonShape,
    this.buttonTextStyle,
    this.onOpen,
    this.onClose,
    this.onHover,
    required this.children,
  });

  /// A required label widget displayed on this item in the menu.
  final Widget label;

  /// Determines the alignment of the submenu when opened relative to the button
  /// that opens it.
  ///
  /// Defaults to [AlignmentDirectional.topEnd].
  final AlignmentGeometry? alignment;

  /// The offset in pixels of the menu relative to the alignment origin
  /// determined by [alignment].
  ///
  /// Use this for fine adjustments of the menu placement.
  ///
  /// Defaults to the start portion of [MenuThemeData.menuPadding] for menus
  /// whose parent menu (the menu that the button for this menu resides in) is
  /// vertical, and the top portion of [MenuThemeData.menuPadding] when it is
  /// horizontal
  final Offset? alignmentOffset;

  /// An optional icon to display before the [label].
  final Widget? leadingIcon;

  /// An optional icon to display after the [label].
  final Widget? trailingIcon;

  /// The semantic label to use for this menu item for its [Semantics].
  ///
  /// By default uses the semantics of the [label] widget.
  final String? semanticsLabel;

  /// The focus node to use for this menu item's button.
  final FocusNode? focusNode;

  /// If true, the menu button will request focus when first built if nothing
  /// else has focus.
  final bool autofocus;

  /// The background color of the cascading menu specified by [children].
  ///
  /// Defaults to the value of [MenuThemeData.menuBackgroundColor] of the
  /// ambient [MenuTheme].
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The shape of the cascading menu specified by [children].
  ///
  /// Defaults to the value of [MenuThemeData.menuShape] of the
  /// ambient [MenuTheme].
  final MaterialStateProperty<ShapeBorder?>? shape;

  /// The Material elevation of the submenu (if any).
  ///
  /// Defaults to the [MenuThemeData.barElevation] of the ambient
  /// [MenuTheme].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of what elevation is.
  final MaterialStateProperty<double?>? elevation;

  /// The padding around the outside of the contents of the menu opened by a
  /// [MenuButton].
  ///
  /// Defaults to the [MenuThemeData.menuPadding] value of the ambient
  /// [MenuTheme].
  final EdgeInsetsDirectional? padding;

  /// The padding around the outside of the button that opens a [MenuButton]'s
  /// submenu.
  ///
  /// Defaults to the [MenuThemeData.itemPadding] value of the ambient
  /// [MenuTheme].
  final EdgeInsetsDirectional? buttonPadding;

  /// The background color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemBackgroundColor] value of
  /// the ambient [MenuTheme].
  final MaterialStateProperty<Color?>? buttonBackgroundColor;

  /// The foreground color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemForegroundColor] value of
  /// the ambient [MenuTheme].
  final MaterialStateProperty<Color?>? buttonForegroundColor;

  /// The overlay color of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemOverlayColor] value of
  /// the ambient [MenuTheme].
  final MaterialStateProperty<Color?>? buttonOverlayColor;

  /// The shape of the button that opens the submenu.
  ///
  /// Defaults to the value of [MenuThemeData.itemShape] value of the
  /// ambient [MenuTheme].
  final MaterialStateProperty<OutlinedBorder?>? buttonShape;

  /// The text style of the button that opens the submenu.
  ///
  /// The color in this text style will only be used if [buttonOverlayColor]
  /// is unset.
  final MaterialStateProperty<TextStyle?>? buttonTextStyle;

  /// Called when the button that opens the submenu is hovered over.
  final ValueChanged<bool>? onHover;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// The list of widgets that appear in the menu when it is opened.
  ///
  /// These can be any widget, but are typically either [MenuItemButton] or
  /// [MenuButton] widgets.
  final List<Widget> children;

  @override
  State<MenuButton> createState() => _MenuButtonState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...children.map<DiagnosticsNode>((Widget child) {
        return child.toDiagnosticsNode();
      })
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', label.toString(), defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticsLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<double?>>('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional?>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional?>('buttonPadding', buttonPadding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('buttonBackgroundColor', buttonBackgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('buttonForegroundColor', buttonForegroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('buttonOverlayColor', buttonOverlayColor, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('buttonShape', buttonShape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('buttonTextStyle', buttonTextStyle, defaultValue: null));
  }
}

class _MenuButtonState extends State<MenuButton> {
  late _ChildMenuNode entry;
  MenuEntry? childMenu;
  bool get _enabled => widget.children.isNotEmpty;
  late FocusScopeNode menuScopeNode;
  FocusNode? _internalFocusNode;
  MenuController? _internalMenuController;

  FocusNode get _buttonFocusNode {
    final FocusNode result = widget.focusNode ?? (_internalFocusNode ??= FocusNode());
    assert(() {
      if (_internalFocusNode != null) {
        _internalFocusNode!.debugLabel = '$MenuButton(${widget.label})';
      }
      return true;
    }());
    return result;
  }

  @override
  void initState() {
    super.initState();
    menuScopeNode = FocusScopeNode();
    assert(() {
      menuScopeNode.debugLabel = '$MenuButton(Scope for ${widget.label})';
      return true;
    }());
    _buttonFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    menuScopeNode.dispose();
    entry.dispose();
    _internalFocusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalMenuController?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateChildMenu();
  }

  @override
  void didUpdateWidget(MenuButton oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChange);
      }
      _buttonFocusNode.addListener(_handleFocusChange);
    }
    _updateChildMenu();
    super.didUpdateWidget(oldWidget);
  }

  void _updateChildMenu() {
    final MenuController controller = MenuController.maybeOf(context) ?? (_internalMenuController ??= MenuController());
    final _MenuNode parent = _MenuNode.maybeOf(context) ?? controller._root;
    final AlignmentGeometry menuAlignment;
    switch (parent.orientation) {
      case Axis.horizontal:
        menuAlignment = widget.alignment ?? AlignmentDirectional.bottomStart;
        break;
      case Axis.vertical:
        menuAlignment = widget.alignment ?? AlignmentDirectional.topEnd;
        break;
    }

    final MenuThemeData menuTheme = MenuTheme.of(context).copyWith(
      menuBackgroundColor: widget.backgroundColor,
      menuShape: widget.shape,
      menuPadding: widget.padding,
    );

    final EdgeInsetsDirectional menuPadding =
        menuTheme.menuPadding ?? MenuTheme.of(context).menuPadding ?? _TokenDefaultsM3(context).menuPadding;

    final Offset menuPaddingOffset;
    switch (parent.orientation) {
      case Axis.horizontal:
        menuPaddingOffset = widget.alignmentOffset ?? Offset(-menuPadding.start, 0);
        break;
      case Axis.vertical:
        menuPaddingOffset = widget.alignmentOffset ?? Offset(0, -menuPadding.top);
        break;
    }

    if (childMenu == null) {
      entry = _ChildMenuNode(
        buttonFocusNode: _buttonFocusNode,
        parent: parent,
        controller: controller,
        menuScopeNode: menuScopeNode,
        onOpen: widget.onOpen,
        onClose: widget.onClose,
        alignment: menuAlignment,
        alignmentOffset: menuPaddingOffset,
        widgetChildren: widget.children,
      );
      childMenu = _createMenuEntryFromExistingNode(entry);
    }
    entry
      ..buttonFocusNode = _buttonFocusNode
      ..menuScopeNode = menuScopeNode
      ..parent = parent
      ..theme = menuTheme
      ..onOpen = widget.onOpen
      ..onClose = widget.onClose
      ..alignment = menuAlignment
      ..alignmentOffset = menuPaddingOffset
      ..widgetChildren = widget.children;
  }

  @override
  Widget build(BuildContext context) {
    final MenuThemeData menuTheme = MenuTheme.of(context);
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(context);
    final Size densityAdjustedSize = const Size(64, 48) + Theme.of(context).visualDensity.baseSizeAdjustment;
    final MaterialStateProperty<EdgeInsetsDirectional?> resolvedPadding =
        MaterialStateProperty.all<EdgeInsetsDirectional?>(
            widget.padding ?? menuTheme.itemPadding ?? defaultTheme.itemPadding);

    return _MenuEntryMarker(
      entry: entry,
      child: Semantics(
        enabled: _enabled,
        // Will default to the label in the Text widget or labelWidget below if
        // not specified.
        label: widget.semanticsLabel,
        child: TextButton(
          style: (TextButtonTheme.of(context).style ?? const ButtonStyle()).copyWith(
            minimumSize: MaterialStateProperty.all<Size?>(densityAdjustedSize),
            backgroundColor:
                widget.buttonBackgroundColor ?? menuTheme.itemBackgroundColor ?? defaultTheme.itemBackgroundColor,
            foregroundColor:
                widget.buttonForegroundColor ?? menuTheme.itemForegroundColor ?? defaultTheme.itemForegroundColor,
            overlayColor: widget.buttonOverlayColor ?? menuTheme.itemOverlayColor ?? defaultTheme.itemOverlayColor,
            padding: resolvedPadding,
            shape: widget.buttonShape ?? menuTheme.itemShape ?? defaultTheme.itemShape,
            textStyle: widget.buttonTextStyle ?? menuTheme.itemTextStyle ?? defaultTheme.itemTextStyle,
          ),
          focusNode: _buttonFocusNode,
          onHover: _enabled ? _handleHover : null,
          onPressed: _enabled ? maybeToggleShowMenu : null,
          child: _MenuItemLabel(
            leadingIcon: widget.leadingIcon,
            trailingIcon: widget.trailingIcon,
            hasSubmenu: true,
            showDecoration: !entry.isTopLevel,
            child: widget.label,
          ),
        ),
      ),
    );
  }

  void maybeToggleShowMenu() {
    if (entry.isOpen) {
      entry.close();
    } else {
      entry.open();
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        // Has to happen in the next frame because the menu bar is not focusable
        // until the first menu is open.
        entry.focusButton();
      });
    }
  }

  // Called when the pointer is hovering over the menu button.
  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);

    // Don't open the root menu bar menus on hover unless something else
    // is already open. This means that the user has to first click to open a
    // menu on the menu bar before hovering allows them to traverse it.
    if (entry.isTopLevel && !entry.controller.menuIsOpen) {
      return;
    }

    if (hovering) {
      setState(() {
        entry.open();
        entry.focusButton();
      });
    }
  }

  void _handleFocusChange() {
    if (_buttonFocusNode.hasPrimaryFocus) {
      entry.open();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', widget.label.toString()));
  }
}

/// A handle to a menu created by [createCascadingMenu].
///
/// A `MenuEntry` can only be created by calling [createCascadingMenu].
///
/// `MenuEntry` is used to control and interrogate a menu after it has been
/// created, with methods such as [open] and [close], attributes like [enabled],
/// [theme], [alignment], [alignmentOffset], and state like [isOpen].
///
/// The [dispose] method must be called when the menu is no longer needed.
///
/// `MenuEntry` is a [ChangeNotifier]. To register for changes, call
/// [addListener], and when you're done listening, call [removeListener].
///
/// See also:
///
/// * [createCascadingMenu], the function that creates a menu given a focus node
///   for the controlling widget and the desired menus, and returns a
///   `MenuEntry`.
/// * [MenuBar], a widget that manages its own `MenuEntry` internally.
/// * [MenuButton], a widget that has a button that manages a submenu.
/// * [MenuItemButton], a widget that draws a menu button with optional shortcut
///   labels.
class MenuEntry with ChangeNotifier {
  /// Private constructor because menu entries can only be created by
  /// [createCascadingMenu].
  MenuEntry._(this._entry) {
    _entry.addListener(notifyListeners);
  }

  final _ChildMenuNode _entry;

  /// The controller that this menu handle is associated with.
  MenuController get controller => _entry.controller;

  /// Enable or disable the menu.
  bool get enabled => _entry.enabled;
  set enabled(bool value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the _entry.enabled value will automatically check for changes and
    // notify listeners.
    _entry.enabled = value;
  }

  /// Sets the menu children of the menu relative to the controlling widget that
  /// the menu is attached to.
  ///
  /// Setting this value will cause the menu to be rebuilt in the next frame.
  List<Widget> get children => _entry.widgetChildren;
  set children(List<Widget> value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the _entry.widgetChildren value will automatically check for
    // changes and notify listeners.
    _entry.widgetChildren = value;
  }

  /// Sets the alignment of the menu relative to the controlling widget that the
  /// menu is attached to.
  ///
  /// The alignment depends on the value of the ambient [Directionality] of the
  /// controlling widget to know which direction is the 'start' of the widget.
  AlignmentGeometry get alignment => _entry.alignment;
  set alignment(AlignmentGeometry value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the _entry.alignment value will automatically check for changes
    // and notify listeners.
    _entry.alignment = value;
  }

  /// Sets the alignment offset of the menu relative to the alignment position
  /// specified by [alignment] on the controlling widget that the menu is
  /// attached to.
  ///
  /// The offset is a directional offset starting at the alignment point, so
  /// increasingly larger positive values of [Offset.dx] will offset from
  /// 'begin' moving towards 'end' from the alignment point specified by
  /// [alignment] on the controlling widget. This will either offset the menu
  /// to the right (for [TextDirection.ltr]) or left (for [TextDirection.rtl]),
  /// depending on the ambient [Directionality].
  Offset get alignmentOffset => _entry.alignmentOffset;
  set alignmentOffset(Offset value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the _entry.alignmentOffset value will automatically check for
    // changes and notify listeners.
    _entry.alignmentOffset = value;
  }

  /// Sets the theme to use for configuring the menu.
  ///
  /// Setting this value will change the visual presentation of the menu to
  /// match the given theme. Setting it to null will return the menu to default
  /// values derived from the ambient [MenuTheme].
  MenuThemeData? get theme => _entry.theme;
  set theme(MenuThemeData? value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the _entry value will automatically check for changes and notify listeners.
    _entry.theme = value;
  }

  /// Whether or not the associated menu is currently open.
  bool get isOpen => _entry.isOpen;

  /// Open the menu.
  ///
  /// Call this from the controlling widget when the menu should open up.
  void open() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _entry.open();
  }

  /// Close the menu.
  ///
  /// Call this when the menu should be closed. Has no effect if the menu is already closed.
  void close() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _entry.close();
  }

  /// Dispose of the menu.
  ///
  /// Must be called when the menu is no longer needed, typically when the
  /// controlling widget is disposed.
  @override
  void dispose() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _entry.removeListener(notifyListeners);
    _entry.dispose();
    super.dispose();
  }
}

/// Creates a new cascading menu given the focus node for the controlling
/// widget.
///
/// Calling `createCascadingMenu` creates a new cascading menu controlled by
/// another widget, typically some type of button.
///
/// The menu is created in a closed state, and [MenuEntry.open] must be called
/// for the menu to be shown.
///
/// A [MenuController] may be supplied to allow this menu to be coordinated with
/// other related menus. If a `controller` is supplied, calling
/// [MenuController.closeAll] on the controller will close all associated menus.
///
/// The returned [MenuEntry] allows control of menu visibility, and
/// reconfiguration of the menu. Setting values on the returned [MenuEntry] will
/// update the menu with those changes in the next frame. The [MenuEntry] can be
/// listened to for state changes.
///
/// Supplying parameters here sets the corresponding fields on the returned
/// [MenuEntry], so setting `alignment` sets [MenuEntry.alignment], and so
/// forth.
///
/// {@tool dartpad}
/// This example shows a menu created with `createCascadingMenu` that contains a
/// single top level menu, containing three items: one for "About", a checkbox
/// menu item for showing a message, and "Quit". The items are identified with
/// an enum value.
///
/// ** See code in examples/api/lib/material/menu_bar/create_cascading_menu.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [MenuEntry], the handle returned from this function.
/// * [MenuBar], a widget that creates and manages a menu bar with cascading
///   menus.
MenuEntry createCascadingMenu(
  FocusNode buttonFocusNode, {
  MenuController? controller,
  MenuThemeData? theme,
  VoidCallback? onOpen,
  VoidCallback? onClose,
  AlignmentDirectional alignment = AlignmentDirectional.bottomStart,
  Offset alignmentOffset = Offset.zero,
  GlobalKey? buttonKey,
  List<Widget> children = const <Widget>[],
}) {
  controller ??= MenuController();
  final FocusScopeNode menuScopeNode = FocusScopeNode();
  assert(() {
    menuScopeNode.debugLabel = '$MenuButton(Scope for createMenuEntry)';
    return true;
  }());
  final _ChildMenuNode entry = _ChildMenuNode(
    buttonFocusNode: buttonFocusNode,
    buttonKey: buttonKey,
    controller: controller,
    menuScopeNode: menuScopeNode,
    parent: controller._root,
    theme: theme,
    onOpen: onOpen,
    onClose: onClose,
    alignment: alignment,
    alignmentOffset: alignmentOffset,
    widgetChildren: children,
  );
  return _createMenuEntryFromExistingNode(entry);
}

MenuEntry _createMenuEntryFromExistingNode(_ChildMenuNode entry) {
  assert(_menuDebug('Creating menu entry from $entry'));
  final MenuEntry menu = MenuEntry._(entry);
  entry.overlayEntry = OverlayEntry(builder: (BuildContext context) {
    final OverlayState overlay = Overlay.of(context)!;
    return _MenuEntryMarker(
      entry: entry,
      child: InheritedTheme.captureAll(
        // Copy all the themes from the menu bar to the overlay.
        entry.topLevel.context,
        _Menu(entry),
        to: overlay.context,
      ),
    );
  });
  return menu;
}

// A widget that draws the menu in the overlay.
class _Menu extends StatelessWidget {
  const _Menu(this.entry);

  final _ChildMenuNode entry;

  @override
  Widget build(BuildContext context) {
    final MenuThemeData menuTheme = MenuTheme.of(context);
    final _TokenDefaultsM3 defaultTheme = _TokenDefaultsM3(context);
    final TextDirection textDirection = Directionality.of(entry.topLevel.context);
    final Set<MaterialState> state = <MaterialState>{
      if (!entry.enabled) MaterialState.disabled,
    };

    final double elevation =
        (entry.theme?.menuElevation ?? menuTheme.menuElevation ?? defaultTheme.menuElevation).resolve(state)!;
    final Color backgroundColor =
        (entry.theme?.menuBackgroundColor ?? menuTheme.menuBackgroundColor ?? defaultTheme.menuBackgroundColor)
            .resolve(state)!;
    final EdgeInsetsDirectional padding = entry.theme?.menuPadding ?? menuTheme.menuPadding ?? defaultTheme.menuPadding;
    final ShapeBorder shape = (entry.theme?.menuShape ?? menuTheme.menuShape ?? defaultTheme.menuShape).resolve(state)!;

    return AnimatedBuilder(
      animation: entry,
      builder: (BuildContext context, Widget? ignoredChild) {
        final Offset menuOrigin = _getMenuPosition();
        return Positioned.directional(
          textDirection: textDirection,
          top: menuOrigin.dy,
          start: menuOrigin.dx,
          child: FocusScope(
            node: entry.menuScopeNode,
            child: Actions(
              actions: <Type, Action<Intent>>{
                DirectionalFocusIntent: _MenuDirectionalFocusAction(controller: entry.controller),
                DismissIntent: _MenuDismissAction(controller: entry.controller),
              },
              child: Shortcuts(
                shortcuts: _kMenuTraversalShortcuts,
                child: _MenuControllerMarker(
                  controller: entry.controller,
                  child: Directionality(
                    // Copy the directionality from the button into the overlay.
                    textDirection: textDirection,
                    child: _MenuPanel(
                      elevation: elevation,
                      color: backgroundColor,
                      padding: padding,
                      crossAxisMinSize: 0,
                      orientation: entry.orientation,
                      expand: true,
                      shape: shape,
                      children: MenuItemGroup._expandGroups(entry.widgetChildren, Axis.vertical),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _getMenuPosition() {
    final BuildContext menuButtonContext = entry.context;
    final TextDirection textDirection = Directionality.of(menuButtonContext);
    final RenderBox button = menuButtonContext.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(menuButtonContext)!.context.findRenderObject()! as RenderBox;
    final Alignment alignment = entry.alignment.resolve(textDirection);

    final Offset alignmentPoint = alignment.withinRect(button.paintBounds);
    Offset menuOrigin = button.localToGlobal(alignmentPoint, ancestor: overlay);
    switch (textDirection) {
      case TextDirection.rtl:
        // Because we need to use Alignment.directional to account for the width
        // of the submenu, we have to make the origin relative to the "start" of
        // the overlay instead of the upper left.
        menuOrigin = Offset(
          overlay.paintBounds.topRight.dx - menuOrigin.dx,
          menuOrigin.dy,
        );
        break;
      case TextDirection.ltr:
        break;
    }
    return menuOrigin + entry.alignmentOffset;
  }
}

/// A group of menu items surrounded by dividers in the menu.
///
/// The group will only have dividers between the group and other menu items. If
/// the group appears at the beginning of the menu, it will only have a divider
/// following, and if it appears at the end of a menu, it will only have a
/// divider before it.
///
/// It works for horizontal menus (e.g. [MenuBar]) as well as vertical ones.
class MenuItemGroup extends StatelessWidget {
  /// Creates a const [MenuItemGroup].
  ///
  /// The [members] attribute is required, and must not be empty.
  const MenuItemGroup({super.key, required this.members, this.orientation = Axis.vertical});

  /// The members of this [MenuItemGroup].
  ///
  /// The list must not be empty.
  final List<Widget> members;

  /// The layout orientation of this group, which determines the layout of the
  /// group items, as well as the orientation of the separating [Divider]s.
  final Axis orientation;

  @override
  Widget build(BuildContext context) {
    assert(members.isNotEmpty);
    switch (orientation) {
      case Axis.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: members,
        );
      case Axis.vertical:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: members,
        );
    }
  }

  static List<Widget> _expandGroups(List<Widget> menus, Axis orientation) {
    int nodeIndex = 0;
    List<Widget> expand(List<Widget> childMenus) {
      final List<Widget> result = <Widget>[];
      for (int widgetIndex = 0; widgetIndex < childMenus.length; widgetIndex += 1) {
        final Widget child = childMenus[widgetIndex];
        if (child is! MenuItemGroup) {
          // Non-MenuItemGroups aren't counted as part of the menu item tree, just
          // rendered.
          result.add(
            FocusTraversalOrder(
              order: NumericFocusOrder(nodeIndex.toDouble()),
              child: child,
            ),
          );
          continue;
        }
        if (child.members.isNotEmpty) {
          if (result.isNotEmpty && result.last is! _MenuItemDivider) {
            result.add(_MenuItemDivider(menuOrientation: orientation));
          }
          result.addAll(expand(child.members));
          if (widgetIndex != childMenus.length - 1 && result.last is! _MenuItemDivider) {
            result.add(_MenuItemDivider(menuOrientation: orientation));
          }
        } else {
          result.add(child);
          nodeIndex += 1;
        }
      }
      return result;
    }

    return expand(menus);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Widget>('members', members));
  }
}

/// A controller that allows control of a [MenuBar] from other places in the
/// widget hierarchy.
///
/// Typically, it's not necessary to create a `MenuController` to use a
/// [MenuBar] or to call [createCascadingMenu], but if open menus need to be
/// closed with the [closeAll] method in response to an event, a
/// `MenuController` can be created and passed to the [MenuBar] or
/// [createCascadingMenu].
///
/// The controller can be listened to for some changes in the state of the menu
/// bar, to see if [menuIsOpen] has changed, for instance.
///
/// The [dispose] method must be called on the controller when it is no longer
/// needed.
class MenuController with Diagnosticable, ChangeNotifier {
  /// Creates a [MenuController] that can be used with a [MenuBar] or
  /// [createCascadingMenu].
  MenuController() {
    _root = _RootMenuNode(this);
  }

  late final _RootMenuNode _root;

  // This holds the previously focused widget when a top level menu is opened,
  // so that when the last menu is dismissed, the focus can be restored.
  FocusNode? _previousFocus;

  /// Returns true if any menu served by this controller is currently open.
  bool get menuIsOpen => _root.openMenus.isNotEmpty;

  @override
  void dispose() {
    _previousFocus = null;
    _root.openMenus.clear();
    super.dispose();
  }

  /// Close any open menus controlled by this [MenuController].
  void closeAll() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (menuIsOpen) {
      assert(_menuDebug('Controller closing all open menus'));
      _root.closeChildren();
      notifyListeners();
    }
  }

  /// Returns the active controller in the given context, and creates a
  /// dependency relationship that will rebuild the context when the controller
  /// is swapped for a different one.
  ///
  /// The controller itself can be listened to for state changes (it is a
  /// [ChangeNotifier]).
  static MenuController of(BuildContext context) {
    final MenuController? found = maybeOf(context);
    if (found == null) {
      throw FlutterError('A ${context.widget.runtimeType} requested a '
          'MenuController, but was not a descendant of a MenuBar: $context');
    }
    return found;
  }

  /// Returns the active controller in the given context, if any, and creates a
  /// dependency relationship that will rebuild the context when the controller
  /// is swapped for a different one.
  ///
  /// The controller itself can be listened to for state changes (it is a
  /// [ChangeNotifier]).
  static MenuController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuControllerMarker>()?.controller;
  }

  // Called by the _MenuEntry.open to notify the controller when a menu item has been
  // opened.
  void _menuOpened(_MenuNode open, {required bool wasOpen}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!wasOpen && !menuIsOpen) {
      // We're opening the first menu, so cache the primary focus so that we can
      // try to return to it when the menu is dismissed. Skips any focus nodes
      // that are part of a menu system, since we don't want to return to those
      // when the menu closes, or it will never close.
      if (FocusManager.instance.primaryFocus?.context != null &&
          MenuController.maybeOf(FocusManager.instance.primaryFocus!.context!) == null) {
        assert(_menuDebug('Setting previous focus to $primaryFocus'));
        _previousFocus = FocusManager.instance.primaryFocus;
      } else {
        _previousFocus = null;
      }
    }
    notifyListeners();
    assert(_menuDebug('Menu opened: $open'));
  }

  // Called by the _MenuEntry.close to notify the controller when a menu item
  // has been closed.
  void _menuClosed(_MenuNode close, {bool inDispose = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!menuIsOpen) {
      // This needs to happen in the next frame so that in cases where we're
      // closing everything, and the _previousFocus is a focus scope that thinks
      // that currently thinks its first focus is in the menu bar, the menu bar
      // will be unfocusable by the time the scope tries to refocus it because
      // no menus will be open, and it will have a more appropriate first focus.
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        assert(_menuDebug('Returning focus to $_previousFocus'));
        _previousFocus?.requestFocus();
        _previousFocus = null;
      });
    }
    if (!inDispose) {
      notifyListeners();
    }
    assert(_menuDebug('Menu closed $close'));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<_MenuNode>('open', _root.openMenus));
    properties.add(DiagnosticsProperty<FocusNode>('previousFocus', _previousFocus));
  }
}

// The InheritedWidget marker for MenuController, used to find the nearest
// ancestor MenuController.
class _MenuControllerMarker extends InheritedWidget {
  const _MenuControllerMarker({
    required this.controller,
    required super.child,
  });

  final MenuController controller;

  @override
  bool updateShouldNotify(_MenuControllerMarker oldWidget) {
    return controller != oldWidget.controller;
  }
}

// The InheritedWidget marker for _MenuEntry, used to find the nearest
// ancestor _MenuEntry for a menu.
class _MenuEntryMarker extends InheritedWidget {
  const _MenuEntryMarker({
    required this.entry,
    required super.child,
  });

  final _MenuNode entry;

  @override
  bool updateShouldNotify(_MenuEntryMarker oldWidget) {
    return entry != oldWidget.entry;
  }
}

class _MenuItemDivider extends StatelessWidget {
  const _MenuItemDivider({this.menuOrientation = Axis.vertical});

  final Axis menuOrientation;

  @override
  Widget build(BuildContext context) {
    switch (menuOrientation) {
      case Axis.horizontal:
        return VerticalDivider(width: math.max(2, 16 + Theme.of(context).visualDensity.horizontal * 4));
      case Axis.vertical:
        return Divider(height: math.max(2, 16 + Theme.of(context).visualDensity.vertical * 4));
    }
  }
}

/// A widget that manages a list of menu buttons in a menu.
///
/// It sizes itself to the widest/tallest item it contains, and then sizes all
/// the other entries to match.
class _MenuPanel extends StatefulWidget implements PreferredSizeWidget {
  const _MenuPanel({
    required this.elevation,
    required this.crossAxisMinSize,
    required this.color,
    required this.padding,
    required this.orientation,
    required this.shape,
    required this.expand,
    required this.children,
  });

  /// The elevation to give the material behind the menu bar.
  final double elevation;

  /// The minimum size to give the menu bar in the axis perpendicular to [orientation].
  final double crossAxisMinSize;

  /// The background color of the menu app bar.
  final Color color;

  /// The padding around the outside of the menu bar contents.
  final EdgeInsetsDirectional padding;

  /// Whether or not the panel will expand to fill extra space when horizontal.
  final bool expand;

  /// The shape of the menu.
  final ShapeBorder shape;

  @override
  Size get preferredSize {
    switch (orientation) {
      case Axis.horizontal:
        return Size.fromHeight(crossAxisMinSize);
      case Axis.vertical:
        return Size.fromWidth(crossAxisMinSize);
    }
  }

  /// The main axis of this panel.
  final Axis orientation;

  /// The list of widgets to use as children of this menu bar.
  ///
  /// These are the top level [MenuButton]s.
  final List<Widget> children;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  Widget _intrinsicCrossSize({required Widget child}) {
    switch (widget.orientation) {
      case Axis.horizontal:
        return IntrinsicHeight(child: child);
      case Axis.vertical:
        return IntrinsicWidth(child: child);
    }
  }

  BoxConstraints _getMinSizeConstraint() {
    switch (widget.orientation) {
      case Axis.horizontal:
        return BoxConstraints(minHeight: widget.crossAxisMinSize);
      case Axis.vertical:
        return BoxConstraints(minWidth: widget.crossAxisMinSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MenuController controller = MenuController.of(context);
    return TapRegion(
      groupId: controller,
      onTapOutside: (PointerDownEvent event) {
        MenuController.of(context).closeAll();
      },
      child: ConstrainedBox(
        constraints: _getMinSizeConstraint(),
        child: _intrinsicCrossSize(
          child: Material(
            color: widget.color,
            shape: widget.shape,
            elevation: widget.elevation,
            child: Padding(
              padding: widget.padding,
              child: Flex(
                textDirection: Directionality.of(context),
                direction: widget.orientation,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ...widget.children,
                  if (widget.expand && widget.orientation == Axis.horizontal) const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A label widget that is used as the default label for a [MenuItemButton] or
/// [MenuButton].
///
/// It not only shows the [MenuButton.label] or [MenuItemButton.label], but if
/// there is a shortcut associated with the [MenuItemButton], it will display a
/// mnemonic for the shortcut. For [MenuButton]s, it will display a visual
/// indicator that there is a submenu.
class _MenuItemLabel extends StatelessWidget {
  /// Creates a const [_MenuItemLabel].
  ///
  /// The [child] and [hasSubmenu] arguments are required.
  const _MenuItemLabel({
    super.key,
    required this.child,
    required this.hasSubmenu,
    this.leadingIcon,
    this.trailingIcon,
    this.shortcut,
    this.showDecoration = true,
  });

  /// The required label widget.
  final Widget child;

  /// Whether or not this menu has a submenu.
  ///
  /// Determines whether the submenu arrow is shown or not.
  final bool hasSubmenu;

  /// The optional icon that comes before the [child].
  final Widget? leadingIcon;

  /// The optional icon that comes after the [child].
  final Widget? trailingIcon;

  /// The shortcut for this label, so that it can generate a string describing
  /// the shortcut.
  final MenuSerializableShortcut? shortcut;

  /// Whether or not this item should show decorations like shortcut labels or
  /// submenu arrows.
  final bool showDecoration;

  @override
  Widget build(BuildContext context) {
    final VisualDensity density = Theme.of(context).visualDensity;
    final double horizontalPadding = math.max(
      _kLabelItemMinSpacing,
      _kLabelItemDefaultSpacing + density.horizontal * 2,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leadingIcon != null) leadingIcon!,
            Padding(
              padding: leadingIcon != null ? EdgeInsetsDirectional.only(start: horizontalPadding) : EdgeInsets.zero,
              child: child,
            ),
            if (trailingIcon != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                child: trailingIcon,
              ),
          ],
        ),
        if (showDecoration && (shortcut != null || hasSubmenu)) SizedBox(width: horizontalPadding),
        if (showDecoration && shortcut != null)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: Text(
              _LocalizedShortcutLabeler.instance.getShortcutLabel(
                shortcut!,
                MaterialLocalizations.of(context),
              ),
            ),
          ),
        if (showDecoration && hasSubmenu)
          Padding(
            padding: EdgeInsetsDirectional.only(start: horizontalPadding),
            child: const Icon(
              Icons.arrow_right, // Automatically switches with text direction.
              size: _kDefaultSubmenuIconSize,
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('child', child.toString()));
    properties.add(DiagnosticsProperty<MenuSerializableShortcut>('shortcut', shortcut, defaultValue: null));
  }
}


// Base class for all menu nodes that make up the menu tree, to allow walking of
// the tree for navigation.
abstract class _MenuNode with DiagnosticableTreeMixin, ChangeNotifier {
  bool get isRoot;
  MenuController get controller;
  _RootMenuNode get root;
  _MenuNode get parent;
  bool get enabled => true;
  FocusScopeNode get menuScopeNode;

  List<_ChildMenuNode> children = <_ChildMenuNode>[];

  void addChild(_ChildMenuNode child) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (isRoot) {
      assert(_menuDebug('Added root child: $child'));
    }
    assert(!children.contains(child));
    children.add(child);
  }

  void removeChild(_ChildMenuNode child) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (isRoot) {
      assert(_menuDebug('Removed root child: $child'));
    }
    assert(children.contains(child));
    children.remove(child);
  }

  void closeChildren({bool inDispose = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_menuDebug('Closing children of ${this}${inDispose ? ' (dispose)' : ''}'));
    for (final _ChildMenuNode child in List<_ChildMenuNode>.from(children)) {
      child.close(inDispose: inDispose);
    }
  }

  void focusButton() {}

  Axis get orientation;

  FocusNode? get firstItemFocusNode {
    if (menuScopeNode.context == null) {
      return null;
    }
    final FocusTraversalPolicy policy =
        FocusTraversalGroup.maybeOf(menuScopeNode.context!) ?? ReadingOrderTraversalPolicy();
    return policy.findFirstFocus(menuScopeNode, ignoreCurrentFocus: true);
  }

  // Returns the active menu entry in the given context, if any, and creates a
  // dependency relationship that will rebuild the context when the entry
  // changes.
  static _MenuNode? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuEntryMarker>()?.entry;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...super.debugDescribeChildren(),
      ...children.map<DiagnosticsNode>((_ChildMenuNode child) => child.toDiagnosticsNode()),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('isRoot', value: isRoot, ifTrue: 'ROOT', defaultValue: false));
    properties.add(DiagnosticsProperty<_MenuNode?>('parent', isRoot ? null : parent, defaultValue: null));
  }
}

class _RootMenuNode extends _MenuNode {
  _RootMenuNode(this.controller) : menuScopeNode = FocusScopeNode();

  @override
  MenuController controller;

  // A list of descendant menus that are currently open.
  final Set<_MenuNode> openMenus = <_MenuNode>{};

  @override
  bool get isRoot => true;

  @override
  _RootMenuNode get root => this;

  @override
  _MenuNode get parent => throw UnimplementedError('Tried to get the parent of the root node');

  @override
  Axis get orientation => Axis.horizontal;

  @override
  FocusScopeNode menuScopeNode;
}

class _ChildMenuNode extends _MenuNode {
  _ChildMenuNode({
    required this.parent,
    required MenuController controller,
    required List<Widget> widgetChildren,
    required this.menuScopeNode,
    required FocusNode buttonFocusNode,
    GlobalKey? buttonKey,
    this.onOpen,
    this.onClose,
    AlignmentGeometry alignment = AlignmentDirectional.bottomStart,
    Offset alignmentOffset = Offset.zero,
    Axis orientation = Axis.vertical,
    MenuThemeData? theme,
  })  : _buttonFocusNode = buttonFocusNode,
        _buttonKey = buttonKey,
        _controller = controller,
        _widgetChildren = widgetChildren,
        _orientation = orientation,
        _alignment = alignment,
        _alignmentOffset = alignmentOffset,
        _theme = theme {
    parent.addChild(this);
  }

  @override
  MenuController get controller => _controller;
  MenuController _controller;
  set controller(MenuController controller) {
    _controller = controller;
    _notifyNextFrame();
  }

  @override
  bool get isRoot => false;

  @override
  _MenuNode parent;

  OverlayEntry? overlayEntry;
  bool isOpen = false;
  VoidCallback? onOpen;
  VoidCallback? onClose;

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment != value) {
      _alignment = value;
      _notifyNextFrame();
    }
  }

  Offset get alignmentOffset => _alignmentOffset;
  Offset _alignmentOffset;
  set alignmentOffset(Offset value) {
    if (_alignmentOffset != value) {
      _alignmentOffset = value;
      _notifyNextFrame();
    }
  }

  BuildContext get context => buttonKey?.currentContext ?? buttonFocusNode.context!;

  FocusNode get buttonFocusNode => _buttonFocusNode;
  FocusNode _buttonFocusNode;
  set buttonFocusNode(FocusNode value) {
    if (_buttonFocusNode != value) {
      _buttonFocusNode = value;
      _notifyNextFrame();
    }
  }

  GlobalKey? get buttonKey => _buttonKey;
  GlobalKey? _buttonKey;
  set buttonKey(GlobalKey? value) {
    if (_buttonKey != value) {
      _buttonKey = value;
      _notifyNextFrame();
    }
  }

  @override
  FocusScopeNode menuScopeNode;

  @override
  Axis get orientation => _orientation;
  Axis _orientation;
  set orientation(Axis value) {
    if (_orientation != value) {
      _orientation = value;
      _notifyNextFrame();
    }
  }

  MenuThemeData? get theme => _theme;
  MenuThemeData? _theme;
  set theme(MenuThemeData? value) {
    if (_theme != value) {
      _theme = value;
      _notifyNextFrame();
    }
  }

  List<Widget> get widgetChildren => _widgetChildren;
  List<Widget> _widgetChildren;
  set widgetChildren(List<Widget> value) {
    if (_widgetChildren != value) {
      _widgetChildren = value;
      _notifyNextFrame();
    }
  }

  bool get isTopLevel => parent.isRoot;

  /// Enable or disable the menu.
  @override
  bool get enabled => _enabled;
  bool _enabled = true;
  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      _notifyNextFrame();
    }
  }

  @override
  _RootMenuNode get root {
    _MenuNode entry = this;
    while (!entry.parent.isRoot) {
      entry = entry.parent;
    }
    return entry.parent as _RootMenuNode;
  }

  _ChildMenuNode get topLevel {
    _MenuNode entry = this;
    while (!entry.parent.isRoot) {
      entry = entry.parent;
    }
    return entry as _ChildMenuNode;
  }

  _ChildMenuNode? get previousSibling {
    final int index = parent.children.indexOf(this);
    assert(index != -1, 'Unable to find this widget in parent');
    if (index > 0) {
      return parent.children[index - 1];
    }
    return null;
  }

  _ChildMenuNode? get nextSibling {
    final int index = parent.children.indexOf(this);
    assert(index != -1, 'Unable to find this widget in parent');
    if (index < parent.children.length - 1) {
      return parent.children[index + 1];
    }
    return null;
  }

  void open() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (isOpen) {
      assert(_menuDebug("Not opening $this because it's already open"));
      return;
    }
    assert(!root.openMenus.contains(this), 'Attempted to add menu $this to root twice');
    parent.closeChildren();
    final bool wasOpen = controller.menuIsOpen;
    root.openMenus.add(this);
    Overlay.of(context)!.insert(overlayEntry!);
    isOpen = true;
    controller._menuOpened(this, wasOpen: wasOpen);
    onOpen?.call();
    _notifyNextFrame();
  }

  void close({bool inDispose = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!isOpen) {
      return;
    }
    assert(root.openMenus.contains(this), 'Menu $this was never recorded as being opened.');
    closeChildren();
    root.openMenus.remove(this);
    overlayEntry?.remove();
    isOpen = false;
    controller._menuClosed(this, inDispose: inDispose);
    onClose?.call();
    _notifyNextFrame();
  }

  @override
  void dispose() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_menuDebug('Disposing of $this'));
    if (!isOpen) {
      return;
    }
    assert(root.openMenus.contains(this), 'Menu $this was never recorded as being opened.');
    closeChildren(inDispose: true);
    root.openMenus.remove(this);
    overlayEntry?.remove();
    overlayEntry = null;
    isOpen = false;
    children.clear();
    parent.removeChild(this);
    super.dispose();
  }

  @override
  void focusButton() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_menuDebug('Requesting focus for $buttonFocusNode'));
    buttonFocusNode.requestFocus();
  }

  void _notifyNextFrame() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Listeners need to always be notified in the next frame because the major
    // listener for this object is in the overlay, and it can't rebuild during
    // the build that triggers the change.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      notifyListeners();
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('isOpen', value: isOpen, ifTrue: 'OPEN', defaultValue: false));
    properties.add(DiagnosticsProperty<FocusNode>('buttonFocusNode', buttonFocusNode));
    properties.add(DiagnosticsProperty<GlobalKey>('buttonKey', buttonKey));
    properties.add(DiagnosticsProperty<FocusScopeNode>('menuScopeNode', menuScopeNode));
  }
}

/// A helper class used to generate shortcut labels for a [ShortcutActivator].
///
/// This helper class is typically used by the [MenuItemButton] class to display
/// a label for its assigned shortcut.
///
/// Call [getShortcutLabel] with the [ShortcutActivator] to get a label for it.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
class _LocalizedShortcutLabeler {
  _LocalizedShortcutLabeler._();

  /// Return the instance for this singleton.
  static _LocalizedShortcutLabeler get instance {
    return _instance ??= _LocalizedShortcutLabeler._();
  }

  static _LocalizedShortcutLabeler? _instance;

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
  String? _getLocalizedName(LogicalKeyboardKey key, MaterialLocalizations localizations) {
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
      LogicalKeyboardKey.eject: localizations.keyboardKeyEject,
      LogicalKeyboardKey.end: localizations.keyboardKeyEnd,
      LogicalKeyboardKey.escape: localizations.keyboardKeyEscape,
      LogicalKeyboardKey.fn: localizations.keyboardKeyFn,
      LogicalKeyboardKey.home: localizations.keyboardKeyHome,
      LogicalKeyboardKey.insert: localizations.keyboardKeyInsert,
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
      LogicalKeyboardKey.scrollLock: localizations.keyboardKeyScrollLock,
      LogicalKeyboardKey.select: localizations.keyboardKeySelect,
      LogicalKeyboardKey.space: localizations.keyboardKeySpace,
    };
    return _cachedShortcutKeys[localizations]![key];
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
  /// [TargetPlatform.iOS], the key [LogicalKeyboardKey.meta] will show as '⌘',
  /// [LogicalKeyboardKey.control] will show as '˄', and
  /// [LogicalKeyboardKey.alt] will show as '⌥'.
  String getShortcutLabel(MenuSerializableShortcut shortcut, MaterialLocalizations localizations) {
    final ShortcutSerialization serialized = shortcut.serializeForMenu();
    if (serialized.trigger != null) {
      final List<String> modifiers = <String>[];
      final LogicalKeyboardKey trigger = serialized.trigger!;
      // These should be in this order, to match the LogicalKeySet version.
      if (serialized.alt!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.alt, localizations));
      }
      if (serialized.control!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.control, localizations));
      }
      if (serialized.meta!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.meta, localizations));
      }
      if (serialized.shift!) {
        modifiers.add(_getModifierLabel(LogicalKeyboardKey.shift, localizations));
      }
      String? shortcutTrigger;
      final int logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger];
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
        if (shortcutTrigger == null && logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
          // If the trigger is a Unicode-character-producing key, then use the character.
          shortcutTrigger = String.fromCharCode(logicalKeyId & LogicalKeyboardKey.valueMask).toUpperCase();
        }
        // Fall back to the key label if all else fails.
        shortcutTrigger ??= trigger.keyLabel;
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger != null && shortcutTrigger.isNotEmpty) shortcutTrigger,
      ].join(' ');
    } else if (serialized.character != null) {
      return serialized.character!;
    }
    throw UnimplementedError('Shortcut labels for ShortcutActivators that do not implement '
        'MenuSerializableShortcut (e.g. ShortcutActivators other than SingleActivator or '
        'CharacterActivator) are not supported.');
  }
}

class _MenuDismissAction extends DismissAction {
  _MenuDismissAction({required this.controller});

  final MenuController controller;

  @override
  bool isEnabled(DismissIntent intent) {
    return controller.menuIsOpen;
  }

  @override
  void invoke(DismissIntent intent) {
    assert(_menuDebug('Dismiss action: Dismissing menus all open menus.'));
    controller.closeAll();
  }
}

class _MenuDirectionalFocusAction extends DirectionalFocusAction {
  /// Creates a [DirectionalFocusAction].
  _MenuDirectionalFocusAction({required this.controller});

  final MenuController controller;

  bool _moveToSubmenu(_ChildMenuNode currentMenu) {
    assert(_menuDebug('Opening submenu'));
    if (!currentMenu.isOpen) {
      // If no submenu is open, then an arrow opens the submenu.
      currentMenu.open();
      return true;
    } else {
      final FocusNode? firstNode = currentMenu.firstItemFocusNode;
      if (firstNode != null && firstNode.nearestScope != firstNode) {
        // Don't request focus if the "first" found node is a focus scope, since that
        // means that nothing else in the submenu is focusable.
        firstNode.requestFocus();
      }
      return true;
    }
  }

  bool _moveToParent(_ChildMenuNode currentMenu) {
    assert(_menuDebug('Moving focus to parent menu button'));
    if (!currentMenu.buttonFocusNode.hasPrimaryFocus) {
      currentMenu.focusButton();
    }
    return true;
  }

  bool _moveToPrevious(_ChildMenuNode currentMenu) {
    assert(_menuDebug('Moving focus to previous item in menu'));
    // Need to invalidate the scope data because we're switching scopes, and
    // otherwise the anti-hysteresis code will interfere with moving to the
    // correct node.
    final FocusTraversalPolicy? policy = FocusTraversalGroup.maybeOf(currentMenu.context);
    policy?.invalidateScopeData(currentMenu.buttonFocusNode.nearestScope!);
    return false;
  }

  bool _moveToNext(_ChildMenuNode currentMenu) {
    assert(_menuDebug('Moving focus to next item in menu'));
    // Need to invalidate the scope data because we're switching scopes, and
    // otherwise the anti-hysteresis code will interfere with moving to the
    // correct node.
    final FocusTraversalPolicy? policy = FocusTraversalGroup.maybeOf(currentMenu.context);
    policy?.invalidateScopeData(currentMenu.buttonFocusNode.nearestScope!);
    return false;
  }

  bool _moveToNextTopLevel(_ChildMenuNode currentMenu) {
    final _ChildMenuNode? sibling = currentMenu.topLevel.nextSibling;
    if (sibling == null) {
      // Wrap around to the first top level.
      currentMenu.topLevel.parent.children.first.focusButton();
    } else {
      sibling.focusButton();
    }
    return true;
  }

  bool _moveToPreviousTopLevel(_ChildMenuNode currentMenu) {
    final _ChildMenuNode? sibling = currentMenu.topLevel.previousSibling;
    if (sibling == null) {
      // Already on the first one, wrap around to the last one.
      currentMenu.topLevel.parent.children.last.focusButton();
    } else {
      sibling.focusButton();
    }
    return true;
  }

  @override
  void invoke(DirectionalFocusIntent intent) {
    assert(_menuDebug('_MenuDirectionalFocusAction invoked with $intent'));
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      super.invoke(intent);
      return;
    }
    if (!controller.menuIsOpen || FocusManager.instance.primaryFocus?.context == null) {
      super.invoke(intent);
      return;
    }
    final _MenuNode? menu = _MenuNode.maybeOf(FocusManager.instance.primaryFocus!.context!);
    if (menu == null || menu.isRoot) {
      super.invoke(intent);
      return;
    }
    final _ChildMenuNode currentMenu = menu as _ChildMenuNode;
    final bool buttonIsFocused = currentMenu.buttonFocusNode.hasPrimaryFocus;
    Axis orientation;
    if (buttonIsFocused) {
      orientation = currentMenu.parent.orientation;
    } else {
      orientation = currentMenu.orientation;
    }
    final bool firstItemIsFocused = currentMenu.firstItemFocusNode?.hasPrimaryFocus ?? false;
    assert(_menuDebug(
        'In _MenuDirectionalFocusAction, current node is ${currentMenu.buttonFocusNode.debugLabel}, '
        'button is${buttonIsFocused ? '' : ' not'} focused. Assuming ${orientation.name} orientation.'));

    switch (intent.direction) {
      case TraversalDirection.up:
        switch (orientation) {
          case Axis.horizontal:
            if (_moveToParent(currentMenu)) {
              return;
            }
            break;
          case Axis.vertical:
            if (firstItemIsFocused) {
              if (_moveToParent(currentMenu)) {
                return;
              }
            }
            if (_moveToPrevious(currentMenu)) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.down:
        switch (orientation) {
          case Axis.horizontal:
            if (_moveToSubmenu(currentMenu)) {
              return;
            }
            break;
          case Axis.vertical:
            if (_moveToNext(currentMenu)) {
              return;
            }
            break;
        }
        break;
      case TraversalDirection.left:
        switch (orientation) {
          case Axis.horizontal:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (_moveToNext(currentMenu)) {
                  return;
                }
                break;
              case TextDirection.ltr:
                if (_moveToPrevious(currentMenu)) {
                  return;
                }
                break;
            }
            break;
          case Axis.vertical:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (buttonIsFocused) {
                  if (_moveToSubmenu(currentMenu)) {
                    return;
                  }
                } else {
                  if (_moveToNextTopLevel(currentMenu)) {
                    return;
                  }
                }
                break;
              case TextDirection.ltr:
                switch (currentMenu.parent.orientation) {
                  case Axis.horizontal:
                    if (_moveToPreviousTopLevel(currentMenu)) {
                      return;
                    }
                    break;
                  case Axis.vertical:
                    if (buttonIsFocused) {
                      if (_moveToPreviousTopLevel(currentMenu)) {
                        return;
                      }
                    } else {
                      if (_moveToParent(currentMenu)) {
                        return;
                      }
                    }
                    break;
                }
                break;
            }
            break;
        }
        break;
      case TraversalDirection.right:
        switch (orientation) {
          case Axis.horizontal:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                if (_moveToPrevious(currentMenu)) {
                  return;
                }
                break;
              case TextDirection.ltr:
                if (_moveToNext(currentMenu)) {
                  return;
                }
                break;
            }
            break;
          case Axis.vertical:
            switch (Directionality.of(context)) {
              case TextDirection.rtl:
                switch (currentMenu.parent.orientation) {
                  case Axis.horizontal:
                    if (_moveToPreviousTopLevel(currentMenu)) {
                      return;
                    }
                    break;
                  case Axis.vertical:
                    if (_moveToParent(currentMenu)) {
                      return;
                    }
                    break;
                }
                break;
              case TextDirection.ltr:
                if (buttonIsFocused) {
                  if (_moveToSubmenu(currentMenu)) {
                    return;
                  }
                } else {
                  if (_moveToNextTopLevel(currentMenu)) {
                    return;
                  }
                }
                break;
            }
            break;
        }
        break;
    }
    super.invoke(intent);
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _TokenDefaultsM3 extends MenuThemeData {
  _TokenDefaultsM3(this.context)
      : super(
          barElevation: MaterialStateProperty.all<double?>(2.0),
          menuElevation: MaterialStateProperty.all<double?>(4.0),
          menuPadding: const EdgeInsetsDirectional.only(top: 8.0, bottom: 8.0),
          menuShape: MaterialStateProperty.all<ShapeBorder?>(_defaultMenuBorder),
          itemShape: MaterialStateProperty.all<ShapeBorder?>(_defaultItemBorder),
          barShape: MaterialStateProperty.all<ShapeBorder?>(_defaultBarBorder),
        );

  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  static const RoundedRectangleBorder _defaultBarBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  static const RoundedRectangleBorder _defaultItemBorder = RoundedRectangleBorder();

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  double get barMinimumHeight {
    return 40 + Theme.of(context).visualDensity.baseSizeAdjustment.dy;
  }

  @override
  EdgeInsetsDirectional get barPadding {
    return EdgeInsetsDirectional.symmetric(
      horizontal: math.max(
        _kTopLevelMenuHorizontalMinPadding,
        2 + Theme.of(context).visualDensity.baseSizeAdjustment.dx,
      ),
    );
  }

  @override
  MaterialStateProperty<Color?> get barBackgroundColor {
    return MaterialStateProperty.all<Color?>(_colors.surface);
  }

  @override
  MaterialStateProperty<double?> get barElevation => super.barElevation!;

  @override
  MaterialStateProperty<Color?> get menuBackgroundColor {
    return MaterialStateProperty.all<Color?>(_colors.surface);
  }

  @override
  MaterialStateProperty<double?> get menuElevation => super.menuElevation!;

  @override
  MaterialStateProperty<ShapeBorder?> get menuShape => super.menuShape!;

  @override
  EdgeInsetsDirectional get menuPadding => super.menuPadding!;

  @override
  MaterialStateProperty<Color?> get itemBackgroundColor {
    return MaterialStateProperty.all<Color?>(_colors.surface);
  }

  @override
  MaterialStateProperty<Color?> get itemForegroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      return _colors.primary;
    });
  }

  @override
  MaterialStateProperty<Color?> get itemOverlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      // Use the component default.
      return null;
    });
  }

  @override
  MaterialStateProperty<TextStyle?> get itemTextStyle {
    return MaterialStateProperty.all<TextStyle?>(Theme.of(context).textTheme.labelLarge);
  }

  @override
  EdgeInsetsDirectional get itemPadding {
    final VisualDensity density = Theme.of(context).visualDensity;
    return EdgeInsetsDirectional.symmetric(
      vertical: math.max(0, density.vertical * 2),
      horizontal: math.max(0, 24 + density.horizontal * 2),
    );
  }

  @override
  MaterialStateProperty<ShapeBorder?> get itemShape => super.itemShape!;
}
