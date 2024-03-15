// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const LoadingAnimation());

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> {
  int _count = 1;
  final math.Random random = math.Random();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('$_count'),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _count += 1;
                });
              },
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _count = math.max(1, _count - 1);
                });
              },
              child: const Icon(Icons.remove),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
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
                    direction: (int depth, Axis direction) {
                      return random.nextBool() ? Axis.horizontal : Axis.vertical;
                    },
                    count: (int depth, int prevCount) {
                      if (random.nextBool()) {
                        return math.min(depth, prevCount + 1);
                      } else {
                        return math.max(1, prevCount - 1);
                      }
                    },
                    builder: (
                      BuildContext context,
                      Animation<double> animation,
                      Color color,
                    ) {
                      // return BasicBox(
                      //   color: color,
                      //   padding: const EdgeInsetsDirectional.all(8),
                      // );
                      return MitosisBox(
                        cornerRadius: 10,
                        color: color,
                        padding: const EdgeInsetsDirectional.all(10),
                        animation: animation,
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

class BasicBox extends StatelessWidget {
  const BasicBox({super.key, required this.color, required this.padding, this.cornerRadius = 10});

  final Color color;
  final double cornerRadius;
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius)),
          color: color,
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
    required this.count,
    required this.direction,
    required this.builder,
  });

  final Axis startDirection;
  // Number of recursive levels.
  final int depth;
  // Number of children at each level.
  final int Function(int, int) count;
  final Axis Function(int, Axis direction) direction;
  final DivideBoxBuilder builder;

  @override
  State<DividedBoxNest> createState() => _DividedBoxNestState();
}

class _DividedBoxNestState extends State<DividedBoxNest> with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> nestAnimation;
  int count = 0;
  Axis direction = Axis.horizontal;

  void _updateParameters(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
      case AnimationStatus.dismissed:
        return;
      case AnimationStatus.completed:
        controller.reset();
        controller.forward();
        setState(() {
          final int newCount = widget.count(widget.depth, count);
          if (count < newCount) {
            setState(() {
              count += 1;
            });
          } else if (count > newCount) {
            setState(() {
              count -= 1;
            });
          }
          direction = widget.direction(widget.depth, direction);
        });
    }
  }

  @override
  void initState() {
    super.initState();
    count = widget.count(0, 0);
    direction = widget.direction(0, Axis.horizontal);
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..addStatusListener(_updateParameters)
      ..forward();
    nestAnimation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    controller.removeStatusListener(_updateParameters);
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  Widget _buildToDepth(BuildContext context, int toDepth, Axis direction, Animation<double> animation, Color color) {
    if (toDepth == 0) {
      return widget.builder(context, animation, color);
    }
    return AnimatedDividedBox(
      direction: direction,
      children: count,
      builder: (BuildContext context, Animation<double> animation, Color color) {
        return _buildToDepth(context, toDepth - 1, direction.swap(), animation, _getColor(widget.depth));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildToDepth(context, widget.depth, widget.startDirection, nestAnimation, _getColor(0));
  }
}

Color _getColor(int index) {
  return Colors.primaries[index % Colors.primaries.length];
}

typedef DivideBoxBuilder = Widget Function(BuildContext context, Animation<double> animation, Color color);

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
        value: 0,
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
      animationSum = 1.0;
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
    this.duration = const Duration(seconds: 1),
    required this.cornerRadius,
    this.padding = EdgeInsetsDirectional.zero,
    required this.color,
    required this.animation,
  });

  /// The duration of the animation.
  final Duration duration;

  /// The corner radius of the boxes.
  final double cornerRadius;

  /// The padding around the boxes.
  final EdgeInsetsDirectional padding;

  /// The color of the boxes.
  final Color color;

  /// The animation that drives the mitosis effect.
  final Animation<double> animation;

  @override
  State<MitosisBox> createState() => _MitosisBoxState();
}

class _MitosisBoxState extends State<MitosisBox> {
  static const double crossover = 0.5;

  @override
  Widget build(BuildContext context) {
    // Until crossover, show two boxes touching each other while the corner
    // radius at the join grows.
    final double cornerParam = math.max(math.min(widget.animation.value / crossover, 1), 0);
    // After crossover, show two boxes initially touching, where the gap
    // between them grows to padding value.
    final double paddingParam = math.max(math.min((widget.animation.value - crossover) / (1.0 - crossover), 1), 0);
    final double innerCornerRadius = widget.cornerRadius * cornerParam;
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            margin: widget.padding.copyWith(end: widget.padding.end * paddingParam),
            decoration: ShapeDecoration(
              color: widget.color,
              shape: RoundedRectangleBorder(
                //side: const BorderSide(),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(widget.cornerRadius),
                  bottomStart: Radius.circular(widget.cornerRadius),
                  topEnd: Radius.circular(innerCornerRadius),
                  bottomEnd: Radius.circular(innerCornerRadius),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: widget.padding.copyWith(start: widget.padding.start * paddingParam),
            decoration: ShapeDecoration(
              color: widget.color,
              shape: RoundedRectangleBorder(
                //side: const BorderSide(),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(innerCornerRadius),
                  bottomStart: Radius.circular(innerCornerRadius),
                  topEnd: Radius.circular(widget.cornerRadius),
                  bottomEnd: Radius.circular(widget.cornerRadius),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
