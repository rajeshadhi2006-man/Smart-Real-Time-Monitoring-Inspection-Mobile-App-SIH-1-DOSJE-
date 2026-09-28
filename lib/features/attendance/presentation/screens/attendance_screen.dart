import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selectedDateFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);
    final records = attendanceState.asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'AUTOMATIC ATTENDANCE LOG',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['Today', 'Yesterday', 'Custom Date'].map((filter) {
                final isSelected = _selectedDateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDateFilter = filter;
                      });
                    },
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: AppColors.surfaceDark,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.tricolorSaffron : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.tricolorSaffron : AppColors.borderDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Main Attendance List
          Expanded(
            child: attendanceState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.statusRed))),
              data: (_) {
                if (records.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fact_check_outlined, color: AppColors.textMuted, size: 48),
                        SizedBox(height: 12),
                        Text('No Attendance Records Found', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Automatic attendance records generated upon successful verification.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final rec = records[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.borderDark,
                                child: Text(rec.personName.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(rec.personName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.statusGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.statusGreen),
                                ),
                                child: Text(rec.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusGreen)),
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.borderDark, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Entry Time: ${rec.entryTime.hour.toString().padLeft(2, '0')}:${rec.entryTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text('Verification: ${rec.verificationStatus}', style: const TextStyle(fontSize: 12, color: AppColors.statusGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Facility Site: ${rec.site}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
