import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/entry_model.dart';

/// حوار إضافة/تعديل اقتباس أو يومية
class AddEntryDialog extends StatefulWidget {
  final EntryModel? entry;
  final EntryType initialType;
  final DateTime? initialDate;

  const AddEntryDialog({
    super.key,
    this.entry,
    this.initialType = EntryType.quote,
    this.initialDate,
  });

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _sourceController = TextEditingController();
  final _tagController = TextEditingController();

  late TabController _tabController;

  EntryType _selectedType = EntryType.quote;
  QuoteCategory _selectedQuoteCategory = QuoteCategory.motivation;
  DiaryMood _selectedMood = DiaryMood.neutral;
  DateTime _selectedDate = DateTime.now();
  bool _isFavorite = false;
  bool _isPrivate = true;
  final List<String> _tags = [];
  bool _isLoading = false;

  bool get _isEditing => widget.entry != null;

  static const _primaryColor = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedType = widget.initialType;

    if (_isEditing) {
      _loadEntryData(widget.entry!);
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  void _loadEntryData(EntryModel entry) {
    _contentController.text = entry.content;
    _titleController.text = entry.title ?? '';
    _authorController.text = entry.author ?? '';
    _sourceController.text = entry.source ?? '';
    _selectedType = entry.type;
    _selectedQuoteCategory = entry.quoteCategory ?? QuoteCategory.other;
    _selectedMood = entry.mood ?? DiaryMood.neutral;
    _selectedDate = entry.date;
    _isFavorite = entry.isFavorite;
    _isPrivate = entry.isPrivate;
    _tags.addAll(entry.tags);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _sourceController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTypeSelector(),
            _buildTabs(),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMainTab(),
                  _buildDetailsTab(),
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
            _selectedType.color,
            _selectedType.color.withValues(alpha: 0.8),
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
              _isEditing ? Icons.edit : _selectedType.icon,
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
                  _isEditing
                      ? 'تعديل ${_selectedType.arabicName}'
                      : '${_selectedType.arabicName} جديد${_selectedType == EntryType.diary ? 'ة' : ''}',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
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

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: EntryType.values.map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? type.color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? type.color : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: type.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      size: 20,
                      color: isSelected ? Colors.white : type.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.arabicName,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : type.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.grey.shade100,
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'المحتوى', icon: Icon(Icons.edit_note, size: 20)),
          Tab(text: 'التفاصيل', icon: Icon(Icons.settings, size: 20)),
        ],
      ),
    );
  }

  Widget _buildMainTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان اليومية
            if (_selectedType == EntryType.diary) ...[
              _buildSectionTitle('العنوان', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.tajawal(fontSize: 16),
                decoration: _inputDecoration('عنوان اليومية', Icons.short_text),
              ),
              const SizedBox(height: 20),
            ],

            // المحتوى
            _buildSectionTitle(
              _selectedType == EntryType.quote ? 'نص الاقتباس' : 'ماذا حدث اليوم؟',
              Icons.format_quote,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontStyle: _selectedType == EntryType.quote
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              maxLines: 6,
              decoration: _inputDecoration(
                _selectedType == EntryType.quote
                    ? 'اكتب الاقتباس هنا...'
                    : 'اكتب أفكارك ومشاعرك...',
                Icons.edit,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'المحتوى مطلوب' : null,
            ),

            const SizedBox(height: 20),

            // للاقتباسات: المؤلف والمصدر
            if (_selectedType == EntryType.quote) ...[
              _buildSectionTitle('المؤلف', Icons.person),
              const SizedBox(height: 8),
              TextFormField(
                controller: _authorController,
                style: GoogleFonts.tajawal(),
                decoration: _inputDecoration('اسم الكاتب أو القائل', Icons.person_outline),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('المصدر (اختياري)', Icons.source),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sourceController,
                style: GoogleFonts.tajawal(),
                decoration: _inputDecoration('كتاب، فيلم، إلخ...', Icons.book_outlined),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('الفئة', Icons.category),
              const SizedBox(height: 8),
              _buildCategorySelector(),
            ],

            // لليوميات: المزاج
            if (_selectedType == EntryType.diary) ...[
              _buildSectionTitle('كيف تشعر؟', Icons.mood),
              const SizedBox(height: 8),
              _buildMoodSelector(),
            ],

            const SizedBox(height: 20),

            // التاريخ
            _buildSectionTitle('التاريخ', Icons.calendar_today),
            const SizedBox(height: 8),
            _buildDateSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التاجات
          _buildSectionTitle('التاجات', Icons.tag),
          const SizedBox(height: 8),
          _buildTagsInput(),

          const SizedBox(height: 24),

          // الخيارات
          _buildSectionTitle('الخيارات', Icons.tune),
          const SizedBox(height: 8),

          // المفضلة
          _buildSwitchTile(
            title: 'إضافة للمفضلة',
            subtitle: 'ستظهر في قائمة المفضلة',
            icon: Icons.favorite,
            value: _isFavorite,
            onChanged: (v) => setState(() => _isFavorite = v),
            activeColor: Colors.red,
          ),

          const SizedBox(height: 12),

          // الخصوصية
          _buildSwitchTile(
            title: 'خاص',
            subtitle: 'لن يظهر للآخرين',
            icon: Icons.lock,
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            activeColor: Colors.blue,
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
      children: QuoteCategory.values.map((category) {
        final isSelected = _selectedQuoteCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedQuoteCategory = category),
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
                  size: 16,
                  color: isSelected ? Colors.white : category.color,
                ),
                const SizedBox(width: 6),
                Text(
                  category.arabicName,
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

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: DiaryMood.values.map((mood) {
        final isSelected = _selectedMood == mood;
        return GestureDetector(
          onTap: () => setState(() => _selectedMood = mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? mood.color : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: mood.color,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: mood.color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(fontSize: isSelected ? 28 : 24),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.arabicName,
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : mood.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDate,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_today, size: 20, color: _primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE', 'ar').format(_selectedDate),
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy', 'ar').format(_selectedDate),
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: Colors.grey.shade400),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (value ? activeColor : Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? activeColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
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
              onPressed: _isLoading ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType.color,
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
                          _isEditing ? 'حفظ التعديلات' : 'إضافة',
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _selectedType.color),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final entry = EntryModel(
        id: widget.entry?.id,
        userId: user.uid,
        type: _selectedType,
        content: _contentController.text.trim(),
        title: _selectedType == EntryType.diary && _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        author: _selectedType == EntryType.quote && _authorController.text.trim().isNotEmpty
            ? _authorController.text.trim()
            : null,
        source: _selectedType == EntryType.quote && _sourceController.text.trim().isNotEmpty
            ? _sourceController.text.trim()
            : null,
        quoteCategory: _selectedType == EntryType.quote ? _selectedQuoteCategory : null,
        mood: _selectedType == EntryType.diary ? _selectedMood : null,
        date: _selectedDate,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
        isFavorite: _isFavorite,
        isPrivate: _isPrivate,
        tags: _tags,
      );

      final collection = FirebaseFirestore.instance.collection('notes');

      if (_isEditing && widget.entry!.id != null) {
        await collection.doc(widget.entry!.id).update(entry.toFirestore());
      } else {
        await collection.add(entry.toFirestore());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isEditing
                      ? 'تم التحديث بنجاح'
                      : 'تمت الإضافة بنجاح',
                  style: GoogleFonts.tajawal(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
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
                const SizedBox(width: 12),
                Expanded(child: Text('حدث خطأ: $e', style: GoogleFonts.tajawal())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
