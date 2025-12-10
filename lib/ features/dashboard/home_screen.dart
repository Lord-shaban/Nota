import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import '../auth/splash/animated_splash_screen.dart';
import 'tasks/tasks_tab_view.dart';
import 'widgets/recent_tasks_widget.dart';
import 'tasks/create_task_dialog.dart';
import 'tasks/create_task_group_dialog.dart';
import '../../core/models/task_model.dart';
import '../../core/models/task_group.dart';

// Cloudinary Configuration
final cloudinary = CloudinaryPublic('dlbwwddv5', 'chat123', cache: false);

// Gemini API Key
const String geminiApiKey = 'AIzaSyDyTexcA5nzBO54Hq9KJ-gzgfVGMhsjrs0';

/// Home Screen / Dashboard (alNota Style)
/// Main screen with tabs matching alNota design exactly
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
  final TextEditingController _noteController = TextEditingController();

  // AI Components
  late stt.SpeechToText _speech;
  late GenerativeModel _model;
  bool _isListening = false;
  String _speechText = '';
  String _fullSpeechText = '';
  Timer? _speechTimer;
  bool _continuousListening = true;

  // Data lists (alNota style - organized by type)
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _quotes = [];

  // AI Processing
  List<Map<String, dynamic>> _extractedItems = [];
  bool _isProcessing = false;

  // UI State
  bool _isSearching = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      // Rebuild to show/hide FAB based on current tab
      if (mounted) setState(() {});
    });
    _speech = stt.SpeechToText();
    _initializeGemini();
    _loadUserData();
    _loadNotesData();
  }

  void _initializeGemini() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _noteController.dispose();
    _speechTimer?.cancel();
    super.dispose();
  }

  // Load user profile data
  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (mounted && doc.exists) {
      setState(() => _userData = doc.data());
    }
  }

  // Load and categorize notes in real-time
  void _loadNotesData() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          setState(() {
            _allNotes = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
            _filteredNotes = _allNotes;
            _categorizeNotes();
          });
        });
  }

  // Categorize notes by type
  void _categorizeNotes() {
    _tasks = _allNotes.where((n) => n['type'] == 'task').toList();
    _appointments = _allNotes.where((n) => n['type'] == 'appointment').toList();
    _expenses = _allNotes.where((n) => n['type'] == 'expense').toList();
    _quotes = _allNotes.where((n) => n['type'] == 'quote').toList();
  }

  // Filter notes by search query
  void _filterNotes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = _allNotes;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      final q = query.toLowerCase();
      _filteredNotes = _allNotes.where((note) {
        final title = (note['title'] ?? '').toString().toLowerCase();
        final content = (note['content'] ?? '').toString().toLowerCase();
        return title.contains(q) || content.contains(q);
      }).toList();
    });
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
                _buildHomeTab(),
                _buildTasksTab(),
                _buildAppointmentsTab(),
                _buildExpensesTab(),
                _buildQuotesTab(),
              ],
            ),
          ),
        ],
      ),
      // Hide main FAB when in tasks tab (index 1)
      floatingActionButton: _tabController.index != 1 ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      drawer: _buildDrawer(),
    );
  }

  // ==================== UI Components ====================

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
                _filterNotes('');
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
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('قريباً: الإشعارات'))),
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
          onChanged: _filterNotes,
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
                      _filterNotes('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
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
        labelStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        tabs: [
          _buildTab(Icons.home_rounded, 'الرئيسية'),
          _buildTab(Icons.task_alt_rounded, 'المهام', _tasks.length),
          _buildTab(
            Icons.calendar_month_rounded,
            'المواعيد',
            _appointments.length,
          ),
          _buildTab(Icons.attach_money_rounded, 'المصروفات', _expenses.length),
          _buildTab(Icons.format_quote_rounded, 'اقتباسات', _quotes.length),
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
        onPressed: _showQuickAddSheet,
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
              leading: Icon(
                Icons.analytics_rounded,
                color: const Color(0xFF58CC02),
              ),
              title: Text('الإحصائيات', style: GoogleFonts.tajawal()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: const Color(0xFF58CC02),
              ),
              title: Text('الإعدادات', style: GoogleFonts.tajawal()),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.red),
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

  // ==================== Tab Content ====================

  Widget _buildHomeTab() {
    final notes = _isSearching ? _filteredNotes : _allNotes;
    return AnimationLimiter(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          _loadNotesData();
        },
        color: const Color(0xFF58CC02),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              if (!_isSearching) ...[
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildStatsCards(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                RecentTasksWidget(
                  onViewAll: () {
                    _tabController.animateTo(1); // Navigate to tasks tab
                  },
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF58CC02),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isSearching
                        ? 'نتائج البحث (${notes.length})'
                        : 'آخر الملاحظات',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching
                              ? Icons.search_off_rounded
                              : Icons.note_add_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSearching ? 'لا توجد نتائج' : 'لا توجد ملاحظات',
                          style: GoogleFonts.tajawal(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...notes
                    .take(_isSearching ? notes.length : 10)
                    .map((n) => _buildNoteCard(n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTab() => const TasksTabView();
  Widget _buildAppointmentsTab() => _buildListTab(
    _appointments,
    Icons.calendar_month_rounded,
    'لا توجد مواعيد',
  );
  Widget _buildExpensesTab() =>
      _buildListTab(_expenses, Icons.attach_money_rounded, 'لا توجد مصروفات');
  Widget _buildQuotesTab() =>
      _buildListTab(_quotes, Icons.format_quote_rounded, 'لا توجد اقتباسات');

  Widget _buildListTab(
    List<Map<String, dynamic>> items,
    IconData emptyIcon,
    String emptyText,
  ) {
    return AnimationLimiter(
      child: RefreshIndicator(
        onRefresh: () async => _loadNotesData(),
        color: const Color(0xFF58CC02),
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(emptyIcon, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      emptyText,
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: _buildNoteCard(items[index]),
                        ),
                      ),
                    ),
              ),
      ),
    );
  }

  // ==================== Widgets ====================

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
        ? 'مساء الخير'
        : 'مساء الخير';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF45A801)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting، ${_userData?['name'] ?? 'صديقي'}',
                  style: GoogleFonts.tajawal(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لديك ${_tasks.where((t) => t['completed'] != true).length} مهمة غير مكتملة',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              hour < 12
                  ? Icons.wb_sunny_rounded
                  : hour < 18
                  ? Icons.wb_twilight_rounded
                  : Icons.nightlight_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final pending = _tasks.where((t) => t['completed'] != true).length;
    final totalExp = _expenses.fold<double>(
      0,
      (sum, e) => sum + ((e['amount'] ?? 0) as num).toDouble(),
    );
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'المهام المعلقة',
          pending.toString(),
          Icons.pending_actions_rounded,
          const Color(0xFF58CC02),
        ),
        _buildStatCard(
          'المواعيد',
          _appointments.length.toString(),
          Icons.event_available_rounded,
          const Color(0xFFFFB800),
        ),
        _buildStatCard(
          'المصروفات',
          totalExp.toStringAsFixed(0),
          Icons.account_balance_wallet_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          'الاقتباسات',
          _quotes.length.toString(),
          Icons.format_quote_rounded,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات سريعة',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickBtn(
                Icons.add_task_rounded,
                'مهمة',
                const Color(0xFF58CC02),
                'task',
              ),
              _buildQuickBtn(
                Icons.event_rounded,
                'موعد',
                const Color(0xFFFFB800),
                'appointment',
              ),
              _buildQuickBtn(
                Icons.receipt_long_rounded,
                'مصروف',
                Colors.blue,
                'expense',
              ),
              _buildQuickBtn(
                Icons.format_quote_rounded,
                'اقتباس',
                Colors.purple,
                'quote',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(IconData icon, String label, Color color, String type) {
    return InkWell(
      onTap: () => _showAddDialog(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final type = note['type'] ?? 'note';
    IconData icon;
    Color color;
    switch (type) {
      case 'task':
        icon = Icons.task_alt_rounded;
        color = const Color(0xFF58CC02);
        break;
      case 'appointment':
        icon = Icons.calendar_month_rounded;
        color = const Color(0xFFFFB800);
        break;
      case 'expense':
        icon = Icons.attach_money_rounded;
        color = Colors.blue;
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.note_rounded;
        color = Colors.grey;
    }

    // عرض مختلف حسب النوع
    if (type == 'appointment') {
      return _buildAppointmentCard(note, icon, color);
    } else if (type == 'expense') {
      return _buildExpenseCard(note, icon, color);
    } else if (type == 'quote') {
      return _buildQuoteCard(note, icon, color);
    }

    // Default card with optional image
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNoteDetails(note),
          onLongPress: () => _showNoteOptions(note),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note['imageUrl'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    note['imageUrl'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['title'] ?? '',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note['content'] ?? '',
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 12),
                              Text('تعديل', style: GoogleFonts.tajawal()),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _editNote(note),
                          ),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'حذف',
                                style: GoogleFonts.tajawal(color: Colors.red),
                              ),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _deleteNote(note['id']),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    IconData icon,
    Color color,
  ) {
    String? dateStr;
    if (appointment['date'] != null) {
      try {
        if (appointment['date'] is Timestamp) {
          dateStr = (appointment['date'] as Timestamp)
              .toDate()
              .toString()
              .substring(0, 10);
        } else {
          dateStr = appointment['date'];
        }
      } catch (e) {
        dateStr = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showNoteDetails(appointment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (dateStr != null)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateStr.split('-')[2],
                        style: GoogleFonts.tajawal(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        dateStr.split('-')[1],
                        style: GoogleFonts.tajawal(fontSize: 12, color: color),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['title'] ?? '',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (appointment['time'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment['time'],
                            style: GoogleFonts.tajawal(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (appointment['content'] != null)
                      Text(
                        appointment['content'],
                        style: GoogleFonts.tajawal(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showNoteOptions(appointment),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
    Map<String, dynamic> expense,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showNoteDetails(expense),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['title'] ?? '',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense['content'] ?? '',
                      style: GoogleFonts.tajawal(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${expense['amount'] ?? 0} ${expense['currency'] ?? 'ر.س'}',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showNoteOptions(expense),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(
    Map<String, dynamic> quote,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showNoteDetails(quote),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote_rounded, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              quote['content'] ?? quote['title'] ?? '',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showNoteOptions(quote),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Dialogs & Actions ====================

  void _showQuickAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'إضافة جديد',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // طرق الإدخال الذكية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدخال ذكي بالـ AI',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAIInputOption(
                        Icons.keyboard_rounded,
                        'نص',
                        const Color(0xFF58CC02),
                        () {
                          Navigator.pop(ctx);
                          _showTextInputDialog();
                        },
                      ),
                      _buildAIInputOption(
                        Icons.mic_rounded,
                        'صوت',
                        const Color(0xFFFFB800),
                        () {
                          Navigator.pop(ctx);
                          _startVoiceInput();
                        },
                      ),
                      _buildAIInputOption(
                        Icons.camera_alt_rounded,
                        'كاميرا',
                        Colors.blue,
                        () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildAIInputOption(
                        Icons.image_rounded,
                        'صورة',
                        Colors.purple,
                        () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // الإضافة اليدوية
            Text(
              'أو إضافة يدوية',
              style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: [
                _buildQuickAddOption(
                  Icons.add_task_rounded,
                  'مهمة',
                  const Color(0xFF58CC02),
                  'task',
                ),
                _buildQuickAddOption(
                  Icons.event_rounded,
                  'موعد',
                  const Color(0xFFFFB800),
                  'appointment',
                ),
                _buildQuickAddOption(
                  Icons.receipt_long_rounded,
                  'مصروف',
                  Colors.blue,
                  'expense',
                ),
                _buildQuickAddOption(
                  Icons.format_quote_rounded,
                  'اقتباس',
                  Colors.purple,
                  'quote',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInputOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'إدخال ذكي',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'اكتب أي شيء وسأستخرجه تلقائياً...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: Color(0xFF58CC02),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مثال: اشتري حليب غداً، اجتماع الساعة 3، دفعت 50 جنيه',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
            ),
            onPressed: () async {
              if (_noteController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _processTextWithAI(_noteController.text);
              _noteController.clear();
            },
            child: Text(
              'تحليل',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddOption(
    IconData icon,
    String label,
    Color color,
    String type,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showAddDialog(type);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(String type) async {
    if (type == 'task') {
      // استخدام نظام المهام الجديد
      await _showTaskCreationFlow();
      return;
    }

    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final typeLabel = type == 'appointment'
        ? 'موعد'
        : type == 'expense'
        ? 'مصروف'
        : 'اقتباس';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إضافة $typeLabel',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: 'المحتوى',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('notes')
                  .add({
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'type': type,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'completed': false,
                  });
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إضافة $typeLabel بنجاح')),
                );
              }
            },
            child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTaskCreationFlow() async {
    // جلب المجموعات الموجودة
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final groupsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('taskGroups')
        .get();

    if (!mounted) return;

    // عرض قائمة المجموعات للاختيار أو إنشاء مهمة بدون مجموعة
    final selectedGroupId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'اختر المجموعة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // خيار إنشاء مهمة بدون مجموعة
              Card(
                color: const Color(0xFFF8F8F8),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task_alt, size: 24),
                  ),
                  title: Text(
                    'بدون مجموعة',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'إنشاء مهمة مستقلة',
                    style: GoogleFonts.tajawal(fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(ctx, 'NO_GROUP'),
                ),
              ),
              if (groupsSnapshot.docs.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groupsSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      final doc = groupsSnapshot.docs[index];
                      final group = TaskGroup.fromFirestore(doc);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(
                            group.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          title: Text(
                            group.title,
                            style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            group.description ?? '',
                            style: GoogleFonts.tajawal(fontSize: 12),
                          ),
                          onTap: () => Navigator.pop(ctx, group.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          if (groupsSnapshot.docs.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (context) => const CreateTaskGroupDialog(),
                );
              },
              child: Text(
                'إنشاء مجموعة',
                style: GoogleFonts.tajawal(color: const Color(0xFF58CC02)),
              ),
            ),
        ],
      ),
    );

    if (selectedGroupId != null && mounted) {
      if (selectedGroupId == 'NO_GROUP') {
        // إنشاء مهمة بدون مجموعة
        _showQuickTaskDialog();
      } else {
        showDialog(
          context: context,
          builder: (context) => CreateTaskDialog(groupId: selectedGroupId),
        );
      }
    }
  }

  void _showQuickTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: Color(0xFF58CC02),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'مهمة سريعة',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'عنوان المهمة',
                  labelStyle: GoogleFonts.tajawal(),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  labelStyle: GoogleFonts.tajawal(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'الأولوية:',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'urgent', child: Text('🔴 عاجل', style: GoogleFonts.tajawal())),
                        DropdownMenuItem(value: 'high', child: Text('🟠 عالي', style: GoogleFonts.tajawal())),
                        DropdownMenuItem(value: 'medium', child: Text('🟡 متوسط', style: GoogleFonts.tajawal())),
                        DropdownMenuItem(value: 'low', child: Text('🟢 منخفض', style: GoogleFonts.tajawal())),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedPriority = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                
                final userId = _auth.currentUser?.uid;
                if (userId == null) return;

                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('notes')
                    .add({
                  'type': 'task',
                  'title': titleCtrl.text.trim(),
                  'content': descCtrl.text.trim(),
                  'priority': selectedPriority,
                  'completed': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنشاء المهمة بنجاح', style: GoogleFonts.tajawal()),
                      backgroundColor: const Color(0xFF58CC02),
                    ),
                  );
                }
              },
              child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetails(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          note['title'] ?? 'بدون عنوان',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text(
          note['content'] ?? 'لا يوجد محتوى',
          style: GoogleFonts.tajawal(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  void _showNoteOptions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF58CC02)),
              title: Text('تعديل', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(ctx);
                _editNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('حذف', style: GoogleFonts.tajawal(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteNote(note['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    final titleCtrl = TextEditingController(text: note['title']);
    final contentCtrl = TextEditingController(text: note['content']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تعديل الملاحظة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: 'المحتوى',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
            ),
            onPressed: () async {
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('notes')
                  .doc(note['id'])
                  .update({
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('تم التحديث')));
              }
            },
            child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteNote(String? docId) {
    if (docId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف الملاحظة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text('هل أنت متأكد؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('notes')
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('تم الحذف')));
              }
            },
            child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
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

  // ==================== AI Features ====================

  Future<void> _processTextWithAI(String text) async {
    _showLoadingDialog('الذكاء الاصطناعي يحلل النص...');

    try {
      final prompt = '''
قم بتحليل النص التالي واستخراج جميع العناصر منه بدقة:

النص: "$text"

استخرج العناصر التالية:
- المهام: أي شيء يحتاج إنجاز (مثل: اشتري، اعمل، راجع، اتصل)
  * اقترح مجموعة مناسبة للمهمة من: 📚 مذاكرة، 🛒 تسوق، 💼 عمل، 🏠 منزل، 🏋️ رياضة، 🎯 شخصي
  * حدد الأولوية: urgent (عاجل)، high (عالي)، medium (متوسط)، low (منخفض)
- المواعيد: أي حدث بتاريخ/وقت (مثل: اجتماع، موعد، غداً، الساعة)
- المصروفات: أي ذكر للمال (مثل: دفعت، اشتريت، جنيه، ريال، دولار)
- الاقتباسات: عبارات ملهمة أو حكم
- الملاحظات: أي شيء آخر

أرجع JSON فقط بدون أي نص إضافي:
{
  "items": [
    {
      "type": "task",
      "title": "عنوان قصير (3-5 كلمات)",
      "content": "المحتوى الكامل",
      "date": "YYYY-MM-DD أو null",
      "time": "HH:MM أو null",
      "amount": رقم أو null,
      "currency": "ر.س/جنيه/دولار أو null",
      "suggestedGroup": "اسم المجموعة مع الإيموجي (للمهام فقط)",
      "priority": "urgent/high/medium/low (للمهام فقط، افتراضي medium)"
    }
  ]
}

مهم جداً: 
- أرجع JSON صحيح فقط
- type يجب أن يكون: task أو appointment أو expense أو quote أو note
- التاريخ بصيغة YYYY-MM-DD
- الوقت بصيغة 24 ساعة HH:MM
- suggestedGroup و priority للمهام فقط
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (mounted) Navigator.pop(context);

      if (response.text != null && response.text!.isNotEmpty) {
        print('AI Response: ${response.text}'); // للتشخيص
        
        var jsonStr = response.text!.trim();
        
        // تنظيف النص
        jsonStr = jsonStr.replaceAll('```json', '');
        jsonStr = jsonStr.replaceAll('```', '');
        jsonStr = jsonStr.trim();
        
        // إزالة أي نص قبل أو بعد JSON
        final jsonStart = jsonStr.indexOf('{');
        final jsonEnd = jsonStr.lastIndexOf('}');
        
        if (jsonStart != -1 && jsonEnd != -1) {
          jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
          
          try {
            final data = json.decode(jsonStr);
            
            if (data['items'] != null && data['items'] is List && (data['items'] as List).isNotEmpty) {
              setState(() {
                _extractedItems = List<Map<String, dynamic>>.from(data['items']);
              });
              _showExtractedItemsDialog();
              return;
            }
          } catch (e) {
            print('JSON Parse Error: $e'); // للتشخيص
            print('JSON String: $jsonStr'); // للتشخيص
          }
        }
      }
      
      // إذا فشل التحليل، احفظ كملاحظة عادية
      if (mounted) {
        await _saveNote({
          'type': 'note',
          'title': text.length > 30 ? '${text.substring(0, 30)}...' : text,
          'content': text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ كملاحظة عادية', style: GoogleFonts.tajawal())),
        );
      }
    } catch (e) {
      print('AI Error: $e'); // للتشخيص
      if (mounted) {
        Navigator.pop(context);
        await _saveNote({
          'type': 'note',
          'title': text.length > 30 ? '${text.substring(0, 30)}...' : text,
          'content': text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحليل. تم الحفظ كملاحظة عادية', style: GoogleFonts.tajawal()), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _startVoiceInput() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    bool available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'التعرف على الصوت غير متاح',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _fullSpeechText = '';
    _speechText = '';
    _continuousListening = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [const Color(0xFFFFB800), const Color(0xFFFFD900)]
                        : [Colors.grey[400]!, Colors.grey[600]!],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isListening)
                      Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_p7ml1rhe.json',
                        width: 150,
                        height: 150,
                      ),
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isListening ? 'أستمع إليك...' : 'اضغط للتحدث',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 200,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _fullSpeechText.isEmpty
                        ? 'ابدأ بالتحدث...'
                        : _fullSpeechText,
                    style: GoogleFonts.tajawal(
                      color: _fullSpeechText.isEmpty
                          ? Colors.grey
                          : Colors.black,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _continuousListening = false;
                      _isListening = false;
                      _speechTimer?.cancel();
                      _speech.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: Text(
                      'إلغاء',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_isListening) {
                        _continuousListening = false;
                        _isListening = false;
                        _speechTimer?.cancel();
                        await _speech.stop();
                        setDialogState(() => _isListening = false);
                        if (_fullSpeechText.isNotEmpty) {
                          Navigator.pop(context);
                          await _processTextWithAI(_fullSpeechText);
                          _fullSpeechText = '';
                        }
                      } else {
                        _continuousListening = true;
                        setDialogState(() => _isListening = true);
                        _startContinuousListening(setDialogState);
                      }
                    },
                    icon: Icon(
                      _isListening ? Icons.check : Icons.mic,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isListening ? 'حفظ' : 'تحدث',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening
                          ? const Color(0xFF58CC02)
                          : const Color(0xFFFFB800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startContinuousListening(StateSetter setDialogState) async {
    if (!_continuousListening) return;
    try {
      await _speech.listen(
        onResult: (result) {
          setDialogState(() {
            if (result.finalResult) {
              if (_fullSpeechText.isNotEmpty) _fullSpeechText += ' ';
              _fullSpeechText += result.recognizedWords;
              _speechText = '';
            } else {
              _speechText = result.recognizedWords;
            }
          });
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 60),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: 'ar-SA',
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);

      if (image != null) {
        _showLoadingDialog('جاري معالجة الصورة...');

        try {
          // رفع الصورة لـ Cloudinary
          CloudinaryResponse cloudinaryResponse = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
          );

          // قراءة الصورة
          final imageBytes = await File(image.path).readAsBytes();
          
          final prompt = '''
قم بتحليل هذه الصورة بدقة واستخرج جميع المعلومات:
- إذا كانت فاتورة: استخرج المصروفات والمبالغ
- إذا كانت قائمة مهام: استخرج المهام
- إذا كانت جدول مواعيد: استخرج المواعيد
- إذا كانت نص: استخرج المحتوى

أرجع JSON فقط:
{
  "items": [
    {
      "type": "task/appointment/expense/quote/note",
      "title": "عنوان قصير",
      "content": "المحتوى",
      "amount": رقم أو null,
      "currency": "العملة أو null"
    }
  ]
}
''';

          final content = [Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])];
          final aiResponse = await _model.generateContent(content);

          if (mounted) Navigator.pop(context);

          if (aiResponse.text != null && aiResponse.text!.isNotEmpty) {
            print('Image AI Response: ${aiResponse.text}');
            
            var jsonStr = aiResponse.text!.trim();
            jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
            
            final jsonStart = jsonStr.indexOf('{');
            final jsonEnd = jsonStr.lastIndexOf('}');
            
            if (jsonStart != -1 && jsonEnd != -1) {
              jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
              
              try {
                final data = json.decode(jsonStr);
                if (data['items'] != null && data['items'] is List && (data['items'] as List).isNotEmpty) {
                  setState(() {
                    _extractedItems = List<Map<String, dynamic>>.from(data['items']);
                    for (var item in _extractedItems) {
                      item['imageUrl'] = cloudinaryResponse.secureUrl;
                    }
                  });
                  _showExtractedItemsDialog();
                  return;
                }
              } catch (e) {
                print('Image JSON Parse Error: $e');
              }
            }
          }
          
          // إذا فشل التحليل، احفظ الصورة كملاحظة
          if (mounted) {
            await _saveNote({
              'type': 'note',
              'title': 'صورة - ${DateTime.now().toString().substring(0, 16)}',
              'content': 'صورة تم رفعها',
              'imageUrl': cloudinaryResponse.secureUrl,
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم حفظ الصورة', style: GoogleFonts.tajawal())),
            );
          }
        } catch (e) {
          print('Image Upload/Process Error: $e');
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في معالجة الصورة', style: GoogleFonts.tajawal()),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Image Picker Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF58CC02)),
            const SizedBox(width: 20),
            Expanded(child: Text(message, style: GoogleFonts.tajawal())),
          ],
        ),
      ),
    );
  }

  void _showExtractedItemsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'تم استخراج ${_extractedItems.length} عنصر',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _extractedItems.length,
            itemBuilder: (context, index) =>
                _buildExtractedItemCard(_extractedItems[index], index),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _extractedItems.clear());
              Navigator.pop(context);
            },
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveMultipleNotes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
            ),
            child: Text(
              'حفظ الكل',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedItemCard(Map<String, dynamic> item, int index) {
    IconData icon;
    Color color;
    switch (item['type']) {
      case 'task':
        icon = Icons.task_alt_rounded;
        color = const Color(0xFF58CC02);
        break;
      case 'appointment':
        icon = Icons.calendar_month_rounded;
        color = const Color(0xFFFFB800);
        break;
      case 'expense':
        icon = Icons.attach_money_rounded;
        color = Colors.blue;
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.note_rounded;
        color = Colors.grey;
    }

    // معلومات إضافية للمهام
    String? priorityEmoji;
    String? priorityLabel;
    if (item['type'] == 'task' && item['priority'] != null) {
      switch (item['priority']) {
        case 'urgent':
          priorityEmoji = '🔴';
          priorityLabel = 'عاجل';
          break;
        case 'high':
          priorityEmoji = '🟠';
          priorityLabel = 'عالي';
          break;
        case 'medium':
          priorityEmoji = '🟡';
          priorityLabel = 'متوسط';
          break;
        case 'low':
          priorityEmoji = '🟢';
          priorityLabel = 'منخفض';
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['title'] ?? 'بدون عنوان',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              ),
            ),
            if (priorityEmoji != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  priorityEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['content'] ?? '',
              style: GoogleFonts.tajawal(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item['type'] == 'task') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item['suggestedGroup'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['suggestedGroup'],
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (priorityLabel != null)
                    Text(
                      priorityLabel,
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => setState(() => _extractedItems.removeAt(index)),
        ),
      ),
    );
  }

  Future<void> _saveNote(Map<String, dynamic> note) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).collection('notes').add({
      ...note,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completed': false,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
    }
  }

  Future<void> _saveMultipleNotes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _showLoadingDialog('جاري الحفظ...');

    int savedCount = 0;

    for (var item in _extractedItems) {
      if (item['type'] == 'task') {
        // معالجة المهام بنظام المجموعات الجديد
        await _saveTaskWithGroup(item);
        savedCount++;
      } else {
        // معالجة العناصر الأخرى كما هي
        await _firestore.collection('users').doc(userId).collection('notes').add({
          ...item,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'completed': false,
        });
        savedCount++;
      }
    }

    Navigator.pop(context);
    setState(() => _extractedItems.clear());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ $savedCount عنصر',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: const Color(0xFF58CC02),
        ),
      );
    }
  }

  Future<void> _saveTaskWithGroup(Map<String, dynamic> item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    String? groupId;
    final suggestedGroup = item['suggestedGroup'] as String?;

    if (suggestedGroup != null && suggestedGroup.isNotEmpty) {
      // البحث عن المجموعة بالاسم
      final groupsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .get();

      final existingGroup = groupsSnapshot.docs.firstWhere(
        (doc) => TaskGroup.fromFirestore(doc).title == suggestedGroup,
        orElse: () => groupsSnapshot.docs.first,
      );

      if (existingGroup.exists) {
        groupId = existingGroup.id;
      } else if (groupsSnapshot.docs.isNotEmpty) {
        // استخدام أول مجموعة متاحة
        groupId = groupsSnapshot.docs.first.id;
      }
    } else {
      // لا يوجد اقتراح - استخدام أول مجموعة متاحة
      final groupsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .limit(1)
          .get();

      if (groupsSnapshot.docs.isNotEmpty) {
        groupId = groupsSnapshot.docs.first.id;
      }
    }

    if (groupId == null) {
      // إنشاء مجموعة افتراضية إذا لم توجد مجموعات
      final newGroupRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .add({
        'title': '📝 عام',
        'icon': '📝',
        'description': 'مجموعة عامة للمهام',
        'color': '#58CC02',
        'userId': userId,
        'totalTasks': 0,
        'completedTasks': 0,
        'taskIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      groupId = newGroupRef.id;
    }

    // إنشاء المهمة
    DateTime? dueDate;
    if (item['date'] != null) {
      try {
        dueDate = DateTime.parse(item['date']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    final task = TaskModel(
      id: '',
      title: item['title'] ?? '',
      description: item['content'] ?? '',
      groupId: groupId,
      priority: item['priority'] ?? 'medium',
      dueDate: dueDate,
      tags: [],
      notes: '',
      isCompleted: false,
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('taskGroups')
        .doc(groupId)
        .collection('tasks')
        .add(task.toFirestore());

    // تحديث إحصائيات المجموعة
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('taskGroups')
        .doc(groupId)
        .update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
