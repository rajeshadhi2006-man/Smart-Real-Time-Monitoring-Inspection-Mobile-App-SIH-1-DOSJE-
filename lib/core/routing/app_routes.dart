/// Application route name constants
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Shell Tabs
  static const String dashboard = '/';
  static const String live = '/live';
  static const String verifyTab = '/verify-tab';
  static const String alerts = '/alerts';
  static const String profile = '/profile';

  // Legacy route aliases for backward compatibility
  static const String notifications = '/alerts';
  static const String inspections = '/live';
  static const String map = '/geofences';

  // Feature Routes
  static const String personDetail = '/person/:id';
  static const String videoCall = '/verification/call/:sessionId';
  static const String verificationSession = '/verification/session/:sessionId';
  static const String finalVerificationResult = '/verification/result/:sessionId';
  static const String geofences = '/geofences';
  static const String geofenceMap = '/geofence/map/:id';
  static const String attendanceLog = '/attendance-log';
  static const String reports = '/reports';
  static const String permissions = '/permissions';
  static const String settings = '/settings';
  static const String diagnostics = '/diagnostics';
  static const String cctv = '/cctv';
  static const String inspectionList = '/inspections-list';
  static const String inspectionDetail = '/inspection/:id';
  static const String inspectionChecklist = '/inspection/:id/checklist';
  static const String startInspection = '/inspection/:id/start';
}
