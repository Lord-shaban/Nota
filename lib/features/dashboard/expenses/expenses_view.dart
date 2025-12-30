import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/expense_model.dart';
import 'widgets/expense_card.dart';
import 'widgets/expense_statistics.dart';
import 'widgets/add_expense_dialog.dart';
import 'widgets/expense_details_dialog.dart';

/// صفحة عرض المصروفات الرئيسية
/// تعرض قائمة المصروفات مع الفلاتر والإحصائيات
class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // الفلاتر
  String _selectedPeriod = 'month';
  ExpenseCategory? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  String _searchQuery = '';
  bool _isSearching = false;

  // التحكم بالبحث
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildLoginRequired(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // AppBar مخصص
            _buildSliverAppBar(context),
          ];
        },
        body: Column(
          children: [
            // تابات
            _buildTabBar(),

            // المحتوى
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // تاب قائمة المصروفات
                  _buildExpensesList(user.uid),

                  // تاب الإحصائيات
                  _buildStatisticsTab(user.uid),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF667eea),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isSearching) ...[
                    Text(
                      'المصروفات',
                      style: GoogleFonts.tajawal(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تتبع وإدارة مصروفاتك اليومية',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // زر البحث
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              } else {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _searchFocusNode.requestFocus();
                });
              }
            });
          },
        ),

        // زر الفلتر
        IconButton(
          icon: Badge(
            isLabelVisible: _selectedCategory != null || _selectedPaymentMethod != null,
            child: const Icon(Icons.filter_list_rounded, color: Colors.white),
          ),
          onPressed: () => _showFilterSheet(context),
        ),
      ],
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.tajawal(color: Colors.white),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث في المصروفات...',
                    hintStyle: GoogleFonts.tajawal(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF667eea),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt_rounded),
            text: 'المصروفات',
          ),
          Tab(
            icon: Icon(Icons.bar_chart_rounded),
            text: 'الإحصائيات',
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(String userId) {
    return Column(
      children: [
        // فلتر الفترة
        const SizedBox(height: 16),
        PeriodFilter(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
        ),
        const SizedBox(height: 12),

        // فلتر الفئة (اختياري)
        CategoryFilter(
          selectedCategory: _selectedCategory,
          onCategoryChanged: (category) =>
              setState(() => _selectedCategory = category),
        ),
        const SizedBox(height: 16),

        // قائمة المصروفات
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getExpensesStream(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF667eea),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final docs = snapshot.data?.docs ?? [];
              final expenses = docs
                  .map((doc) => ExpenseModel.fromFirestore(doc))
                  .where((expense) => _filterExpense(expense))
                  .toList();

              // ترتيب حسب التاريخ
              expenses.sort((a, b) => b.date.compareTo(a.date));

              if (expenses.isEmpty) {
                return _buildEmptyState(context);
              }

              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 100,
                  ),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: ExpenseCard(
                            expense: expense,
                            onTap: () => _showExpenseDetails(context, expense),
                            onEdit: () => _editExpense(context, expense),
                            onDelete: () => _deleteExpense(context, expense),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getExpensesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF667eea),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];
        final expenses = docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .where((expense) => _filterExpenseByPeriod(expense))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 100,
          ),
          child: ExpenseStatistics(
            expenses: expenses,
            period: _getPeriodLabel(),
          ),
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _addNewExpense(context),
      backgroundColor: const Color(0xFF667eea),
      elevation: 8,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'إضافة مصروف',
        style: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'يجب تسجيل الدخول',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سجل دخولك لعرض مصروفاتك',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 70,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد مصروفات',
            style: GoogleFonts.tajawal(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة مصروفاتك لتتبع إنفاقك',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addNewExpense(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'إضافة مصروف',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 70,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'حدث خطأ',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // دوال البيانات
  Stream<QuerySnapshot> _getExpensesStream(String userId) {
    // استعلام بسيط لتجنب مشاكل Firestore indexes
    return FirebaseFirestore.instance
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'expense')
        .snapshots();
  }

  bool _filterExpense(ExpenseModel expense) {
    // فلتر الفترة
    if (!_filterExpenseByPeriod(expense)) return false;

    // فلتر الفئة
    if (_selectedCategory != null && expense.category != _selectedCategory) {
      return false;
    }

    // فلتر طريقة الدفع
    if (_selectedPaymentMethod != null &&
        expense.paymentMethod != _selectedPaymentMethod) {
      return false;
    }

    // فلتر البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final matchesTitle = expense.title.toLowerCase().contains(query);
      final matchesDesc =
          expense.description?.toLowerCase().contains(query) ?? false;
      final matchesVendor =
          expense.vendor?.toLowerCase().contains(query) ?? false;
      final matchesTags = expense.tags.any((tag) =>
          tag.toLowerCase().contains(query));

      if (!matchesTitle && !matchesDesc && !matchesVendor && !matchesTags) {
        return false;
      }
    }

    return true;
  }

  bool _filterExpenseByPeriod(ExpenseModel expense) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case 'today':
        final expenseDate = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        return expenseDate == today;

      case 'week':
        final weekAgo = today.subtract(const Duration(days: 7));
        return expense.date.isAfter(weekAgo);

      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return expense.date.isAfter(monthAgo);

      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return expense.date.isAfter(yearAgo);

      case 'all':
      default:
        return true;
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'year':
        return 'هذه السنة';
      case 'all':
      default:
        return 'كل الوقت';
    }
  }

  // دوال الإجراءات
  void _addNewExpense(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (result == true && mounted) {
      // تم إضافة المصروف بنجاح
    }
  }

  void _showExpenseDetails(BuildContext context, ExpenseModel expense) async {
    await showDialog(
      context: context,
      builder: (context) => ExpenseDetailsDialog(expense: expense),
    );
  }

  void _editExpense(BuildContext context, ExpenseModel expense) async {
    await showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    );
  }

  Future<void> _deleteExpense(BuildContext context, ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(
              'تأكيد الحذف',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${expense.title}"؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(expense.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'تم حذف المصروف',
                    style: GoogleFonts.tajawal(),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedPaymentMethod: _selectedPaymentMethod,
        onApply: (category, paymentMethod) {
          setState(() {
            _selectedCategory = category;
            _selectedPaymentMethod = paymentMethod;
          });
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedCategory = null;
            _selectedPaymentMethod = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Bottom Sheet للفلترة
class _FilterBottomSheet extends StatefulWidget {
  final ExpenseCategory? selectedCategory;
  final PaymentMethod? selectedPaymentMethod;
  final Function(ExpenseCategory?, PaymentMethod?) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedPaymentMethod,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  ExpenseCategory? _category;
  PaymentMethod? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _paymentMethod = widget.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // العنوان
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تصفية المصروفات',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: widget.onReset,
                  child: Text(
                    'إعادة تعيين',
                    style: GoogleFonts.tajawal(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // الفئة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الفئة',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((category) {
                    final isSelected = _category == category;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(category.arabicName),
                      avatar: Icon(
                        category.icon,
                        size: 18,
                        color: isSelected ? Colors.white : category.color,
                      ),
                      backgroundColor: category.color.withOpacity(0.1),
                      selectedColor: category.color,
                      labelStyle: GoogleFonts.tajawal(
                        color: isSelected ? Colors.white : category.color,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _category = selected ? category : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // طريقة الدفع
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طريقة الدفع',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _paymentMethod == method;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(method.arabicName),
                      avatar: Icon(
                        method.icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF667eea),
                      ),
                      backgroundColor:
                          const Color(0xFF667eea).withOpacity(0.1),
                      selectedColor: const Color(0xFF667eea),
                      labelStyle: GoogleFonts.tajawal(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF667eea),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _paymentMethod = selected ? method : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // زر التطبيق
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_category, _paymentMethod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'تطبيق الفلتر',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // مساحة آمنة للأسفل
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
