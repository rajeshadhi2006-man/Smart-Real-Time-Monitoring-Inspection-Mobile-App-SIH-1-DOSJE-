import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/permission_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _service = PermissionService();
  Map<PermissionType, PermissionState> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final perms = await _service.checkAllPermissions();
    setState(() {
      _permissions = perms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'HARDWARE & SYSTEM PERMISSIONS',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPermissionCard(
                  type: PermissionType.location,
                  title: 'GPS Location Services',
                  description: 'Required for real-time 100m geofence auditing and location verification.',
                  icon: Icons.location_on_rounded,
                ),
                _buildPermissionCard(
                  type: PermissionType.camera,
                  title: 'Camera Access',
                  description: 'Required for WebRTC video calling and facial verification streams.',
                  icon: Icons.camera_alt_rounded,
                ),
                _buildPermissionCard(
                  type: PermissionType.microphone,
                  title: 'Microphone Access',
                  description: 'Required for voice verification speaker authentication.',
                  icon: Icons.mic_rounded,
                ),
                _buildPermissionCard(
                  type: PermissionType.notifications,
                  title: 'Push Notifications',
                  description: 'Required for real-time geofence alert broadcasts and call requests.',
                  icon: Icons.notifications_rounded,
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionCard({
    required PermissionType type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final state = _permissions[type] ?? PermissionState.denied;
    final isGranted = state == PermissionState.granted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tricolorSaffron, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isGranted
                ? null
                : () async {
                    final res = await _service.requestPermission(type);
                    setState(() {
                      _permissions[type] = res;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isGranted ? AppColors.statusGreen.withValues(alpha: 0.2) : AppColors.tricolorSaffron,
              elevation: 0,
            ),
            child: Text(
              isGranted ? 'GRANTED' : 'GRANT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isGranted ? AppColors.statusGreen : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
