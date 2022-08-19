// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'menu_bar.dart';
import 'theme.dart';

// Examples can assume:
// const Widget child = SizedBox();

/// Defines the visual properties of [MenuBar], [MenuButton] and
/// [MenuItemButton] widgets.
///
/// Descendant widgets obtain the current [MenuThemeData] object
/// using `MenuTheme.of(context)`. Instances of
/// [MenuThemeData] can be customized with
/// [MenuThemeData.copyWith].
///
/// Typically, a [MenuThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.menuTheme]. Otherwise,
/// [MenuTheme] can be used to configure its own widget subtree.
///
/// All [MenuThemeData] properties are `null` by default.
/// If any of these properties are null, the menu bar will provide its own
/// defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme for the application.
@immutable
class MenuThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [MenuTheme].
  const MenuThemeData({
    this.barMinimumHeight,
    this.barShape,
    this.barPadding,
    this.barBackgroundColor,
    this.barElevation,
    this.menuBackgroundColor,
    this.menuElevation,
    this.menuShape,
    this.menuPadding,
    this.itemBackgroundColor,
    this.itemForegroundColor,
    this.itemOverlayColor,
    this.itemTextStyle,
    this.itemPadding,
    this.itemShape,
  });

  /// Override the default [MenuBar.minimumHeight].
  final double? barMinimumHeight;

  /// The padding around the outside of a [MenuBar].
  final EdgeInsetsDirectional? barPadding;

  /// The background color of the [MenuBar].
  final MaterialStateProperty<Color?>? barBackgroundColor;

  /// The Material elevation of the [MenuBar].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of how elevation works.
  final MaterialStateProperty<double?>? barElevation;

  /// The shape of a [MenuBar].
  final MaterialStateProperty<OutlinedBorder?>? barShape;

  /// The background color of a [MenuButton].
  final MaterialStateProperty<Color?>? menuBackgroundColor;

  /// The Material elevation of the [MenuButton].
  ///
  /// See also:
  ///
  ///  * [Material.elevation] for a description of how elevation works.
  final MaterialStateProperty<double?>? menuElevation;

  /// The shape of a [MenuButton].
  final MaterialStateProperty<ShapeBorder?>? menuShape;

  /// The padding around the outside of a [MenuButton].
  final EdgeInsetsDirectional? menuPadding;

  // MenuBarItem properties

  /// The background color of a [MenuItemButton].
  final MaterialStateProperty<Color?>? itemBackgroundColor;

  /// The foreground color of a [MenuItemButton], used to color the text and
  /// shortcut labels of a [MenuItemButton].
  final MaterialStateProperty<Color?>? itemForegroundColor;

  /// The overlay color of a [MenuItemButton], used to color the overlay of a
  /// [MenuItemButton], typically seen when the [MaterialState.hovered],
  /// [MaterialState.selected], and/or [MaterialState.focused] states apply.
  final MaterialStateProperty<Color?>? itemOverlayColor;

  /// The text style of the [MenuItemButton]s in a [MenuBar].
  ///
  /// The color in this text style will only be used if [itemForegroundColor]
  /// is unset.
  final MaterialStateProperty<TextStyle?>? itemTextStyle;

  /// The padding around the outside of an individual [MenuItemButton].
  final EdgeInsetsDirectional? itemPadding;

  /// The shape of an individual [MenuItemButton].
  final MaterialStateProperty<OutlinedBorder?>? itemShape;

  /// Creates a copy of this object with the given fields replaced with the new
  /// values.
  MenuThemeData copyWith({
    EdgeInsetsDirectional? barPadding,
    MaterialStateProperty<Color?>? barBackgroundColor,
    MaterialStateProperty<double?>? barElevation,
    MaterialStateProperty<OutlinedBorder?>? barShape,
    MaterialStateProperty<Color?>? menuBackgroundColor,
    MaterialStateProperty<double?>? menuElevation,
    MaterialStateProperty<OutlinedBorder?>? menuShape,
    EdgeInsetsDirectional? menuPadding,
    MaterialStateProperty<Color?>? itemBackgroundColor,
    MaterialStateProperty<Color?>? itemForegroundColor,
    MaterialStateProperty<Color?>? itemOverlayColor,
    MaterialStateProperty<TextStyle?>? itemTextStyle,
    EdgeInsetsDirectional? itemPadding,
    MaterialStateProperty<OutlinedBorder?>? itemShape,
  }) {
    return MenuThemeData(
      barPadding: barPadding ?? this.barPadding,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
      barElevation: barElevation ?? this.barElevation,
      barShape: barShape ?? this.barShape,
      menuBackgroundColor: menuBackgroundColor ?? this.menuBackgroundColor,
      menuElevation: menuElevation ?? this.menuElevation,
      menuShape: menuShape ?? this.menuShape,
      menuPadding: menuPadding ?? this.menuPadding,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      itemForegroundColor: itemForegroundColor ?? this.itemForegroundColor,
      itemOverlayColor: itemOverlayColor ?? this.itemOverlayColor,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      itemPadding: itemPadding ?? this.itemPadding,
      itemShape: itemShape ?? this.itemShape,
    );
  }

  /// Linearly interpolate between two [MenuThemeData]s.
  ///
  /// If both arguments are null, then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static MenuThemeData? lerp(MenuThemeData? a, MenuThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    return MenuThemeData(
      barPadding: EdgeInsetsDirectional.lerp(a?.barPadding, b?.barPadding, t),
      barBackgroundColor: _lerpProperties<Color?>(a?.barBackgroundColor, b?.barBackgroundColor, t, Color.lerp),
      barElevation: _lerpProperties<double?>(a?.barElevation, b?.barElevation, t, lerpDouble),
      barShape: _lerpProperties<OutlinedBorder?>(a?.barShape, b?.barShape, t, OutlinedBorder.lerp),
      menuBackgroundColor: _lerpProperties<Color?>(a?.menuBackgroundColor, b?.menuBackgroundColor, t, Color.lerp),
      menuElevation: _lerpProperties<double?>(a?.menuElevation, b?.menuElevation, t, lerpDouble),
      menuShape: _lerpProperties<ShapeBorder?>(a?.menuShape, b?.menuShape, t, ShapeBorder.lerp),
      menuPadding: EdgeInsetsDirectional.lerp(a?.menuPadding, b?.menuPadding, t),
      itemBackgroundColor: _lerpProperties<Color?>(a?.itemBackgroundColor, b?.itemBackgroundColor, t, Color.lerp),
      itemForegroundColor: _lerpProperties<Color?>(a?.itemForegroundColor, b?.itemForegroundColor, t, Color.lerp),
      itemOverlayColor: _lerpProperties<Color?>(a?.itemOverlayColor, b?.itemOverlayColor, t, Color.lerp),
      itemTextStyle: _lerpProperties<TextStyle?>(a?.itemTextStyle, b?.itemTextStyle, t, TextStyle.lerp),
      itemPadding: EdgeInsetsDirectional.lerp(a?.itemPadding, b?.itemPadding, t),
      itemShape: _lerpProperties<OutlinedBorder?>(
        a?.itemShape,
        b?.itemShape,
        t,
        (OutlinedBorder? a, OutlinedBorder? b, double t) {
          return OutlinedBorder.lerp(a, b, t);
        },
      ),
    );
  }

  static MaterialStateProperty<T>? _lerpProperties<T>(
    MaterialStateProperty<T>? a,
    MaterialStateProperty<T>? b,
    double t,
    T Function(T?, T?, double) lerpFunction,
  ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null) {
      return null;
    }
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }

  @override
  int get hashCode {
    return Object.hash(
      barPadding,
      barBackgroundColor,
      barElevation,
      barShape,
      menuBackgroundColor,
      menuElevation,
      menuShape,
      menuPadding,
      itemBackgroundColor,
      itemForegroundColor,
      itemOverlayColor,
      itemTextStyle,
      itemPadding,
      itemShape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MenuThemeData &&
        other.barPadding == barPadding &&
        other.barBackgroundColor == barBackgroundColor &&
        other.barElevation == barElevation &&
        other.barShape == barShape &&
        other.menuBackgroundColor == menuBackgroundColor &&
        other.menuElevation == menuElevation &&
        other.menuShape == menuShape &&
        other.menuPadding == menuPadding &&
        other.itemBackgroundColor == itemBackgroundColor &&
        other.itemForegroundColor == itemForegroundColor &&
        other.itemOverlayColor == itemOverlayColor &&
        other.itemTextStyle == itemTextStyle &&
        other.itemPadding == itemPadding &&
        other.itemShape == itemShape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional>('barPadding', barPadding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('barBackgroundColor', barBackgroundColor,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<double?>>('barElevation', barElevation, defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('barShape', barShape, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('menuBackgroundColor', menuBackgroundColor,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<double?>>('menuElevation', menuElevation, defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('menuShape', menuShape, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional>('menuPadding', menuPadding, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('itemBackgroundColor', itemBackgroundColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('itemForegroundColor', itemForegroundColor,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<Color?>>('itemOverlayColor', itemOverlayColor, defaultValue: null));
    properties.add(
        DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('itemTextStyle', itemTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional>('menuItemPadding', itemPadding, defaultValue: null));
    properties
        .add(DiagnosticsProperty<MaterialStateProperty<ShapeBorder?>>('itemShape', itemShape, defaultValue: null));
  }
}

class _LerpProperties<T> implements MaterialStateProperty<T> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final MaterialStateProperty<T>? a;
  final MaterialStateProperty<T>? b;
  final double t;
  final T Function(T?, T?, double) lerpFunction;

  @override
  T resolve(Set<MaterialState> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

/// An inherited widget that defines the configuration for [MenuBar] and
/// [MenuItemButton] in this widget's descendants.
///
/// Values specified here are used for [MenuBar] and [MenuItemButton] properties
/// that are not given an explicit non-null value.
///
/// See also:
///  * [MenuBar], a widget that manages [MenuItemButton]s.
///  * [MenuItemButton], a widget that is a selectable item in a menu bar menu.
///  * [MenuButton], a widget that specifies an item with a cascading
///    submenu in a [MenuBar] menu.
class MenuTheme extends InheritedTheme {
  /// Creates a theme that controls the configurations for [MenuBar] and
  /// [MenuItemButton] in its widget subtree.
  const MenuTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// The properties for [MenuBar] and [MenuItemButton] in this widget's
  /// descendants.
  final MenuThemeData data;

  /// Returns the closest instance of this class's [data] value that encloses
  /// the given context. If there is no ancestor, it returns
  /// [ThemeData.menuTheme]. Applications can assume that the returned
  /// value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final MenuThemeData theme = MenuTheme.of(context);
  ///   return MenuTheme(
  ///     data: theme.copyWith(
  ///       barBackgroundColor: const MaterialStatePropertyAll<Color?>(Colors.red),
  ///     ),
  ///     child: child,
  ///   );
  /// }
  /// ```
  static MenuThemeData of(BuildContext context) {
    final MenuTheme? menuTheme = context.dependOnInheritedWidgetOfExactType<MenuTheme>();
    return menuTheme?.data ?? Theme.of(context).menuTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MenuTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MenuTheme oldWidget) => data != oldWidget.data;
}
