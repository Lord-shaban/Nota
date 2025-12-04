import 'package:flutter/material.dart';

/// Quick Actions Widget
/// Provides quick access to common actions
class QuickActions extends StatelessWidget {
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddAppointment;

  const QuickActions({
    super.key,
    this.onAddNote,
    this.onAddTask,
    this.onAddExpense,
    this.onAddAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickActionButton(
                icon: Icons.note_add_outlined,
                label: 'Add Note',
                color: Colors.blue,
                onTap: onAddNote ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add note feature coming soon!'),
                        ),
                      );
                    },
              ),
              _QuickActionButton(
                icon: Icons.add_task_outlined,
                label: 'Add Task',
                color: Colors.green,
                onTap: onAddTask ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add task feature coming soon!'),
                        ),
                      );
                    },
              ),
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add Expense',
                color: Colors.orange,
                onTap: onAddExpense ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add expense feature coming soon!'),
                        ),
                      );
                    },
              ),
              _QuickActionButton(
                icon: Icons.event_available_outlined,
                label: 'Schedule',
                color: Colors.purple,
                onTap: onAddAppointment ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Schedule feature coming soon!'),
                        ),
                      );
                    },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Action Button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal Quick Actions (alternative layout)
class HorizontalQuickActions extends StatelessWidget {
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;

  const HorizontalQuickActions({
    super.key,
    this.onAddNote,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.note_add_outlined,
              label: 'Add Note',
              color: Colors.blue,
              onTap: onAddNote ?? () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.add_task_outlined,
              label: 'Add Task',
              color: Colors.green,
              onTap: onAddTask ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Quick Actions Menu
class FloatingQuickActionsMenu extends StatefulWidget {
  final VoidCallback? onAddNote;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddExpense;

  const FloatingQuickActionsMenu({
    super.key,
    this.onAddNote,
    this.onAddTask,
    this.onAddExpense,
  });

  @override
  State<FloatingQuickActionsMenu> createState() =>
      _FloatingQuickActionsMenuState();
}

class _FloatingQuickActionsMenuState extends State<FloatingQuickActionsMenu>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FloatingActionItem(
                icon: Icons.note_add_outlined,
                label: 'Note',
                onTap: () {
                  _toggle();
                  widget.onAddNote?.call();
                },
              ),
              const SizedBox(height: 12),
              _FloatingActionItem(
                icon: Icons.add_task_outlined,
                label: 'Task',
                onTap: () {
                  _toggle();
                  widget.onAddTask?.call();
                },
              ),
              const SizedBox(height: 12),
              _FloatingActionItem(
                icon: Icons.add_circle_outline,
                label: 'Expense',
                onTap: () {
                  _toggle();
                  widget.onAddExpense?.call();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _FloatingActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FloatingActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}
