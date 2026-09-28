import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/monitored_persons_provider.dart';
import '../../../../providers/realtime_connection_provider.dart';
import '../../../../services/realtime_service.dart';

class LiveMonitoringScreen extends ConsumerStatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  ConsumerState<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends ConsumerState<LiveMonitoringScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final personsState = ref.watch(monitoredPersonsProvider);
    final connectionStatus = ref.watch(realtimeConnectionProvider).value ?? RealtimeConnectionStatus.connected;
    final persons = personsState.asData?.value ?? [];

    final filteredPersons = persons.where((p) {
      if (_selectedFilter == 'ALL') return true;
      return p.status == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE MONITORING',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connectionStatus == RealtimeConnectionStatus.connected
                        ? AppColors.statusGreen
                        : AppColors.statusRed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  connectionStatus == RealtimeConnectionStatus.connected
                      ? 'REAL-TIME CONNECTED'
                      : 'RECONNECTING...',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: connectionStatus == RealtimeConnectionStatus.connected
                        ? AppColors.statusGreen
                        : AppColors.statusRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['ALL', 'INSIDE', 'OUTSIDE', 'VERIFYING', 'VERIFIED', 'UNAUTHORIZED', 'OFFLINE'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: AppColors.surfaceDark,
                    labelStyle: TextStyle(
                      fontSize: 11,
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

          // Main Persons List
          Expanded(
            child: personsState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron)),
              error: (err, _) => Center(child: Text('Error loading data: $err', style: const TextStyle(color: AppColors.statusRed))),
              data: (_) {
                if (filteredPersons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.radar_rounded, color: AppColors.textMuted, size: 50),
                        const SizedBox(height: 12),
                        const Text(
                          'No Monitored Persons Found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No persons match filter "$_selectedFilter"',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPersons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final person = filteredPersons[index];
                    final statusColor = AppColors.statusColor(person.status);

                    return InkWell(
                      onTap: () => context.push('/person/${person.id}'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.borderDark,
                                  child: Text(
                                    person.name.substring(0, 1),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: ${person.id} • ${person.assignedSite}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    person.status,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.borderDark, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Geofence: ${person.geofenceName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  'GPS Accuracy: ±${person.gpsAccuracy.toInt()}m',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
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
