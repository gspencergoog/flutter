import 'dart:ui';
import 'package:flutter/widgets.dart';

/// A listener that can be used to configure callbacks that will be called at
/// various points in the application lifecycle.
/// A callback type that is used by [AppLifecycleListener.onExitRequested] to
/// ask the application if it wants to cancel application termination or not.
typedef AppExitRequestCallback = Future<AppExitResponse> Function();

/// A listener that can be used to configure callbacks that will be called at
/// various points in the application lifecycle.
class AppLifecycleListener with WidgetsBindingObserver  {
  /// Creates an [AppLifecycleListener].
  AppLifecycleListener({
    required this.binding,
    this.onInitialize,
    this.onStart,
    this.onResume,
    this.onInactive,
    this.onHide,
    this.onShow,
    this.onPause,
    this.onRestart,
    this.onDetach,
    this.onExitRequested,
    this.onStateChange,
  }) : _lifecycleState = AppLifecycleState.detached {
    binding.addObserver(this);
  }

  AppLifecycleState _lifecycleState;

  /// The [WidgetsBinding] to listen to for application lifecycle events.
  ///
  /// Typically, this is set to [WidgetsBinding.instance], but may be
  /// substituted for testing or other specialized bindings.
  final WidgetsBinding binding;

  /// Called anytime the state changes, passing the new state.
  ///
  /// The [AppLifecycleListener] class is also a [ChangeNotifier], which
  /// performs a similar function as this callback, but as a notifier that can
  /// be supplied to another listener.
  final ValueChanged<AppLifecycleState>? onStateChange;

  /// A callback that is called when [runApp] has been called and the embedding
  /// is initialized.
  final VoidCallback? onInitialize;

  /// A callback that is called when the app has scheduled the first frame.
  final VoidCallback? onStart;

  /// A callback that is called when the application loses input focus.
  ///
  /// On mobile platforms, this can be during a phone call or when a system
  /// dialog is visible.
  ///
  /// On desktop platforms, this is when all views in an application have lost
  /// input focus but at least one view of the application is still visible.
  ///
  /// On the web, this is when the window (or tab) has lost input focus.
  final VoidCallback? onInactive;

  /// A callback that is called when a view in the application gains input
  /// focus.
  ///
  /// A call to this callback indicates that the application is entering a state
  /// where it is visible, active, and accepting user input.
  final VoidCallback? onResume;

  /// A callback that is called when the application is hidden.
  ///
  /// On mobile platforms, this is usually just before the application is
  /// replaced by another application in the foreground.
  ///
  /// On desktop platforms, this is just before the application is hidden by
  /// being minimized or otherwise hiding all views of the application.
  ///
  /// On the web, this is just before a window (or tab) is hidden.
  final VoidCallback? onHide;

  /// A callback that is called when the application is shown.
  ///
  /// On mobile platforms, this is usually just before the application
  /// replaces another application in the foreground.
  ///
  /// On desktop platforms, this is just before the application is shown after
  /// being minimized or otherwise made to show at least one view of the
  /// application.
  ///
  /// On the web, this is just before a window (or tab) is shown.
  final VoidCallback? onShow;

  /// A callback that is called when the application is paused.
  ///
  /// On mobile platforms, this happens right before the application is replaced
  /// by another application.
  ///
  /// On desktop platforms and the web, this function is not called.
  final VoidCallback? onPause;

  /// A callback that is called when the application is resumed after being
  /// paused.
  ///
  /// On mobile platforms, this happens just before this application takes over
  /// as the active application.
  ///
  /// On desktop platforms and the web, this function is not called.
  final VoidCallback? onRestart;

  /// A callback used to ask the application if it will allow exiting the
  /// application for cases where the exit is cancelable.
  ///
  /// Exiting the application isn't always cancelable, but when it is, this
  /// function will be called before exit occurs.
  ///
  /// Responding [AppExitResponse.exit] will continue termination, and
  /// responding [AppExitResponse.cancel] will cancel it. If termination
  /// is not canceled, the application will immediately exit.
  final AppExitRequestCallback? onExitRequested;

  /// A callback that is called when an application has exited, and detached all
  /// host views from the engine.
  ///
  /// This callback is only called on iOS and Android.
  final VoidCallback? onDetach;

  bool _debugDisposed = false;

  /// Call when the listener is no longer in use.
  ///
  /// Do not use the object after calling [dispose].
  ///
  /// Subclasses must call this method in their overridden [dispose], if any.
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    binding.removeObserver(this);
    _debugDisposed = true;
  }

  bool _debugAssertNotDisposed() {
  assert(() {
    if (_debugDisposed) {
      throw FlutterError(
        'A $runtimeType was used after being disposed.\n'
        'Once you have called dispose() on a $runtimeType, it '
        'can no longer be used.',
      );
    }
    return true;
  }());
  return true;
}

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    assert(_debugAssertNotDisposed());
    if (onExitRequested == null) {
      return AppExitResponse.exit;
    }
    return onExitRequested!();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    assert(_debugAssertNotDisposed());
    if (state == _lifecycleState) {
      return;
    }
    final AppLifecycleState previousState = _lifecycleState;
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.initializing:
        onInitialize?.call();
        break;
      case AppLifecycleState.resumed:
        onResume?.call();
        break;
      case AppLifecycleState.inactive:
        if (previousState == AppLifecycleState.hidden) {
          onShow?.call();
        } else if (previousState == AppLifecycleState.resumed) {
          onInactive?.call();
        }
        break;
      case AppLifecycleState.hidden:
        if (previousState == AppLifecycleState.paused) {
          onRestart?.call();
        } else if (previousState == AppLifecycleState.inactive) {
          onHide?.call();
        }
        break;
      case AppLifecycleState.paused:
        if (previousState == AppLifecycleState.initializing) {
          onStart?.call();
        } else if (previousState == AppLifecycleState.hidden) {
          onPause?.call();
        }
        break;
      case AppLifecycleState.detached:
        onDetach?.call();
        break;
    }
    onStateChange?.call(_lifecycleState);
  }
}
