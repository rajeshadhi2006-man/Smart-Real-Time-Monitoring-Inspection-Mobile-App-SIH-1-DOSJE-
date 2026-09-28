import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/monitored_person.dart';
import '../../../../providers/monitored_persons_provider.dart';
import '../../../../providers/verification_provider.dart';

class VerifyTabScreen extends ConsumerWidget {
  const VerifyTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsState = ref.watch(monitoredPersonsProvider);
    final persons = personsState.asData?.value ?? [];

    final pendingPersons = persons.where((p) => p.status == 'VERIFYING' || p.status == 'PENDING' || p.todayAttendanceStatus == 'PENDING').toList();
    final recentPersons = persons.where((p) => p.status == 'VERIFIED' || p.todayAttendanceStatus == 'PRESENT').toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'IDENTITY VERIFICATION HUB',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start New Verification Hero Card
            InkWell(
              onTap: () => _showPersonSelectionModal(context, ref, persons),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.govtHeaderGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.tricolorSaffron, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tricolorSaffron.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.video_call_rounded, color: AppColors.tricolorSaffron, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start New Verification',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Call person & execute WebRTC biometric check',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Pending Verification Section
            const Text(
              'PENDING VERIFICATIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            if (pendingPersons.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.statusGreen, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No Pending Verifications',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'All assigned persons are verified for today.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingPersons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),

                itemBuilder: (context, index) {
                  final person = pendingPersons[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.borderDark,
                          child: Text(
                            person.name.substring(0, 1),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Location: ${person.assignedSite}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _startVerificationFlow(context, ref, person),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tricolorSaffron,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('VERIFY NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // Recent Verifications Section
            const Text(
              'RECENT VERIFICATION HISTORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            if (recentPersons.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    'No Recent Verifications Executed Today',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentPersons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),

                itemBuilder: (context, index) {
                  final person = recentPersons[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.statusGreen, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const Text(
                                'Face ✓ MATCH • Voice ✓ MATCH • GPS ✓ INSIDE',
                                style: TextStyle(fontSize: 11, color: AppColors.statusGreen),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'VERIFIED',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusGreen),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPersonSelectionModal(BuildContext context, WidgetRef ref, List<MonitoredPerson> persons) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Monitored Person for Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              if (persons.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No persons available to verify.', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: persons.length,
                    itemBuilder: (context, index) {
                      final person = persons[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryNavy,
                          child: Text(person.name.substring(0, 1), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(person.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: Text(person.assignedSite, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.tricolorSaffron),
                        onTap: () {
                          Navigator.pop(context);
                          _startVerificationFlow(context, ref, person);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _startVerificationFlow(BuildContext context, WidgetRef ref, MonitoredPerson person) async {
    final session = await ref.read(verificationProvider.notifier).startSession(
      personId: person.id,
      personName: person.name,
      officerId: 'GOV-OFFICER-001',
    );
    if (context.mounted) {
      context.push('/verification/call/${session.id}');
    }
  }
}
