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

typedef DivideBoxBuilder = Widget Function(BuildContext context, Animation<double> animation, Color color);

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends RandomizerState<LoadingAnimation> {
  int _count = 1;
  final List<int> _levels = <int>[1, 2, 3, 2, 1, 2, 1, 3, 2];
  int _currentLevel = 0;

  @override
  void updateSettings() {
    setState(() {
      _currentLevel = (_currentLevel + 1) % _levels.length;
      _count = _levels[_currentLevel];
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
                children: _count,
                direction: Axis.vertical,
                builder: (
                  BuildContext context,
                  Animation<double> animation,
                  Color color,
                ) {
                  return DividedBoxNest(
                    depth: _count,
                    getDirection: (int depth, Axis direction) {
                      return random.nextBool() ? Axis.horizontal : Axis.vertical;
                    },
                    getCount: (int depth, int prevCount) {
                      return depth;
                      // if (random.nextBool()) {
                      //   return math.min(depth, prevCount + 1);
                      // } else {
                      //   return math.max(1, prevCount - 1);
                      // }
                    },
                    getColor: _getColor,
                    builder: (
                      BuildContext context,
                      Animation<double> animation,
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

  Widget _buildToDepth(BuildContext context, int depth, Axis direction, Animation<double> animation, Color color) {
    if (depth == widget.depth) {
      return widget.builder(context, animation, color);
    }
    return AnimatedDividedBox(
      direction: direction,
      children: widget.getCount(depth, count),
      builder: (BuildContext context, Animation<double> animation, Color color) {
        return _buildToDepth(context, depth + 1, direction, animation, widget.getColor(depth));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildToDepth(context, 0, widget.startDirection, nestAnimation, widget.getColor(0));
  }
}

class AnimatedDividedBox extends StatefulWidget {
  const AnimatedDividedBox({
    super.key,
    required int children,
    required this.builder,
    this.direction = Axis.horizontal,
    this.duration = const Duration(milliseconds: 500),
  }) : children = children > 1 ? children : 1;

  final int children;
  final DivideBoxBuilder builder;
  final Axis direction;
  final Duration duration;

  @override
  State<AnimatedDividedBox> createState() => _AnimatedDividedBoxState();
}

class _AnimatedDividedBoxState extends State<AnimatedDividedBox> with TickerProviderStateMixin {
  Map<int, AnimationController> controllers = <int, AnimationController>{};
  Map<int, AnimationController> exitingControllers = <int, AnimationController>{};
  int childSerial = 0;

  @override
  void initState() {
    super.initState();
    addChildren();
  }

  @override
  void dispose() {
    <int, AnimationController>{...controllers, ...exitingControllers}.forEach(
      (int index, AnimationController controller) {
        controller.removeListener(_redraw);
        controller.stop();
        controller.dispose();
      },
    );
    super.dispose();
  }

  void _redraw() {
    setState(() {
      // force a frame.
    });
  }

  void addChildren() {
    while (controllers.length < widget.children) {
      final int serial = childSerial++;
      controllers[serial] = AnimationController(
        value: 0.001,
        vsync: this,
        duration: widget.duration,
      )
        ..addListener(_redraw)
        ..forward();
    }
  }

  void removeChildren() {
    Future<void> removeChild(int removeSerial) async {
      final AnimationController remove = controllers[removeSerial]!;
      exitingControllers[removeSerial] = remove;
      controllers.remove(removeSerial);
      await remove.reverse();
      remove.removeListener(_redraw);
      exitingControllers.remove(removeSerial);
      remove.dispose();
    }

    final int removeCount = controllers.length - widget.children;
    for (int i = 0; i < removeCount; ++i) {
      final List<int> sortedSerials = controllers.keys.toList()..sort();
      final int removeSerial = sortedSerials.first;
      removeChild(removeSerial);
    }
  }

  @override
  void didUpdateWidget(AnimatedDividedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children != widget.children) {
      if (widget.children > controllers.length) {
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
    final Map<int, AnimationController> allControllers = <int, AnimationController>{
      ...exitingControllers,
      ...controllers,
    };
    return CustomMultiChildLayout(
      delegate: _SpreadLayoutDelegate(
        animations: allControllers,
        direction: widget.direction,
      ),
      children: <Widget>[
        for (final MapEntry<int, AnimationController> controller in allControllers.entries)
          LayoutId(
            id: controller.key,
            child: widget.builder(context, controller.value, _getColor(controller.key)),
          ),
      ],
    );
  }
}

class _SpreadLayoutDelegate extends MultiChildLayoutDelegate {
  _SpreadLayoutDelegate({
    required this.animations,
    this.direction = Axis.horizontal,
  });

  final Map<int, AnimationController> animations;
  final Axis direction;
  List<double> _layoutAnimationValues = <double>[];

  // Perform layout will be called when re-layout is needed.
  @override
  void performLayout(Size size) {
    double animationSum = animations.values.fold<double>(
      0.0,
      (double sum, Animation<double> animation) => sum + animation.value,
    );
    if (animationSum == 0) {
      animationSum = 0.0001;
    }
    Offset childPosition = Offset.zero;

    for (final MapEntry<int, AnimationController> entry in animations.entries) {
      // layoutChild must be called exactly once for each child.

      final double scaledValue = entry.value.value / animationSum;
      switch (direction) {
        case Axis.horizontal:
          final Size currentSize = layoutChild(
            entry.key,
            BoxConstraints.tightFor(
              height: size.height,
              width: size.width * scaledValue,
            ),
          );
          positionChild(entry.key, childPosition);
          childPosition += Offset(currentSize.width, 0);
        case Axis.vertical:
          final Size currentSize = layoutChild(
            entry.key,
            BoxConstraints.tightFor(
              height: size.height * scaledValue,
              width: size.width,
            ),
          );
          positionChild(entry.key, childPosition);
          childPosition += Offset(0, currentSize.height);
      }
    }
    _layoutAnimationValues =
        animations.values.map<double>((AnimationController controller) => controller.value).toList();
  }

  // shouldRelayout is called to see if the delegate has changed and requires a
  // layout to occur. Should only return true if the delegate state itself
  // changes: changes in the CustomMultiChildLayout attributes will
  // automatically cause a relayout, like any other widget.
  @override
  bool shouldRelayout(_SpreadLayoutDelegate oldDelegate) {
    final List<double> animationValues =
        animations.values.map<double>((AnimationController controller) => controller.value).toList();
    return direction != oldDelegate.direction || !listEquals(animationValues, oldDelegate._layoutAnimationValues);
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
