import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// فئات المصروفات
enum ExpenseCategory {
  food, // طعام
  transport, // مواصلات
  shopping, // تسوق
  entertainment, // ترفيه
  health, // صحة
  bills, // فواتير
  education, // تعليم
  housing, // سكن
  personal, // شخصي
  savings, // ادخار
  gifts, // هدايا
  travel, // سفر
  subscriptions, // اشتراكات
  other, // أخرى
}

/// طرق الدفع
enum PaymentMethod {
  cash, // نقدي
  creditCard, // بطاقة ائتمان
  debitCard, // بطاقة خصم
  bankTransfer, // تحويل بنكي
  mobilePayment, // دفع عبر الهاتف
  check, // شيك
  other, // أخرى
}

/// أولوية المصروف
enum ExpensePriority {
  essential, // ضروري
  important, // مهم
  optional, // اختياري
}

/// حالة المصروف المتكرر
enum RecurrenceType {
  none, // غير متكرر
  daily, // يومي
  weekly, // أسبوعي
  monthly, // شهري
  yearly, // سنوي
}

/// امتداد لتحويل ExpenseCategory إلى نص عربي
extension ExpenseCategoryExtension on ExpenseCategory {
  String get arabicName {
    switch (this) {
      case ExpenseCategory.food:
        return 'طعام';
      case ExpenseCategory.transport:
        return 'مواصلات';
      case ExpenseCategory.shopping:
        return 'تسوق';
      case ExpenseCategory.entertainment:
        return 'ترفيه';
      case ExpenseCategory.health:
        return 'صحة';
      case ExpenseCategory.bills:
        return 'فواتير';
      case ExpenseCategory.education:
        return 'تعليم';
      case ExpenseCategory.housing:
        return 'سكن';
      case ExpenseCategory.personal:
        return 'شخصي';
      case ExpenseCategory.savings:
        return 'ادخار';
      case ExpenseCategory.gifts:
        return 'هدايا';
      case ExpenseCategory.travel:
        return 'سفر';
      case ExpenseCategory.subscriptions:
        return 'اشتراكات';
      case ExpenseCategory.other:
        return 'أخرى';
    }
  }

  String get englishName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.housing:
        return 'Housing';
      case ExpenseCategory.personal:
        return 'Personal';
      case ExpenseCategory.savings:
        return 'Savings';
      case ExpenseCategory.gifts:
        return 'Gifts';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.subscriptions:
        return 'Subscriptions';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.health:
        return Icons.medical_services_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.housing:
        return Icons.home_rounded;
      case ExpenseCategory.personal:
        return Icons.person_rounded;
      case ExpenseCategory.savings:
        return Icons.savings_rounded;
      case ExpenseCategory.gifts:
        return Icons.card_giftcard_rounded;
      case ExpenseCategory.travel:
        return Icons.flight_rounded;
      case ExpenseCategory.subscriptions:
        return Icons.subscriptions_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF9800); // برتقالي
      case ExpenseCategory.transport:
        return const Color(0xFF2196F3); // أزرق
      case ExpenseCategory.shopping:
        return const Color(0xFF9C27B0); // بنفسجي
      case ExpenseCategory.entertainment:
        return const Color(0xFFE91E63); // وردي
      case ExpenseCategory.health:
        return const Color(0xFFF44336); // أحمر
      case ExpenseCategory.bills:
        return const Color(0xFF4CAF50); // أخضر
      case ExpenseCategory.education:
        return const Color(0xFF3F51B5); // نيلي
      case ExpenseCategory.housing:
        return const Color(0xFF795548); // بني
      case ExpenseCategory.personal:
        return const Color(0xFF607D8B); // رمادي أزرق
      case ExpenseCategory.savings:
        return const Color(0xFF009688); // تركوازي
      case ExpenseCategory.gifts:
        return const Color(0xFFFF5722); // برتقالي غامق
      case ExpenseCategory.travel:
        return const Color(0xFF00BCD4); // سماوي
      case ExpenseCategory.subscriptions:
        return const Color(0xFF673AB7); // بنفسجي غامق
      case ExpenseCategory.other:
        return const Color(0xFF9E9E9E); // رمادي
    }
  }
}

/// امتداد لتحويل PaymentMethod إلى نص عربي
extension PaymentMethodExtension on PaymentMethod {
  String get arabicName {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
      case PaymentMethod.debitCard:
        return 'بطاقة خصم';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.mobilePayment:
        return 'دفع عبر الهاتف';
      case PaymentMethod.check:
        return 'شيك';
      case PaymentMethod.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.creditCard:
        return Icons.credit_card_rounded;
      case PaymentMethod.debitCard:
        return Icons.payment_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.mobilePayment:
        return Icons.phone_android_rounded;
      case PaymentMethod.check:
        return Icons.receipt_rounded;
      case PaymentMethod.other:
        return Icons.more_horiz_rounded;
    }
  }
}

/// امتداد لتحويل ExpensePriority إلى نص عربي
extension ExpensePriorityExtension on ExpensePriority {
  String get arabicName {
    switch (this) {
      case ExpensePriority.essential:
        return 'ضروري';
      case ExpensePriority.important:
        return 'مهم';
      case ExpensePriority.optional:
        return 'اختياري';
    }
  }

  Color get color {
    switch (this) {
      case ExpensePriority.essential:
        return const Color(0xFFF44336); // أحمر
      case ExpensePriority.important:
        return const Color(0xFFFF9800); // برتقالي
      case ExpensePriority.optional:
        return const Color(0xFF4CAF50); // أخضر
    }
  }
}

/// امتداد لتحويل RecurrenceType إلى نص عربي
extension RecurrenceTypeExtension on RecurrenceType {
  String get arabicName {
    switch (this) {
      case RecurrenceType.none:
        return 'غير متكرر';
      case RecurrenceType.daily:
        return 'يومي';
      case RecurrenceType.weekly:
        return 'أسبوعي';
      case RecurrenceType.monthly:
        return 'شهري';
      case RecurrenceType.yearly:
        return 'سنوي';
    }
  }
}

/// نموذج المصروف
class ExpenseModel {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final ExpensePriority priority;
  final RecurrenceType recurrence;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final String? receiptUrl;
  final String? location;
  final String? vendor;
  final bool isRefunded;
  final double? refundAmount;
  final String? notes;
  final Map<String, dynamic>? metadata;

  ExpenseModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.amount,
    this.currency = 'EGP',
    this.category = ExpenseCategory.other,
    this.paymentMethod = PaymentMethod.cash,
    this.priority = ExpensePriority.optional,
    this.recurrence = RecurrenceType.none,
    required this.date,
    DateTime? createdAt,
    this.updatedAt,
    this.tags = const [],
    this.receiptUrl,
    this.location,
    this.vendor,
    this.isRefunded = false,
    this.refundAmount,
    this.notes,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  /// إنشاء نموذج من بيانات Firestore
  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ExpenseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'EGP',
      category: _categoryFromString(data['category']),
      paymentMethod: _paymentMethodFromString(data['paymentMethod']),
      priority: _priorityFromString(data['priority']),
      recurrence: _recurrenceFromString(data['recurrence']),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      receiptUrl: data['receiptUrl'],
      location: data['location'],
      vendor: data['vendor'],
      isRefunded: data['isRefunded'] ?? false,
      refundAmount: (data['refundAmount'] as num?)?.toDouble(),
      notes: data['notes'],
      metadata: data['metadata'],
    );
  }

  /// إنشاء نموذج من Map
  factory ExpenseModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ExpenseModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'EGP',
      category: _categoryFromString(data['category']),
      paymentMethod: _paymentMethodFromString(data['paymentMethod']),
      priority: _priorityFromString(data['priority']),
      recurrence: _recurrenceFromString(data['recurrence']),
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : data['date'] is DateTime
              ? data['date']
              : DateTime.now(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      receiptUrl: data['receiptUrl'],
      location: data['location'],
      vendor: data['vendor'],
      isRefunded: data['isRefunded'] ?? false,
      refundAmount: (data['refundAmount'] as num?)?.toDouble(),
      notes: data['notes'],
      metadata: data['metadata'],
    );
  }

  /// تحويل النموذج إلى Map لحفظه في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'priority': priority.name,
      'recurrence': recurrence.name,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'tags': tags,
      'receiptUrl': receiptUrl,
      'location': location,
      'vendor': vendor,
      'isRefunded': isRefunded,
      'refundAmount': refundAmount,
      'notes': notes,
      'metadata': metadata,
      'type': 'expense', // للتوافق مع الكود القديم
    };
  }

  /// نسخ النموذج مع تعديلات
  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    ExpensePriority? priority,
    RecurrenceType? recurrence,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? receiptUrl,
    String? location,
    String? vendor,
    bool? isRefunded,
    double? refundAmount,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      location: location ?? this.location,
      vendor: vendor ?? this.vendor,
      isRefunded: isRefunded ?? this.isRefunded,
      refundAmount: refundAmount ?? this.refundAmount,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// المبلغ الفعلي (بعد الاسترداد)
  double get effectiveAmount => isRefunded ? (amount - (refundAmount ?? 0)) : amount;

  /// تنسيق المبلغ
  String get formattedAmount {
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// تنسيق المبلغ الفعلي
  String get formattedEffectiveAmount {
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${effectiveAmount.toStringAsFixed(2)}';
  }

  /// الحصول على رمز العملة
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EGP':
        return 'ج.م ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SAR':
        return 'ر.س ';
      case 'AED':
        return 'د.إ ';
      case 'KWD':
        return 'د.ك ';
      default:
        return '$currency ';
    }
  }

  /// تحويل النص إلى فئة
  static ExpenseCategory _categoryFromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    try {
      return ExpenseCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => ExpenseCategory.other,
      );
    } catch (_) {
      return ExpenseCategory.other;
    }
  }

  /// تحويل النص إلى طريقة دفع
  static PaymentMethod _paymentMethodFromString(String? value) {
    if (value == null) return PaymentMethod.cash;
    try {
      return PaymentMethod.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => PaymentMethod.cash,
      );
    } catch (_) {
      return PaymentMethod.cash;
    }
  }

  /// تحويل النص إلى أولوية
  static ExpensePriority _priorityFromString(String? value) {
    if (value == null) return ExpensePriority.optional;
    try {
      return ExpensePriority.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => ExpensePriority.optional,
      );
    } catch (_) {
      return ExpensePriority.optional;
    }
  }

  /// تحويل النص إلى نوع التكرار
  static RecurrenceType _recurrenceFromString(String? value) {
    if (value == null) return RecurrenceType.none;
    try {
      return RecurrenceType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => RecurrenceType.none,
      );
    } catch (_) {
      return RecurrenceType.none;
    }
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, title: $title, amount: $amount, category: ${category.arabicName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
