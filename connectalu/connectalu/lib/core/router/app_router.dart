import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../models/user_model.dart';
import '../../features/applications/presentation/applicant_list_screen.dart';
import '../../features/applications/presentation/my_applications_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/dashboard/presentation/founder_dashboard_screen.dart';
import '../../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../../features/opportunities/presentation/opportunity_feed_screen.dart';
import '../../features/opportunities/presentation/search_screen.dart';
import '../../features/startup/presentation/startup_profile_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/auth/presentation/account_screen.dart';
import '../../features/opportunities/presentation/bookmarks_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/auth/presentation/account_edit_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';

/// Central place for auth-gating logic. Every route decision funnels
/// through `redirect`, so there's exactly one source of truth for
/// "can this user see this screen right now" instead of scattering
/// auth checks across individual screens.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profileAsync = ref.read(userProfileProvider);

      final loggedIn = authState.value != null;
      final loc = state.matchedLocation;

      // Always allow these routes without any checks
      if (loc == '/admin/login') return null;

      // Not logged in — only /login is allowed
      if (!loggedIn) {
        return loc == '/login' ? null : '/login';
      }

      // Logged in but profile still loading — don't redirect yet
      if (profileAsync.isLoading) return null;

      final profile = profileAsync.value;

      // ── Admin user ──
      if (profile?.role == UserRole.admin) {
        // Only /admin is allowed for admin users
        if (loc == '/admin') return null;
        return '/admin';
      }

      // If profile is null, don't redirect — could be transient while
      // the profile stream starts after an auth state change.
      if (profile == null) return null;

      // ── Regular user ──
      // Block access to admin routes
      if (loc == '/admin') return '/';

      // Needs onboarding
      if (profile.role == null && loc != '/onboarding') {
        return '/onboarding';
      }

      // Already logged in, on login page → go home
      if (loc == '/login') return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const OpportunityFeedScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
          GoRoute(
            path: '/applications',
            builder: (_, __) => const MyApplicationsScreen(),
          ),
          GoRoute(
            path: '/founder',
            builder: (_, __) => const FounderDashboardScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (_, __) => const _ChatListPlaceholder(),
          ),
        ],
      ),
      GoRoute(
        path: '/opportunities/:id',
        builder: (_, state) =>
            OpportunityDetailScreen(opportunityId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/startups/:id',
        builder: (_, state) =>
            StartupProfileScreen(startupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/founder/opportunities/:id/applicants',
        builder: (_, state) => ApplicantListScreen(
          opportunityId: state.pathParameters['id']!,
          opportunityTitle: state.extra as String? ?? 'Opportunity',
        ),
      ),
      GoRoute(
        path: '/account/edit',
        builder: (_, __) => const AccountEditScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (_, __) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatScreen(
          chatId: state.pathParameters['id']!,
          otherUserName: state.extra as String? ?? 'Chat',
        ),
      ),
    ],
  );
});

/// Bridges Riverpod's stream-based auth/profile state into something
/// go_router's `refreshListenable` (a plain Listenable) can consume, so
/// the router re-evaluates `redirect` whenever auth or profile changes —
/// not just on navigation events.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

class _ChatListPlaceholder extends ConsumerWidget {
  const _ChatListPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(myChatThreadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threadsAsync.when(
        data: (threads) => threads.isEmpty
            ? const Center(child: Text('No conversations yet.'))
            : ListView.builder(
                itemCount: threads.length,
                itemBuilder: (_, i) {
                  final t = threads[i];
                  final myUid = ref.read(userProfileProvider).value?.uid;
                  final otherName = t.participantNames.entries
                      .firstWhere((e) => e.key != myUid,
                          orElse: () => const MapEntry('', 'Unknown'))
                      .value;
                  return ListTile(
                    title: Text(otherName),
                    subtitle: Text(t.lastMessage ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => GoRouter.of(context)
                        .push('/chat/${t.id}', extra: otherName),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
