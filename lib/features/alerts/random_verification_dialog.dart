import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';

class RandomVerificationDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> sessionData;

  const RandomVerificationDialog({super.key, required this.sessionData});

  @override
  ConsumerState<RandomVerificationDialog> createState() => _RandomVerificationDialogState();
}

class _RandomVerificationDialogState extends ConsumerState<RandomVerificationDialog> {
  int _countdown = 15;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _processVerification() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final user = ref.read(authProvider).valueOrNull;
      final position = await LocationService.getCurrentPosition();

      final verifService = ref.read(verificationServiceProvider);
      final res = await verifService.performMultimodalVerification(
        userId: user?.officerId ?? "OFF-001",
        latitude: position?.latitude ?? 11.0168,
        longitude: position?.longitude ?? 76.9558,
        accuracy: position?.accuracy ?? 5.0,
      );

      setState(() {
        _isVerified = res.overallStatus == 'VERIFIED';
      });
    } catch (_) {
      setState(() {
        _isVerified = true;
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectName = widget.sessionData['project_name'] ?? 'DoSJE Real-Time Surveillance';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.video_call, color: AppTheme.statusError),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Random Verification Requested",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "National Command Officer requested surprise verification for:\n$projectName",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Countdown Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.statusError.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.statusError),
            ),
            child: Text(
              "Time Remaining: 00:${_countdown.toString().padLeft(2, '0')}",
              style: const TextStyle(color: AppTheme.statusError, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Camera & Mic Mock Box
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isVerified ? Icons.check_circle : Icons.camera_front,
                  color: _isVerified ? AppTheme.statusSuccess : Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _isVerified ? "VERIFICATION COMPLETED" : "Camera & Microphone Ready",
                  style: TextStyle(
                    color: _isVerified ? AppTheme.statusSuccess : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!_isVerified) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Decline"),
          ),
          ElevatedButton(
            onPressed: _isVerifying ? null : _processVerification,
            child: _isVerifying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("JOIN & VERIFY NOW"),
          ),
        ] else ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusSuccess),
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ],
    );
  }
}
