import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'navigation/app_drawer.dart';
import 'navigation/tab_bar.dart';
import 'home/home_view.dart';
import 'categories/tasks_view.dart';
import 'categories/expenses_view.dart';
import 'categories/appointments_view.dart';
import 'categories/quotes_view.dart';
import 'search/search_functionality.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchFunctionality()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          DashboardTabBar(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HomeView(),
                TasksView(),
                ExpensesView(),
                AppointmentsView(),
                QuotesView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  String _getAppBarTitle() {
    const titles = ['Nota - Home', 'Tasks', 'Expenses', 'Appointments', 'Quotes'];
    return titles[_currentIndex];
  }

  Widget _buildFAB() {
    final actions = [
      (Icons.add, 'Add Note'),
      (Icons.add_task, 'Add Task'),
      (Icons.add, 'Add Expense'),
      (Icons.event, 'Add Appointment'),
      (Icons.format_quote, 'Add Quote'),
    ];
    
    final (icon, tooltip) = actions[_currentIndex];
    
    return FloatingActionButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' coming soon!')),
      ),
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
