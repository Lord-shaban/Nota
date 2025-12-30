import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

/// حوار إضافة/تعديل مصروف
/// يوفر واجهة متقدمة لإدخال تفاصيل المصروف
class AddExpenseDialog extends StatefulWidget {
  final ExpenseModel? expense; // للتعديل
  final DateTime? initialDate;

  const AddExpenseDialog({
    super.key,
    this.expense,
    this.initialDate,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();

  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  ExpensePriority _selectedPriority = ExpensePriority.optional;
  RecurrenceType _selectedRecurrence = RecurrenceType.none;
  String _selectedCurrency = 'EGP';
  final List<String> _tags = [];

  bool _isLoading = false;

  final List<String> _currencies = [
    'EGP',
    'USD',
    'EUR',
    'GBP',
    'SAR',
    'AED',
    'KWD',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.expense != null) {
      _loadExpenseData(widget.expense!);
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  void _loadExpenseData(ExpenseModel expense) {
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toString();
    _descriptionController.text = expense.description ?? '';
    _vendorController.text = expense.vendor ?? '';
    _locationController.text = expense.location ?? '';
    _notesController.text = expense.notes ?? '';
    _selectedDate = expense.date;
    _selectedTime = TimeOfDay.fromDateTime(expense.date);
    _selectedCategory = expense.category;
    _selectedPaymentMethod = expense.paymentMethod;
    _selectedPriority = expense.priority;
    _selectedRecurrence = expense.recurrence;
    _selectedCurrency = expense.currency;
    _tags.addAll(expense.tags);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.expense != null;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الهيدر
            _buildHeader(context, isEditing),

            // التابات
            _buildTabBar(),

            // المحتوى
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(context),
                  _buildAdvancedTab(context),
                ],
              ),
            ),

            // الأزرار السفلية
            _buildBottomButtons(context, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedCategory.color,
            _selectedCategory.color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing
                  ? Icons.edit_rounded
                  : Icons.add_card_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'تعديل المصروف' : 'إضافة مصروف جديد',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat.yMMMEd('ar').format(_selectedDate),
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _selectedCategory.color.withOpacity(0.1),
      child: TabBar(
        controller: _tabController,
        labelColor: _selectedCategory.color,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _selectedCategory.color,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline_rounded),
            text: 'معلومات أساسية',
          ),
          Tab(
            icon: Icon(Icons.settings_rounded),
            text: 'خيارات متقدمة',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حقل العنوان
            _buildSectionTitle('العنوان'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _buildInputDecoration(
                hintText: 'مثال: غداء في مطعم',
                prefixIcon: Icons.title_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال عنوان المصروف';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // حقل المبلغ والعملة
            _buildSectionTitle('المبلغ'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: _buildInputDecoration(
                      hintText: '0.00',
                      prefixIcon: Icons.attach_money_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال المبلغ';
                      }
                      if (double.tryParse(value) == null) {
                        return 'مبلغ غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: _buildInputDecoration(),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(
                          currency,
                          style: GoogleFonts.tajawal(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCurrency = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // الفئة
            _buildSectionTitle('الفئة'),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 20),

            // طريقة الدفع
            _buildSectionTitle('طريقة الدفع'),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 20),

            // التاريخ والوقت
            _buildSectionTitle('التاريخ والوقت'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeButton(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat.yMMMd('ar').format(_selectedDate),
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeButton(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // الوصف (اختياري)
            _buildSectionTitle('الوصف (اختياري)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _buildInputDecoration(
                hintText: 'أضف وصفاً للمصروف...',
                prefixIcon: Icons.description_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الأولوية
          _buildSectionTitle('الأولوية'),
          const SizedBox(height: 8),
          _buildPrioritySelector(),
          const SizedBox(height: 20),

          // التكرار
          _buildSectionTitle('التكرار'),
          const SizedBox(height: 8),
          _buildRecurrenceSelector(),
          const SizedBox(height: 20),

          // البائع/المتجر
          _buildSectionTitle('البائع/المتجر (اختياري)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _vendorController,
            decoration: _buildInputDecoration(
              hintText: 'مثال: كارفور',
              prefixIcon: Icons.store_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // الموقع
          _buildSectionTitle('الموقع (اختياري)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            decoration: _buildInputDecoration(
              hintText: 'مثال: القاهرة',
              prefixIcon: Icons.location_on_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // التاجات
          _buildSectionTitle('التاجات'),
          const SizedBox(height: 8),
          _buildTagsInput(),
          const SizedBox(height: 20),

          // ملاحظات
          _buildSectionTitle('ملاحظات (اختياري)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: _buildInputDecoration(
              hintText: 'أضف ملاحظات إضافية...',
              prefixIcon: Icons.note_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.tajawal(color: Colors.grey.shade400),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _selectedCategory.color)
          : null,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _selectedCategory.color,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemCount: ExpenseCategory.values.length,
        itemBuilder: (context, index) {
          final category = ExpenseCategory.values[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color
                    : category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : category.color.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? Colors.white : category.color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.arabicName,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : category.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((method) {
        final isSelected = method == _selectedPaymentMethod;
        return InkWell(
          onTap: () => setState(() => _selectedPaymentMethod = method),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedCategory.color
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? _selectedCategory.color
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  method.icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  method.arabicName,
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
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: ExpensePriority.values.map((priority) {
        final isSelected = priority == _selectedPriority;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? priority.color
                    : priority.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: priority.color,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                priority.arabicName,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : priority.color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecurrenceSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecurrenceType.values.map((recurrence) {
        final isSelected = recurrence == _selectedRecurrence;
        return InkWell(
          onTap: () => setState(() => _selectedRecurrence = recurrence),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedCategory.color
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? _selectedCategory.color
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              recurrence.arabicName,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: _selectedCategory.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: _buildInputDecoration(
                  hintText: 'أضف تاج...',
                  prefixIcon: Icons.tag_rounded,
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: Icon(
                Icons.add_circle_rounded,
                color: _selectedCategory.color,
                size: 32,
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(
                  '#$tag',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: _selectedCategory.color,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _tags.remove(tag)),
                backgroundColor: _selectedCategory.color.withOpacity(0.1),
                side: BorderSide(
                  color: _selectedCategory.color.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // زر الإلغاء
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // زر الحفظ
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedCategory.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: _selectedCategory.color.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditing
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'حفظ التعديلات' : 'إضافة المصروف',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedCategory.color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedCategory.color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final expenseDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final expense = ExpenseModel(
        id: widget.expense?.id,
        userId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        priority: _selectedPriority,
        recurrence: _selectedRecurrence,
        date: expenseDate,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: widget.expense != null ? DateTime.now() : null,
        tags: _tags,
        vendor: _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final collection = FirebaseFirestore.instance.collection('notes');

      if (widget.expense != null && widget.expense!.id != null) {
        // تعديل مصروف موجود
        await collection.doc(widget.expense!.id).update(expense.toFirestore());
      } else {
        // إضافة مصروف جديد
        await collection.add(expense.toFirestore());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.expense != null
                      ? 'تم تحديث المصروف بنجاح'
                      : 'تم إضافة المصروف بنجاح',
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'حدث خطأ: $e',
                    style: GoogleFonts.tajawal(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
