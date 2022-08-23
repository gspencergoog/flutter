// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/material/ink_well.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'button_style_button.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'divider.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'menu_bar_theme.dart';
import 'menu_button_theme.dart';
import 'menu_style.dart';
import 'menu_theme.dart';
import 'text_button.dart';
import 'theme.dart';
import 'theme_data.dart';

// Enable if you want verbose logging about menu changes.
const bool _kDebugMenus = true;

// How close to the edge of the safe area the menu will be placed.
const double _kMenuViewPadding = 8.0;

// The default size of the arrow in _MenuItemLabel that indicates that a menu
// has a submenu.
const double _kDefaultSubmenuIconSize = 24.0;

// The default spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemDefaultSpacing = 18.0;

// The minimum spacing between the the leading icon, label, trailing icon, and
// shortcut label in a _MenuItemLabel.
const double _kLabelItemMinSpacing = 4.0;

// The minimum vertical spacing on the outside of menus.
const double _kMenuVerticalMinPadding = 4.0;

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
/// When a menu item with a submenu is clicked on, it toggles the visibility of
/// the submenu. When the menu item is hovered over, the submenu will open, and
/// hovering over other items will close the previous menu and open the newly
/// hovered one. When those open/close transitions occur, [MenuButton.onOpen],
/// and [MenuButton.onClose] are called on the corresponding [MenuButton] child
/// of the menu bar.
///
/// {@template flutter.material.menu_bar.shortcuts_note}
/// Menu items using [MenuItemButton] can have a [SingleActivator] or
/// [CharacterActivator] assigned to them as their [MenuItemButton.shortcut],
/// which will display an appropriate shortcut hint. Shortcuts are not
/// automatically registered, they must be available in the context that the
/// [MenuBar] resides in, and registered via another mechanism.
///
/// If shortcuts should be generally enabled, but are not easily defined in the
/// context surrounding the menu bar, consider registering them with a
/// [ShortcutRegistry] (one is included in the [WidgetsApp] (and thus also
/// [MaterialApp] and [CupertinoApp]) already), as shown in the example below.
/// To be sure that selecting a menu item and triggering the shortcut do the
/// same thing, it is recommended that they trigger the same [Intent] or call
/// the same callback.
///
/// {@tool dartpad}
/// This example shows a [MenuBar] that contains a single top level menu,
/// containing three items for "About", a checkbox menu item for showing a
/// message, and "Quit". The items are identified with an enum value, and the
/// shortcuts are registered globally with [ShortcutRegistry].
///
/// ** See code in examples/api/lib/material/menu_bar/menu_bar.0.dart **
/// {@end-tool}
/// {@endtemplate}
///
/// See also:
///
/// * [MenuButton], a menu item which manages a submenu.
/// * [MenuItemGroup], a menu item which collects its members into a group
///   separated from other menu items by a divider.
/// * [MenuItemButton], a leaf menu item which displays the label, an optional
///   shortcut label, and optional leading and trailing icons.
/// * [createMaterialMenu], a function that creates a [MenuEntry] that allows
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
    this.style,
    this.clipBehavior = Clip.none,
    this.statesController,
    required this.children,
  });

  /// An optional controller that allows outside control of the menu bar.
  ///
  /// You can use a controller to close any open menus from outside of the menu
  /// bar using [MenuController.closeAll].
  ///
  /// If a controller is provided here, it must be disposed by the owner of the
  /// controller when it is done being used.
  final MenuController? controller;

  /// The [MenuStyle] that defines the visual attributes of the menu bar.
  final MenuStyle? style;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// The [MaterialStatesController] that manages the states for the menu bar.
  ///
  /// This only manages the states for the menu bar itself, not for its
  /// submenus.
  final MaterialStatesController? statesController;

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
    properties.add(DiagnosticsProperty<MenuStyle?>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null));
  }
}

class _MenuBarState extends State<MenuBar> with DiagnosticableTreeMixin {
  MenuController? _internalController;
  MaterialStatesController? _internalStatesController;
  MenuController get _controller {
    return widget.controller ?? (_internalController ??= MenuController());
  }

  MaterialStatesController get _statesController => widget.statesController ?? _internalStatesController!;

  void handleStatesControllerChange() {
    // Force a rebuild to resolve MaterialStateProperty properties
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    assert(() {
      _controller._root.menuScopeNode.debugLabel = 'MenuBar';
      return true;
    }());
    initStatesController();
  }

  void initStatesController() {
    if (widget.statesController == null) {
      _internalStatesController = MaterialStatesController();
    }
    _statesController.addListener(handleStatesControllerChange);
  }

  @override
  void didUpdateWidget(MenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
    }
    if (widget.statesController != oldWidget.statesController) {
      oldWidget.statesController?.removeListener(handleStatesControllerChange);
      if (widget.statesController != null) {
        _internalStatesController?.dispose();
        _internalStatesController = null;
      }
      initStatesController();
    }
  }

  @override
  void dispose() {
    _statesController.removeListener(handleStatesControllerChange);
    _internalStatesController?.dispose();
    _internalController?.dispose();
    _internalController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? ignoredChild) {
        return ExcludeFocus(
          excluding: !_controller.menuIsOpen,
          child: TapRegion(
            groupId: _controller,
            onTapOutside: (PointerDownEvent event) {
              _controller.closeAll();
            },
            child: _MenuControllerMarker(
              controller: _controller,
              child: FocusScope(
                node: _controller._root.menuScopeNode,
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    DirectionalFocusIntent: _MenuDirectionalFocusAction(controller: _controller),
                    DismissIntent: _MenuDismissAction(controller: _controller),
                  },
                  child: Shortcuts(
                    shortcuts: _kMenuTraversalShortcuts,
                    child: _MenuPanel(
                      menuStyle: widget.style,
                      clipBehavior: widget.clipBehavior,
                      statesController: _statesController,
                      orientation: Axis.horizontal,
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

/// A button for use in a [MenuBar] that can be activated by click or keyboard
/// navigation that displays a shortcut hint and optional leading/trailing
/// icons.
///
/// This widget represents a leaf entry in a menu that is typically part of a
/// [MenuBar], but may be used independently, or as part of a menu created with
/// [createMaterialMenu].
///
/// It shows a hint for an associated shortcut, if any. When selected via click,
/// hitting enter while focused, or activating the associated [shortcut], it
/// will call its [onPressed] callback or fire its [onPressedIntent] intent,
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
/// * [createMaterialMenu], a function that creates a [MenuEntry] that allows
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
  /// The [child] attribute is required.
  const MenuItemButton({
    super.key,
    this.shortcut,
    this.onPressed,
    this.onHover,
    this.onLongPress,
    this.onFocusChange,
    this.focusNode,
    this.style,
    this.statesController,
    this.clipBehavior = Clip.none,
    this.leadingIcon,
    this.trailingIcon,
    required this.child,
  });

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback and [onLongPress] are null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onPressed;

  /// Called when the button is long-pressed.
  ///
  /// If this callback and [onPressed] are null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onLongPress;

  /// Called when a pointer enters or exits the button response area.
  ///
  /// The value passed to the callback is true if a pointer has entered this
  /// part of the material and false if a pointer has exited this part of the
  /// material.
  final ValueChanged<bool>? onHover;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding
  /// properties in [themeStyleOf] and [defaultStyleOf]. [MaterialStateProperty]s
  /// that resolve to non-null values will similarly override the corresponding
  /// [MaterialStateProperty]s in [themeStyleOf] and [defaultStyleOf].
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// {@macro flutter.material.inkwell.statesController}
  final MaterialStatesController? statesController;

  /// Typically the button's label.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// The optional shortcut that selects this [MenuItemButton].
  ///
  /// This shortcut is only enabled when [onPressed] is set.
  final MenuSerializableShortcut? shortcut;

  /// An optional icon to display before the [child] label.
  final Widget? leadingIcon;

  /// An optional icon to display after the [child] label.
  final Widget? trailingIcon;

  /// Whether the button is enabled or disabled.
  ///
  /// Buttons are disabled by default. To enable a button, set its [onPressed]
  /// or [onLongPress] properties to a non-null value.
  bool get enabled => onPressed != null || onLongPress != null;

  @override
  State<MenuItemButton> createState() => _MenuItemButtonState();

  /// Defines the button's default appearance.
  ///
  /// The button [child]'s [Text] and [Icon] widgets are rendered with
  /// the [ButtonStyle]'s foreground color. The button's [InkWell] adds
  /// the style's overlay color when the button is focused, hovered
  /// or pressed. The button's background color becomes its [Material]
  /// color and is transparent by default.
  ///
  /// All of the ButtonStyle's defaults appear below.
  ///
  /// In this list "Theme.foo" is shorthand for
  /// `Theme.of(context).foo`. Color scheme values like
  /// "onSurface(0.38)" are shorthand for
  /// `onSurface.withOpacity(0.38)`. [MaterialStateProperty] valued
  /// properties that are not followed by a sublist have the same
  /// value for all states, otherwise the values are as specified for
  /// each state and "others" means all other states.
  ///
  /// The `textScaleFactor` is the value of
  /// `MediaQuery.of(context).textScaleFactor` and the names of the
  /// EdgeInsets constructors and `EdgeInsetsGeometry.lerp` have been
  /// abbreviated for readability.
  ///
  /// The color of the [ButtonStyle.textStyle] is not used, the
  /// [ButtonStyle.foregroundColor] color is used instead.
  ///
  /// * `textStyle` - Theme.textTheme.labelLarge
  /// * `backgroundColor` - transparent
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * others - Theme.colorScheme.primary
  /// * `overlayColor`
  ///   * hovered - Theme.colorScheme.primary(0.08)
  ///   * focused or pressed - Theme.colorScheme.primary(0.12)
  ///   * others - null
  /// * `shadowColor` - null
  /// * `surfaceTintColor` - null
  /// * `elevation` - 0
  /// * `padding`
  ///   * `textScaleFactor <= 1` - all(8)
  ///   * `1 < textScaleFactor <= 2` - lerp(all(8), horizontal(8))
  ///   * `2 < textScaleFactor <= 3` - lerp(horizontal(8), horizontal(4))
  ///   * `3 < textScaleFactor` - horizontal(4)
  /// * `minimumSize` - Size(64, 40)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `side` - null
  /// * `shape` - StadiumBorder()
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.basic
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - theme.visualDensity
  /// * `tapTargetSize` - theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - Theme.splashFactory
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest
  /// [MenuButtonTheme] ancestor.
  ButtonStyle? themeStyleOf(BuildContext context) {
    return MenuButtonTheme.of(context).style;
  }

  /// A static convenience method that constructs a menu item button
  /// [ButtonStyle] given simple values.
  ///
  /// The [foregroundColor] color is used to create a [MaterialStateProperty]
  /// [ButtonStyle.foregroundColor] value. Specify a value for [foregroundColor]
  /// to specify the color of the button's icons. The [hoverColor], [focusColor]
  /// and [highlightColor] colors are used to indicate the hover, focus,
  /// and pressed states. Use [backgroundColor] for the button's background
  /// fill color. Use [disabledForegroundColor] and [disabledBackgroundColor]
  /// to specify the button's disabled icon and fill color.
  ///
  /// All of the other parameters are either used directly or used to
  /// create a [MaterialStateProperty] with a single value for all
  /// states.
  ///
  /// All parameters default to null, by default this method returns
  /// a [ButtonStyle] that doesn't override anything.
  ///
  /// For example, to override the default foreground color for a
  /// [MenuItemButton], as well as its overlay color, with all of the
  /// standard opacity adjustments for the pressed, focused, and
  /// hovered states, one could write:
  ///
  /// ```dart
  /// MenuItemButton(
  ///   leadingIcon: const Icon(Icons.pets),
  ///   style: MenuItemButton.styleFrom(foregroundColor: Colors.green),
  ///   onPressed: () {
  ///     // ...
  ///   },
  ///   child: const Text('Button Label'),
  /// ),
  /// ```
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    BorderSide? side,
    OutlinedBorder? shape,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
  }) {
    return TextButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation,
      padding: padding,
      minimumSize: minimumSize,
      fixedSize: fixedSize,
      maximumSize: maximumSize,
      side: side,
      shape: shape,
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('child', child.toString(), defaultValue: null));
    properties.add(FlagProperty('enabled', value: onPressed != null, ifFalse: 'DISABLED'));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
  }
}

class _MenuItemButtonState extends State<MenuItemButton> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _createInternalFocusNodeIfNeeded();
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
      _createInternalFocusNodeIfNeeded();
      _focusNode.addListener(_handleFocusChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      // Close any child menus of this menu.
      _MenuNode.maybeOf(context)?.closeChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle mergedStyle =
      widget.style?.merge(widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context))) ??
      widget.themeStyleOf(context)?.merge(widget.defaultStyleOf(context)) ??
      widget.defaultStyleOf(context);

    return TextButton(
      onPressed: _enabled ? _handleSelect : null,
      onHover: _enabled ? _handleHover : null,
      onLongPress: _enabled ? widget.onLongPress : null,
      onFocusChange: _enabled ? widget.onFocusChange : null,
      focusNode: _focusNode,
      style: mergedStyle,
      statesController: widget.statesController,
      clipBehavior: widget.clipBehavior,
      child: _MenuItemLabel(
        leadingIcon: widget.leadingIcon,
        shortcut: widget.shortcut,
        trailingIcon: widget.trailingIcon,
        hasSubmenu: false,
        child: widget.child!,
      ),
    );
  }

  void _createInternalFocusNodeIfNeeded() {
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        if (_internalFocusNode != null) {
          _internalFocusNode!.debugLabel = '$MenuItemButton(${widget.child})';
        }
        return true;
      }());
    }
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
    assert(_menuDebug('Selected ${widget.child} menu'));
    widget.onPressed?.call();
    MenuController.of(context).closeAll();
  }
}

/// A menu item widget that displays a hierarchical cascading menu as part of a
/// [MenuBar].
///
/// This widget represents an item in a [MenuBar] that has a submenu. Like the
/// leaf [MenuItemButton], it shows a label with an optional leading or trailing
/// icon, along with an arrow icon showing that it has a submenu.
///
/// By default the submenu will appear to the side of the controlling button.
/// The alignment and offset of the submenu can be controlled by setting
/// [alignment] and [alignmentOffset], respectively.
///
/// When activated (clicked, through keyboard navigation, or via hovering with a
/// mouse), it will open a submenu containing the [menuChildren].
///
/// See also:
///
/// * [MenuItemButton], a widget that represents a leaf menu item that does not
///   host a submenu.
/// * [MenuBar], a widget that renders menu items in a row in a Material Design
///   style.
/// * [PlatformMenuBar], a widget that renders similar menu bar items from a
///   [PlatformMenuItem] using platform-native APIs instead of Flutter.
class MenuButton extends ButtonStyleButton {
  /// Creates a const [MenuButton].
  ///
  /// The [child] attribute is required.
  const MenuButton({
    super.key,
    super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.clipBehavior = Clip.none,
    this.leadingIcon,
    this.trailingIcon,
    this.onOpen,
    this.onClose,
    this.menuStyle,
    this.alignmentOffset,
    required this.menuChildren,
    required super.child,
  });

  /// The offset in pixels of the menu relative to the alignment origin
  /// determined by [alignment].
  ///
  /// Use this for fine adjustments of the menu placement.
  ///
  /// Defaults to the start portion of [MenuThemeData.padding] for menus
  /// whose parent menu (the menu that the button for this menu resides in) is
  /// vertical, and the top portion of [MenuThemeData.padding] when it is
  /// horizontal.
  final Offset? alignmentOffset;

  /// An optional icon to display before the [child].
  final Widget? leadingIcon;

  /// An optional icon to display after the [child].
  final Widget? trailingIcon;

  /// The [MenuStyle] of the menu specified by [menuChildren].
  ///
  /// Defaults to the value of [MenuThemeData.style] of the
  /// ambient [MenuTheme].
  final MenuStyle? menuStyle;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// The list of widgets that appear in the menu when it is opened.
  ///
  /// These can be any widget, but are typically either [MenuItemButton] or
  /// [MenuButton] widgets.
  final List<Widget> menuChildren;

  /// Defines the button's default appearance.
  ///
  /// The button [child]'s [Text] and [Icon] widgets are rendered with
  /// the [ButtonStyle]'s foreground color. The button's [InkWell] adds
  /// the style's overlay color when the button is focused, hovered
  /// or pressed. The button's background color becomes its [Material]
  /// color and is transparent by default.
  ///
  /// All of the ButtonStyle's defaults appear below.
  ///
  /// In this list "Theme.foo" is shorthand for
  /// `Theme.of(context).foo`. Color scheme values like
  /// "onSurface(0.38)" are shorthand for
  /// `onSurface.withOpacity(0.38)`. [MaterialStateProperty] valued
  /// properties that are not followed by a sublist have the same
  /// value for all states, otherwise the values are as specified for
  /// each state and "others" means all other states.
  ///
  /// The `textScaleFactor` is the value of
  /// `MediaQuery.of(context).textScaleFactor` and the names of the
  /// EdgeInsets constructors and `EdgeInsetsGeometry.lerp` have been
  /// abbreviated for readability.
  ///
  /// The color of the [ButtonStyle.textStyle] is not used, the
  /// [ButtonStyle.foregroundColor] color is used instead.
  ///
  /// * `textStyle` - Theme.textTheme.labelLarge
  /// * `backgroundColor` - transparent
  /// * `foregroundColor`
  ///   * disabled - Theme.colorScheme.onSurface(0.38)
  ///   * others - Theme.colorScheme.primary
  /// * `overlayColor`
  ///   * hovered - Theme.colorScheme.primary(0.08)
  ///   * focused or pressed - Theme.colorScheme.primary(0.12)
  ///   * others - null
  /// * `shadowColor` - null
  /// * `surfaceTintColor` - null
  /// * `elevation` - 0
  /// * `padding`
  ///   * `textScaleFactor <= 1` - all(8)
  ///   * `1 < textScaleFactor <= 2` - lerp(all(8), horizontal(8))
  ///   * `2 < textScaleFactor <= 3` - lerp(horizontal(8), horizontal(4))
  ///   * `3 < textScaleFactor` - horizontal(4)
  /// * `minimumSize` - Size(64, 40)
  /// * `fixedSize` - null
  /// * `maximumSize` - Size.infinite
  /// * `side` - null
  /// * `shape` - StadiumBorder()
  /// * `mouseCursor`
  ///   * disabled - SystemMouseCursors.basic
  ///   * others - SystemMouseCursors.click
  /// * `visualDensity` - theme.visualDensity
  /// * `tapTargetSize` - theme.materialTapTargetSize
  /// * `animationDuration` - kThemeChangeDuration
  /// * `enableFeedback` - true
  /// * `alignment` - Alignment.center
  /// * `splashFactory` - Theme.splashFactory
  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    return _MenuButtonDefaultsM3(context);
  }

  /// Returns the [MenuButtonThemeData.style] of the closest
  /// [MenuButtonTheme] ancestor.
  @override
  ButtonStyle? themeStyleOf(BuildContext context) {
    return MenuButtonTheme.of(context).style;
  }

  @override
  State<MenuButton> createState() => _MenuButtonState();

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...menuChildren.map<DiagnosticsNode>((Widget child) {
        return child.toDiagnosticsNode();
      })
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', child.toString(), defaultValue: null));
    properties.add(DiagnosticsProperty<MenuStyle>('menuStyle', menuStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('leadingIcon', leadingIcon, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('trailingIcon', trailingIcon, defaultValue: null));
  }
}

class _MenuButtonState extends State<MenuButton> {
  late _ChildMenuNode _node;
  MenuEntry? _childMenu;
  bool get _enabled => widget.menuChildren.isNotEmpty;
  late FocusScopeNode _menuScopeNode;
  FocusNode? _internalFocusNode;
  MenuController? _internalMenuController;
  FocusNode get _buttonFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _menuScopeNode = FocusScopeNode();
    assert(() {
      _menuScopeNode.debugLabel = '$MenuButton(Scope for ${widget.child})';
      return true;
    }());
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      assert(() {
        if (_internalFocusNode != null) {
          _internalFocusNode!.debugLabel = '$MenuButton(${widget.child})';
        }
        return true;
      }());
    }
    _buttonFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _menuScopeNode.dispose();
    _node.dispose();
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
      if (widget.focusNode == null) {
        _internalFocusNode ??= FocusNode();
        assert(() {
          if (_internalFocusNode != null) {
            _internalFocusNode!.debugLabel = '$MenuButton(${widget.child})';
          }
          return true;
        }());
      }
      _buttonFocusNode.addListener(_handleFocusChange);
    }
    _updateChildMenu();
    super.didUpdateWidget(oldWidget);
  }

  void _updateChildMenu() {
    final MenuController controller = MenuController.maybeOf(context) ?? (_internalMenuController ??= MenuController());
    final _MenuNode parent = _MenuNode.maybeOf(context) ?? controller._root;
    final MenuStyle? themeStyle = MenuTheme.of(context).style;
    final MenuStyle defaultStyle = _MenuDefaultsM3(context);

    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(widget.menuStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    T? resolve<T>(MaterialStateProperty<T>? Function(MenuStyle? style) getProperty) {
      return effectiveValue(
        (MenuStyle? style) {
          return getProperty(style)?.resolve(widget.statesController?.value ?? const<MaterialState>{});
        },
      );
    }

    final Offset menuPaddingOffset;
    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsets menuPadding = resolve<EdgeInsetsGeometry?>((MenuStyle? style) => style?.padding)!.resolve(textDirection);
    switch (parent.orientation) {
      case Axis.horizontal:
        switch (textDirection) {
          case TextDirection.rtl:
            menuPaddingOffset = widget.alignmentOffset ?? Offset(-menuPadding.right, 0);
            break;
          case TextDirection.ltr:
            menuPaddingOffset = widget.alignmentOffset ?? Offset(-menuPadding.left, 0);
            break;
        }
        break;
      case Axis.vertical:
        menuPaddingOffset = widget.alignmentOffset ?? Offset(0, -menuPadding.top);
        break;
    }

    if (_childMenu == null) {
      _node = _ChildMenuNode(
        parent: parent,
        controller: controller,
        buttonFocusNode: _buttonFocusNode,
        menuScopeNode: _menuScopeNode,
        buttonStyle: widget.style,
        menuStyle: widget.menuStyle,
        menuClipBehavior: widget.clipBehavior,
        onOpen: widget.onOpen,
        onClose: widget.onClose,
        alignmentOffset: menuPaddingOffset,
        widgetChildren: widget.menuChildren,
        statesController: widget.statesController,
      );
      _childMenu = _createMenuEntryFromExistingNode(_node);
    } else {
      _node
        ..parent = parent
        ..controller = controller
        ..buttonFocusNode = _buttonFocusNode
        ..menuScopeNode = _menuScopeNode
        ..buttonStyle = widget.style
        ..menuStyle = widget.menuStyle
        ..menuClipBehavior = widget.clipBehavior
        ..onOpen = widget.onOpen
        ..onClose = widget.onClose
        ..alignmentOffset = menuPaddingOffset
        ..widgetChildren = widget.menuChildren
        ..statesController = widget.statesController;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MenuNodeMarker(
      node: _node,
      child: TextButton(
        style: widget.style ?? MenuButtonTheme.of(context).style ?? _MenuButtonDefaultsM3(context),
        focusNode: _buttonFocusNode,
        onHover: _enabled ? _handleHover : null,
        onPressed: _enabled ? maybeToggleShowMenu : null,
        child: _MenuItemLabel(
          leadingIcon: widget.leadingIcon,
          trailingIcon: widget.trailingIcon,
          hasSubmenu: true,
          showDecoration: !_node.isTopLevel,
          child: widget.child!,
        ),
      ),
    );
  }

  void maybeToggleShowMenu() {
    if (_node.isOpen) {
      _node.close();
    } else {
      _node.open();
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        // Has to happen in the next frame because the menu bar is not focusable
        // until the first menu is open.
        _node.focusButton();
      });
    }
  }

  // Called when the pointer is hovering over the menu button.
  void _handleHover(bool hovering) {
    widget.onHover?.call(hovering);

    // Don't open the root menu bar menus on hover unless something else
    // is already open. This means that the user has to first click to open a
    // menu on the menu bar before hovering allows them to traverse it.
    if (_node.isTopLevel && !_node.controller.menuIsOpen) {
      return;
    }

    if (hovering) {
      _node.open();
      _node.focusButton();
    }
  }

  void _handleFocusChange() {
    if (_buttonFocusNode.hasPrimaryFocus) {
      _node.open();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('label', widget.child.toString()));
  }
}

/// A handle to a menu created by [createMaterialMenu].
///
/// A `MenuEntry` can only be created by calling [createMaterialMenu].
///
/// `MenuEntry` is used to control and interrogate a menu after it has been
/// created, with methods such as [open] and [close], attributes like [enabled],
/// [menuStyle], [alignment], [alignmentOffset], and state like [isOpen].
///
/// The [dispose] method must be called when the menu is no longer needed.
///
/// `MenuEntry` is a [ChangeNotifier]. To register for changes, call
/// [addListener], and when you're done listening, call [removeListener].  It
/// notifies its listeners when its attributes (e.g. [enabled], [alignment],
/// etc.) change.
///
/// See also:
///
/// * [createMaterialMenu], the function that creates a menu given a focus node
///   for the controlling widget and the desired menus, and returns a
///   `MenuEntry`.
/// * [MenuBar], a widget that manages its own `MenuEntry` internally.
/// * [MenuButton], a widget that has a button that manages a submenu.
/// * [MenuItemButton], a widget that draws a menu button with optional shortcut
///   labels.
class MenuEntry with ChangeNotifier {
  /// Private constructor because menu entries can only be created by
  /// [createMaterialMenu].
  MenuEntry._(this._entry) {
    _entry.addListener(notifyListeners);
  }

  final _ChildMenuNode _entry;

  /// The controller that this menu handle is associated with.
  MenuController get controller => _entry.controller;

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

  /// Sets the alignment of the origin of the menu relative to the rectangle
  /// occupied by the controlling widget that the menu is attached to.
  ///
  /// The alignment depends on the value of the ambient [Directionality] of the
  /// controlling widget to know which direction is the 'start' of the widget.
  AlignmentGeometry? get alignment => _entry.menuStyle!.alignment;
  set alignment(AlignmentGeometry? value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the menuStyle value will automatically check for changes and
    // notify listeners.
    if (alignment == null) {
      _entry.menuStyle = _entry.menuStyle?.copyWithout(alignment: true);
      return;
    }
    _entry.menuStyle = _entry.menuStyle?.copyWith(alignment: value) ?? MenuStyle(alignment: value);
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

  /// Sets the [MenuStyle] to use for configuring the menu.
  ///
  /// Setting this value will change the visual presentation of the menu to
  /// match the given theme. Setting it to null will return the menu to default
  /// values derived from the ambient [MenuTheme].
  ///
  /// If the menu is already open, then the theme for the menu will be updated.
  MenuStyle? get menuStyle => _entry.menuStyle;
  set menuStyle(MenuStyle? value) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    // Setting the _entry value will automatically check for changes and notify listeners.
    _entry.menuStyle = value;
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
/// Calling `createMaterialMenu` creates a new cascading menu controlled by
/// another widget, typically some type of button.
///
/// The menu is created in a closed state, and [MenuEntry.open] must be called
/// for the menu to be shown.
///
/// An optional [MenuController] may be supplied to allow this menu to be
/// coordinated with other related menus. The supplied controller is owned by
/// the caller, and must be disposed by the owner when it is no longer in use.
/// If a `controller` is supplied, calling [MenuController.closeAll] on the
/// controller will close all associated menus.
///
/// The returned [MenuEntry] allows control of menu visibility, and
/// reconfiguration of the menu. Setting values on the returned [MenuEntry] will
/// update the menu with those changes in the next frame. The [MenuEntry] can be
/// listened to for state changes.
///
/// {@tool dartpad}
/// This example shows a menu created with `createMaterialMenu` that contains a
/// single top level menu, containing three items: one for "About", a checkbox
/// menu item for showing a message, and "Quit". The items are identified with
/// an enum value.
///
/// ** See code in examples/api/lib/material/menu_bar/create_material_menu.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [MenuEntry], the handle returned from this function.
/// * [MenuBar], a widget that creates and manages a menu bar with cascading
///   menus.
MenuEntry createMaterialMenu(
  FocusNode buttonFocusNode, {
  MenuController? controller,
  MaterialStatesController? statesController,
  MenuStyle? style,
  Clip clipBehavior = Clip.none,
  VoidCallback? onOpen,
  VoidCallback? onClose,
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
    statesController: statesController,
    menuScopeNode: menuScopeNode,
    parent: controller._root,
    menuStyle: style,
    menuClipBehavior: clipBehavior,
    onOpen: onOpen,
    onClose: onClose,
    alignmentOffset: alignmentOffset,
    widgetChildren: children,
  );
  return _createMenuEntryFromExistingNode(entry);
}

MenuEntry _createMenuEntryFromExistingNode(_ChildMenuNode node) {
  assert(_menuDebug('Creating menu entry from $node'));
  final MenuEntry menuEntry = MenuEntry._(node);
  node.overlayEntry = OverlayEntry(builder: (BuildContext context) {
    final OverlayState overlay = Overlay.of(context)!;
    return _MenuNodeMarker(
      node: node,
      child: InheritedTheme.captureAll(
        // Copy all the themes from the menu bar to the overlay.
        node.topLevel.context,
        _Submenu(node: node),
        to: overlay.context,
      ),
    );
  });
  return menuEntry;
}

// A widget that is defines the menu inside of the overlay entry.
class _Submenu extends StatefulWidget {
  const _Submenu({required this.node});

  final _ChildMenuNode node;

  @override
  State<_Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<_Submenu> {
  MaterialStatesController? internalStatesController;

  void handleStatesControllerChange() {
    // Force a rebuild to resolve MaterialStateProperty properties
    setState(() {});
  }

  MaterialStatesController get statesController => widget.node.statesController ?? internalStatesController!;

  void initStatesController() {
    if (widget.node.statesController == null) {
      internalStatesController = MaterialStatesController();
    }
    statesController.addListener(handleStatesControllerChange);
  }

  @override
  void initState() {
    super.initState();
    initStatesController();
  }

  @override
  void didUpdateWidget(_Submenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.statesController != oldWidget.node.statesController) {
      oldWidget.node.statesController?.removeListener(handleStatesControllerChange);
      if (widget.node.statesController != null) {
        internalStatesController?.dispose();
        internalStatesController = null;
      }
      initStatesController();
    }
  }

  @override
  void dispose() {
    statesController.removeListener(handleStatesControllerChange);
    internalStatesController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.node,
      builder: (BuildContext context, Widget? ignoredChild) {
        // Use the text direction of the context where the button is.
        final TextDirection textDirection = Directionality.of(widget.node.topLevel.context);
        final MenuButtonThemeData menuButtonTheme = MenuButtonTheme.of(context);
        final Set<MaterialState> state = <MaterialState>{
          if (!widget.node.enabled) MaterialState.disabled,
        };

        final MenuStyle? themeStyle;
        final MenuStyle defaultStyle;
        switch (widget.node.parent.orientation) {
          case Axis.horizontal:
            themeStyle = MenuBarTheme.of(context).style;
            defaultStyle = _MenuBarDefaultsM3(context);
            break;
          case Axis.vertical:
            themeStyle = MenuTheme.of(context).style;
            defaultStyle = _MenuDefaultsM3(context);
            break;
        }
        final MenuStyle? widgetStyle = widget.node.menuStyle;

        T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
          return getProperty(widgetStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
        }

        final MaterialStateMouseCursor mouseCursor = _MouseCursor(
          (Set<MaterialState> states) => effectiveValue((MenuStyle? style) => style?.mouseCursor?.resolve(states)),
        );

        final VisualDensity visualDensity =
            effectiveValue((MenuStyle? style) => style?.visualDensity) ?? VisualDensity.standard;
        final AlignmentGeometry alignment = effectiveValue((MenuStyle? style) => style?.alignment)!;

        final EdgeInsetsGeometry buttonPadding = widget.node.buttonStyle?.padding?.resolve(state) ??
            menuButtonTheme.style?.padding?.resolve(state) ??
            _MenuButtonDefaultsM3(context).padding!.resolve(state);

        return MouseRegion(
          cursor: mouseCursor,
          hitTestBehavior: HitTestBehavior.deferToChild,
          child: Theme(
            data: Theme.of(context).copyWith(
              visualDensity: visualDensity,
            ),
            child: CustomSingleChildLayout(
              delegate: _MenuLayout(
                buttonRect: _getMenuButtonRect(),
                textDirection: textDirection,
                buttonPadding: buttonPadding,
                avoidBounds: DisplayFeatureSubScreen.avoidBounds(MediaQuery.of(context)).toSet(),
                alignment: alignment,
                alignmentOffset: widget.node.alignmentOffset,
                menuNode: widget.node,
              ),
              child: FocusScope(
                node: widget.node.menuScopeNode,
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    DirectionalFocusIntent: _MenuDirectionalFocusAction(controller: widget.node.controller),
                    DismissIntent: _MenuDismissAction(controller: widget.node.controller),
                  },
                  child: Shortcuts(
                    shortcuts: _kMenuTraversalShortcuts,
                    child: _MenuControllerMarker(
                      controller: widget.node.controller,
                      child: Directionality(
                        // Copy the directionality from the button into the overlay.
                        textDirection: textDirection,
                        child: _MenuPanel(
                          menuStyle: widgetStyle,
                          clipBehavior: widget.node.menuClipBehavior,
                          statesController: statesController,
                          orientation: widget.node.orientation,
                          children: MenuItemGroup._expandGroups(widget.node.widgetChildren, Axis.vertical),
                        ),
                      ),
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

  RelativeRect _getMenuButtonRect() {
    final RenderBox button = widget.node.context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(widget.node.context)!.context.findRenderObject()! as RenderBox;
    final Offset upperLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Offset lowerRight = button.localToGlobal(button.paintBounds.bottomRight, ancestor: overlay);
    return RelativeRect.fromRect(Rect.fromPoints(upperLeft, lowerRight), overlay.paintBounds);
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
  ///
  /// Defaults to [Axis.vertical].
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
/// [MenuBar] or to call [createMaterialMenu], but if open menus need to be
/// closed with the [closeAll] method in response to an event, a
/// `MenuController` can be created and passed to the [MenuBar] or
/// [createMaterialMenu].
///
/// The controller can be listened to for some changes in the state of the menu
/// bar, to see if [menuIsOpen] has changed, for instance.
///
/// The [dispose] method must be called on the controller when it is no longer
/// needed.
class MenuController with Diagnosticable, ChangeNotifier {
  /// Creates a [MenuController] that can be used with a [MenuBar] or
  /// [createMaterialMenu].
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
class _MenuNodeMarker extends InheritedWidget {
  const _MenuNodeMarker({
    required this.node,
    required super.child,
  });

  final _MenuNode node;

  @override
  bool updateShouldNotify(_MenuNodeMarker oldWidget) {
    return node != oldWidget.node;
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
class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    required this.menuStyle,
    required this.statesController,
    this.clipBehavior = Clip.none,
    required this.orientation,
    required this.children,
  });

  /// The menu style that has all the attributes for this menu panel.
  final MenuStyle? menuStyle;

  /// The [MaterialStatesController] that manages the states for this panel.
  final MaterialStatesController statesController;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The layout orientation of this panel.
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

  @override
  Widget build(BuildContext context) {
    final MenuStyle? themeStyle;
    final MenuStyle defaultStyle;
    switch (widget.orientation) {
      case Axis.horizontal:
        themeStyle = MenuBarTheme.of(context).style;
        defaultStyle = _MenuBarDefaultsM3(context);
        break;
      case Axis.vertical:
        themeStyle = MenuTheme.of(context).style;
        defaultStyle = _MenuDefaultsM3(context);
        break;
    }
    final MenuStyle? widgetStyle = widget.menuStyle;

    T? effectiveValue<T>(T? Function(MenuStyle? style) getProperty) {
      return getProperty(widgetStyle) ?? getProperty(themeStyle) ?? getProperty(defaultStyle);
    }

    T? resolve<T>(MaterialStateProperty<T>? Function(MenuStyle? style) getProperty) {
      return effectiveValue(
        (MenuStyle? style) {
          return getProperty(style)?.resolve(widget.statesController.value);
        },
      );
    }

    final Color? backgroundColor = resolve<Color?>((MenuStyle? style) => style?.backgroundColor);
    final Color? shadowColor = resolve<Color?>((MenuStyle? style) => style?.shadowColor);
    final Color? surfaceTintColor = resolve<Color?>((MenuStyle? style) => style?.surfaceTintColor);
    final double elevation = resolve<double?>((MenuStyle? style) => style?.elevation) ?? 0;
    final EdgeInsetsGeometry padding =
        resolve<EdgeInsetsGeometry?>((MenuStyle? style) => style?.padding) ?? EdgeInsets.zero;
    final Size? minimumSize = resolve<Size?>((MenuStyle? style) => style?.minimumSize);
    final Size? fixedSize = resolve<Size?>((MenuStyle? style) => style?.fixedSize);
    final Size? maximumSize = resolve<Size?>((MenuStyle? style) => style?.maximumSize);
    final BorderSide? side = resolve<BorderSide?>((MenuStyle? style) => style?.side);
    final OutlinedBorder shape = resolve<OutlinedBorder?>((MenuStyle? style) => style?.shape)!.copyWith(side: side);
    final VisualDensity visualDensity =
        effectiveValue((MenuStyle? style) => style?.visualDensity) ?? VisualDensity.standard;
    final Offset densityAdjustment = visualDensity.baseSizeAdjustment;

    BoxConstraints effectiveConstraints = visualDensity.effectiveConstraints(
      BoxConstraints(
        minWidth: minimumSize?.width ?? 0,
        minHeight: minimumSize?.height ?? 0,
        maxWidth: maximumSize?.width ?? double.infinity,
        maxHeight: maximumSize?.height ?? double.infinity,
      ),
    );
    if (fixedSize != null) {
      final Size size = effectiveConstraints.constrain(fixedSize);
      if (size.width.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minWidth: size.width,
          maxWidth: size.width,
        );
      }
      if (size.height.isFinite) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minHeight: size.height,
          maxHeight: size.height,
        );
      }
    }

    // Per the Material Design team: don't allow the VisualDensity
    // adjustment to reduce the width of the left/right padding. If we
    // did, VisualDensity.compact, the default for desktop/web, would
    // reduce the horizontal padding to zero.
    final double dy = densityAdjustment.dy;
    final double dx = math.max(0, densityAdjustment.dx);
    final EdgeInsetsGeometry resolvedPadding = padding
        .add(EdgeInsets.fromLTRB(dx, dy, dx, dy))
        .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity); // ignore_clamp_double_lint

    final MenuController controller = MenuController.of(context);
    return ConstrainedBox(
      constraints: effectiveConstraints,
      child: TapRegion(
        groupId: controller,
        onTapOutside: (PointerDownEvent event) {
          MenuController.of(context).closeAll();
        },
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: widget.orientation == Axis.horizontal ? Axis.vertical : Axis.horizontal,
          child: _intrinsicCrossSize(
            child: Material(
              elevation: elevation,
              shape: shape,
              color: backgroundColor,
              shadowColor: shadowColor,
              surfaceTintColor: surfaceTintColor,
              type: backgroundColor == null ? MaterialType.transparency : MaterialType.canvas,
              clipBehavior: widget.clipBehavior,
              child: Padding(
                padding: resolvedPadding,
                child: SingleChildScrollView(
                  scrollDirection: widget.orientation,
                  child: Flex(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: Directionality.of(context),
                    direction: widget.orientation,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.children,
                  ),
                ),
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
/// It not only shows the [MenuButton.child] or [MenuItemButton.child], but if
/// there is a shortcut associated with the [MenuItemButton], it will display a
/// mnemonic for the shortcut. For [MenuButton]s, it will display a visual
/// indicator that there is a submenu.
class _MenuItemLabel extends StatelessWidget {
  /// Creates a const [_MenuItemLabel].
  ///
  /// The [child] and [hasSubmenu] arguments are required.
  const _MenuItemLabel({
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

// Positions the menu in the view while trying to keep as much as possible
// visible in the view.
class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({
    required this.buttonRect,
    required this.textDirection,
    required this.buttonPadding,
    required this.alignment,
    required this.alignmentOffset,
    required this.avoidBounds,
    required this.menuNode,
  });

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final RelativeRect buttonRect;

  // Whether to prefer going to the left or to the right.
  final TextDirection textDirection;

  // The padding around the button opening the menu. This is used to determine
  // how far away from the edge of the screen to place the menu, since otherwise
  // the first menu in a menu bar will be closer to the edge of the screen than
  // allowed, and will get moved over.
  final EdgeInsetsGeometry buttonPadding;

  // The alignment to use when finding the ideal location for the menu.
  AlignmentGeometry alignment;

  // The offset from the alignment to add to the alignment position to find the
  // ideal location for the menu.
  Offset alignmentOffset;

  // List of rectangles that we should avoid overlapping. Unusable screen area.
  final Set<Rect> avoidBounds;

  final _MenuNode menuNode;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus 8.0 pixels in each
    // direction.
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuViewPadding),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by
    // getConstraintsForChild.
    final Rect overlayRect = Offset.zero & size;
    final Rect absoluteButtonRect = buttonRect.toRect(overlayRect);
    final Alignment alignment = this.alignment.resolve(textDirection);
    final Offset desiredPosition = alignment.withinRect(absoluteButtonRect);
    final Offset originCenter = absoluteButtonRect.center;
    final Iterable<Rect> subScreens = DisplayFeatureSubScreen.subScreensInBounds(overlayRect, avoidBounds);
    final Rect screen = _closestScreen(subScreens, originCenter);
    final EdgeInsets resolvedButtonPadding = buttonPadding.resolve(textDirection);

    double x = desiredPosition.dx;
    double y = desiredPosition.dy + alignmentOffset.dy;
    final Rect allowedRect = Rect.fromLTRB(
      screen.left + resolvedButtonPadding.left,
      screen.top + resolvedButtonPadding.top,
      screen.right - resolvedButtonPadding.right,
      screen.bottom - resolvedButtonPadding.bottom,
    );

    switch (textDirection) {
      case TextDirection.rtl:
        x -= childSize.width + alignmentOffset.dx;
        break;
      case TextDirection.ltr:
        x += alignmentOffset.dx;
        break;
    }

    bool offLeftSide(double x) => x < allowedRect.left;
    bool offRightSide(double x) => x + childSize.width > allowedRect.right;
    bool offTop(double y) => y < allowedRect.top;
    bool offBottom(double y) => y + childSize.height > allowedRect.bottom;
    // Avoid going outside an area defined as the rectangle offset from the
    // edge of the screen by the button padding. If the menu is off of the screen,
    // move the menu to the other side of the button first, and then if it
    // doesn't fit there, then just move it over as much as needed to make it
    // fit.
    if (childSize.width >= allowedRect.width) {
      // It just doesn't fit, so put as much on the screen as possible.
      x = allowedRect.left;
    } else {
      if (offLeftSide(x)) {
        // If the parent is a different orientation than the current one, then
        // just push it over instead of trying the other side.
        if (menuNode.parent.orientation != menuNode.orientation) {
          x = allowedRect.left;
        } else {
          final double newX = absoluteButtonRect.right;
          if (!offRightSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.left;
          }
        }
      } else if (offRightSide(x)) {
        if (menuNode.parent.orientation != menuNode.orientation) {
          x = allowedRect.right - childSize.width;
        } else {
          final double newX = absoluteButtonRect.left - childSize.width;
          if (!offLeftSide(newX)) {
            x = newX;
          } else {
            x = allowedRect.right - childSize.width;
          }
        }
      }
    }
    if (childSize.height >= allowedRect.height) {
      // Too tall to fit, fit as much on as possible.
      y = allowedRect.top;
    } else {
      if (offTop(y)) {
        final double newY = absoluteButtonRect.bottom;
        if (!offBottom(newY)) {
          y = newY;
        } else {
          y = allowedRect.top;
        }
      } else if (offBottom(y)) {
        final double newY = absoluteButtonRect.top - childSize.height;
        if (!offTop(newY)) {
          y = newY;
        } else {
          y = allowedRect.bottom - childSize.height;
        }
      }
    }
    return Offset(x, y);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance < (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        textDirection != oldDelegate.textDirection ||
        alignment != oldDelegate.alignment ||
        alignmentOffset != oldDelegate.alignmentOffset ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
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

  @protected
  List<_ChildMenuNode> children = <_ChildMenuNode>[];

  void addChild(_ChildMenuNode child) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(isRoot || _menuDebug('Added root child: $child'));
    assert(!children.contains(child));
    children.add(child);
  }

  void removeChild(_ChildMenuNode child) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(isRoot || _menuDebug('Removed root child: $child'));
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

  void focusButton();

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
    return context.dependOnInheritedWidgetOfExactType<_MenuNodeMarker>()?.node;
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

  @override
  void focusButton() {}
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
    Offset alignmentOffset = Offset.zero,
    Axis orientation = Axis.vertical,
    ButtonStyle? buttonStyle,
    MenuStyle? menuStyle,
    MenuStyle? menuBarStyle,
    Clip menuClipBehavior = Clip.none,
    MaterialStatesController? statesController,
  })  : _buttonFocusNode = buttonFocusNode,
        _buttonKey = buttonKey,
        _controller = controller,
        _statesController = statesController,
        _widgetChildren = widgetChildren,
        _orientation = orientation,
        _alignmentOffset = alignmentOffset,
        _buttonStyle = buttonStyle,
        _menuStyle = menuStyle,
        _menuClipBehavior = menuClipBehavior,
        _menuBarStyle = menuBarStyle {
    parent.addChild(this);
  }

  @override
  MenuController get controller => _controller;
  MenuController _controller;
  set controller(MenuController value) {
    if (_controller != value) {
      _controller = value;
      _notifyNextFrame();
    }
  }

  MaterialStatesController? get statesController => _statesController;
  MaterialStatesController? _statesController;
  set statesController(MaterialStatesController? value) {
    if (_statesController != value) {
      _statesController = value;
      _notifyNextFrame();
    }
  }

  @override
  bool get isRoot => false;

  @override
  _MenuNode parent;

  OverlayEntry? overlayEntry;
  bool isOpen = false;
  VoidCallback? onOpen;
  VoidCallback? onClose;

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

  MenuStyle? get menuBarStyle => _menuBarStyle;
  MenuStyle? _menuBarStyle;
  set menuBarStyle(MenuStyle? value) {
    if (_menuBarStyle != value) {
      _menuBarStyle = value;
      _notifyNextFrame();
    }
  }

  MenuStyle? get menuStyle => _menuStyle;
  MenuStyle? _menuStyle;
  set menuStyle(MenuStyle? value) {
    if (_menuStyle != value) {
      _menuStyle = value;
      _notifyNextFrame();
    }
  }

  Clip get menuClipBehavior => _menuClipBehavior;
  Clip _menuClipBehavior;
  set menuClipBehavior(Clip value) {
    if (_menuClipBehavior != value) {
      _menuClipBehavior = value;
      _notifyNextFrame();
    }
  }

  ButtonStyle? get buttonStyle => _buttonStyle;
  ButtonStyle? _buttonStyle;
  set buttonStyle(ButtonStyle? value) {
    if (_buttonStyle != value) {
      _buttonStyle = value;
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
    assert(_menuDebug('In _MenuDirectionalFocusAction, current node is ${currentMenu.buttonFocusNode.debugLabel}, '
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

class _MouseCursor extends MaterialStateMouseCursor {
  const _MouseCursor(this.resolveCallback);

  final MaterialPropertyResolver<MouseCursor?> resolveCallback;

  @override
  MouseCursor resolve(Set<MaterialState> states) => resolveCallback(states) ?? MouseCursor.uncontrolled;

  @override
  String get debugDescription => 'Menu_MouseCursor';
}

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

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuButtonDefaultsM3 extends ButtonStyle {
  _MenuButtonDefaultsM3(this.context)
      : super(
          animationDuration: kThemeChangeDuration,
          enableFeedback: true,
          alignment: AlignmentDirectional.centerStart,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<TextStyle?> get textStyle =>
      MaterialStatePropertyAll<TextStyle?>(Theme.of(context).textTheme.labelLarge);

  @override
  MaterialStateProperty<Color?>? get backgroundColor => ButtonStyleButton.allOrNull<Color>(Colors.transparent);

  @override
  MaterialStateProperty<Color?>? get foregroundColor => MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        return _colors.primary;
      });

  @override
  MaterialStateProperty<Color?>? get overlayColor => MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.pressed)) {
          return _colors.primary.withOpacity(0.12);
        }
        return null;
      });

  // No default shadow color

  // No default surface tint color

  @override
  MaterialStateProperty<double>? get elevation => ButtonStyleButton.allOrNull<double>(0.0);

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding =>
      ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(_scaledPadding(context));

  @override
  MaterialStateProperty<Size>? get minimumSize => ButtonStyleButton.allOrNull<Size>(const Size(64.0, 40.0));

  // No default fixedSize

  @override
  MaterialStateProperty<Size>? get maximumSize => ButtonStyleButton.allOrNull<Size>(Size.infinite);

  // No default side

  @override
  MaterialStateProperty<OutlinedBorder>? get shape =>
      ButtonStyleButton.allOrNull<OutlinedBorder>(const RoundedRectangleBorder());

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor =>
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      });

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;

  EdgeInsetsGeometry _scaledPadding(BuildContext context) {
    return ButtonStyleButton.scaledPadding(
      const EdgeInsets.all(8),
      const EdgeInsets.symmetric(horizontal: 8),
      const EdgeInsets.symmetric(horizontal: 4),
      MediaQuery.maybeOf(context)?.textScaleFactor ?? 1,
    );
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuDefaultsM3 extends MenuStyle {
  _MenuDefaultsM3(this.context)
      : super(
          elevation: const MaterialStatePropertyAll<double?>(4.0),
          shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
          alignment: AlignmentDirectional.topEnd,
        );

  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        vertical: math.max(
          _kMenuVerticalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dy,
        ),
      ),
    );
  }

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(_colors.surface);
  }
}

// This class will eventually be auto-generated, so it should remain at the end
// of the file.
class _MenuBarDefaultsM3 extends MenuStyle {
  _MenuBarDefaultsM3(this.context)
      : super(
          elevation: const MaterialStatePropertyAll<double?>(4.0),
          shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
          alignment: AlignmentDirectional.bottomStart,
        );

  static const RoundedRectangleBorder _defaultMenuBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(2.0, 3.0)));

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        horizontal: math.max(
          _kTopLevelMenuHorizontalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dx,
        ),
      ),
    );
  }

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(_colors.surface);
  }
}
