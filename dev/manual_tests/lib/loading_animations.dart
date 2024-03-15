// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  timeDilation = 1.5;
  runApp(const LoadingAnimation());
}

typedef DivideBoxBuilder = Widget Function(BuildContext context, Color color);

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends RandomizerState<LoadingAnimation> {
  int _depth = 1;
  Axis _topDirection = Axis.vertical;
  final List<int> _levels = <int>[1, 2, 3, 4, 3, 2, 1, 2, 1, 3, 2];
  int _currentLevel = 0;

  @override
  void updateSettings() {
    setState(() {
      _currentLevel = (_currentLevel + 1) % _levels.length;
      _depth = _levels[_currentLevel];
      _topDirection = _topDirection.swap();
    });
  }

  Color _getColor(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedDividedBox(
                children: _depth,
                direction: _topDirection,
                builder: (
                  BuildContext context,
                  Color color,
                ) {
                  return DividedBoxNest(
                    depth: _depth,
                    getDirection: (int depth, Axis direction) {
                      return random.nextBool() ? Axis.horizontal : Axis.vertical;
                    },
                    getCount: (int depth, int prevCount) {
                      return _depth - depth;
                    },
                    getColor: _getColor,
                    builder: (
                      BuildContext context,
                      Color color,
                    ) {
                      return MitosisBox(
                        cornerRadius: 12,
                        color: color,
                        margin: const EdgeInsetsDirectional.all(8),
                      );
                    },
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class DividedBoxNest extends StatefulWidget {
  const DividedBoxNest({
    super.key,
    this.startDirection = Axis.horizontal,
    this.depth = 2,
    required this.getCount,
    required this.getDirection,
    required this.getColor,
    required this.builder,
  });

  final Axis startDirection;
  // Number of recursive levels.
  final int depth;
  // Number of children at each level.
  final Color Function(int index) getColor;
  final int Function(int index, int lastCount) getCount;
  final Axis Function(int index, Axis lastDirection) getDirection;
  final DivideBoxBuilder builder;

  @override
  State<DividedBoxNest> createState() => _DividedBoxNestState();
}

class _DividedBoxNestState extends RandomizerState<DividedBoxNest> {
  late final Animation<double> nestAnimation;
  int count = 0;
  Axis direction = Axis.horizontal;

  @override
  void onTick() {
    setState(() {
      // Redraw
    });
  }

  @override
  void updateSettings() {
    setState(() {
      count = widget.getCount(widget.depth, count);
      direction = widget.getDirection(widget.depth, direction);
    });
  }

  @override
  void initState() {
    super.initState();
    count = widget.getCount(0, 0);
    direction = widget.getDirection(0, Axis.horizontal);
    nestAnimation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  Widget _buildToDepth(BuildContext context, int depth, Axis direction, Color color) {
    if (depth == widget.depth) {
      return widget.builder(context, color);
    }
    return AnimatedDividedBox(
      direction: direction,
      children: widget.getCount(depth, count),
      builder: (BuildContext context, Color color) {
        return _buildToDepth(context, depth + 1, direction, widget.getColor(depth));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildToDepth(context, 0, widget.startDirection, widget.getColor(0));
  }
}

class AnimatedDividedBox extends StatefulWidget {
  const AnimatedDividedBox({
    super.key,
    required int children,
    required this.builder,
    this.direction = Axis.horizontal,
    this.duration = const Duration(milliseconds: 500),
  }) : numChildren = children > 1 ? children : 1;

  final int numChildren;
  final DivideBoxBuilder builder;
  final Axis direction;
  final Duration duration;

  @override
  State<AnimatedDividedBox> createState() => _AnimatedDividedBoxState();
}

class _AnimatedDividedBoxState extends State<AnimatedDividedBox> with TickerProviderStateMixin {
  List<ValueKey<int>> children = <ValueKey<int>>[];
  List<ValueKey<int>> exitingChildren = <ValueKey<int>>[];
  int childSerial = 0;

  @override
  void initState() {
    super.initState();
    addChildren();
  }

  void addChildren() {
    while (children.length < widget.numChildren) {
      final int serial = childSerial++;
      children.add(ValueKey<int>(serial));
    }
  }

  void removeChildren() {
    final int removeCount = children.length - widget.numChildren;
    for (int i = 0; i < removeCount; ++i) {
      exitingChildren.add(children.removeAt(0));
    }
  }

  @override
  void didUpdateWidget(AnimatedDividedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numChildren != widget.numChildren) {
      if (widget.numChildren > children.length) {
        addChildren();
      } else {
        removeChildren();
      }
    }
  }

  Color _getColor(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      mainAxisSize: MainAxisSize.min,
      direction: widget.direction,
      children: <Widget>[
        for (final ValueKey<int> child in children)
          ExpandingBox(
            key: child,
            child: Builder(
              builder: (BuildContext context) {
                return widget.builder(context, _getColor(child.value));
              },
            ),
          ),
        for (final ValueKey<int> child in exitingChildren)
          ExpandingBox(
            key: child,
            onRemove: () {
              exitingChildren.remove(child);
            },
            child: Builder(
              builder: (BuildContext context) {
                return widget.builder(context, _getColor(child.value));
              },
            ),
          )
      ],
    );
  }
}

class ExpandingBox extends StatefulWidget {
  const ExpandingBox({
    super.key,
    this.duration = const Duration(milliseconds: 500),
    required this.child,
    this.onRemove,
  });

  final VoidCallback? onRemove;
  final Duration duration;
  final Widget child;

  @override
  State<ExpandingBox> createState() => _ExpandingBoxState();
}

class _ExpandingBoxState extends State<ExpandingBox> with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      value: 0,
      duration: widget.duration,
    )
      ..forward()
      ..addListener(_redraw);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    controller.removeListener(_redraw);
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  Future<void> _startLeaving() async {
    await controller.reverse();
    widget.onRemove?.call();
  }

  @override
  void didUpdateWidget(covariant ExpandingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onRemove != widget.onRemove) {
      if (widget.onRemove != null) {
        _startLeaving();
      } else {
        controller.forward();
      }
    }
  }

  void _redraw() {
    setState(() {
      // force a frame.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: (1000 * animation.value + 1).round(),
      child: widget.child,
    );
  }
}

/// A widget that animates a mitosis effect.
class MitosisBox extends StatefulWidget {
  const MitosisBox({
    super.key,
    required this.cornerRadius,
    this.margin = EdgeInsetsDirectional.zero,
    required this.color,
  });

  /// The corner radius of the boxes.
  final double cornerRadius;

  /// The padding around the boxes.
  final EdgeInsetsDirectional margin;

  /// The color of the boxes.
  final Color color;

  @override
  State<MitosisBox> createState() => _MitosisBoxState();
}

class _MitosisBoxState extends RandomizerState<MitosisBox> {
  late final Animation<double> animation;
  static const double crossover = 0.25;
  Axis _direction = Axis.horizontal;

  @override
  void updateSettings() {
    setState(() {
      _direction = random.nextBool() ? Axis.horizontal : Axis.vertical;
    });
  }

  @override
  void onTick() {
    setState(() {
      // Redraw
    });
  }

  @override
  void initState() {
    super.initState();
    _direction = random.nextBool() ? Axis.horizontal : Axis.vertical;
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    // Things are simpler if it hasn't split yet.
    if (animation.value == 0) {
      return Container(
        margin: widget.margin,
        decoration: ShapeDecoration(
          color: widget.color,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: widget.color),
            borderRadius: BorderRadiusDirectional.all(
              Radius.circular(widget.cornerRadius),
            ),
          ),
        ),
      );
    }

    // Until crossover, show two boxes touching each other while the corner
    // radius at the join grows.
    final double cornerParam = math.max(math.min(animation.value / crossover, 1), 0);
    // After crossover, show two boxes initially touching, where the gap
    // between them grows to padding value.
    final double paddingParam = math.max(math.min((animation.value - crossover) / (1.0 - crossover), 1), 0);
    final double innerCornerRadius = widget.cornerRadius * cornerParam;

    BorderRadiusDirectional startRadius;
    BorderRadiusDirectional endRadius;
    EdgeInsetsDirectional startMargin;
    EdgeInsetsDirectional endMargin;
    switch (_direction) {
      case Axis.horizontal:
        startMargin = widget.margin.copyWith(end: widget.margin.end * paddingParam);
        endMargin = widget.margin.copyWith(start: widget.margin.end * paddingParam);
        startRadius = BorderRadiusDirectional.only(
          topStart: Radius.circular(widget.cornerRadius),
          bottomStart: Radius.circular(widget.cornerRadius),
          topEnd: Radius.circular(innerCornerRadius),
          bottomEnd: Radius.circular(innerCornerRadius),
        );
        endRadius = BorderRadiusDirectional.only(
          topStart: Radius.circular(innerCornerRadius),
          bottomStart: Radius.circular(innerCornerRadius),
          topEnd: Radius.circular(widget.cornerRadius),
          bottomEnd: Radius.circular(widget.cornerRadius),
        );
      case Axis.vertical:
        startMargin = widget.margin.copyWith(bottom: widget.margin.end * paddingParam);
        endMargin = widget.margin.copyWith(top: widget.margin.end * paddingParam);
        startRadius = BorderRadiusDirectional.only(
          topStart: Radius.circular(widget.cornerRadius),
          bottomStart: Radius.circular(innerCornerRadius),
          topEnd: Radius.circular(widget.cornerRadius),
          bottomEnd: Radius.circular(innerCornerRadius),
        );
        endRadius = BorderRadiusDirectional.only(
          topStart: Radius.circular(innerCornerRadius),
          bottomStart: Radius.circular(widget.cornerRadius),
          topEnd: Radius.circular(innerCornerRadius),
          bottomEnd: Radius.circular(widget.cornerRadius),
        );
    }

    return Flex(
      direction: _direction,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: startMargin,
            decoration: ShapeDecoration(
              color: widget.color,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: widget.color),
                borderRadius: startRadius,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: endMargin,
            decoration: ShapeDecoration(
              color: widget.color,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: widget.color),
                borderRadius: endRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract class RandomizerState<T extends StatefulWidget> extends State<T> with TickerProviderStateMixin {
  late final AnimationController controller;
  final math.Random random = math.Random();
  Timer? pauseTimer;

  // Override this to change settings while the animation is at zero.
  void updateSettings() {}

  void _intermittentLooping(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        return;
      case AnimationStatus.dismissed:
        pauseTimer = Timer(Duration(milliseconds: random.nextInt(1000) + 500), () {
          updateSettings();
          controller.forward();
          pauseTimer!.cancel();
          pauseTimer = null;
        });
        return;
      case AnimationStatus.completed:
        pauseTimer = Timer(Duration(milliseconds: random.nextInt(1000) + 500), () {
          controller.reverse();
          pauseTimer!.cancel();
          pauseTimer = null;
        });
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..forward()
      ..addStatusListener(_intermittentLooping)
      ..addListener(onTick);
  }

  void onTick() {}

  @override
  void dispose() {
    pauseTimer?.cancel();
    pauseTimer = null;
    controller.removeListener(onTick);
    controller.stop();
    controller.dispose();
    super.dispose();
  }
}
