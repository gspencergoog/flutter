import 'package:flutter/widgets.dart';

/// A callback type that is used by [AppLifecycleListener.onExitRequested] to
/// ask the application if it wants to cancel application termination or not.
typedef AppExitRequestCallback = Future<AppExitResponse> Function();

/// A listener that can be used to configure callbacks that will be called at
/// various points in the application lifecycle.
class AppLifecycleListener extends ValueNotifier<AppLifecycleState> with WidgetsBindingObserver  {
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
    this.onExit,
    this.onDetach,
    this.onExitRequested,
    this.onStateChange,
  }) : super(binding.lifecycleState ?? AppLifecycleState.detached) {
    binding.addObserver(this);
  }

  /// The [WidgetsBinding] to listen to for application lifecycle events.
  ///
  /// Typically, this is set to [WidgetsBinding.instance], but may be
  /// substituted for testing or other specialized bindings.
  final WidgetsBinding binding;

  /// Contains the current lifecycle state that the application is in.
  late AppLifecycleState lifecycleState;

  /// Disposes of the application object.
  ///
  /// This should be called when this object is no longer needed.
  ///
  /// The object should not be used after calling [dispose].
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called anytime the state changes, passing the new state.
  ///
  /// The [AppLifecycleListener] class is also a [ChangeNotifier], which
  /// performs a similar function as this callback, but as a notifier that can
  /// be supplied to another listener.
  final ValueChanged<AppLifecycleState>? onStateChange;

  /// A callback that is called when [runApp] has been called and the embedding
  /// is initialized.
  final VoidCallback? onInitialize;

  /// A callback that is called when the app scheduled the first frame.
  final VoidCallback? onStart;

  /// A callback that is called when the application loses input focus.
  ///
  /// On mobile platforms, this can be during a phone call or when a system
  /// dialog is visible.
  ///
  /// On desktop platforms, this is when all views in an application have lost
  /// input focus.
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
  /// On desktop platforms, this is just before focus is lost by the focused
  /// view to another view that is not part of the application.
  final VoidCallback? onHide;

  /// A callback that is called when the application is shown.
  final VoidCallback? onShow;

  /// A callback that is called when the application is paused.
  ///
  /// On mobile platforms, this happens right before the application is replaced
  /// by another application.
  ///
  /// On desktop platforms, this function is not called.
  final VoidCallback? onPause;

  /// A callback that is called when the application is resumed after being
  /// paused.
  ///
  /// On mobile platforms, this happens just before this application takes over
  /// as the active application.
  ///
  /// On desktop platforms, this function is not called.
  final VoidCallback? onRestart;

  /// A callback used to ask the application if it will allow exiting the
  /// application for cases where the exit is cancelable.
  ///
  /// Exiting the application isn't always cancelable, but when it is, this
  /// function will be called before exit occurs.
  ///
  /// Responding [AppExitResponse.exit] will continue termination, and
  /// responding [AppExitResponse.cancel] will cancel it. If termination
  /// is not canceled, it will be immediately followed by a call to [onExit].
  final AppExitRequestCallback? onExitRequested;

  /// A callback that is called when an application is about the be terminated
  /// in an orderly fashion.
  ///
  /// Not all terminations are orderly (e.g. being killed by a task manager or
  /// sent a SIGKILL, power being unplugged, rapid unplanned disassembly,
  /// supernovae, etc.), but when they are, this function will be called.
  ///
  /// The application has an undefined short amount of time (think milliseconds)
  /// to save any unsaved state or close any resources before the application
  /// terminates. The application will eventually terminate in the middle of
  /// these operations if they take too long, so anything executed here should
  /// be as fast and robust to interruption as possible.
  ///
  /// Also, not all exits are requests, but when they are, consider supplying
  /// [onExitRequested], which is called in the event of a *requested* exit that
  /// can be canceled, and where you have more time to save unsaved documents,
  /// ask the user questions, etc.
  final VoidCallback? onExit;

  /// A callback that is called when an application has exited, and detached all
  /// host views from the engine.
  ///
  /// This callback is only called on iOS and Android.
  final VoidCallback? onDetach;

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (onExitRequested == null) {
      return AppExitResponse.exit;
    }
    return onExitRequested!();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (state == lifecycleState) {
      return;
    }
    final AppLifecycleState previousState = lifecycleState;
    lifecycleState = state;
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
      case AppLifecycleState.exiting:
        onExit?.call();
        break;
      case AppLifecycleState.detached:
        onDetach?.call();
        break;
    }
    notifyListeners();
    onStateChange?.call(lifecycleState);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final DataModel model = DataModel(WidgetsBinding.instance);
  runApp(const MyApp(model));
  model.dispose();
}

class DataModel {
  DataModel(WidgetsBinding binding)  {
    _lifecycleListener = AppLifecycleListener(
      binding: binding,
      onExit: willExit,
      onExitRequested: didRequestExit,
    );
  }

  late AppLifecycleListener _lifecycleListener;
  bool _hasUnsavedDocuments = false;
  bool _stateSaved = false;

  void _saveState() {
    if (_stateSaved) {
      return;
    }
    // TODO: Commit any unsaved application state.
    _stateSaved = true;
  }

  void willExit() => _saveState();

  Future<AppExitResponse> didRequestExit() async {
    if (_hasUnsavedDocuments) {
      if (await showSaveDialog() == SaveDocuments.cancel) {
        // The user canceled when asked to save documents, so cancel the exit.
        return AppExitResponse.cancel;
      }
      _hasUnsavedDocuments = false;
    }
    return AppExitResponse.exit;
  }

  @mustCallSuper
  void dispose() {
    _lifecycleListener.dispose();
  }
}
