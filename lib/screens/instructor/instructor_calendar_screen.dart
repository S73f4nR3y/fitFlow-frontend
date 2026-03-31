import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class InstructorCalendarScreen extends StatefulWidget {
  const InstructorCalendarScreen({super.key});

  @override
  State<InstructorCalendarScreen> createState() =>
      _InstructorCalendarScreenState();
}

class _InstructorCalendarScreenState extends State<InstructorCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<dynamic> _schedules = [];
  bool _isLoading = false;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadSchedules();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();

    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    try {
      final schedules = await api.getInstructorSchedules(
        startDate: _formatDateKey(startDate),
        endDate: _formatDateKey(endDate),
      );

      final events = <DateTime, List<dynamic>>{};
      for (var schedule in schedules) {
        final date = DateTime.parse(schedule['date'].toString()).toLocal();
        final dateKey = DateTime(date.year, date.month, date.day);
        if (!events.containsKey(dateKey)) {
          events[dateKey] = [];
        }
        events[dateKey]!.add(schedule);
      }

      setState(() {
        _schedules = schedules;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  bool _hasScheduleOverlap(DateTime newDate, String newStart, String newEnd) {
    final eventsForDay = _getEventsForDay(newDate);
    final newStartMinutes = _timeToMinutes(newStart);
    final newEndMinutes = _timeToMinutes(newEnd);

    for (var event in eventsForDay) {
      final existingStart = event['startTime'] as String;
      final existingEnd = event['endTime'] as String;
      final existingStartMinutes = _timeToMinutes(existingStart);
      final existingEndMinutes = _timeToMinutes(existingEnd);

      if (newStartMinutes < existingEndMinutes &&
          newEndMinutes > existingStartMinutes) {
        return true;
      }
    }
    return false;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mi Calendario', style: AppTextStyles.h3)),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadSchedules();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSelectedDayEvents(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay ?? DateTime.now());

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              _selectedDay == null
                  ? 'Selecciona un día'
                  : 'No hay clases este día',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final schedule = events[index];
        final classInfo = schedule['classEntity'] ?? {};
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showScheduleDetails(schedule, classInfo),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${schedule['startTime']} - ${schedule['endTime']}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule['currentParticipants'] ?? 0}/${classInfo['maxParticipants'] ?? 20}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(classInfo['title'] ?? 'Clase', style: AppTextStyles.h4),
                  if (classInfo['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      classInfo['description'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      Text(
                        '\$${classInfo['price'] ?? 0}',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      Text(
                        ' ${classInfo['durationMinutes'] ?? 30} min',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showScheduleDetails(dynamic schedule, dynamic classInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(classInfo['title'] ?? 'Clase', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            _detailRow(
              Icons.access_time,
              'Horario',
              '${schedule['startTime']} - ${schedule['endTime']}',
            ),
            _detailRow(
              Icons.people,
              'Participantes',
              '${schedule['currentParticipants'] ?? 0} / ${classInfo['maxParticipants'] ?? 20}',
            ),
            _detailRow(
              Icons.attach_money,
              'Precio',
              '\$${classInfo['price'] ?? 0}',
            ),
            _detailRow(
              Icons.timer,
              'Duración',
              '${classInfo['durationMinutes'] ?? 30} minutos',
            ),
            if (schedule['location'] != null)
              _detailRow(Icons.location_on, 'Ubicación', schedule['location']),
            if (schedule['notes'] != null)
              _detailRow(Icons.note, 'Notas', schedule['notes']),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: AppTextStyles.labelSmall),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
