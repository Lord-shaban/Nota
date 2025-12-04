import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Search Functionality
/// Provides local search among all user's notes and data
class SearchFunctionality extends StatefulWidget {
  const SearchFunctionality({super.key});

  @override
  State<SearchFunctionality> createState() => _SearchFunctionalityState();
}

class _SearchFunctionalityState extends State<SearchFunctionality> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // all, notes, tasks, expenses, appointments

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),

          // Search Results
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CategoryChip(
            label: 'All',
            icon: Icons.apps,
            isSelected: _selectedCategory == 'all',
            onTap: () => setState(() => _selectedCategory = 'all'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Notes',
            icon: Icons.note_outlined,
            isSelected: _selectedCategory == 'notes',
            onTap: () => setState(() => _selectedCategory = 'notes'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Tasks',
            icon: Icons.task_alt_outlined,
            isSelected: _selectedCategory == 'tasks',
            onTap: () => setState(() => _selectedCategory = 'tasks'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Expenses',
            icon: Icons.attach_money_outlined,
            isSelected: _selectedCategory == 'expenses',
            onTap: () => setState(() => _selectedCategory = 'expenses'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Appointments',
            icon: Icons.calendar_today_outlined,
            isSelected: _selectedCategory == 'appointments',
            onTap: () => setState(() => _selectedCategory = 'appointments'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please login to search'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedCategory == 'all' || _selectedCategory == 'notes')
            _buildNotesResults(user.uid),
          if (_selectedCategory == 'all' || _selectedCategory == 'tasks')
            _buildTasksResults(user.uid),
          if (_selectedCategory == 'all' || _selectedCategory == 'expenses')
            _buildExpensesResults(user.uid),
          if (_selectedCategory == 'all' ||
              _selectedCategory == 'appointments')
            _buildAppointmentsResults(user.uid),
        ],
      ),
    );
  }

  Widget _buildNotesResults(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final content = (data['content'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || content.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          'Notes',
          Icons.note_outlined,
          Colors.blue,
          docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _SearchResultCard(
              icon: Icons.note_outlined,
              color: Colors.blue,
              title: data['title'] ?? 'Untitled',
              subtitle: data['content'] ?? '',
              onTap: () {
                // TODO: Navigate to note detail
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTasksResults(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final description =
              (data['description'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) ||
              description.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          'Tasks',
          Icons.task_alt_outlined,
          Colors.green,
          docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _SearchResultCard(
              icon: Icons.task_alt_outlined,
              color: Colors.green,
              title: data['title'] ?? 'Untitled',
              subtitle: data['description'] ?? '',
              trailing: data['isCompleted'] == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                // TODO: Navigate to task detail
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildExpensesResults(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final category = (data['category'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) ||
              category.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          'Expenses',
          Icons.attach_money_outlined,
          Colors.orange,
          docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
            return _SearchResultCard(
              icon: Icons.attach_money_outlined,
              color: Colors.orange,
              title: data['title'] ?? 'Untitled',
              subtitle: data['category'] ?? '',
              trailing: Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              onTap: () {
                // TODO: Navigate to expense detail
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentsResults(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) ||
              location.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          'Appointments',
          Icons.calendar_today_outlined,
          Colors.purple,
          docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
            return _SearchResultCard(
              icon: Icons.calendar_today_outlined,
              color: Colors.purple,
              title: data['title'] ?? 'Untitled',
              subtitle: dateTime != null ? _formatDateTime(dateTime) : '',
              onTap: () {
                // TODO: Navigate to appointment detail
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${children.length})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Search your notes, tasks, and more',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Category Chip Widget
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search Result Card Widget
class _SearchResultCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
