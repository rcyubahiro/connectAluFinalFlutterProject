import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/chat_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final myChatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).watchMyThreads(profile.uid);
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});
