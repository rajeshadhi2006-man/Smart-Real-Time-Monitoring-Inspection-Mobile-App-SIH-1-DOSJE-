import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../domain/models/notification_item.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    final todayItems = notifications.where((n) => n.timeAgo.contains('min') || n.timeAgo.contains('hour') || n.timeAgo.contains('Now')).toList();
    final earlierItems = notifications.where((n) => !todayItems.contains(n)).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Center',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Inspection Assignments & AI Alerts',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => notifier.markAllAsRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: notifications.isEmpty
            ? const Center(child: Text('No active notifications.'))
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  if (todayItems.isNotEmpty) ...[
                    _buildSectionHeader('TODAY'),
                    ...todayItems.map((item) => _buildNotificationTile(context, item, notifier)),
                  ],
                  if (earlierItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSectionHeader('EARLIER'),
                    ...earlierItems.map((item) => _buildNotificationTile(context, item, notifier)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationItem item,
    NotificationsNotifier notifier,
  ) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case NotificationType.assignment:
        icon = Icons.assignment_turned_in_outlined;
        iconColor = AppColors.infoBlue;
        break;
      case NotificationType.aiAlert:
        icon = Icons.auto_awesome_outlined;
        iconColor = AppColors.dangerRed;
        break;
      case NotificationType.reminder:
        icon = Icons.schedule_outlined;
        iconColor = AppColors.warningAmber;
        break;
      case NotificationType.system:
        icon = Icons.cloud_done_outlined;
        iconColor = AppColors.successGreen;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: item.isRead
              ? AppColors.borderLight
              : AppColors.primaryNavy.withValues(alpha: 0.2),
          width: item.isRead ? 1.0 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () {
            notifier.markAsRead(item.id);
            if (item.relatedInspectionId != null) {
              context.push('/inspection/${item.relatedInspectionId}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    item.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            item.timeAgo,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
