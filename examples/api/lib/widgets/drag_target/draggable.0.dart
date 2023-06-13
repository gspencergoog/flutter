// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
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
        DragSource(
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
              child: Text('Drag Source'),
            ),
          ),
        ),
        DragDestination(
          acceptedTypes: const <ExternalContentType>{
            ExternalContentType.plainText,
            ExternalContentType.html,
          },
          child: Container(
            height: 100.0,
            width: 100.0,
            color: Colors.cyan,
            child: Center(
              child: Text('Value is: $acceptedData'),
            ),
          ),
          onAccept: (Iterable<ExternalData> data) {
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
/// the [DragSource].
///
/// This includes the [Velocity] at which the pointer was moving and [Offset]
/// when the draggable event occurred, and whether its [DragDestination] accepted it.
///
/// Also, this is the details object for callbacks that use [DragSourceEndCallback].
class DragSourceDetails {
  /// Creates details for a [DragSourceDetails].
  ///
  /// If [wasAccepted] is not specified, it will default to `false`.
  ///
  /// The [velocity] or [offset] arguments must not be `null`.
  DragSourceDetails({
    this.wasAccepted = false,
    required this.velocity,
    required this.offset,
  });

  /// Determines whether the [DragDestination] accepted this draggable.
  final bool wasAccepted;

  /// The velocity at which the pointer was moving when the specific pointer
  /// event occurred on the draggable.
  final Velocity velocity;

  /// The global position when the specific pointer event occurred on
  /// the draggable.
  final Offset offset;
}

/// The function type for [DragSource.onProvideData], used to supply the
/// data for a drag and drop operation when the data is dropped on the target.
typedef DragSourceDataProvider = Iterable<ExternalData> Function();

/// Signature for when a [DragSource] is dropped without being accepted by a [DragDestination].
///
/// Used by [DragSource.onDragCanceled].
typedef DragSourceCanceledCallback = void Function(Velocity velocity, Offset offset);

/// Signature for when the draggable is dropped.
///
/// The velocity and offset at which the pointer was moving when the draggable
/// was dropped is available in the [DragSourceDetails]. Also included in the
/// `details` is whether the draggable's [DragDestination] accepted it.
///
/// Used by [DragSource.onDragEnd].
typedef DragSourceEndCallback = void Function(DragSourceDetails details);

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
/// * [DragDestination]
class DragSource extends StatefulWidget {
  /// Creates a widget that can be dragged out of the application to the desktop
  /// or another application.
  ///
  /// The [child] and [feedback] arguments must not be null.
  const DragSource({
    super.key,
    required this.child,
    required this.feedback,
    required this.onProvideData,
    this.childWhenDragging,
    this.affinity,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
    this.allowedButtonsFilter,
  });

  /// Supplies a single plain text, UTF-8 encoded, item for dragging to another
  /// application.
  DragSource.plainText({
    super.key,
    required this.child,
    required this.feedback,
    required String text,
    this.childWhenDragging,
    this.affinity,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
    this.allowedButtonsFilter,
  }) : onProvideData = _provideText(text);

  static DragSourceDataProvider _provideText(String text) {
    return () => <ExternalData>[
          ExternalData(
            values: <ExternalDataItem<Object>>[
              ExternalDataItem<String>(type: ContentType.text, data: text),
            ],
          ),
        ];
  }

  /// The data that will be dropped by this draggable, in selection order.
  ///
  /// Each [ExternalData] object can have multiple MIME type representations.
  final DragSourceDataProvider onProvideData;

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
  /// the location of the [DragSource] itself when a drag is underway.
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
  final DragSourceCanceledCallback? onDragCanceled;

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
  final DragSourceEndCallback? onDragEnd;

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
  State<DragSource> createState() => _DragSourceState();
}

class _DragSourceState extends State<DragSource> {
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

  _DragSourceAvatar? _startDrag(Offset position) {
    final Offset dragStartPoint;
    dragStartPoint = position;
    setState(() {
      _activeCount += 1;
    });
    final _DragSourceAvatar avatar = _DragSourceAvatar(
      overlayState: Overlay.of(context, debugRequiredFor: widget),
      data: widget.onProvideData(),
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
          widget.onDragEnd!(DragSourceDetails(
            wasAccepted: wasAccepted,
            velocity: velocity,
            offset: offset,
          ));
        }
        if (wasAccepted && widget.onDragCompleted != null) {
          widget.onDragCompleted!();
        }
        if (!wasAccepted && widget.onDragCanceled != null) {
          widget.onDragCanceled!(velocity, offset);
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

/// Signature for building children of a [DragDestination].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [DragDestination] and that is an accepted type as defined by
/// [DragDestination.acceptedTypes].
///
/// Used by [DragDestination.builder].
typedef DragDestinationBuilder = Widget Function(
  BuildContext context,
  List<ExternalData> candidateData,
);

/// A container for details related to a drag to a drag destination.
// This is a class and not a record or just an Offset so that additional details
// may be added in the future without breaking the signature of
// DragDestinationAcceptWithDetails.
@immutable
class DragDestinationDetails {
  const DragDestinationDetails(this.dragLocation);

  final Offset dragLocation;
}

/// Signature for causing a [DragTarget] to accept the given data.
///
/// Used by [DragTarget.onAccept].
typedef DragDestinationAccept = void Function(Iterable<ExternalData> data);

/// Signature for determining information about the acceptance by a [DragTarget].
///
/// Used by [DragTarget.onAcceptWithDetails].
typedef DragDestinationAcceptWithDetails = void Function(Iterable<ExternalData> data, DragDestinationDetails dragDetails);

/// A widget that receives data when data is dropped on an application by the
/// operating system.
///
/// When a dragged source data is dragged on top of a drag destination, the drag
/// destination compares the types offered by the data to the types it will
/// accept. If the user does drop the drag source on top of the drag destination
/// (and the drag destination has indicated that it will accept the drag
/// source's data), then the drag target is asked to accept the drag source's
/// data.
///
/// See also:
///
/// * [DragSource], A widget that defines types for dragging data out of an
///   application.
class DragDestination extends StatefulWidget {
  /// Creates a widget that receives drags.
  const DragDestination({
    super.key,
    required this.acceptedTypes,
    required this.child,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  /// The acceptable content types (MIME types) of dropped objects.
  final Set<ExternalContentType> acceptedTypes;

  /// The child of this widget, covering the area that can be used as a drag
  /// target.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final Widget child;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Supplies a list of external data objects, each of which has its own MIME
  /// type and data payload.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final DragDestinationAccept? onAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAccept], but with information, including the data, in a
  /// [DragTargetDetails].
  final DragDestinationAcceptWithDetails? onAcceptWithDetails;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final DragTargetLeave<List<ExternalData>>? onLeave;

  /// Called when a [DragSource] moves within this [DragTarget].
  ///
  /// This includes entering and leaving the target.
  final DragTargetMove<List<ExternalData>>? onMove;

  /// How to behave during a hit test.
  ///
  /// Defaults to [HitTestBehavior.translucent].
  final HitTestBehavior hitTestBehavior;

  @override
  State<DragDestination> createState() => _DragDestinationState();
}

class _DragDestinationState extends State<DragDestination> {
  final List<_DragSourceAvatar> _candidateAvatars = <_DragSourceAvatar>[];
  final List<_DragSourceAvatar> _rejectedAvatars = <_DragSourceAvatar>[];

  bool didEnter(_DragSourceAvatar avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    setState(() {
      _candidateAvatars.add(avatar);
    });
    return true;
  }

  void didLeave(_DragSourceAvatar avatar) {
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

  void didDrop(_DragSourceAvatar avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    widget.onAccept?.call(avatar.data);
    widget.onAcceptWithDetails?.call(avatar.data, DragDestinationDetails(avatar._lastOffset!));
  }

  void didMove(_DragSourceAvatar avatar) {
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
      child: widget.child,
    );
  }
}

enum _DragEndKind { dropped, canceled }

typedef _OnDragEnd = void Function(Velocity velocity, Offset offset, bool wasAccepted);

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away. _DraggableState has some delicate logic to continue
// needing this object for pointer events even after it has been disposed.
class _DragSourceAvatar extends Drag {
  _DragSourceAvatar({
    required this.overlayState,
    required this.data,
    required this.feedback,
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
  final Offset dragStartPoint;
  final Widget feedback;
  final DragUpdateCallback? onDragUpdate;
  final _OnDragEnd? onDragEnd;
  final OverlayState overlayState;

  _DragDestinationState? _activeTarget;
  final List<_DragDestinationState> _enteredTargets = <_DragDestinationState>[];
  Offset _position;
  Offset? _lastOffset;
  OverlayEntry? _entry;

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += details.delta;
    updateDrag(_position);
    if (onDragUpdate != null && _position != oldPosition) {
      onDragUpdate!(details);
    }
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, details.velocity);
  }

  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Offset globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    _entry!.markNeedsBuild();
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, globalPosition, View.of(overlayState.context).viewId);

    final List<_DragDestinationState> targets = _getDragTargets(result.path).toList();

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length && _enteredTargets.isNotEmpty) {
      listsMatch = true;
      final Iterator<_DragDestinationState> iterator = targets.iterator;
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
      for (final _DragDestinationState target in _enteredTargets) {
        target.didMove(this);
      }
      return;
    }

    // Leave old targets.
    _leaveAllEntered();

    // Enter new targets.
    final _DragDestinationState? newTarget = targets.cast<_DragDestinationState?>().firstWhere(
      (_DragDestinationState? target) {
        if (target == null) {
          return false;
        }
        _enteredTargets.add(target);
        return target.didEnter(this);
      },
      orElse: () => null,
    );

    // Report moves to the targets.
    for (final _DragDestinationState target in _enteredTargets) {
      target.didMove(this);
    }

    _activeTarget = newTarget;
  }

  Iterable<_DragDestinationState> _getDragTargets(Iterable<HitTestEntry> path) {
    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    final List<_DragDestinationState> targets = <_DragDestinationState>[];
    for (final HitTestEntry entry in path) {
      final HitTestTarget target = entry.target;
      if (target is RenderMetaData) {
        final dynamic metaData = target.metaData;
        if (metaData is _DragDestinationState) {
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
}

@immutable
abstract interface class ExternalDataItemInterface<T extends Object> {
  const ExternalDataItemInterface();

  ExternalContentType get type;
  T get data;
}

base class ExternalDataItem<T extends Object> implements ExternalDataItemInterface<T> {
  const ExternalDataItem({required this.type, required this.data})
      : assert(T is String || T is ByteData || T is Uri || T is List<String> || T is List<ByteData> || T is List<Uri>,
            "Only specific payload types are allowed, and $T isn't one of them.");

  @override
  final ExternalContentType type;

  @override
  final T data;
}

class ExternalData {
  ExternalData({required this.values})
      : assert(values.isNotEmpty),
        assert(values.map<ExternalContentType>((ExternalDataItemInterface<Object> item) => item.type).toSet().length == values.length,
            'Supplied $ExternalDataItem values must all have unique content types.'),
        byType = Map<ExternalContentType, ExternalDataItemInterface<Object>>.fromEntries(
          values.map<MapEntry<ExternalContentType, ExternalDataItemInterface<Object>>>(
            (ExternalDataItemInterface<Object> item) => MapEntry<ExternalContentType, ExternalDataItemInterface<Object>>(item.type, item),
          ),
        );

  final Iterable<ExternalDataItem<Object>> values;
  final Map<ExternalContentType, ExternalDataItemInterface<Object>> byType;
}

final class PlainTextExternalData extends ExternalDataItem<String> {
  const PlainTextExternalData({required String text}) : super(type: ExternalContentType.plainText, data: text);
}

final class HtmlExternalData extends ExternalDataItem<String> {
  const HtmlExternalData({required String html}) : super(type: ExternalContentType.html, data: html);
}

final class PngExternalData extends ExternalDataItem<ByteData> {
  PngExternalData({required ByteData pngData}) : super(type: ExternalContentType.fromComponents('image', 'png'), data: pngData);
}

final class JpegExternalData extends ExternalDataItem<ByteData> {
  JpegExternalData({required ByteData jpegData}) : super(type: ExternalContentType.fromComponents('image', 'jpeg'), data: jpegData);
}

final class BinaryExternalData extends ExternalDataItem<ByteData> {
  const BinaryExternalData({required ByteData binaryData}) : super(type: ExternalContentType.binary, data: binaryData);
}

final class UrlListExternalData extends ExternalDataItem<List<Uri>> {
  UrlListExternalData({required List<Uri> uris})
      : super(type: ExternalContentType.fromComponents('text', 'uri-list', parameters: const <String, String?>{'charset': 'utf-8'}), data: uris);
}

/// A MIME/IANA media type used as the type for [ExternalData] data types.
///
/// An [ExternalContentType] is immutable.
@immutable
class ExternalContentType {
  factory ExternalContentType(String mimeType) => parse(mimeType);

  /// Creates a new [ExternalContentType] object setting the primary type and
  /// sub type. Additional parameters can also be set using [parameters]. Keys
  /// passed in parameters will be converted to lower case, as will some values
  /// (notably, the "charset" parameter).
  factory ExternalContentType.fromComponents(String primaryType, String subType,
      {Map<String, String?> parameters = const <String, String?>{}}) {
    final ContentType contentType = ContentType(primaryType, subType, parameters: parameters);
    assert(_isValidMimeType(contentType));
    return ExternalContentType._(
      // Use ContentType fields instead of arguments because they could have had
      // their case changed when parsed.
      contentType.primaryType,
      contentType.subType,
      contentType.parameters,
      contentType.toString(),
    );
  }

  const ExternalContentType._(this._primaryType, this._subType, this._parameters, this._mimeType);

  String get mimeType => _mimeType;
  String get mimePrimaryType => _primaryType;
  String get mimeSubType => _subType;
  String? get charset => _parameters['charset'];

  Map<String, String?> get mimeParameters => _parameters;

  // Doesn't use a ContentType as the internal representation because
  // ContentType can't be const, so static const common types couldn't be
  // defined.
  final String _mimeType;
  final String _primaryType;
  final String _subType;
  final Map<String, String?> _parameters;

  static const ExternalContentType plainText =
      ExternalContentType._('text', 'plain', <String, String?>{'charset': 'utf-8'}, 'text/plain;charset=utf-8');
  static const ExternalContentType html =
      ExternalContentType._('text', 'html', <String, String?>{'charset': 'utf-8'}, 'text/html;charset=utf-8');
  static const ExternalContentType binary =
      ExternalContentType._('application', 'octet-stream', <String, String?>{}, 'application/octet-stream');

  static ExternalContentType parse(String value) {
    final ContentType contentType = ContentType.parse(value);
    assert(_isValidMimeType(contentType),
        'MIME type $value is not a valid MIME type. The multipart and message primary MIME types are not supported.');
    return ExternalContentType._(
      contentType.primaryType,
      contentType.subType,
      contentType.parameters,
      contentType.toString(),
    );
  }

  static bool _isValidMimeType(ContentType type) {
    // Do some validation that the ContentType class doesn't do.
    const String validName = r'''[-\w!#$%&'*+.^`|~]+''';
    // Multipart and message types are not supported.
    const String primaryType = '(?<type>application|audio|example|font|image|model|text|video|x-(?:$validName))';
    if (!RegExp(primaryType).hasMatch(type.primaryType)) {
      return false;
    }
    if (!RegExp(validName).hasMatch(type.subType)) {
      return false;
    }
    return true;
  }
}
