// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'menu_bar.dart';
import 'theme.dart';

/// Defines the visual properties of [MenuBar] and [MenuBarItem] widgets.
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
    this.backgroundColor,
    this.textStyle,
    this.menuBarElevation,
    this.menuBarColor,
    this.menuBarHeight,
    this.menuElevation,
    this.menuShape,
    this.menuPadding,
  });

  /// The background color of a [MenuBar] and its menus.
  final MaterialStateProperty<Color?>? backgroundColor;

  /// The text style of items in [MenuBarItem], and [MenuBar].
  final MaterialStateProperty<TextStyle?>? textStyle;

  /// The Material elevation of the [MenuBar].
  final double? menuBarElevation;

  /// The background color of the [MenuBar].
  final MaterialStateProperty<Color?>? menuBarColor;

  /// The height of the menu bar.
  final double? menuBarHeight;

  /// The Material elevation of the [MenuBar] menus.
  final double? menuElevation;

  /// The shape around a [MenuBar] menu.
  final ShapeBorder? menuShape;

  /// The padding around the outside of a [MenuBar] menu.
  final EdgeInsets? menuPadding;

  /// Creates a copy of this object with the given fields replaced with the new
  /// values.
  MenuBarThemeData copyWith({
    MaterialStateProperty<Color?>? backgroundColor,
    MaterialStateTextStyle? textStyle,
    double? menuBarElevation,
    MaterialStateProperty<Color?>? menuBarColor,
    double? menuBarHeight,
    double? menuElevation,
    ShapeBorder? menuShape,
    EdgeInsets? menuPadding,
  }) {
    return MenuBarThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      menuBarElevation: menuBarElevation ?? this.menuBarElevation,
      menuBarColor: menuBarColor ?? this.menuBarColor,
      menuBarHeight: menuBarHeight ?? this.menuBarHeight,
      menuElevation: menuElevation ?? this.menuElevation,
      menuPadding: menuPadding ?? this.menuPadding,
      menuShape: menuShape ?? this.menuShape,
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
      backgroundColor: _lerpProperties<Color?>(a?.backgroundColor, b?.backgroundColor, t, Color.lerp),
      menuShape: ShapeBorder.lerp(a?.menuShape, b?.menuShape, t),
      menuElevation: lerpDouble(a?.menuElevation, b?.menuElevation, t),
      menuBarElevation: lerpDouble(a?.menuBarElevation, b?.menuBarElevation, t),
      textStyle: _lerpProperties<TextStyle?>(a?.textStyle, b?.textStyle, t, TextStyle.lerp),
      menuBarColor: _lerpProperties<Color?>(a?.menuBarColor, b?.menuBarColor, t, Color.lerp),
      menuBarHeight: lerpDouble(a?.menuBarHeight, b?.menuBarHeight, t),
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
      backgroundColor,
      menuShape,
      menuBarElevation,
      textStyle,
      menuBarColor,
      menuBarHeight,
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
        && other.menuBarElevation == menuBarElevation
        && other.backgroundColor == backgroundColor
        && other.menuShape == menuShape
        && other.textStyle == textStyle
        && other.menuBarColor == menuBarColor
        && other.menuBarHeight == menuBarHeight
        && other.menuPadding == menuPadding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('color', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', menuShape, defaultValue: null));
    properties.add(DoubleProperty('menuBarElevation', menuBarElevation, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<TextStyle?>>('text style', textStyle, defaultValue: null));
    properties.add(DoubleProperty('menuBarHeight', menuBarHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('menuBarColor', menuBarColor, defaultValue: null));
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
///  * [MenuBarItem], a widget that is a selectable item in a menu bar menu.
///  * [MenuBar], a widget that manages top-level [MenuBarItem]s in a row.
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
