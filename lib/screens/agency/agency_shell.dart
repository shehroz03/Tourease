import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AgencyShell extends StatefulWidget {
  final Widget child;

  const AgencyShell({super.key, required this.child});

  @override
  State<AgencyShell> createState() => _AgencyShellState();
}

class _AgencyShellState extends State<AgencyShell> {
  // History of tab indices to allow back navigation through tabs
  final List<int> _history = [0];
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    String location = '';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      // Fallback
    }

    final isDashboard = location.startsWith('/agency/dashboard');
    final canPopRoute = context.canPop();

    return PopScope(
      canPop: false, // Handle pop manually to support tab history
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If there's a route to pop (e.g. a detail page pushed on top), pop it
        if (canPopRoute) {
          context.pop();
          return;
        }

        // If we have tab history, go back to previous tab
        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            final previousIndex = _history.last;
            _navigateToIndex(previousIndex, context, addToHistory: false);
          });
        } else if (!isDashboard) {
          // If not on dashboard and no history, go to dashboard
          _onItemTapped(0, context);
        } else {
          // On dashboard and no history, exit app
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) >
                  const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.tour_outlined),
              selectedIcon: Icon(Icons.tour),
              label: 'Tours',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/agency/dashboard')) return 0;
    if (location.startsWith('/agency/tours')) return 1;
    if (location.startsWith('/agency/bookings')) return 2;
    if (location.startsWith('/agency/chats')) return 3;
    if (location.startsWith('/agency/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (_calculateSelectedIndex(context) == index) return;

    setState(() {
      _history.remove(index);
      _history.add(index);
    });

    _navigateToIndex(index, context, addToHistory: false);
  }

  void _navigateToIndex(
    int index,
    BuildContext context, {
    bool addToHistory = true,
  }) {
    if (addToHistory) {
      setState(() {
        _history.remove(index);
        _history.add(index);
      });
    }

    switch (index) {
      case 0:
        context.go('/agency/dashboard');
        break;
      case 1:
        context.go('/agency/tours');
        break;
      case 2:
        context.go('/agency/bookings');
        break;
      case 3:
        context.go('/agency/chats');
        break;
      case 4:
        context.go('/agency/settings');
        break;
    }
  }
}
