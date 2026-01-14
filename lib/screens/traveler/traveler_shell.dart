import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TravelerShell extends StatefulWidget {
  final Widget child;

  const TravelerShell({super.key, required this.child});

  @override
  State<TravelerShell> createState() => _TravelerShellState();
}

class _TravelerShellState extends State<TravelerShell> {
  // History of tab indices to allow back navigation through tabs
  final List<int> _history = [0];
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    String location = '';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      // Fallback for cases where state might be temporarily unavailable
    }

    final isHome = location.startsWith('/traveler/home');
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
        } else if (!isHome) {
          // If not on home and no history, go to home
          _onItemTapped(0, context);
        } else {
          // On home and no history, allow system pop (exit app)
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
        body: Stack(
          children: [
            widget.child,
            Positioned(
              right: 16,
              bottom: 100, // Above the navigation bar
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/chatbot'),
                label: const Text(
                  'Tour Buddy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                icon: const Icon(Icons.smart_toy_rounded, size: 24),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          indicatorColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00BFA5)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: Color(0xFF00BFA5)),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark, color: Color(0xFF00BFA5)),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat, color: Color(0xFF00BFA5)),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person, color: Color(0xFF00BFA5)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/traveler/home')) return 0;
    if (location.startsWith('/traveler/search')) return 1;
    if (location.startsWith('/traveler/bookings')) return 2;
    if (location.startsWith('/traveler/chats')) return 3;
    if (location.startsWith('/traveler/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (_calculateSelectedIndex(context) == index) return;

    setState(() {
      // Remove index if already in history to move it to the end
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
        context.go('/traveler/home');
        break;
      case 1:
        context.go('/traveler/search');
        break;
      case 2:
        context.go('/traveler/bookings');
        break;
      case 3:
        context.go('/traveler/chats');
        break;
      case 4:
        context.go('/traveler/profile');
        break;
    }
  }
}
