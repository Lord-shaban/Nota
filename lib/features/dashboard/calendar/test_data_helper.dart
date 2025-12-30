import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// أداة لإضافة بيانات تجريبية للمواعيد
class AppointmentTestData {
  /// إضافة مواعيد تجريبية
  static Future<void> addSampleAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ يرجى تسجيل الدخول أولاً');
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    final samples = [
      // موعد قريب - خلال ساعة
      {
        'title': 'اجتماع فريق التطوير',
        'description': 'مناقشة التحديثات والخطة المستقبلية',
        'location': 'قاعة الاجتماعات',
        'type': 'meeting',
        'dateTime': Timestamp.fromDate(now.add(const Duration(hours: 1))),
      },
      // موعد اليوم
      {
        'title': 'موعد طبيب الأسنان',
        'description': 'فحص دوري',
        'location': 'عيادة د. أحمد',
        'type': 'doctor',
        'dateTime': Timestamp.fromDate(now.add(const Duration(hours: 3))),
      },
      // موعد غداً
      {
        'title': 'مقابلة عمل',
        'description': 'مقابلة لوظيفة مطور Flutter',
        'location': 'برج المملكة',
        'type': 'work',
        'dateTime': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 1, 10, 0),
        ),
      },
      // حدث بعد يومين
      {
        'title': 'حفل تخرج',
        'description': 'احتفال بالتخرج',
        'location': 'قاعة المؤتمرات',
        'type': 'event',
        'dateTime': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 2, 18, 0),
        ),
      },
      // موعد شخصي
      {
        'title': 'جلسة رياضية',
        'description': 'تمارين في النادي',
        'location': 'النادي الرياضي',
        'type': 'personal',
        'dateTime': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 3, 17, 0),
        ),
      },
      // تذكير
      {
        'title': 'تجديد الرخصة',
        'description': 'تجديد رخصة القيادة',
        'location': 'إدارة المرور',
        'type': 'reminder',
        'dateTime': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 5, 9, 0),
        ),
      },
      // موعد سابق (أمس)
      {
        'title': 'اجتماع العميل',
        'description': 'مناقشة متطلبات المشروع',
        'location': 'مقهى ستاربكس',
        'type': 'meeting',
        'dateTime': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 1, 11, 0),
        ),
        'isCompleted': true,
      },
    ];

    try {
      print('🔄 جاري إضافة المواعيد التجريبية...');

      for (var apt in samples) {
        await firestore.collection('appointments').add({
          ...apt,
          'userId': user.uid,
          'notes': '',
          'attendees': <String>[],
          'isCompleted': apt['isCompleted'] ?? false,
          'createdAt': Timestamp.now(),
        });
      }

      print('✅ تم إضافة ${samples.length} موعد بنجاح!');
    } catch (e) {
      print('❌ خطأ: $e');
    }
  }

  /// حذف جميع المواعيد
  static Future<void> clearAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ تم حذف ${snapshot.docs.length} موعد');
    } catch (e) {
      print('❌ خطأ: $e');
    }
  }
}
