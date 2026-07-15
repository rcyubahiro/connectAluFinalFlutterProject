import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/notification_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());

final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(userProfileProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).watchForUser(uid);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsProvider)
      .value
      ?.where((n) => !n.read)
      .length ?? 0;
});
