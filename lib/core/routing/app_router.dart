import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/location/presentation/screens/live_monitoring_screen.dart';
import '../../features/attendance/presentation/screens/verify_tab_screen.dart';
import '../../features/attendance/presentation/screens/video_call_screen.dart';
import '../../features/attendance/presentation/screens/verification_session_screen.dart';
import '../../features/attendance/presentation/screens/final_verification_result_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/attendance/presentation/screens/reports_screen.dart';
import '../../features/notifications/presentation/screens/alerts_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/person_detail_screen.dart';
import '../../features/profile/presentation/screens/permissions_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/diagnostic_screen.dart';
import '../../features/projects/presentation/screens/geofences_screen.dart';
import '../../features/projects/presentation/screens/geofence_map_screen.dart';
import '../../features/cctv/presentation/screens/cctv_live_screen.dart';
import '../../features/inspections/presentation/screens/inspections_list_screen.dart';
import '../../features/inspections/presentation/screens/inspection_detail_screen.dart';
import '../../features/inspections/presentation/screens/inspection_checklist_screen.dart';
import '../../features/inspections/presentation/screens/start_inspection_screen.dart';
import '../../features/shell/presentation/screens/main_shell_screen.dart';
import 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // 5 Stateful Bottom Shell Navigation Branches
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.live,
                builder: (context, state) => const LiveMonitoringScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.verifyTab,
                builder: (context, state) => const VerifyTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alerts,
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Sub-routes & Workflow Screens
      GoRoute(
        path: AppRoutes.personDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PersonDetailScreen(personId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.videoCall,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return VideoCallScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.verificationSession,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return VerificationSessionScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.finalVerificationResult,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return FinalVerificationResultScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.geofences,
        builder: (context, state) => const GeofencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.geofenceMap,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GeofenceMapScreen(geofenceId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.attendanceLog,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostics,
        builder: (context, state) => const DiagnosticScreen(),
      ),
      GoRoute(
        path: AppRoutes.cctv,
        builder: (context, state) => const CctvLiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.inspectionList,
        builder: (context, state) => const InspectionsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.inspectionDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InspectionDetailScreen(inspectionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.inspectionChecklist,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InspectionChecklistScreen(inspectionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.startInspection,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return StartInspectionScreen(inspectionId: id);
        },
      ),
    ],
  );
});


