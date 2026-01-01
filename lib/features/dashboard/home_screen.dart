import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/splash/animated_splash_screen.dart';
import 'tasks/tasks_tab_view.dart';
import 'appointments/appointments_view.dart';
import 'expenses/expenses_view.dart';
import 'quotes_diary/quotes_diary_view.dart';
import 'home/enhanced_home_tab.dart';
import '../../features/input_system/coordinator/unified_input_handler.dart';

/// Home Screen / Dashboard المحسن
/// الشاشة الرئيسية مع التابات والربط مع نظام الإدخال الموحد
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  
  late UnifiedInputHandler _inputHandler;

  // UI State
  bool _isSearching = false;
  Map<String, dynamic>? _userData;

  // Data counts for tab badges
  int _tasksCount = 0;
  int _appointmentsCount = 0;
  int _expensesCount = 0;
  int _quotesCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    
    _loadUserData();
    _setupDataListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inputHandler = UnifiedInputHandler(
      context: context,
      tabController: _tabController,
      onDataSaved: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _inputHandler.dispose();
    super.dispose();
  }

  void _setupDataListeners() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen to tasks count
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('type', isEqualTo: 'task')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _tasksCount = snapshot.docs.where((d) {
            final data = d.data();
            return data['completed'] != true;
          }).length;
        });
      }
    });

    // Listen to appointments count
    _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _appointmentsCount = snapshot.docs.where((d) {
            final data = d.data();
            final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
            return dateTime != null && dateTime.isAfter(now) && data['status'] != 'completed';
          }).length;
        });
      }
    });

    // Listen to expenses count
    _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() => _expensesCount = snapshot.docs.length);
      }
    });

    // Listen to quotes count
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('type', isEqualTo: 'quote')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() => _quotesCount = snapshot.docs.length);
      }
    });
  }

  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (mounted && doc.exists) {
      setState(() => _userData = doc.data());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                EnhancedHomeTab(
                  mainTabController: _tabController,
                  onAddNew: () => _inputHandler.showQuickAddSheet(),
                  userData: _userData,
                ),
                const TasksTabView(),
                const AppointmentsView(),
                const ExpensesView(),
                const QuotesDiaryView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _shouldShowMainFAB() ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      drawer: _buildDrawer(),
    );
  }

  bool _shouldShowMainFAB() {
    // Hide FAB on tabs that have their own FAB
    return _tabController.index == 0;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded, color: Color(0xFF58CC02)),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: Color(0xFF58CC02),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'النوتة',
            style: GoogleFonts.tajawal(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C3C3C),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_rounded, color: Colors.blue),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD900).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFFFB800),
            ),
          ),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('قريباً: الإشعارات')),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.tajawal(),
          decoration: InputDecoration(
            hintText: 'ابحث في ملاحظاتك...',
            hintStyle: GoogleFonts.tajawal(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF58CC02),
        indicatorWeight: 3,
        labelColor: const Color(0xFF58CC02),
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 16),
        tabs: [
          _buildTab(Icons.home_rounded, 'الرئيسية'),
          _buildTab(Icons.task_alt_rounded, 'المهام', _tasksCount),
          _buildTab(Icons.calendar_month_rounded, 'المواعيد', _appointmentsCount),
          _buildTab(Icons.attach_money_rounded, 'المصروفات', _expensesCount),
          _buildTab(Icons.format_quote_rounded, 'اقتباسات', _quotesCount),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, [int? count]) {
    return Tab(
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () => _inputHandler.showQuickAddSheet(),
        backgroundColor: const Color(0xFF58CC02),
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة جديد',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = _auth.currentUser;
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF58CC02), Color(0xFF45A801)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF58CC02),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['name'] ?? 'المستخدم',
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: Color(0xFF58CC02)),
              title: Text('الإحصائيات', style: GoogleFonts.tajawal()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Color(0xFF58CC02)),
              title: Text('الإعدادات', style: GoogleFonts.tajawal()),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text('تسجيل الخروج', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text('هل أنت متأكد؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AnimatedSplashScreen()),
          (route) => false,
        );
      }
    }
  }
}
