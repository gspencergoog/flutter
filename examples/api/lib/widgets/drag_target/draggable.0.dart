// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [Draggable].

void main() => runApp(const DraggableExampleApp());

class DraggableExampleApp extends StatelessWidget {
  const DraggableExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Draggable Sample')),
        body: const DraggableExample(),
      ),
    );
  }
}

class DraggableExample extends StatefulWidget {
  const DraggableExample({super.key});

  @override
  State<DraggableExample> createState() => _DraggableExampleState();
}

class _DraggableExampleState extends State<DraggableExample> {
  Object acceptedData = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ExternalDraggable(
          onProvideData: () {
            return <ExternalData>[
              ExternalData(
                values: <ExternalDataItem<Object>>{
                  UrlListExternalData(
                    uris: <Uri>[
                      Uri.parse('http://google.com'),
                    ],
                  ),
                },
              ),
            ];
          },
          feedback: Container(
            color: Colors.deepOrange,
            height: 100,
            width: 100,
            child: const Icon(Icons.directions_run),
          ),
          childWhenDragging: Container(
            height: 100.0,
            width: 100.0,
            color: Colors.pinkAccent,
            child: const Center(
              child: Text('Child When Dragging'),
            ),
          ),
          child: Container(
            height: 100.0,
            width: 100.0,
            color: Colors.lightGreenAccent,
            child: const Center(
              child: Text('Draggable'),
            ),
          ),
        ),
        ExternalDragTarget(
          acceptedTypes: <ContentType>{ContentType.text, ContentType.html},
          builder: (
            BuildContext context,
            List<ExternalData> accepted,
          ) {
            return Container(
              height: 100.0,
              width: 100.0,
              color: Colors.cyan,
              child: Center(
                child: Text('Value is: $accepted'),
              ),
            );
          },
          onAccept: (List<ExternalData> data) {
            setState(() {
              acceptedData = data;
            });
          },
        ),
      ],
    );
  }
}

/// Represents the details when a specific pointer event occurred on
/// the [ExternalDraggable].
///
/// This includes the [Velocity] at which the pointer was moving and [Offset]
/// when the draggable event occurred, and whether its [ExternalDragTarget] accepted it.
///
/// Also, this is the details object for callbacks that use [ExternalDragEndCallback].
class ExternalDraggableDetails {
  /// Creates details for a [ExternalDraggableDetails].
  ///
  /// If [wasAccepted] is not specified, it will default to `false`.
  ///
  /// The [velocity] or [offset] arguments must not be `null`.
  ExternalDraggableDetails({
    this.wasAccepted = false,
    required this.velocity,
    required this.offset,
  });

  /// Determines whether the [ExternalDragTarget] accepted this draggable.
  final bool wasAccepted;

  /// The velocity at which the pointer was moving when the specific pointer
  /// event occurred on the draggable.
  final Velocity velocity;

  /// The global position when the specific pointer event occurred on
  /// the draggable.
  final Offset offset;
}


/// The function type for [ExternalDraggable.onProvideData], used to supply the
/// data for a drag and drop operation when the data is dropped on the target.
typedef ExternalDraggableDataProvider = Iterable<ExternalData> Function();

/// Signature for when a [ExternalDraggable] is dropped without being accepted by a [ExternalDragTarget].
///
/// Used by [ExternalDraggable.onDraggableCanceled].
typedef ExternalDraggableCanceledCallback = void Function(Velocity velocity, Offset offset);

/// Signature for when the draggable is dropped.
///
/// The velocity and offset at which the pointer was moving when the draggable
/// was dropped is available in the [ExternalDraggableDetails]. Also included in the
/// `details` is whether the draggable's [ExternalDragTarget] accepted it.
///
/// Used by [ExternalDraggable.onDragEnd].
typedef ExternalDragEndCallback = void Function(ExternalDraggableDetails details);

/// A widget that can be dragged out of an application to be dropped on another
/// application on the platform.
///
/// When a draggable widget recognizes the start of a drag gesture, it displays
/// a [feedback] widget that tracks the pointer across the screen. If the user
/// lets go of the pointer while on top of a operating system drag target, that
/// target is given the data produced when [onProvideData] is called.
///
/// This widget displays [child] when no drags are underway. If
/// [childWhenDragging] is non-null, this widget instead displays
/// [childWhenDragging] when drags are underway. Otherwise, this widget always
/// displays [child].
///
/// See also:
///
/// * [ExternalDragTarget]
class ExternalDraggable extends StatefulWidget {
  /// Creates a widget that can be dragged out of the application to the desktop
  /// or another application.
  ///
  /// The [child] and [feedback] arguments must not be null.
  const ExternalDraggable({
    super.key,
    required this.child,
    required this.feedback,
    required this.onProvideData,
    this.axis,
    this.childWhenDragging,
    this.affinity,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
    this.allowedButtonsFilter,
  });

  /// The data that will be dropped by this draggable, in selection order.
  ///
  /// Each [ExternalData] object can have multiple MIME type representations.
  final ExternalDraggableDataProvider onProvideData;

  /// The [Axis] to restrict this draggable's movement, if specified.
  ///
  /// When axis is set to [Axis.horizontal], this widget can only be dragged
  /// horizontally. Behavior is similar for [Axis.vertical].
  ///
  /// Defaults to allow drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// When null, allows drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// For the direction of gestures this widget competes with to start a drag
  /// event, see [affinity].
  final Axis? axis;

  /// The widget below this widget in the tree.
  ///
  /// This widget displays [child] when zero drags are underway. If
  /// [childWhenDragging] is non-null, this widget instead displays
  /// [childWhenDragging] when one or more drags are underway. Otherwise, this
  /// widget always displays [child].
  ///
  /// The [feedback] widget is shown under the pointer when a drag is underway.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The widget to display instead of [child] when one or more drags are
  /// underway.
  ///
  /// If this is null, then this widget will always display [child] (and so the
  /// drag source representation will not change while a drag is under way).
  ///
  /// The [feedback] widget is shown under the pointer when a drag is underway.
  final Widget? childWhenDragging;

  /// The widget to show under the pointer when a drag is underway.
  ///
  /// See [child] and [childWhenDragging] for information about what is shown at
  /// the location of the [ExternalDraggable] itself when a drag is underway.
  final Widget feedback;

  /// Controls how this widget competes with other gestures to initiate a drag.
  ///
  /// If affinity is null, this widget initiates a drag as soon as it recognizes
  /// a tap down gesture, regardless of any directionality. If affinity is
  /// horizontal (or vertical), then this widget will compete with other
  /// horizontal (or vertical, respectively) gestures.
  ///
  /// For example, if this widget is placed in a vertically scrolling region and
  /// has horizontal affinity, pointer motion in the vertical direction will
  /// result in a scroll and pointer motion in the horizontal direction will
  /// result in a drag. Conversely, if the widget has a null or vertical
  /// affinity, pointer motion in any direction will result in a drag rather
  /// than in a scroll because the draggable widget, being the more specific
  /// widget, will out-compete the [Scrollable] for vertical gestures.
  ///
  /// For the directions this widget can be dragged in after the drag event
  /// starts, see [Draggable.axis].
  final Axis? affinity;

  /// Called when the draggable starts being dragged.
  final VoidCallback? onDragStarted;

  /// Called when the draggable is dragged.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true), and if this widget has actually
  /// moved.
  final DragUpdateCallback? onDragUpdate;

  /// Called when the draggable is dropped without being accepted by the
  /// platform.
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up being canceled, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final ExternalDraggableCanceledCallback? onDraggableCanceled;

  /// Called when the draggable is dropped and accepted by the platform.
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up completing, this callback will still
  /// be called. For this reason, implementations of this callback might need to
  /// check [State.mounted] to check whether the state receiving the callback is
  /// still in the tree.
  final VoidCallback? onDragCompleted;

  /// Called when the draggable is dropped.
  ///
  /// The velocity and offset at which the pointer was moving when it was
  /// dropped is available in the [DraggableDetails]. Also included in the
  /// `details` is whether the draggable's [DragTarget] accepted it.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true).
  final ExternalDragEndCallback? onDragEnd;

  /// How to behave during hit test.
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  final HitTestBehavior hitTestBehavior;

  /// {@macro flutter.gestures.multidrag._allowedButtonsFilter}
  final AllowedButtonsFilter? allowedButtonsFilter;

  /// Creates a gesture recognizer that recognizes the start of the drag.
  ///
  /// Subclasses can override this function to customize when they start
  /// recognizing a drag.
  @protected
  MultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    switch (affinity) {
      case Axis.horizontal:
        return HorizontalMultiDragGestureRecognizer(allowedButtonsFilter: allowedButtonsFilter)..onStart = onStart;
      case Axis.vertical:
        return VerticalMultiDragGestureRecognizer(allowedButtonsFilter: allowedButtonsFilter)..onStart = onStart;
      case null:
        return ImmediateMultiDragGestureRecognizer(allowedButtonsFilter: allowedButtonsFilter)..onStart = onStart;
    }
  }

  @override
  State<ExternalDraggable> createState() => _ExternalDraggableState();
}

class _ExternalDraggableState extends State<ExternalDraggable> {
  @override
  void initState() {
    super.initState();
    _recognizer = widget.createRecognizer(_startDrag);
  }

  @override
  void dispose() {
    _disposeRecognizerIfInactive();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _recognizer!.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    super.didChangeDependencies();
  }

  // This gesture recognizer has an unusual lifetime. We want to support the use
  // case of removing the Draggable from the tree in the middle of a drag. That
  // means we need to keep this recognizer alive after this state object has
  // been disposed because it's the one listening to the pointer events that are
  // driving the drag.
  //
  // We achieve that by keeping count of the number of active drags and only
  // disposing the gesture recognizer after (a) this state object has been
  // disposed and (b) there are no more active drags.
  GestureRecognizer? _recognizer;
  int _activeCount = 0;

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0) {
      return;
    }
    _recognizer!.dispose();
    _recognizer = null;
  }

  void _routePointer(PointerDownEvent event) {
    _recognizer!.addPointer(event);
  }

  _ExternalDragAvatar? _startDrag(Offset position) {
    final Offset dragStartPoint;
    dragStartPoint = position;
    setState(() {
      _activeCount += 1;
    });
    final _ExternalDragAvatar avatar = _ExternalDragAvatar(
      overlayState: Overlay.of(context, debugRequiredFor: widget),
      data: widget.onProvideData(),
      axis: widget.axis,
      initialPosition: position,
      dragStartPoint: dragStartPoint,
      feedback: widget.feedback,
      onDragUpdate: (DragUpdateDetails details) {
        if (mounted && widget.onDragUpdate != null) {
          widget.onDragUpdate!(details);
        }
      },
      onDragEnd: (Velocity velocity, Offset offset, bool wasAccepted) {
        if (mounted) {
          setState(() {
            _activeCount -= 1;
          });
        } else {
          _activeCount -= 1;
          _disposeRecognizerIfInactive();
        }
        if (mounted && widget.onDragEnd != null) {
          widget.onDragEnd!(ExternalDraggableDetails(
            wasAccepted: wasAccepted,
            velocity: velocity,
            offset: offset,
          ));
        }
        if (wasAccepted && widget.onDragCompleted != null) {
          widget.onDragCompleted!();
        }
        if (!wasAccepted && widget.onDraggableCanceled != null) {
          widget.onDraggableCanceled!(velocity, offset);
        }
      },
    );
    widget.onDragStarted?.call();
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    final bool showChild = _activeCount == 0 || widget.childWhenDragging == null;
    return Listener(
      behavior: widget.hitTestBehavior,
      onPointerDown: _routePointer,
      child: showChild ? widget.child : widget.childWhenDragging,
    );
  }
}

/// Signature for building children of a [ExternalDragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [ExternalDragTarget] and that is an accepted type as defined by
/// [ExternalDragTarget.acceptedTypes].
///
/// Used by [ExternalDragTarget.builder].
typedef ExternalDragTargetBuilder = Widget Function(
  BuildContext context,
  List<ExternalData> candidateData,
);

/// Signature for causing a [DragTarget] to accept the given data.
///
/// Used by [DragTarget.onAccept].
typedef ExternalDragTargetAccept = void Function(Iterable<ExternalData> data);

/// Signature for determining information about the acceptance by a [DragTarget].
///
/// Used by [DragTarget.onAcceptWithDetails].
typedef ExternalDragTargetAcceptWithDetails = void Function(ExternalDragTargetDetails details);

/// A widget that receives data when external data is dropped on an application
/// by the operating system.
///
/// When a external draggable data is dragged on top of a drag target, the drag
/// target compares the types offered by the external data to the types it will
/// accept. If the user does drop the draggable on top of the drag target (and
/// the drag target has indicated that it will accept the draggable's data),
/// then the drag target is asked to accept the draggable's data.
///
/// See also:
///
/// * [ExternalDraggable], A widget that defines types for dragging data out of
///   an application.
class ExternalDragTarget extends StatefulWidget {
  /// Creates a widget that receives drags.
  ExternalDragTarget({
    super.key,
    required this.builder,
    required this.acceptedTypes,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
  }) : assert(_debugVerifyDataTypes(acceptedTypes), 'Data type list $acceptedTypes contains an invalid MIME type.');

  static bool _debugVerifyDataTypes(Set<ContentType> acceptedTypes) {
    if (acceptedTypes.isEmpty) {
      return false;
    }

    for (final ContentType type in acceptedTypes) {
      if (!isValidMimeType(type)) {
        return false;
      }
    }
    return true;
  }

  /// The acceptable content types (MIME types) of dropped objects.
  final Set<ContentType> acceptedTypes;

  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final ExternalDragTargetBuilder builder;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Supplies a list of external data objects, each of which has its own MIME
  /// type and data payload.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final ExternalDragTargetAccept? onAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAccept], but with information, including the data, in a
  /// [DragTargetDetails].
  final ExternalDragTargetAcceptWithDetails? onAcceptWithDetails;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final DragTargetLeave<List<ExternalData>>? onLeave;

  /// Called when a [Draggable] moves within this [DragTarget].
  ///
  /// This includes entering and leaving the target.
  final DragTargetMove<List<ExternalData>>? onMove;

  /// How to behave during hit testing.
  ///
  /// Defaults to [HitTestBehavior.translucent].
  final HitTestBehavior hitTestBehavior;

  @override
  State<ExternalDragTarget> createState() => _ExternalDragTargetState();

  static bool isValidMimeType(ContentType type) {
    // Do some validation that the ContentType class doesn't do.
    const String validName = r'''[-\w!#$%&'*+.^`|~]+''';
    const String primaryType =
        '(?<type>application|audio|example|font|image|message|model|multipart|text|video|x-(?:$validName))';
    if (!RegExp(primaryType).hasMatch(type.primaryType)) {
      return false;
    }
    if (!RegExp(validName).hasMatch(type.subType)) {
      return false;
    }
    return true;
  }
}

List<T> _mapAvatarsToData<T extends Object>(List<_ExternalDragAvatar> avatars) {
  return avatars.map<T>((_ExternalDragAvatar avatar) => avatar.data as T).toList();
}

class _ExternalDragTargetState extends State<ExternalDragTarget> {
  final List<_ExternalDragAvatar> _candidateAvatars = <_ExternalDragAvatar>[];
  final List<_ExternalDragAvatar> _rejectedAvatars = <_ExternalDragAvatar>[];

  bool didEnter(_ExternalDragAvatar avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    setState(() {
      _candidateAvatars.add(avatar);
    });
    return true;
  }

  void didLeave(_ExternalDragAvatar avatar) {
    assert(_candidateAvatars.contains(avatar) || _rejectedAvatars.contains(avatar));
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateAvatars.remove(avatar);
      _rejectedAvatars.remove(avatar);
    });
    widget.onLeave?.call(avatar.data as List<ExternalData>);
  }

  void didDrop(_ExternalDragAvatar avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    widget.onAccept?.call(avatar.data as List<ExternalData>);
    widget.onAcceptWithDetails?.call(
      ExternalDragTargetDetails(
        data: avatar.data as List<ExternalData>,
        offset: avatar._lastOffset!,
      ),
    );
  }

  void didMove(_ExternalDragAvatar avatar) {
    if (!mounted) {
      return;
    }
    widget.onMove?.call(
      DragTargetDetails<List<ExternalData>>(
        data: avatar.data as List<ExternalData>,
        offset: avatar._lastOffset!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      behavior: widget.hitTestBehavior,
      child: widget.builder(context, _mapAvatarsToData<ExternalData>(_candidateAvatars)),
    );
  }
}

enum _DragEndKind { dropped, canceled }

typedef _OnDragEnd = void Function(Velocity velocity, Offset offset, bool wasAccepted);

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away. _DraggableState has some delicate logic to continue
// needing this object for pointer events even after it has been disposed.
class _ExternalDragAvatar extends Drag {
  _ExternalDragAvatar({
    required this.overlayState,
    required this.data,
    required this.feedback,
    this.axis,
    required Offset initialPosition,
    this.dragStartPoint = Offset.zero,
    this.onDragUpdate,
    this.onDragEnd,
  }) : _position = initialPosition {
    _entry = OverlayEntry(builder: _build);
    overlayState.insert(_entry!);
    updateDrag(initialPosition);
  }

  final Iterable<ExternalData> data;
  final Axis? axis;
  final Offset dragStartPoint;
  final Widget feedback;
  final DragUpdateCallback? onDragUpdate;
  final _OnDragEnd? onDragEnd;
  final OverlayState overlayState;

  _ExternalDragTargetState? _activeTarget;
  final List<_ExternalDragTargetState> _enteredTargets = <_ExternalDragTargetState>[];
  Offset _position;
  Offset? _lastOffset;
  OverlayEntry? _entry;

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += _restrictAxis(details.delta);
    updateDrag(_position);
    if (onDragUpdate != null && _position != oldPosition) {
      onDragUpdate!(details);
    }
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, _restrictVelocityAxis(details.velocity));
  }

  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Offset globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    _entry!.markNeedsBuild();
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition);

    final List<_ExternalDragTargetState> targets = _getDragTargets(result.path).toList();

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length && _enteredTargets.isNotEmpty) {
      listsMatch = true;
      final Iterator<_ExternalDragTargetState> iterator = targets.iterator;
      for (int i = 0; i < _enteredTargets.length; i += 1) {
        iterator.moveNext();
        if (iterator.current != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    // If everything's the same, report moves, and bail early.
    if (listsMatch) {
      for (final _ExternalDragTargetState target in _enteredTargets) {
        target.didMove(this);
      }
      return;
    }

    // Leave old targets.
    _leaveAllEntered();

    // Enter new targets.
    final _ExternalDragTargetState? newTarget = targets.cast<_ExternalDragTargetState?>().firstWhere(
      (_ExternalDragTargetState? target) {
        if (target == null) {
          return false;
        }
        _enteredTargets.add(target);
        return target.didEnter(this);
      },
      orElse: () => null,
    );

    // Report moves to the targets.
    for (final _ExternalDragTargetState target in _enteredTargets) {
      target.didMove(this);
    }

    _activeTarget = newTarget;
  }

  Iterable<_ExternalDragTargetState> _getDragTargets(Iterable<HitTestEntry> path) {
    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    final List<_ExternalDragTargetState> targets = <_ExternalDragTargetState>[];
    for (final HitTestEntry entry in path) {
      final HitTestTarget target = entry.target;
      if (target is RenderMetaData) {
        final dynamic metaData = target.metaData;
        if (metaData is _ExternalDragTargetState) {
          targets.add(metaData);
        }
      }
    }
    return targets;
  }

  void _leaveAllEntered() {
    for (int i = 0; i < _enteredTargets.length; i += 1) {
      _enteredTargets[i].didLeave(this);
    }
    _enteredTargets.clear();
  }

  void finishDrag(_DragEndKind endKind, [Velocity? velocity]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTarget != null) {
      _activeTarget!.didDrop(this);
      wasAccepted = true;
      _enteredTargets.remove(_activeTarget);
    }
    _leaveAllEntered();
    _activeTarget = null;
    _entry!.remove();
    _entry!.dispose();
    _entry = null;
    onDragEnd?.call(velocity ?? Velocity.zero, _lastOffset!, wasAccepted);
  }

  Widget _build(BuildContext context) {
    final RenderBox box = overlayState.context.findRenderObject()! as RenderBox;
    final Offset overlayTopLeft = box.localToGlobal(Offset.zero);
    return Positioned(
      left: _lastOffset!.dx - overlayTopLeft.dx,
      top: _lastOffset!.dy - overlayTopLeft.dy,
      child: feedback,
    );
  }

  Velocity _restrictVelocityAxis(Velocity velocity) {
    if (axis == null) {
      return velocity;
    }
    return Velocity(
      pixelsPerSecond: _restrictAxis(velocity.pixelsPerSecond),
    );
  }

  Offset _restrictAxis(Offset offset) {
    if (axis == null) {
      return offset;
    }
    if (axis == Axis.horizontal) {
      return Offset(offset.dx, 0.0);
    }
    return Offset(0.0, offset.dy);
  }
}

/// Represents the details when a pointer event occurred on the [DragTarget].
class ExternalDragTargetDetails {
  /// Creates details for a [DragTarget] callback.
  ///
  /// The [offset] must not be null.
  ExternalDragTargetDetails({required this.data, required this.offset});

  /// The data that was dropped onto this [DragTarget].
  final Iterable<ExternalData> data;

  /// The global position when the specific pointer event occurred on
  /// the draggable.
  final Offset offset;
}

@immutable
class ExternalDataItem<T extends Object> {
  const ExternalDataItem({required this.type, required this.data})
      : assert(T is String || T is ByteData || T is Uri || T is List<String> || T is List<ByteData> || T is List<Uri>,
            "Only specific payload types are allowed, and $T isn't one of them.");

  final ContentType type;
  final T data;
}

class ExternalData {
  ExternalData({required this.values})
      : assert(values.isNotEmpty),
        assert(values.map<ContentType>((ExternalDataItem<Object> item) => item.type).toSet().length == values.length,
            'Supplied $ExternalDataItem values must all have unique content types.'),
        byType = Map<ContentType, ExternalDataItem<Object>>.fromEntries(
          values.map<MapEntry<ContentType, ExternalDataItem<Object>>>(
            (ExternalDataItem<Object> item) => MapEntry<ContentType, ExternalDataItem<Object>>(item.type, item),
          ),
        );

  final Iterable<ExternalDataItem<Object>> values;
  final Map<ContentType, ExternalDataItem<Object>> byType;
}

class PlainTextExternalData extends ExternalDataItem<String> {
  PlainTextExternalData({required String text}) : super(type: ContentType.text, data: text);
}

class HtmlExternalData extends ExternalDataItem<String> {
  HtmlExternalData({required String html}) : super(type: ContentType.html, data: html);
}

class PngExternalData extends ExternalDataItem<ByteData> {
  PngExternalData({required ByteData pngData}) : super(type: ContentType('image','png'), data: pngData);
}

class JpegExternalData extends ExternalDataItem<ByteData> {
  JpegExternalData({required ByteData jpegData}) : super(type: ContentType('image', 'jpeg'), data: jpegData);
}

class UrlListExternalData extends ExternalDataItem<List<Uri>> {
  UrlListExternalData({required List<Uri> uris}) : super(type: ContentType('text', 'uri-list', charset: 'utf-8'), data: uris);
}
