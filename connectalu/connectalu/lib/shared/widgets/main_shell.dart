import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../models/user_model.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final isFounder = profile?.role == UserRole.founder;
    final location = GoRouterState.of(context).matchedLocation;

    final destinations = isFounder
        ? const [
            _NavDest('/', Icons.home_outlined, Icons.home_rounded, 'Home'),
            _NavDest('/search', Icons.search_outlined, Icons.search, 'Explore'),
            _NavDest('/founder', Icons.storefront_outlined, Icons.storefront, 'Startups'),
            _NavDest('/account', Icons.person_outline, Icons.person, 'Profile'),
          ]
        : const [
            _NavDest('/', Icons.home_outlined, Icons.home_rounded, 'Home'),
            _NavDest('/search', Icons.search_outlined, Icons.search, 'Explore'),
            _NavDest('/applications', Icons.assignment_outlined, Icons.assignment, 'Applications'),
            _NavDest('/account', Icons.person_outline, Icons.person, 'Profile'),
          ];

    final currentIndex =
        destinations.indexWhere((d) => d.path == location).clamp(0, destinations.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(destinations[i].path),
          backgroundColor: Colors.white,
          elevation: 0,
          height: 64,
          destinations: destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.activeIcon),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavDest {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDest(this.path, this.icon, this.activeIcon, this.label);
}
