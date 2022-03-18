// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'menu_bar.dart';
import 'theme.dart';

/// Defines the visual properties of [MenuBar], [MenuBarSubMenu] and
/// [MenuBarItem] widgets.
///
/// Descendant widgets obtain the current [MenuBarThemeData] object
/// using `MenuBarTheme.of(context)`. Instances of
/// [MenuBarThemeData] can be customized with
/// [MenuBarThemeData.copyWith].
///
/// Typically, a [MenuBarThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.menuBarTheme]. Otherwise,
/// [MenuBarTheme] can be used to configure its own widget subtree.
///
/// All [MenuBarThemeData] properties are `null` by default.
/// If any of these properties are null, the menu bar will provide its own
/// defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class MenuBarThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [MenuBarTheme].
  const MenuBarThemeData({
    this.textStyle,
    this.menuBarBackgroundColor,
    this.menuBarElevation,
    this.menuBarHeight,
    this.menuBackgroundColor,
    this.menuElevation,
    this.menuShape,
    this.menuPadding,
  });

  /// The text style of items in a [MenuBarItem].
  final MaterialStateProperty<TextStyle?>? textStyle;

  /// The background color of the [MenuBar].
  final MaterialStateProperty<Color?>? menuBarBackgroundColor;

  /// The Material elevation of the [MenuBar].
  final double? menuBarElevation;

  /// The height of the menu bar.
  final double? menuBarHeight;

  /// The background color of a [MenuBarSubMenu].
  final MaterialStateProperty<Color?>? menuBackgroundColor;

  /// The Material elevation of the [MenuBarSubMenu].
  final double? menuElevation;

  /// The shape around a [MenuBarSubMenu].
  final ShapeBorder? menuShape;

  /// The padding around the outside of a [MenuBarSubMenu].
  final EdgeInsets? menuPadding;

  /// Creates a copy of this object with the given fields replaced with the new
  /// values.
  MenuBarThemeData copyWith({
    MaterialStateTextStyle? textStyle,
    MaterialStateProperty<Color?>? menuBarBackgroundColor,
    double? menuBarElevation,
    double? menuBarHeight,
    MaterialStateProperty<Color?>? menuBackgroundColor,
    double? menuElevation,
    ShapeBorder? menuShape,
    EdgeInsets? menuPadding,
  }) {
    return MenuBarThemeData(
      textStyle: textStyle ?? this.textStyle,
      menuBarBackgroundColor: menuBarBackgroundColor ?? this.menuBarBackgroundColor,
      menuBarElevation: menuBarElevation ?? this.menuBarElevation,
      menuBarHeight: menuBarHeight ?? this.menuBarHeight,
      menuBackgroundColor: menuBackgroundColor ?? this.menuBackgroundColor,
      menuElevation: menuElevation ?? this.menuElevation,
      menuShape: menuShape ?? this.menuShape,
      menuPadding: menuPadding ?? this.menuPadding,
    );
  }

  /// Linearly interpolate between two [MenuBarThemeData]s.
  ///
  /// If both arguments are null, then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static MenuBarThemeData? lerp(MenuBarThemeData? a, MenuBarThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return MenuBarThemeData(
      textStyle: _lerpProperties<TextStyle?>(a?.textStyle, b?.textStyle, t, TextStyle.lerp),
      menuBarBackgroundColor: _lerpProperties<Color?>(a?.menuBarBackgroundColor, b?.menuBarBackgroundColor, t, Color.lerp),
      menuBarElevation: lerpDouble(a?.menuBarElevation, b?.menuBarElevation, t),
      menuBarHeight: lerpDouble(a?.menuBarHeight, b?.menuBarHeight, t),
      menuBackgroundColor: _lerpProperties<Color?>(a?.menuBackgroundColor, b?.menuBackgroundColor, t, Color.lerp),
      menuElevation: lerpDouble(a?.menuElevation, b?.menuElevation, t),
      menuShape: ShapeBorder.lerp(a?.menuShape, b?.menuShape, t),
      menuPadding: EdgeInsets.lerp(a?.menuPadding, b?.menuPadding, t),
    );
  }

  static MaterialStateProperty<T>? _lerpProperties<T>(
      MaterialStateProperty<T>? a,
      MaterialStateProperty<T>? b,
      double t,
      T Function(T?, T?, double) lerpFunction,
      ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null)
      return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }

  @override
  int get hashCode {
    return hashValues(
      textStyle,
      menuBarBackgroundColor,
      menuBarElevation,
      menuBarHeight,
      menuBackgroundColor,
      menuElevation,
      menuShape,
      menuPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is MenuBarThemeData
        && other.textStyle == textStyle
        && other.menuBarBackgroundColor == menuBarBackgroundColor
        && other.menuBarElevation == menuBarElevation
        && other.menuBarHeight == menuBarHeight
        && other.menuBackgroundColor == menuBackgroundColor
        && other.menuElevation == menuElevation
        && other.menuShape == menuShape
        && other.menuPadding == menuPadding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('text style', textStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('menuBarColor', menuBarBackgroundColor, defaultValue: null));
    properties.add(DoubleProperty('menuBarElevation', menuBarElevation, defaultValue: null));
    properties.add(DoubleProperty('menuBarHeight', menuBarHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('backgroundColor', menuBackgroundColor, defaultValue: null));
    properties.add(DoubleProperty('menuElevation', menuElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', menuShape, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsets>('menuPadding', menuPadding, defaultValue: null));
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
/// [MenuBarItem] in this widget's descendants.
///
/// Values specified here are used for [MenuBar] and [MenuBarItem] properties
/// that are not given an explicit non-null value.
///
/// See also:
///  * [MenuBar], a widget that manages [MenuBarItem]s.
///  * [MenuBarItem], a widget that is a selectable item in a menu bar menu.
///  * [MenuBarSubMenu], a widget that specifies an item with a cascading
///    submenu in a [MenuBar] menu.
class MenuBarTheme extends InheritedTheme {
  /// Creates a theme that controls the configurations for [MenuBar] and
  /// [MenuBarItem] in its widget subtree.
  const MenuBarTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The properties for [MenuBar] and [MenuBarItem] in this widget's
  /// descendants.
  final MenuBarThemeData data;

  /// Returns the closest instance of this class's [data] value that encloses
  /// the given context. If there is no ancestor, it returns
  /// [ThemeData.menuBarTheme]. Applications can assume that the returned
  /// value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MenuBarThemeData theme = MenuBarTheme.of(context);
  /// ```
  static MenuBarThemeData of(BuildContext context) {
    final MenuBarTheme? menuBarTheme = context.dependOnInheritedWidgetOfExactType<MenuBarTheme>();
    return menuBarTheme?.data ?? Theme.of(context).menuBarTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MenuBarTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MenuBarTheme oldWidget) => data != oldWidget.data;
}
