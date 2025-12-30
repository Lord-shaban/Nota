import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/entry_model.dart';
import 'widgets/entry_card.dart';
import 'widgets/add_entry_dialog.dart';

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

  final _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllEntriesTab(),
                _buildQuotesTab(),
                _buildDiaryTab(),
              ],
            ),
          ),
        ],
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
          // شريط البحث
          Container(
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

    Query query = FirebaseFirestore.instance
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'quote_diary');

    // فلتر النوع من التاب أو من الفلتر
    final effectiveType = typeFilter ?? _filterType;
    if (effectiveType != null) {
      query = query.where('entryType', isEqualTo: effectiveType.name);
    }

    // فلتر المفضلة
    if (_showFavoritesOnly) {
      query = query.where('isFavorite', isEqualTo: true);
    }

    // فلتر الفئة (للاقتباسات)
    if (_filterCategory != null && (effectiveType == null || effectiveType == EntryType.quote)) {
      query = query.where('quoteCategory', isEqualTo: _filterCategory!.name);
    }

    // فلتر المزاج (لليوميات)
    if (_filterMood != null && (effectiveType == null || effectiveType == EntryType.diary)) {
      query = query.where('mood', isEqualTo: _filterMood!.name);
    }

    query = query.orderBy('date', descending: true);

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

        // تطبيق فلتر البحث
        final filteredDocs = docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final entry = EntryModel.fromFirestore(doc);
          final searchLower = _searchQuery.toLowerCase();
          return entry.content.toLowerCase().contains(searchLower) ||
              (entry.title?.toLowerCase().contains(searchLower) ?? false) ||
              (entry.author?.toLowerCase().contains(searchLower) ?? false) ||
              entry.tags.any((tag) => tag.toLowerCase().contains(searchLower));
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(typeFilter);
        }

        return AnimationLimiter(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final entry = EntryModel.fromFirestore(filteredDocs[index]);
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: EntryCard(
                      entry: entry,
                      onTap: () => _showEntryDetails(entry),
                      onFavoriteToggle: () => _toggleFavorite(entry),
                      onEdit: () => _showEditDialog(entry),
                      onDelete: () => _deleteEntry(entry),
                    ),
                  ),
                ),
              );
            },
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

/// صفحة تفاصيل المدخل
class _EntryDetailsSheet extends StatelessWidget {
  final EntryModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryDetailsSheet({
    required this.entry,
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
                      style: GoogleFonts.tajawal(
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
                          style: GoogleFonts.tajawal(
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
                                style: GoogleFonts.tajawal(
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
