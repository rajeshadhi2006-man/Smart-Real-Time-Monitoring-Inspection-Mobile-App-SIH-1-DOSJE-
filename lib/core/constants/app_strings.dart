/// Application UI strings, government identity tags, and system labels
class AppStrings {
  const AppStrings._();

  static const String governmentOfIndia = 'GOVERNMENT OF INDIA';
  static const String ministryTitle = 'Ministry of Social Justice and Empowerment';
  static const String pmuPortalName = 'Nirikshan PMU Field Suite';
  
  // Dashboard Strings
  static const String dashboardAssigned = 'Assigned';
  static const String dashboardPending = 'Pending';
  static const String dashboardCompleted = 'Completed';
  static const String dashboardAlerts = 'AI Alerts';
  static const String todaysInspection = "Today's Inspection";
  static const String quickActions = 'Field Actions';

  // Inspection Steps
  static const String stepLocation = '1. Location Verification';
  static const String stepChecklist = '2. Digital Checklist';
  static const String stepEvidence = '3. Tamper-Evident Evidence';
  static const String stepAttendance = '4. Beneficiary Verification';
  static const String stepAiAnalytics = '5. AI Risk Anomaly';
  static const String stepSummary = '6. Final Review & Submission';

  // Offline banner
  static const String offlineMode = 'Offline Mode Active';
  static const String offlineSubtitle =
      'Data will be encrypted locally and queued for automatic sync.';
  static const String syncPending = 'Sync Pending';
  static const String allSynced = 'All Data Synchronized';
}
