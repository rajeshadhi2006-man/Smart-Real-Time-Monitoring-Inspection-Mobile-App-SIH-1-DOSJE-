import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Sovereign Quick Action Dock
/// Provides rapid field deployment buttons with glowing icon halos
class GovtQuickActionDock extends StatelessWidget {
  final VoidCallback onBiometrics;
  final VoidCallback onEvidence;
  final VoidCallback onAlerts;
  final VoidCallback onInspections;

  const GovtQuickActionDock({
    super.key,
    required this.onBiometrics,
    required this.onEvidence,
    required this.onAlerts,
    required this.onInspections,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildActionItem(
          title: "Biometrics",
          subtitle: "Face Match",
          icon: Icons.face_retouching_natural_rounded,
          color: const Color(0xFF0284C7),
          badgeText: "ARCFACE",
          onTap: onBiometrics,
        ),
        const SizedBox(width: 10),
        _buildActionItem(
          title: "Evidence",
          subtitle: "SHA Vault",
          icon: Icons.camera_alt_rounded,
          color: AppColors.statusGreen,
          badgeText: "GEO-HASH",
          onTap: onEvidence,
        ),
        const SizedBox(width: 10),
        _buildActionItem(
          title: "Surprise",
          subtitle: "Checklist",
          icon: Icons.checklist_rounded,
          color: AppColors.tricolorSaffron,
          badgeText: "AUDIT",
          onTap: onInspections,
        ),
        const SizedBox(width: 10),
        _buildActionItem(
          title: "Incidents",
          subtitle: "Emergency",
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFFEF4444),
          badgeText: "LIVE SOS",
          onTap: onAlerts,
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Glowing Circle Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
