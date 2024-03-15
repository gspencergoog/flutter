// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  int _count = 0;

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
                  _count = math.max(0, _count - 1);
                });
              },
              child: const Icon(Icons.remove),
            ),
          ],
        ),
        body: Center(
          child: AnimatedDividedBox(children: _count),
        ),
      ),
    );
  }
}

class AnimatedDividedBox extends StatefulWidget {
  const AnimatedDividedBox({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.duration = const Duration(milliseconds: 500),
  });

  final int children;
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
    debugPrint('Added: ${controllers.length} controllers with ${exitingControllers.length} exiting');
  }

  void removeChildren() {
    Future<void> removeChild(int removeSerial) async {
      final AnimationController remove = controllers[removeSerial]!;
      exitingControllers[removeSerial] = remove;
      controllers.remove(removeSerial);
      debugPrint('Removing: ${controllers.length} controllers with ${exitingControllers.length} exiting');
      await remove.reverse();
      remove.removeListener(_redraw);
      exitingControllers.remove(removeSerial);
      debugPrint('Remove Done: ${controllers.length} controllers with ${exitingControllers.length} exiting');
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
        for (final int serial in allControllers.keys)
          LayoutId(
            id: serial,
            child: Container(height: 100, color: _getColor(serial)),
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
