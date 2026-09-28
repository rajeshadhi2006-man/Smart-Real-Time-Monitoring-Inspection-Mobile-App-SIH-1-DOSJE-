import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/call_session.dart';
import '../../../../providers/call_provider.dart';
import '../../../../providers/verification_provider.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const VideoCallScreen({super.key, required this.sessionId});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    final session = ref.read(verificationProvider);
    if (session != null) {
      ref.read(webRtcServiceProvider).initiateCall(
            personId: session.personId,
            personName: session.personName,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationSession = ref.watch(verificationProvider);
    final callStateAsync = ref.watch(callSessionProvider);
    final callState = callStateAsync.value?.state ?? CallState.CONNECTED;

    final personName = verificationSession?.personName ?? 'Monitored Subject';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IDENTITY VERIFICATION CALL',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Session ID: ${widget.sessionId}',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Call Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: _getCallStateColor(callState).withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCallStateColor(callState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCallStateLabel(callState, personName),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getCallStateColor(callState),
                    ),
                  ),
                ],
              ),
            ),

            // Video Views Container
            Expanded(
              child: Stack(
                children: [
                  // Remote Large Video Feed
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: _isVideoOff
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off, color: AppColors.textMuted, size: 50),
                                SizedBox(height: 8),
                                Text('Camera Off', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.primaryNavy,
                                child: Text(
                                  personName.substring(0, 1),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                personName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'WebRTC Video Stream Active',
                                style: TextStyle(fontSize: 12, color: AppColors.statusGreen),
                              ),
                            ],
                          ),
                  ),

                  // Small Officer Local Camera Preview Overlay
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.tricolorSaffron, width: 1.5),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: AppColors.tricolorSaffron, size: 30),
                          SizedBox(height: 4),
                          Text('Officer (You)', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Call Action Buttons Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _buildCallControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        label: _isVideoOff ? 'Cam On' : 'Cam Off',
                        isActive: _isVideoOff,
                        onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                      ),
                      _buildCallControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        label: 'Speaker',
                        isActive: _isSpeakerOn,
                        onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                      ),
                      _buildCallControlButton(
                        icon: Icons.call_end,
                        label: 'End Call',
                        color: AppColors.statusRed,
                        onTap: () {
                          ref.read(webRtcServiceProvider).endCall();
                          context.pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // START BIOMETRIC VERIFICATION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/verification/session/${widget.sessionId}');
                      },
                      icon: const Icon(Icons.fingerprint, color: Colors.black),
                      label: const Text(
                        'START BIOMETRIC & GPS VERIFICATION',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tricolorSaffron,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    Color color = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(

            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.tricolorSaffron : AppColors.cardDark,
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Icon(icon, color: isActive ? Colors.black : color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Color _getCallStateColor(CallState state) {
    switch (state) {
      case CallState.CONNECTED:
        return AppColors.statusGreen;
      case CallState.CALLING:
      case CallState.RINGING:
      case CallState.CONNECTING:
        return AppColors.statusAmber;
      default:
        return AppColors.statusRed;
    }
  }

  String _getCallStateLabel(CallState state, String personName) {
    switch (state) {
      case CallState.CALLING:
        return 'Calling $personName...';
      case CallState.RINGING:
        return 'Ringing... Waiting for response';
      case CallState.CONNECTING:
        return 'Establishing WebRTC Peer Connection...';
      case CallState.CONNECTED:
        return '🟢 WebRTC Call Active';
      case CallState.REJECTED:
        return 'Call Rejected by User';
      case CallState.MISSED:
        return 'Call Missed';
      case CallState.ENDED:
        return 'Call Ended';
      case CallState.FAILED:
        return 'Call Connection Failed';
      default:
        return 'Connecting...';
    }
  }
}
