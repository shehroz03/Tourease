import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  // History of tab indices to allow back navigation through tabs
  final List<int> _history = [0];
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDashboard = location.startsWith('/admin/dashboard');
    final canPopRoute = context.canPop();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (canPopRoute) {
          context.pop();
          return;
        }

        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            final previousIndex = _history.last;
            _navigateToIndex(previousIndex, context, addToHistory: false);
          });
        } else if (!isDashboard) {
          _onItemTapped(0, context);
        } else {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    extended: true,
                    backgroundColor: Colors.white,
                    unselectedIconTheme: IconThemeData(
                      color: Colors.grey.shade400,
                    ),
                    selectedIconTheme: IconThemeData(
                      color: Colors.blue.shade700,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    selectedLabelTextStyle: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    indicatorColor: Colors.blue.shade50,
                    selectedIndex: _calculateSelectedIndex(context),
                    onDestinationSelected: (index) =>
                        _onItemTapped(index, context),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Command Center'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.verified_user_outlined),
                        selectedIcon: Icon(Icons.verified_user),
                        label: Text('Agencies'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: Text('Tour Inventory'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('System Settings'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.reviews_outlined),
                        selectedIcon: Icon(Icons.reviews),
                        label: Text('Moderation'),
                      ),
                    ],
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            );
          }

          return Scaffold(
            body: widget.child,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 70,
                backgroundColor: Colors.white,
                elevation: 0,
                indicatorColor: Colors.blue.shade50,
                selectedIndex: _calculateSelectedIndex(context),
                onDestinationSelected: (index) => _onItemTapped(index, context),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  _buildNavDestination(
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    'Admin',
                  ),
                  _buildNavDestination(
                    Icons.verified_user_outlined,
                    Icons.verified_user,
                    'Agencies',
                  ),
                  _buildNavDestination(
                    Icons.explore_outlined,
                    Icons.explore,
                    'Tours',
                  ),
                  _buildNavDestination(
                    Icons.settings_outlined,
                    Icons.settings,
                    'Settings',
                  ),
                  _buildNavDestination(
                    Icons.reviews_outlined,
                    Icons.reviews,
                    'Moderation',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.grey.shade400),
      selectedIcon: Icon(selectedIcon, color: Colors.blue.shade700),
      label: label,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/agencies')) return 1;
    if (location.startsWith('/admin/tours')) return 2;
    if (location.startsWith('/admin/settings')) return 3;
    if (location.startsWith('/admin/review-moderation')) return 4;
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
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/agencies');
        break;
      case 2:
        context.go('/admin/tours');
        break;
      case 3:
        context.go('/admin/settings');
        break;
      case 4:
        context.go('/admin/review-moderation');
        break;
    }
  }
}
