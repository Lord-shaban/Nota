import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/entry_model.dart';
import 'widgets/add_entry_dialog.dart';

/// أنواع العرض المتاحة
enum ViewMode {
  list,
  grid,
  masonry,
}

extension ViewModeExtension on ViewMode {
  String get arabicName {
    switch (this) {
      case ViewMode.list:
        return 'قائمة';
      case ViewMode.grid:
        return 'شبكة';
      case ViewMode.masonry:
        return 'بنترست';
    }
  }

  IconData get icon {
    switch (this) {
      case ViewMode.list:
        return Icons.view_list;
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.masonry:
        return Icons.dashboard;
    }
  }
}

/// قائمة الخطوط المتاحة
class FontOption {
  final String name;
  final String arabicName;
  final TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color, FontStyle? fontStyle, double? height}) getStyle;

  const FontOption({
    required this.name,
    required this.arabicName,
    required this.getStyle,
  });
}

final List<FontOption> availableFonts = [
  FontOption(
    name: 'tajawal',
    arabicName: 'تجول',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.tajawal(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'cairo',
    arabicName: 'القاهرة',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.cairo(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'amiri',
    arabicName: 'أميري',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.amiri(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'lateef',
    arabicName: 'لطيف',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.lateef(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'almarai',
    arabicName: 'المراعي',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.almarai(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'changa',
    arabicName: 'شانغا',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.changa(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'elMessiri',
    arabicName: 'المسيري',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.elMessiri(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
  FontOption(
    name: 'arefRuqaa',
    arabicName: 'عارف رقعة',
    getStyle: ({fontSize, fontWeight, color, fontStyle, height}) =>
        GoogleFonts.arefRuqaa(fontSize: fontSize, fontWeight: fontWeight, color: color, fontStyle: fontStyle, height: height),
  ),
];

/// واجهة الاقتباسات واليوميات
class QuotesDiaryView extends StatefulWidget {
  const QuotesDiaryView({super.key});

  @override
  State<QuotesDiaryView> createState() => _QuotesDiaryViewState();
}

class _QuotesDiaryViewState extends State<QuotesDiaryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // الفلاتر
  EntryType? _filterType;
  QuoteCategory? _filterCategory;
  DiaryMood? _filterMood;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';

  // إعدادات العرض
  ViewMode _viewMode = ViewMode.list;
  String _selectedFont = 'tajawal';

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _primaryColor = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _viewMode = ViewMode.values[prefs.getInt('quotes_view_mode') ?? 0];
      _selectedFont = prefs.getString('quotes_font') ?? 'tajawal';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quotes_view_mode', _viewMode.index);
    await prefs.setString('quotes_font', _selectedFont);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  FontOption get _currentFont =>
      availableFonts.firstWhere((f) => f.name == _selectedFont, orElse: () => availableFonts.first);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              child: _buildTabs(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllEntriesTab(),
            _buildQuotesTab(),
            _buildDiaryTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add),
        label: Text(
          'إضافة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث مع أزرار العرض
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.tajawal(),
                    decoration: InputDecoration(
                      hintText: 'البحث في الاقتباسات واليوميات...',
                      hintStyle: GoogleFonts.tajawal(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
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
              ),
              const SizedBox(width: 8),
              // زر تغيير العرض
              _buildViewModeButton(),
              const SizedBox(width: 4),
              // زر تغيير الخط
              _buildFontButton(),
            ],
          ),

          const SizedBox(height: 12),

          // فلاتر سريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'المفضلة',
                  icon: Icons.favorite,
                  isSelected: _showFavoritesOnly,
                  onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'الكل',
                  icon: Icons.all_inclusive,
                  isSelected: _filterType == null,
                  onTap: () => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'اقتباسات',
                  icon: Icons.format_quote,
                  isSelected: _filterType == EntryType.quote,
                  onTap: () => setState(() => _filterType = EntryType.quote),
                  color: EntryType.quote.color,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'يوميات',
                  icon: Icons.book,
                  isSelected: _filterType == EntryType.diary,
                  onTap: () => setState(() => _filterType = EntryType.diary),
                  color: EntryType.diary.color,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'المزيد',
                  icon: Icons.tune,
                  isSelected: false,
                  onTap: () => _showFilterSheet(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton() {
    return PopupMenuButton<ViewMode>(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_viewMode.icon, color: _primaryColor, size: 22),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (mode) {
        setState(() => _viewMode = mode);
        _savePreferences();
      },
      itemBuilder: (context) => ViewMode.values.map((mode) {
        return PopupMenuItem<ViewMode>(
          value: mode,
          child: Row(
            children: [
              Icon(
                mode.icon,
                color: _viewMode == mode ? _primaryColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                mode.arabicName,
                style: GoogleFonts.tajawal(
                  fontWeight: _viewMode == mode ? FontWeight.bold : FontWeight.normal,
                  color: _viewMode == mode ? _primaryColor : Colors.black87,
                ),
              ),
              if (_viewMode == mode) ...[
                const Spacer(),
                Icon(Icons.check, color: _primaryColor, size: 18),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.font_download, color: Color(0xFF6366F1), size: 22),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (font) {
        setState(() => _selectedFont = font);
        _savePreferences();
      },
      itemBuilder: (context) => availableFonts.map((font) {
        final isSelected = _selectedFont == font.name;
        return PopupMenuItem<String>(
          value: font.name,
          child: Row(
            children: [
              Text(
                'أ ب ج',
                style: font.getStyle(
                  fontSize: 16,
                  color: isSelected ? _primaryColor : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                font.arabicName,
                style: GoogleFonts.tajawal(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? _primaryColor : Colors.black87,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, color: _primaryColor, size: 18),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? _primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'الكل', icon: Icon(Icons.grid_view, size: 20)),
          Tab(text: 'الاقتباسات', icon: Icon(Icons.format_quote, size: 20)),
          Tab(text: 'اليوميات', icon: Icon(Icons.book, size: 20)),
        ],
      ),
    );
  }

  Widget _buildAllEntriesTab() {
    return _buildEntriesList(null);
  }

  Widget _buildQuotesTab() {
    return _buildEntriesList(EntryType.quote);
  }

  Widget _buildDiaryTab() {
    return _buildEntriesList(EntryType.diary);
  }

  Widget _buildEntriesList(EntryType? typeFilter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildLoginRequired();
    }

    // استعلام بسيط فقط بـ userId و type لتجنب الحاجة لـ composite index
    final query = FirebaseFirestore.instance
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'quote_diary');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];

        // تحويل المستندات إلى نماذج
        var entries = docs.map((doc) => EntryModel.fromFirestore(doc)).toList();

        // فلتر النوع من التاب أو من الفلتر (محلياً)
        final effectiveType = typeFilter ?? _filterType;
        if (effectiveType != null) {
          entries = entries.where((e) => e.type == effectiveType).toList();
        }

        // فلتر المفضلة (محلياً)
        if (_showFavoritesOnly) {
          entries = entries.where((e) => e.isFavorite).toList();
        }

        // فلتر الفئة للاقتباسات (محلياً)
        if (_filterCategory != null && (effectiveType == null || effectiveType == EntryType.quote)) {
          entries = entries.where((e) => e.quoteCategory == _filterCategory).toList();
        }

        // فلتر المزاج لليوميات (محلياً)
        if (_filterMood != null && (effectiveType == null || effectiveType == EntryType.diary)) {
          entries = entries.where((e) => e.mood == _filterMood).toList();
        }

        // تطبيق فلتر البحث
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          entries = entries.where((entry) {
            return entry.content.toLowerCase().contains(searchLower) ||
                (entry.title?.toLowerCase().contains(searchLower) ?? false) ||
                (entry.author?.toLowerCase().contains(searchLower) ?? false) ||
                entry.tags.any((tag) => tag.toLowerCase().contains(searchLower));
          }).toList();
        }

        // ترتيب حسب التاريخ (الأحدث أولاً)
        entries.sort((a, b) => b.date.compareTo(a.date));

        if (entries.isEmpty) {
          return _buildEmptyState(typeFilter);
        }

        // اختيار طريقة العرض
        return AnimationLimiter(
          child: _buildEntriesView(entries),
        );
      },
    );
  }

  Widget _buildEntriesView(List<EntryModel> entries) {
    switch (_viewMode) {
      case ViewMode.list:
        return _buildListView(entries);
      case ViewMode.grid:
        return _buildGridView(entries);
      case ViewMode.masonry:
        return _buildMasonryView(entries);
    }
  }

  Widget _buildListView(List<EntryModel> entries) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50,
            child: FadeInAnimation(
              child: _StyledEntryCard(
                entry: entry,
                font: _currentFont,
                onTap: () => _showEntryDetails(entry),
                onFavoriteToggle: () => _toggleFavorite(entry),
                onEdit: () => _showEditDialog(entry),
                onDelete: () => _deleteEntry(entry),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<EntryModel> entries) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: 2,
          duration: const Duration(milliseconds: 375),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _StyledEntryCard(
                entry: entry,
                font: _currentFont,
                isCompact: true,
                onTap: () => _showEntryDetails(entry),
                onFavoriteToggle: () => _toggleFavorite(entry),
                onEdit: () => _showEditDialog(entry),
                onDelete: () => _deleteEntry(entry),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasonryView(List<EntryModel> entries) {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: 2,
          duration: const Duration(milliseconds: 375),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _StyledEntryCard(
                entry: entry,
                font: _currentFont,
                isMasonry: true,
                onTap: () => _showEntryDetails(entry),
                onFavoriteToggle: () => _toggleFavorite(entry),
                onEdit: () => _showEditDialog(entry),
                onDelete: () => _deleteEntry(entry),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'يجب تسجيل الدخول',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(EntryType? type) {
    final icon = type == EntryType.quote
        ? Icons.format_quote
        : type == EntryType.diary
            ? Icons.book
            : Icons.library_books;
    final title = type == EntryType.quote
        ? 'لا توجد اقتباسات'
        : type == EntryType.diary
            ? 'لا توجد يوميات'
            : 'لا توجد مدخلات';
    final subtitle = type == EntryType.quote
        ? 'احفظ اقتباساتك المفضلة'
        : type == EntryType.diary
            ? 'ابدأ بكتابة يومياتك'
            : 'ابدأ بإضافة اقتباس أو يومية';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: _primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(initialType: type),
            icon: const Icon(Icons.add),
            label: Text('إضافة جديد', style: GoogleFonts.tajawal()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog({EntryType? initialType}) {
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        initialType: initialType ?? EntryType.quote,
      ),
    );
  }

  void _showEditDialog(EntryModel entry) {
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(entry: entry),
    );
  }

  void _showEntryDetails(EntryModel entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryDetailsSheet(
        entry: entry,
        font: _currentFont,
        onEdit: () {
          Navigator.pop(context);
          _showEditDialog(entry);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteEntry(entry);
        },
      ),
    );
  }

  Future<void> _toggleFavorite(EntryModel entry) async {
    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(entry.id)
          .update({'isFavorite': !entry.isFavorite});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _deleteEntry(EntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف ${entry.type.arabicName}', style: GoogleFonts.tajawal()),
        content: Text(
          'هل أنت متأكد من حذف هذا ${entry.type.arabicName}؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(entry.id)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم الحذف بنجاح', style: GoogleFonts.tajawal()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e')),
          );
        }
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        currentCategory: _filterCategory,
        currentMood: _filterMood,
        onApply: (category, mood) {
          setState(() {
            _filterCategory = category;
            _filterMood = mood;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _filterCategory = null;
            _filterMood = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Delegate for pinned tab bar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

/// بطاقة مخصصة بالخط المختار
class _StyledEntryCard extends StatelessWidget {
  final EntryModel entry;
  final FontOption font;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isCompact;
  final bool isMasonry;

  const _StyledEntryCard({
    required this.entry,
    required this.font,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.onEdit,
    this.isCompact = false,
    this.isMasonry = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getGradientColor(),
              _getGradientColor().withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getGradientColor().withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isCompact || isMasonry
            ? _buildCompactContent()
            : _buildFullContent(context),
      ),
    );
  }

  Color _getGradientColor() {
    if (entry.isQuote && entry.quoteCategory != null) {
      return entry.quoteCategory!.color;
    } else if (entry.isDiary && entry.mood != null) {
      return entry.mood!.color;
    }
    return entry.type.color;
  }

  Widget _buildCompactContent() {
    final maxLines = isMasonry
        ? (entry.content.length > 150 ? 6 : entry.content.length > 80 ? 4 : 3)
        : 3;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isMasonry ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // النوع والمفضلة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTypeBadge(),
              if (entry.isFavorite)
                const Icon(Icons.favorite, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          // المحتوى
          Text(
            entry.content,
            style: font.getStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry.author != null && entry.isQuote) ...[
            const SizedBox(height: 8),
            Text(
              '— ${entry.author}',
              style: font.getStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          // التاريخ
          Text(
            DateFormat('d MMM', 'ar').format(entry.date),
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الهيدر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTypeBadge(),
                  const SizedBox(width: 8),
                  if (entry.isQuote && entry.quoteCategory != null)
                    _buildCategoryBadge(),
                  if (entry.isDiary && entry.mood != null)
                    _buildMoodBadge(),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // المفضلة
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // القائمة
                  _buildPopupMenu(context),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // أيقونة الاقتباس
          if (entry.isQuote)
            Icon(
              Icons.format_quote,
              color: Colors.white.withValues(alpha: 0.8),
              size: 32,
            ),

          // عنوان اليومية
          if (entry.isDiary && entry.title != null) ...[
            Text(
              entry.title!,
              style: font.getStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),

          // المحتوى بالخط المختار
          Text(
            entry.content,
            style: font.getStyle(
              fontSize: entry.isQuote ? 18 : 15,
              fontStyle: entry.isQuote ? FontStyle.italic : FontStyle.normal,
              color: Colors.white,
              height: 1.6,
            ),
          ),

          // المؤلف (للاقتباسات)
          if (entry.isQuote && entry.author != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.author!,
                    style: font.getStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // المصدر (للاقتباسات)
          if (entry.isQuote && entry.source != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.source!,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // التاجات
          if (entry.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // التاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE، d MMMM yyyy', 'ar').format(entry.date),
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
              if (entry.isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'خاص',
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(entry.type.icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            entry.type.arabicName,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        entry.quoteCategory!.arabicName,
        style: GoogleFonts.tajawal(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMoodBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        entry.mood!.emoji,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 12),
              Text('تعديل', style: GoogleFonts.tajawal()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text('حذف', style: GoogleFonts.tajawal(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

/// صفحة تفاصيل المدخل
class _EntryDetailsSheet extends StatelessWidget {
  final EntryModel entry;
  final FontOption font;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryDetailsSheet({
    required this.entry,
    required this.font,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: entry.type.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          entry.type.icon,
                          color: entry.type.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.type.arabicName,
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE، d MMMM yyyy', 'ar').format(entry.date),
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // العنوان (لليوميات)
                  if (entry.isDiary && entry.title != null) ...[
                    Text(
                      entry.title!,
                      style: font.getStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // المحتوى
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.isQuote)
                          Icon(
                            Icons.format_quote,
                            color: Colors.grey.shade400,
                            size: 28,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          entry.content,
                          style: font.getStyle(
                            fontSize: 16,
                            fontStyle: entry.isQuote ? FontStyle.italic : FontStyle.normal,
                            height: 1.7,
                          ),
                        ),
                        if (entry.isQuote && entry.author != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 2,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                entry.author!,
                                style: font.getStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // المعلومات الإضافية
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (entry.quoteCategory != null)
                        _buildInfoChip(
                          entry.quoteCategory!.arabicName,
                          entry.quoteCategory!.icon,
                          entry.quoteCategory!.color,
                        ),
                      if (entry.mood != null)
                        _buildInfoChip(
                          '${entry.mood!.emoji} ${entry.mood!.arabicName}',
                          entry.mood!.icon,
                          entry.mood!.color,
                        ),
                      if (entry.isFavorite)
                        _buildInfoChip('مفضل', Icons.favorite, Colors.red),
                      if (entry.isPrivate)
                        _buildInfoChip('خاص', Icons.lock, Colors.grey),
                    ],
                  ),

                  // التاجات
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// صفحة الفلاتر
class _FilterSheet extends StatefulWidget {
  final QuoteCategory? currentCategory;
  final DiaryMood? currentMood;
  final Function(QuoteCategory?, DiaryMood?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    this.currentCategory,
    this.currentMood,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  QuoteCategory? _selectedCategory;
  DiaryMood? _selectedMood;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
    _selectedMood = widget.currentMood;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المقبض
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فلاتر متقدمة',
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: widget.onClear,
                child: Text('مسح الكل', style: GoogleFonts.tajawal(color: Colors.red)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // فئات الاقتباسات
          Text(
            'فئة الاقتباس',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuoteCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = isSelected ? null : category;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? category.color : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 16,
                        color: isSelected ? Colors.white : category.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.arabicName,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // المزاج
          Text(
            'المزاج',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: DiaryMood.values.map((mood) {
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMood = isSelected ? null : mood;
                }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? mood.color : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? mood.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        mood.arabicName,
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // زر التطبيق
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_selectedCategory, _selectedMood),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'تطبيق الفلاتر',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
