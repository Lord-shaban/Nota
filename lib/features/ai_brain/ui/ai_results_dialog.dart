// ai_results_dialog.dart
// ------------------------------------------------------------
// Path: lib/components/ai_brain/ui/ai_results_dialog.dart
// Displays AI analysis results with categorized data
// Shows confidence scores, extracted details, and actions
// Created by Student 4
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import '../models/ai_models.dart';

/// Dialog showing AI analysis results with beautiful UI
class AIResultsDialog extends StatelessWidget {
  final CategoryResult categoryResult;
  final Map<String, dynamic>? extractedDetails;
  final List<ActionSuggestion>? suggestions;

  const AIResultsDialog({
    super.key,
    required this.categoryResult,
    this.extractedDetails,
    this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF1E1E2E),
              const Color(0xFF2D2D44),
            ]
                : [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCategoryCard(context),
                    const SizedBox(height: 16),
                    _buildConfidenceIndicator(context),
                    const SizedBox(height: 20),
                    if (extractedDetails != null && extractedDetails!.isNotEmpty)
                      _buildExtractedDetails(context),
                    if (suggestions != null && suggestions!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSuggestions(context),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// Build dialog header with gradient and icon
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getCategoryGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              categoryResult.categoryEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete ✓',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Build main category card
  Widget _buildCategoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categoryResult.displayCategory.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                categoryResult.categoryEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            categoryResult.originalText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (categoryResult.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryResult.reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build confidence indicator with progress bar
  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidence = categoryResult.confidence;
    final isHighConfidence = categoryResult.isConfident;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${confidence.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getCategoryColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCategoryColor(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isHighConfidence ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: isHighConfidence ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isHighConfidence
                    ? 'High confidence - Classification is reliable'
                    : 'Medium confidence - Please verify the category',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build extracted details section
  Widget _buildExtractedDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extracted Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: extractedDetails!.entries.map((entry) {
              if (entry.value == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getIconForField(entry.key),
                      size: 18,
                      color: _getCategoryColor(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatFieldName(entry.key),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Build suggestions section
  Widget _buildSuggestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Suggestions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions!.map((suggestion) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.action,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (suggestion.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          suggestion.reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(suggestion.priority),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    suggestion.priority.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Save to Nota'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _getCategoryColor(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🎨 STYLING HELPERS
  // ════════════════════════════════════════════════════════════

  /// Get color for category
  Color _getCategoryColor() {
    switch (categoryResult.category.toLowerCase()) {
      case 'todo':
      case 'to-do':
        return Colors.green;
      case 'appointment':
        return Colors.blue;
      case 'expense':
        return Colors.orange;
      case 'quote':
        return Colors.purple;
      case 'note':
      default:
        return Colors.grey;
    }
  }

  /// Get gradient colors for category
  List<Color> _getCategoryGradient() {
    final baseColor = _getCategoryColor();
    return [
      baseColor,
      baseColor.withOpacity(0.7),
    ];
  }

  /// Get icon for extracted field
  IconData _getIconForField(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'title':
        return Icons.title;
      case 'amount':
      case 'price':
        return Icons.attach_money;
      case 'currency':
        return Icons.currency_exchange;
      case 'date':
      case 'deadline':
        return Icons.calendar_today;
      case 'time':
        return Icons.access_time;
      case 'location':
        return Icons.location_on;
      case 'priority':
        return Icons.flag;
      case 'category':
        return Icons.category;
      case 'description':
        return Icons.description;
      default:
        return Icons.label;
    }
  }

  /// Format field name for display
  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
        ? ''
        : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🧪 TESTING HELPER
  // ════════════════════════════════════════════════════════════

  /// Show sample dialog for testing
  static Future<bool?> showSample(BuildContext context) {
    final sampleResult = CategoryResult(
      category: 'todo',
      confidence: 85.0,
      originalText: 'اشتري حليب من السوبر ماركت غداً',
      reason: 'يحتوي على فعل أمر يتطلب إجراء',
    );

    final sampleDetails = {
      'title': 'شراء حليب',
      'priority': 'medium',
      'deadline': 'غداً',
      'category': 'shopping',
    };

    final sampleSuggestions = [
      ActionSuggestion(
        action: 'إضافة تذكير قبل الموعد بساعة',
        category: 'todo',
        priority: 'medium',
        reason: 'لضمان عدم النسيان',
      ),
      ActionSuggestion(
        action: 'تحديد وقت محدد للتسوق',
        category: 'appointment',
        priority: 'low',
        reason: 'للتنظيم الأفضل',
      ),
    ];

    return showDialog<bool>(
      context: context,
      builder: (context) => AIResultsDialog(
        categoryResult: sampleResult,
        extractedDetails: sampleDetails,
        suggestions: sampleSuggestions,
      ),
    );
  }
}
