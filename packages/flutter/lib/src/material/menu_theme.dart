// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
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
        other.menuPadding == menuPadding;
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


/// A [ButtonStyle] that overrides the default appearance of [MenuButton]s and
/// [MenuItemButton]s when it's used with [MenuButtonTheme] or with the overall
/// [Theme]'s [ThemeData.menuTheme].
///
/// The [style]'s properties override [TextButton]'s default style, i.e.  the
/// [ButtonStyle] returned by [TextButton.defaultStyleOf]. Only the style's
/// non-null property values or resolved non-null [MaterialStateProperty] values
/// are used.
///
/// See also:
///
///  * [MenuButtonTheme], the theme which is configured with this class.
///  * [TextButton.defaultStyleOf], which returns the default [ButtonStyle] for
///    text buttons.
///  * [TextButton.styleFrom], which converts simple values into a [ButtonStyle]
///    that's consistent with [TextButton]'s defaults.
///  * [MaterialStateProperty.resolve], "resolve" a material state property to a
///    simple value based on a set of [MaterialState]s.
///  * [ThemeData.textButtonTheme], which can be used to override the default
///    [ButtonStyle] for [TextButton]s below the overall [Theme].
@immutable
class MenuButtonThemeData with Diagnosticable {
  /// Creates a [MenuButtonThemeData].
  ///
  /// The [style] may be null.
  const MenuButtonThemeData({ this.style });

  /// Overrides for [MenuButton] and [MenuItemButton]'s default style.
  ///
  /// Non-null properties or non-null resolved [MaterialStateProperty] values
  /// override the [ButtonStyle] returned by [MenuButton.defaultStyleOf] or
  /// [MenuItemButton.defaultStyleOf].
  ///
  /// If [style] is null, then this theme doesn't override anything.
  final ButtonStyle? style;

  /// Linearly interpolate between two text button themes.
  static MenuButtonThemeData? lerp(MenuButtonThemeData? a, MenuButtonThemeData? b, double t) {
    assert (t != null);
    if (a == null && b == null) {
      return null;
    }
    return MenuButtonThemeData(
      style: ButtonStyle.lerp(a?.style, b?.style, t),
    );
  }

  @override
  int get hashCode => style.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MenuButtonThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

/// Overrides the default [ButtonStyle] of its [MenuItemButton] and [MenuButton]
/// descendants.
///
/// See also:
///
///  * [MenuButtonThemeData], which is used to configure this theme.
///  * [TextButton.defaultStyleOf], which returns the default [ButtonStyle] for
///    text buttons.
///  * [TextButton.styleFrom], which converts simple values into a [ButtonStyle]
///    that's consistent with [TextButton]'s defaults.
///  * [ThemeData.textButtonTheme], which can be used to override the default
///    [ButtonStyle] for [TextButton]s below the overall [Theme].
class MenuButtonTheme extends InheritedTheme {
  /// Create a [MenuButtonTheme].
  ///
  /// The [data] parameter must not be null.
  const MenuButtonTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// The configuration of this theme.
  final MenuButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [MenuButtonTheme] widget, then
  /// [ThemeData.textButtonTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MenuButtonThemeData theme = MenuButtonTheme.of(context);
  /// ```
  static MenuButtonThemeData of(BuildContext context) {
    final MenuButtonTheme? buttonTheme = context.dependOnInheritedWidgetOfExactType<MenuButtonTheme>();
    return buttonTheme?.data ?? Theme.of(context).menuButtonTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MenuButtonTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MenuButtonTheme oldWidget) => data != oldWidget.data;
}
