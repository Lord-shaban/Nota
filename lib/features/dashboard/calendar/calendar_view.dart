// calendar_view.dart
// ------------------------------------------------------------
// Calendar View for Appointments
// Inspired by alNota's calendar integration
// Uses table_calendar package for interactive calendar display
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

/// Calendar View Widget
/// Displays appointments in a calendar format
class CalendarView extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final Map<DateTime, List<dynamic>>? events;

  const CalendarView({
    Key? key,
    this.onDateSelected,
    this.events,
  }) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // Get events for the selected day
    return widget.events?[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        _buildCalendar(),
        const Divider(height: 1),
        Expanded(
          child: _buildEventsList(),
        ),
      ],
    );
  }

  /// Calendar Header
  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFB800), const Color(0xFFFFD900)],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'التقويم',
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.view_week
                  : Icons.view_module,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Calendar Widget
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.saturday,
        locale: 'ar',
        calendarStyle: CalendarStyle(
          // Today
          todayDecoration: BoxDecoration(
            color: const Color(0xFFFFB800).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          // Selected
          selectedDecoration: BoxDecoration(
            color: const Color(0xFFFFB800),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Markers (events)
          markerDecoration: BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markersAnchor: 0.7,
          // Weekend
          weekendTextStyle: const TextStyle(color: Colors.red),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFFFFB800)),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFFFFB800)),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
          weekendStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDateSelected?.call(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  /// Events List for Selected Day
  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildEventCard(events[index], index),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مواعيد',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر يوماً آخر لرؤية المواعيد',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Event Card
  Widget _buildEventCard(dynamic event, int index) {
    // Assuming event is a Map with title, time, location
    final title = event['title'] ?? 'موعد';
    final time = event['time'] ?? '';
    final location = event['location'] ?? '';
    final type = event['type'] ?? 'general';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: _getEventColor(type),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getEventColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getEventIcon(type),
              color: _getEventColor(type),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
    );
  }

  /// Get event color by type
  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'meeting':
        return Colors.blue;
      case 'appointment':
        return Colors.purple;
      case 'reminder':
        return Colors.orange;
      case 'deadline':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  /// Get event icon by type
  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'meeting':
        return Icons.people;
      case 'appointment':
        return Icons.event;
      case 'reminder':
        return Icons.notifications;
      case 'deadline':
        return Icons.flag;
      default:
        return Icons.event_note;
    }
  }
}
