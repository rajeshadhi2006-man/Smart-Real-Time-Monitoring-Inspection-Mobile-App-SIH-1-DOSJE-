import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/alert_model.dart';
import '../../../../providers/alerts_provider.dart';
import '../../domain/models/notification_item.dart';

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier()
      : super([
          const NotificationItem(
            id: 'notif_telemetry',
            title: 'Live Telemetry Active',
            message:
                'Cryptographic field audit node connected to MoSJE Realtime database.',
            timeAgo: 'Just now',
            type: NotificationType.system,
          ),
          const NotificationItem(
            id: 'notif_enrollment_ready',
            title: 'Live Enrollment Synchronizer Ready',
            message:
                'Field audit sites enrolled from the Web Portal appear dynamically in your dashboard.',
            timeAgo: 'Just now',
            type: NotificationType.system,
          ),
        ]);

  void addNotification(NotificationItem notif) {
    if (!state.any((n) => n.id == notif.id)) {
      state = [notif, ...state];
    }
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final item in state) item.copyWith(isRead: true),
    ];
  }

  int get unreadCount => state.where((item) => !item.isRead).length;
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  final notifier = NotificationsNotifier();

  ref.listen<AsyncValue<List<AlertModel>>>(alertsProvider, (previous, next) {
    next.whenData((alerts) {
      for (final alert in alerts) {
        final notif = NotificationItem(
          id: alert.id,
          title: alert.category,
          message: '${alert.personName}: ${alert.description} (${alert.location})',
          timeAgo: 'Recent',
          type: NotificationType.aiAlert,
          isRead: alert.status == 'RESOLVED' || alert.status == 'ACKNOWLEDGED',
        );
        notifier.addNotification(notif);
      }
    });
  });

  return notifier;
});

