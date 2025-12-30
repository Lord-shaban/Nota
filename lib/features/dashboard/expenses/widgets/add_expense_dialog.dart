import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

/// حوار إضافة/تعديل مصروف محسّن
/// متوافق مع تصميم باقي التطبيق
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

  bool get _isEditing => widget.expense != null;

  // الألوان الرئيسية - متوافقة مع التطبيق
  static const _primaryColor = Color(0xFF6366F1);

  final List<String> _currencies = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED', 'KWD'];

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabs(),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildAdvancedTab(),
                ],
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedCategory.color,
            _selectedCategory.color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing ? Icons.edit : Icons.add_card,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'تعديل المصروف' : 'مصروف جديد',
                  style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('EEEE، d MMMM', 'ar').format(_selectedDate),
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.grey.shade50,
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'المعلومات الأساسية', icon: Icon(Icons.info_outline, size: 20)),
          Tab(text: 'تفاصيل إضافية', icon: Icon(Icons.settings, size: 20)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حقل العنوان
            _buildSectionTitle('العنوان', Icons.title),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: GoogleFonts.tajawal(fontSize: 16),
              decoration: _inputDecoration('أدخل عنوان المصروف', Icons.receipt),
              validator: (v) => v?.isEmpty ?? true ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 20),

            // حقل المبلغ والعملة
            _buildSectionTitle('المبلغ', Icons.attach_money),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: _inputDecoration('0.00', Icons.payments),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'المبلغ مطلوب';
                      if (double.tryParse(v!) == null) return 'مبلغ غير صحيح';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _currencies.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // الفئة
            _buildSectionTitle('الفئة', Icons.category),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 20),

            // طريقة الدفع
            _buildSectionTitle('طريقة الدفع', Icons.payment),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 20),

            // التاريخ والوقت
            _buildSectionTitle('التاريخ والوقت', Icons.schedule),
            const SizedBox(height: 8),
            _buildDateTimeSection(),
            const SizedBox(height: 20),

            // الوصف
            _buildSectionTitle('الوصف (اختياري)', Icons.description),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              style: GoogleFonts.tajawal(),
              decoration: _inputDecoration('أضف وصفاً للمصروف...', Icons.description_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الأولوية
          _buildSectionTitle('الأولوية', Icons.flag),
          const SizedBox(height: 8),
          _buildPrioritySelector(),
          const SizedBox(height: 20),

          // التكرار
          _buildSectionTitle('التكرار', Icons.repeat),
          const SizedBox(height: 8),
          _buildRecurrenceSelector(),
          const SizedBox(height: 20),

          // البائع/المتجر
          _buildSectionTitle('البائع/المتجر', Icons.store),
          const SizedBox(height: 8),
          TextFormField(
            controller: _vendorController,
            style: GoogleFonts.tajawal(),
            decoration: _inputDecoration('مثال: كارفور (اختياري)', Icons.store_outlined),
          ),
          const SizedBox(height: 20),

          // الموقع
          _buildSectionTitle('الموقع', Icons.location_on),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            style: GoogleFonts.tajawal(),
            decoration: _inputDecoration('أضف الموقع (اختياري)', Icons.location_on_outlined),
          ),
          const SizedBox(height: 20),

          // التاجات
          _buildSectionTitle('التاجات', Icons.tag),
          const SizedBox(height: 8),
          _buildTagsInput(),
          const SizedBox(height: 20),

          // ملاحظات
          _buildSectionTitle('ملاحظات', Icons.note),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            style: GoogleFonts.tajawal(),
            maxLines: 2,
            decoration: _inputDecoration('أضف ملاحظات (اختياري)', Icons.note_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.tajawal(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? category.color : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category.color : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: category.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  category.arabicName,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
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

  Widget _buildPaymentMethodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((method) {
        final isSelected = _selectedPaymentMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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
                    fontSize: 13,
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
        final isSelected = _selectedPriority == priority;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? priority.color : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: priority.color,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: priority.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    _getPriorityIcon(priority),
                    size: 20,
                    color: isSelected ? Colors.white : priority.color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priority.arabicName,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : priority.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPriorityIcon(ExpensePriority priority) {
    switch (priority) {
      case ExpensePriority.essential:
        return Icons.priority_high;
      case ExpensePriority.important:
        return Icons.arrow_upward;
      case ExpensePriority.optional:
        return Icons.arrow_downward;
    }
  }

  Widget _buildRecurrenceSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecurrenceType.values.map((recurrence) {
        final isSelected = _selectedRecurrence == recurrence;
        return GestureDetector(
          onTap: () => setState(() => _selectedRecurrence = recurrence),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              recurrence.arabicName,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        // التاريخ
        Expanded(
          child: InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_today, size: 18, color: _primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التاريخ',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM', 'ar').format(_selectedDate),
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // الوقت
        Expanded(
          child: InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.access_time, size: 18, color: _primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوقت',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          _selectedTime.format(context),
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                style: GoogleFonts.tajawal(),
                decoration: _inputDecoration('أضف تاج...', Icons.tag),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _addTag,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: Icon(Icons.close, size: 16, color: _primaryColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
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
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isEditing ? Icons.save : Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'حفظ التعديلات' : 'إضافة المصروف',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
