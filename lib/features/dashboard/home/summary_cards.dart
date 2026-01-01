import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// بطاقات الملخص - تعرض إحصائيات سريعة لكل قسم
class SummaryCards extends StatelessWidget {
  final VoidCallback onTapTasks;
  final VoidCallback onTapAppointments;
  final VoidCallback onTapExpenses;
  final VoidCallback onTapQuotes;

  const SummaryCards({
    super.key,
    required this.onTapTasks,
    required this.onTapAppointments,
    required this.onTapExpenses,
    required this.onTapQuotes,
  });

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedStreams(),
      builder: (context, snapshot) {
        int pendingTasks = 0;
        int upcomingAppointments = 0;
        double totalExpenses = 0;
        int quotesCount = 0;

        if (snapshot.hasData) {
          // Tasks count
          final tasksSnapshot = snapshot.data![0];
          pendingTasks = tasksSnapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['completed'] != true;
          }).length;

          // Appointments count
          final appointmentsSnapshot = snapshot.data![1];
          final now = DateTime.now();
          upcomingAppointments = appointmentsSnapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
            return dateTime != null && dateTime.isAfter(now) && data['status'] != 'completed';
          }).length;

          // Expenses sum (this month)
          final expensesSnapshot = snapshot.data![2];
          final monthStart = DateTime(now.year, now.month, 1);
          for (var doc in expensesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();
            if (date != null && date.isAfter(monthStart)) {
              totalExpenses += (data['amount'] ?? 0).toDouble();
            }
          }

          // Quotes count
          final quotesSnapshot = snapshot.data![3];
          quotesCount = quotesSnapshot.docs.length;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _SummaryCard(
              title: 'المهام المعلقة',
              value: pendingTasks.toString(),
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFF58CC02),
              onTap: onTapTasks,
            ),
            _SummaryCard(
              title: 'المواعيد القادمة',
              value: upcomingAppointments.toString(),
              icon: Icons.event_available_rounded,
              color: const Color(0xFFFFB800),
              onTap: onTapAppointments,
            ),
            _SummaryCard(
              title: 'مصروفات الشهر',
              value: totalExpenses.toStringAsFixed(0),
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.blue,
              subtitle: 'ر.س',
              onTap: onTapExpenses,
            ),
            _SummaryCard(
              title: 'الاقتباسات',
              value: quotesCount.toString(),
              icon: Icons.format_quote_rounded,
              color: Colors.purple,
              onTap: onTapQuotes,
            ),
          ],
        );
      },
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedStreams() async* {
    final firestore = FirebaseFirestore.instance;

    // Listen to tasks
    final tasksStream = firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .where('type', isEqualTo: 'task')
        .snapshots();

    // Listen to appointments
    final appointmentsStream = firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .snapshots();

    // Listen to expenses
    final expensesStream = firestore
        .collection('expenses')
        .where('userId', isEqualTo: _userId)
        .snapshots();

    // Listen to quotes
    final quotesStream = firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .where('type', isEqualTo: 'quote')
        .snapshots();

    await for (final tasks in tasksStream) {
      final appointments = await appointmentsStream.first;
      final expenses = await expensesStream.first;
      final quotes = await quotesStream.first;
      yield [tasks, appointments, expenses, quotes];
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.tajawal(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
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
        ),
      ),
    );
  }
}
