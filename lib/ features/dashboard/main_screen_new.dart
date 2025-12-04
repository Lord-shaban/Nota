import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import dashboard components
import 'navigation/app_drawer.dart';
import 'navigation/tab_bar.dart';
import 'home/home_view.dart';
import 'categories/tasks_view.dart';
import 'categories/expenses_view.dart';
import 'categories/appointments_view.dart';
import 'categories/quotes_view.dart';
import 'search/search_functionality.dart';

/// Main Screen - Dashboard Entry Point
/// Combines all dashboard features with TabBar navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
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

    // Redirect to login if not authenticated
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          // Search Button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchFunctionality(),
                ),
              );
            },
            tooltip: 'Search',
          ),
          // Notifications Button (placeholder)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Custom TabBar
          DashboardTabBar(tabController: _tabController),

          // TabBarView
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Nota - Home';
      case 1:
        return 'Tasks';
      case 2:
        return 'Expenses';
      case 3:
        return 'Appointments';
      case 4:
        return 'Quotes';
      default:
        return 'Nota';
    }
  }

  Widget? _buildFloatingActionButton() {
    IconData icon;
    String tooltip;
    VoidCallback onPressed;

    switch (_currentIndex) {
      case 0: // Home - Add Note
        icon = Icons.add;
        tooltip = 'Add Note';
        onPressed = () => _showAddNoteDialog();
        break;
      case 1: // Tasks
        icon = Icons.add_task;
        tooltip = 'Add Task';
        onPressed = () => _showAddTaskDialog();
        break;
      case 2: // Expenses
        icon = Icons.add;
        tooltip = 'Add Expense';
        onPressed = () => _showAddExpenseDialog();
        break;
      case 3: // Appointments
        icon = Icons.event;
        tooltip = 'Add Appointment';
        onPressed = () => _showAddAppointmentDialog();
        break;
      case 4: // Quotes
        icon = Icons.format_quote;
        tooltip = 'Add Quote';
        onPressed = () => _showAddQuoteDialog();
        break;
      default:
        return null;
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  // Placeholder dialogs for adding items
  void _showAddNoteDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Note dialog coming soon!'),
      ),
    );
  }

  void _showAddTaskDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Task dialog coming soon!'),
      ),
    );
  }

  void _showAddExpenseDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Expense dialog coming soon!'),
      ),
    );
  }

  void _showAddAppointmentDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Appointment dialog coming soon!'),
      ),
    );
  }

  void _showAddQuoteDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Quote dialog coming soon!'),
      ),
    );
  }
}

/// Alternative: Bottom Navigation Bar Version
class MainScreenBottomNav extends StatefulWidget {
  const MainScreenBottomNav({super.key});

  @override
  State<MainScreenBottomNav> createState() => _MainScreenBottomNavState();
}

class _MainScreenBottomNavState extends State<MainScreenBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeView(),
    TasksView(),
    ExpensesView(),
    AppointmentsView(),
    QuotesView(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchFunctionality(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add action coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Tasks';
      case 2:
        return 'Expenses';
      case 3:
        return 'Appointments';
      case 4:
        return 'Quotes';
      default:
        return 'Nota';
    }
  }
}
