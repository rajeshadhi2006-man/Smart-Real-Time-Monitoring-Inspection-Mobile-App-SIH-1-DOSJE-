import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell_screen.dart';
import 'services/offline/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("=== FLUTTER ERROR CAUGHT ===");
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack?.toString());
  };

  // Initialize persistent API gateway configuration
  await AppConfig.init();

  // Initialize Sovereign Offline Synchronization Engine
  await OfflineSyncService().initialize();

  runApp(
    const ProviderScope(
      child: SihUserApp(),
    ),
  );
}

class SihUserApp extends ConsumerWidget {
  const SihUserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'DoSJE Field Inspection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainShellScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF071324),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    color: AppColors.tricolorSaffron,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Initializing MoSJE Nirikshan...",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => const LoginScreen(),
      ),
    );
  }
}
