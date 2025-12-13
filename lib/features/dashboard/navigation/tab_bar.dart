import 'package:flutter/material.dart';

/// Custom TabBar Widget for Dashboard Navigation
/// Allows switching between different category views
class DashboardTabBar extends StatelessWidget {
  final TabController tabController;

  const DashboardTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).primaryColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.home_outlined, size: 20),
            text: 'Home',
          ),
          Tab(
            icon: Icon(Icons.task_alt_outlined, size: 20),
            text: 'Tasks',
          ),
          Tab(
            icon: Icon(Icons.attach_money_outlined, size: 20),
            text: 'Expenses',
          ),
          Tab(
            icon: Icon(Icons.calendar_today_outlined, size: 20),
            text: 'Appointments',
          ),
          Tab(
            icon: Icon(Icons.format_quote_outlined, size: 20),
            text: 'Quotes',
          ),
        ],
      ),
    );
  }
}

/// Simple TabBar for Minimal Design
class SimpleTabBar extends StatelessWidget {
  final TabController tabController;

  const SimpleTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      indicatorColor: Theme.of(context).primaryColor,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      tabs: const [
        Tab(text: 'Home'),
        Tab(text: 'Tasks'),
        Tab(text: 'Expenses'),
        Tab(text: 'Appointments'),
        Tab(text: 'Quotes'),
      ],
    );
  }
}

/// Bottom Navigation TabBar Alternative
class BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt_outlined),
          activeIcon: Icon(Icons.task_alt),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_outlined),
          activeIcon: Icon(Icons.attach_money),
          label: 'Expenses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Dates',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_quote_outlined),
          activeIcon: Icon(Icons.format_quote),
          label: 'Quotes',
        ),
      ],
    );
  }
}
