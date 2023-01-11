import 'package:flutter/widgets.dart';

/// A callback type that is used by
/// [ApplicationLifecycleListener.onExitRequested] to ask the application if it
/// wants to cancel application termination or not.
typedef ExitRequestCallback = Future<ExitResponse> Function();

/// A listener that can be used to configure callbacks that will be
/// called at various points in the application lifecycle.
class ApplicationLifecycleListener extends ValueNotifier<AppLifecycleState> with WidgetsBindingObserver  {
  /// Creates an [ApplicationLifecycleListener].
  ApplicationLifecycleListener({
    required this.binding,
    this.onInitialize,
    this.onStart,
    this.onExit,
    this.onActive,
    this.onInactive,
    this.onHide,
    this.onShow,
    this.onPause,
    this.onResume,
    this.onExitRequested,
    this.onStateChange,
  }) : super(binding.lifecycleState ?? AppLifecycleState.exiting) {
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
  final void Function(AppLifecycleState state)? onStateChange;

  /// A callback that is called when [runApp] has been called and the embedding
  /// is initialized.
  final VoidCallback? onInitialize;

  /// A callback that is called when the app scheduled the first frame.
  final VoidCallback? onStart;

  /// A callback used to ask the application if it will allow exiting the
  /// application for cases where the exit is cancelable.
  ///
  /// Exiting the application isn't always cancelable, but when it is, this
  /// function will be called before exit occurs.
  ///
  /// Responding [ExitResponse.exit] will continue termination, and responding
  /// [ExitResponse.cancel] will cancel it. If termination is not canceled, it
  /// will be immediately followed by a call to [onExit].
  final ExitRequestCallback? onExitRequested;

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
  /// Also, not all exits are requests, but for times when they are, consider
  /// supplying [onExitRequested], which is called in the event of a *requested*
  /// exit that can be canceled, and where you have more time to save unsaved
  /// documents, ask the user questions, etc.
  final VoidCallback? onExit;

  /// A callback that is called when the application loses input focus.
  ///
  /// On mobile platforms, this can be during a phone call or when a system
  /// dialog is visible.
  ///
  /// On desktop platforms, this is when all views in an application have lost
  /// input focus.
  final VoidCallback? onInactive;

  /// A callback that is called when a view in the application gains
  /// input focus.
  final VoidCallback? onActive;

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
  /// On desktop platforms, this function is only called during shutdown.
  final VoidCallback? onPause;

  /// A callback that is called when the application is resumed after
  /// being paused.
  ///
  /// On mobile platforms, this happens just before this application takes over
  /// as the active application.
  ///
  /// On desktop platforms, this function is only called during startup.
  final VoidCallback? onResume;

  @override
  Future<ExitResponse> didRequestExit() async {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (onExitRequested == null) {
      return ExitResponse.exit;
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
      case AppLifecycleState.active:
      case AppLifecycleState.resumed:
        onActive?.call();
        break;
      case AppLifecycleState.inactive:
        if (previousState == AppLifecycleState.hidden) {
          onShow?.call();
        } else if (previousState == AppLifecycleState.active) {
          onInactive?.call();
        }
        break;
      case AppLifecycleState.hidden:
        if (previousState == AppLifecycleState.paused) {
          onResume?.call();
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
    _lifecycleListener = ApplicationLifecycleListener(
      binding: binding,
      onStateChange: didChangeAppLifecycleState,
      onExitRequested: didRequestExit,
    );
  }

  late ApplicationLifecycleListener _lifecycleListener;
  bool _hasUnsavedDocuments = false;
  bool _stateSaved = false;

  void _saveState() {
    if (_stateSaved) {
      return;
    }
    // TODO: Commit any unsaved application state.
    _stateSaved = true;
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveState();
    }
  }

  Future<ExitResponse> didRequestExit() async {
    if (_hasUnsavedDocuments) {
      if (await showSaveDialog() == SaveDocuments.cancel) {
        // The user canceled when asked to save documents, so cancel the exit.
        return ExitResponse.cancel;
      }
      _hasUnsavedDocuments = false;
    }
    return ExitResponse.exit;
  }

  @mustCallSuper
  void dispose() {
    _lifecycleListener.dispose();
  }
}
