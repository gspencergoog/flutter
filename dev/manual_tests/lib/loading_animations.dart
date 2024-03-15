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
                builder: (BuildContext context, int index) {
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
                    builder: (BuildContext context, int index) => BasicBox(index: index),
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class BasicBox extends StatelessWidget {
  const BasicBox({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: _getColor(index),
      )),
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

class _DividedBoxNestState extends State<DividedBoxNest> {
  Timer? timer;
  int count = 0;
  Axis direction = Axis.horizontal;

  @override
  void initState() {
    super.initState();
    direction = widget.direction(0, Axis.horizontal);
    timer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (Timer timer) {
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
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget _buildToDepth(BuildContext context, int toDepth, Axis direction, int index) {
    if (toDepth == 0) {
      return widget.builder(context, index);
    }
    return AnimatedDividedBox(
      direction: direction,
      children: count,
      builder: (BuildContext context, int index) {
        return _buildToDepth(context, toDepth - 1, direction.swap(), widget.depth * 10 + index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildToDepth(context, widget.depth, widget.startDirection, 0);
  }
}

Color _getColor(int index) {
  return Colors.primaries[index % Colors.primaries.length];
}

typedef DivideBoxBuilder = Widget Function(BuildContext context, int index);

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
        for (final int serial in allControllers.keys)
          LayoutId(
            id: serial,
            child: widget.builder(context, serial),
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
