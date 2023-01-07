import 'package:flutter/widgets.dart';

/// A callback type that is used by [LifecycleListener.onShouldApplicationTerminate]
/// to ask the application if it wants to cancel application termination or not.
typedef ApplicationShouldTerminateCallback = Future<ApplicationTerminationResponse> Function();

/// An application class that can be used to configure callbacks that will be
/// called at various points in the application lifecycle.
///
/// This class is meant to replace calling of [runApp] directly. Instead, you
/// can create one of these and call [run], which will call [runApp] for you.
class LifecycleListener with WidgetsBindingObserver {
  /// Creates an [LifecycleListener].
  LifecycleListener({
    this.onInitiated,
    this.onTerminating,
    this.onActive,
    this.onInactive,
    this.onShouldApplicationTerminate,
    this.onHidden,
    this.onShown,
    this.onPaused,
    this.onResumed,
  }) {
    WidgetsFlutterBinding.ensureInitialized().addObserver(this);
  }

  /// Disposes of the application object.
  ///
  /// The object should not be used after calling [dispose]. It is called
  /// automatically if the application receives an
  /// [AppLifecycleState.terminating] event.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// A callback that is called when [runApp] is called and the first
  /// frame is requested.
  final VoidCallback? onInitiated;

  /// A callback used to ask the application if it will allow terminating of the
  /// application in the case where termination is cancelable.
  ///
  /// Terminating the application isn't always cancelable, but when it is, this
  /// function will be called before termination occurs.
  ///
  /// Responding [ApplicationTerminationResponse.terminate] will continue
  /// termination, and responding [ApplicationTerminationResponse.cancel] will
  /// cancel it. If termination is not canceled, it will be immediately followed
  /// by a call to [onTerminating].
  final ApplicationShouldTerminateCallback? onShouldApplicationTerminate;

  /// A callback that is called when an application is about the be terminated
  /// in an orderly fashion.
  ///
  /// Not all terminations are orderly (e.g. being killed by a task manager),
  /// but when they are, this function will be called.
  ///
  /// The application has an undefined short amount of time (think milliseconds)
  /// to save any unsaved state or close any resources before the application
  /// terminates. The application will eventually terminate in the middle of
  /// these operations if they take too long, so the anything executed here
  /// should be as fast and robust to interruption as possible.
  final VoidCallback? onTerminating;

  /// A callback that is called just before the application loses input focus.
  ///
  /// On mobile platforms, this can be during a phone call or when a system
  /// dialog is visible.
  ///
  /// On desktop platforms, this is when all views in an application have lost
  /// input focus.
  final VoidCallback? onInactive;

  /// A callback that is called just before the application gains input focus.
  final VoidCallback? onActive;

  /// A callback that is called just before the application is hidden.
  ///
  /// On mobile platforms, this is usually just before the application is
  /// replaced by another application in the foreground.
  ///
  /// On desktop platforms, this is just before focus is lost by the focused
  /// view to another view that is not part of the application.
  final VoidCallback? onHidden;

  /// A callback that is called just before the application is shown, either
  /// after being hidden, or at startup.
  final VoidCallback? onShown;

  /// A callback that is called just before the application is paused.
  ///
  /// On mobile platforms, this happens right before the application is replaced by another application.
  ///
  /// On desktop applications, this state isn't ever entered.
  final VoidCallback? onPaused;

  /// A callback that is called just before the application is resumed after
  /// being paused.
  ///
  /// On mobile platforms, this happens just before this application takes over
  /// as the active application.
  ///
  /// This doesn't happen on desktop platforms.
  final VoidCallback? onResumed;

  @override
  Future<ApplicationTerminationResponse> didRequestApplicationTermination() async {
    if (onShouldApplicationTerminate == null) {
          return ApplicationTerminationResponse.terminate;
    }
    return onShouldApplicationTerminate!();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.initiated:
        onInitiated?.call();
        break;
      case AppLifecycleState.paused:
        onHidden?.call();
        break;
      case AppLifecycleState.inactive:
        onInactive?.call();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        onActive?.call();
        break;
      case AppLifecycleState.terminating:
        onTerminating?.call();
        dispose();
        break;
    }
  }
}
