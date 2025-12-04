import 'package:flutter/material.dart';

/// Stats Grid Widget
/// Displays statistics in a grid layout
class StatsGrid extends StatelessWidget {
  final int totalNotes;
  final int totalTasks;
  final int completedTasks;
  final int totalExpenses;
  final double totalAmount;
  final int upcomingAppointments;

  const StatsGrid({
    super.key,
    this.totalNotes = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalExpenses = 0,
    this.totalAmount = 0.0,
    this.upcomingAppointments = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                icon: Icons.note_outlined,
                title: 'Total Notes',
                value: totalNotes.toString(),
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.task_alt_outlined,
                title: 'Tasks',
                value: '$completedTasks/$totalTasks',
                color: Colors.green,
                subtitle: 'completed',
              ),
              _StatCard(
                icon: Icons.attach_money_outlined,
                title: 'Expenses',
                value: totalExpenses.toString(),
                color: Colors.orange,
                subtitle: '\$${totalAmount.toStringAsFixed(2)}',
              ),
              _StatCard(
                icon: Icons.calendar_today_outlined,
                title: 'Appointments',
                value: upcomingAppointments.toString(),
                color: Colors.purple,
                subtitle: 'upcoming',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual Stat Card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
          // Icon and Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),

          // Value and Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact Stats Row (alternative layout)
class CompactStatsRow extends StatelessWidget {
  final int notesCount;
  final int tasksCount;
  final int expensesCount;

  const CompactStatsRow({
    super.key,
    this.notesCount = 0,
    this.tasksCount = 0,
    this.expensesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactStatItem(
            icon: Icons.note_outlined,
            count: notesCount,
            label: 'Notes',
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _CompactStatItem(
            icon: Icons.task_alt_outlined,
            count: tasksCount,
            label: 'Tasks',
            color: Colors.green,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _CompactStatItem(
            icon: Icons.attach_money_outlined,
            count: expensesCount,
            label: 'Expenses',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
