import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:ui';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'presentation/providers/app_providers.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          color: Colors.white,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'Something went wrong. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Unhandled async error: $error');
        debugPrintStack(stackTrace: stack);
        return true;
      };

      // Initialize any async dependencies here (SharedPreferences, etc.)
      runApp(const ProviderScope(child: QuickBiteApp()));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class QuickBiteApp extends ConsumerWidget {
  const QuickBiteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'QuickBite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (!isDark) {
          return child ?? const SizedBox.shrink();
        }

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppTheme.darkBackgroundGradient,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: AppRoutes.router,
    );
  }
}
