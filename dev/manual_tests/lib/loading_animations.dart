// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  timeDilation = 1;
  runApp(const LoadingAnimation());
}

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends RandomizerState<LoadingAnimation> {
  int _topDivisions = 1;
  List<int> _childDivisions = <int>[2];
  List<Axis> _childDirections = <Axis>[Axis.horizontal];
  Axis _topDirection = Axis.vertical;
  final List<int> _levels = <int>[1, 2, 3, 2];
  int _currentLevel = 0;

  @override
  void updateSettings() {
    setState(() {
      _currentLevel = (_currentLevel + 1) % _levels.length;
      final int oldDivisions = _topDivisions;
      _topDivisions = _levels[_currentLevel];
      // Only change the direction when we only have one top level, to avoid
      // jarring rotations.
      _topDirection = oldDivisions == 1 ? _getDirection() : _topDirection;
      _childDivisions = List<int>.generate(_topDivisions, (int index) => random.nextInt(2) + 1);
      _childDirections= List<Axis>.generate(_topDivisions, (int index) => Axis.values[random.nextInt(Axis.values.length)]);
    });
  }

  Axis _getDirection() {
    return random.nextBool() ? Axis.horizontal : Axis.vertical;
  }

  Color _getColor(int index) {
    return Colors.grey.shade300;
    // return Colors.primaries[index % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedDividedBox(
              direction: _topDirection,
              children: <DividedBoxChild>[
                for (int i = 0; i < _topDivisions; ++i)
                  DividedBoxChild(
                    id: i,
                    child: AnimatedDividedBox(
                      direction: _childDirections[i],
                      children: <DividedBoxChild>[
                        for (int j = 0; j < _childDivisions[i]; ++j)
                          DividedBoxChild(
                            id: j,
                            child: MitosisBox(
                              cornerRadius: 18,
                              color: _getColor(i * _childDivisions[i] + j),
                              margin: const EdgeInsetsDirectional.all(8),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DividedBoxChild extends StatelessWidget {
  const DividedBoxChild({super.key, required this.id, required this.child});

  final Object id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class AnimatedDividedBox extends StatefulWidget {
  const AnimatedDividedBox({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
  }) : assert(children.length > 0);

  final List<DividedBoxChild> children;
  final Axis direction;

  @override
  State<AnimatedDividedBox> createState() => _AnimatedDividedBoxState();
}

class _AnimatedDividedBoxState extends State<AnimatedDividedBox> with TickerProviderStateMixin {
  List<DividedBoxChild> children = <DividedBoxChild>[];

  @override
  void initState() {
    super.initState();
    children = widget.children;
  }

  @override
  void didUpdateWidget(AnimatedDividedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children != widget.children) {
      final Set<Object> ids = children.map<Object>((DividedBoxChild child) => child.id).toSet();
      // Only add in the new ids, since the old ones will be removed over time
      // as they shrink out. Append all the new ones.
      children.addAll(widget.children.where((DividedBoxChild child) => !ids.contains(child.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<Object> widgetIds = widget.children.map<Object>((DividedBoxChild child) => child.id).toSet();

    return Flex(
      mainAxisSize: MainAxisSize.min,
      direction: widget.direction,
      children: <Widget>[
        for (final DividedBoxChild child in children)
          ExpandingBox(
            key: ValueKey<Object>(child.id),
            onRemove: !widgetIds.contains(child.id) ? () => children.remove(child) : null,
            child: child,
          ),
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
    return Expanded(
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
  _MitosisBoxState()
      : super(
          duration: const Duration(milliseconds: 500),
          maxPause: const Duration(milliseconds: 2000),
          minPause: const Duration(milliseconds: 250),
        );

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
  RandomizerState({
    this.duration = const Duration(milliseconds: 500),
    this.minPause = const Duration(milliseconds: 250),
    this.maxPause = const Duration(milliseconds: 1000),
  });

  Duration duration;
  Duration minPause;
  Duration maxPause;
  late final AnimationController controller;
  final math.Random random = math.Random();
  Timer? pauseTimer;

  // Override this to change settings while the animation is at zero.
  void updateSettings() {}

  void _intermittentLooping(AnimationStatus status) {
    final Duration pause = Duration(milliseconds: random.nextInt(maxPause.inMilliseconds) + minPause.inMilliseconds) * timeDilation;
    switch (status) {
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        return;
      case AnimationStatus.dismissed:
        pauseTimer = Timer(pause, () {
          updateSettings();
          controller.forward();
          pauseTimer!.cancel();
          pauseTimer = null;
        });
        return;
      case AnimationStatus.completed:
        pauseTimer = Timer(pause, () {
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
      duration: duration,
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
