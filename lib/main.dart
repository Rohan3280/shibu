import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_controller.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ShibuTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ShibuApp());
}

class ShibuApp extends StatefulWidget {
  const ShibuApp({super.key});

  @override
  State<ShibuApp> createState() => _ShibuAppState();
}

class _ShibuAppState extends State<ShibuApp> with WidgetsBindingObserver {
  late final SettingsController _controller = SettingsController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system wallpaper picker or the widget tray is the
    // one moment the app's view of the world is reliably stale.
    if (state == AppLifecycleState.resumed && !_controller.isLoading) {
      _controller.refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShibuScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Shibu',
        debugShowCheckedModeBanner: false,
        theme: ShibuTheme.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final controller = ShibuScope.of(context);

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (controller.error != null) {
      return _LoadFailure(error: controller.error!);
    }
    return controller.settings.onboarded
        ? const HomeShell()
        : const OnboardingScreen();
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 16),
            const Text(
              'Shibu could not load its kanji deck.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: ShibuScope.of(context).load,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Makes the single [SettingsController] available to the whole tree.
///
/// An [InheritedNotifier] is enough here — Shibu has one controller and no
/// cross-screen state beyond it, so a dependency-injection package would be
/// more machinery than the app needs.
class ShibuScope extends InheritedNotifier<SettingsController> {
  const ShibuScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShibuScope>();
    assert(scope != null, 'No ShibuScope found in context');
    return scope!.notifier!;
  }

  /// Reads the controller without subscribing to rebuilds.
  static SettingsController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ShibuScope>();
    assert(scope != null, 'No ShibuScope found in context');
    return scope!.notifier!;
  }
}
