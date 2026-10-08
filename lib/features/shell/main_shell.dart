import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../home/home_screen.dart';
import '../household/my_household_screen.dart';
import '../profile/profile_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Головна', Icons.home_outlined, Icons.home),
  _Destination('Мій дім', Icons.people_outline, Icons.people),
  _Destination('Профіль', Icons.person_outline, Icons.person),
];

/// Каркас авторизованої частини: бічна панель на широких екранах,
/// нижня навігація — на вузьких (див. адаптивний макет, рис. 9 лаби №2).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  // IndexedStack зберігає стан сторінок під час перемикання розділів.
  Widget get _pages => IndexedStack(
    index: _index,
    children: const [HomeScreen(), MyHouseholdScreen(), ProfileScreen()],
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.wide;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(selected: _index, onSelect: _select),
            Expanded(child: _pages),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(alignment: Alignment.centerLeft, child: AppLogo()),
            ),
            Expanded(child: _pages),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogo(),
            const SizedBox(height: 32),
            for (var i = 0; i < _destinations.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _SidebarItem(
                  destination: _destinations[i],
                  selected: i == selected,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.selected : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
              ),
              const SizedBox(width: 12),
              Text(
                destination.label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
