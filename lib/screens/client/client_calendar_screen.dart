import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ClientCalendarScreen extends StatefulWidget {
  const ClientCalendarScreen({super.key});

  @override
  State<ClientCalendarScreen> createState() => _ClientCalendarScreenState();
}

class _ClientCalendarScreenState extends State<ClientCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<dynamic> _availableClasses = [];
  List<dynamic> _myBookings = [];
  bool _isLoading = false;
  Map<DateTime, List<dynamic>> _availableEvents = {};
  Map<DateTime, List<dynamic>> _bookingEvents = {};
  late TabController _tabController;
  Set<String> _bookedScheduleIds = {};

  String? _getInstructorPhotoUrl(dynamic instructor) {
    // Check instructor.avatarUrl (from /instructors/profile/:id endpoint)
    final avatarUrl = instructor['avatarUrl'];
    if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
      final url = avatarUrl.toString();
      if (url.startsWith('http')) return url;
      return 'http://localhost:3000$url';
    }
    // Check instructor.user.avatarUrl (from /classes/public endpoint)
    final user = instructor['user'];
    if (user != null) {
      final userAvatarUrl = user['avatarUrl'];
      if (userAvatarUrl != null && userAvatarUrl.toString().isNotEmpty) {
        final url = userAvatarUrl.toString();
        if (url.startsWith('http')) return url;
        return 'http://localhost:3000$url';
      }
    }
    // Fallback to photoUrl
    final photoUrl = instructor['photoUrl'];
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      final url = photoUrl.toString();
      if (url.startsWith('http')) return url;
      return 'http://localhost:3000$url';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();

    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    try {
      final classes = await api.getUpcomingClassSchedules(
        startDate: _formatDateKey(startDate),
        endDate: _formatDateKey(endDate),
      );

      final bookings = await api.getMyBookings();

      final availableEvents = <DateTime, List<dynamic>>{};
      for (var schedule in classes) {
        final date = DateTime.parse(schedule['date'].toString()).toLocal();
        final dateKey = DateTime(date.year, date.month, date.day);
        if (!availableEvents.containsKey(dateKey)) {
          availableEvents[dateKey] = [];
        }
        availableEvents[dateKey]!.add(schedule);
      }

      final bookingEvents = <DateTime, List<dynamic>>{};
      final bookedIds = <String>{};
      for (var booking in bookings) {
        if (booking['status'] == 'confirmed') {
          bookedIds.add(booking['scheduleId']);
          final schedule = booking['schedule'];
          if (schedule != null) {
            final date = DateTime.parse(schedule['date'].toString()).toLocal();
            final dateKey = DateTime(date.year, date.month, date.day);
            if (!bookingEvents.containsKey(dateKey)) {
              bookingEvents[dateKey] = [];
            }
            bookingEvents[dateKey]!.add(booking);
          }
        }
      }

      setState(() {
        _availableClasses = classes;
        _myBookings = bookings;
        _availableEvents = availableEvents;
        _bookingEvents = bookingEvents;
        _bookedScheduleIds = bookedIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getAvailableEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _availableEvents[key] ?? [];
  }

  List<dynamic> _getBookingEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _bookingEvents[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario', style: AppTextStyles.h3),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Clases Disponibles'),
            Tab(text: 'Mis Reservas'),
          ],
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              if (_tabController.index == 0) {
                return _getAvailableEventsForDay(day);
              } else {
                return _getBookingEventsForDay(day);
              }
            },
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
              _loadData();
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
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableClassesList(),
                      _buildMyBookingsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableClassesList() {
    final events = _getAvailableEventsForDay(_selectedDay ?? DateTime.now());

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
                  : 'No hay clases disponibles',
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
        final instructor = classInfo['instructor'] ?? {};
        final isFull =
            (schedule['currentParticipants'] ?? 0) >=
            (classInfo['maxParticipants'] ?? 20);
        final isAlreadyBooked = _bookedScheduleIds.contains(schedule['id']);
        final canBook = !isFull && !isAlreadyBooked;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: canBook
                ? () => _showClassDetails(schedule, classInfo, instructor)
                : null,
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
                          color: isFull
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${schedule['startTime']} - ${schedule['endTime']}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isFull ? AppColors.error : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isFull
                            ? 'LLENO'
                            : (isAlreadyBooked ? 'RESERVADO' : 'DISPONIBLE'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isFull ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(classInfo['title'] ?? 'Clase', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        instructor['displayName'] ?? 'Instructor',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
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
                        Icons.people,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule['currentParticipants'] ?? 0}/${classInfo['maxParticipants'] ?? 20}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isFull
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
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
                  if (canBook) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _bookClass(schedule, classInfo),
                        child: const Text('Reservar'),
                      ),
                    ),
                  ] else if (isAlreadyBooked) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ya reservado',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClassDetails(
    dynamic schedule,
    dynamic classInfo,
    dynamic instructor,
  ) {
    final isAlreadyBooked = _bookedScheduleIds.contains(schedule['id']);
    final isFull =
        (schedule['currentParticipants'] ?? 0) >=
        (classInfo['maxParticipants'] ?? 20);
    final canBook = !isFull && !isAlreadyBooked;

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
            if (classInfo['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                classInfo['description'],
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showInstructorProfile(instructor),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          _getInstructorPhotoUrl(instructor) != null
                          ? NetworkImage(_getInstructorPhotoUrl(instructor)!)
                          : null,
                      child: _getInstructorPhotoUrl(instructor) == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instructor['displayName'] ?? 'Instructor',
                            style: AppTextStyles.h4,
                          ),
                          Text(
                            'Toca para ver perfil',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            _detailRow(
              Icons.access_time,
              'Horario',
              '${schedule['startTime']} - ${schedule['endTime']}',
            ),
            _detailRow(
              Icons.people,
              'Cupo',
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
            const SizedBox(height: 24),
            if (isAlreadyBooked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Ya tienes esta reserva',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              )
            else if (isFull)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Clase llena',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _bookClass(schedule, classInfo);
                  },
                  child: const Text('Reservar Clase'),
                ),
              ),
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

  void _showInstructorProfile(dynamic instructor) {
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
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: _getInstructorPhotoUrl(instructor) != null
                  ? NetworkImage(_getInstructorPhotoUrl(instructor)!)
                  : null,
              child: _getInstructorPhotoUrl(instructor) == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              instructor['displayName'] ?? 'Instructor',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            if (instructor['bio'] != null && instructor['bio'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                instructor['bio'],
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (instructor['specialties'] != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: (instructor['specialties'] as List)
                    .map<Widget>(
                      (s) => Chip(
                        label: Text(
                          s.toString(),
                          style: AppTextStyles.labelSmall,
                        ),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (instructor['instagramUrl'] != null)
                  _buildSocialButton(
                    Icons.camera_alt,
                    instructor['instagramUrl'],
                  ),
                if (instructor['websiteUrl'] != null)
                  _buildSocialButton(Icons.language, instructor['websiteUrl']),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String url) {
    return IconButton(
      icon: Icon(icon, color: AppColors.primary),
      onPressed: () {},
    );
  }

  Widget _buildMyBookingsList() {
    final events = _getBookingEventsForDay(_selectedDay ?? DateTime.now());

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              _selectedDay == null
                  ? 'Selecciona un día'
                  : 'No tienes reservas este día',
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
        final booking = events[index];
        final schedule = booking['schedule'] ?? {};
        final classInfo = schedule['classEntity'] ?? {};
        final instructor = classInfo['instructor'] ?? {};

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () =>
                _showBookingDetails(booking, schedule, classInfo, instructor),
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
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${schedule['startTime']} - ${schedule['endTime']}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CONFIRMADO',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(classInfo['title'] ?? 'Clase', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        instructor['displayName'] ?? 'Instructor',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(booking['id']),
                      icon: const Icon(Icons.cancel, color: AppColors.error),
                      label: const Text(
                        'Cancelar Reserva',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBookingDetails(
    dynamic booking,
    dynamic schedule,
    dynamic classInfo,
    dynamic instructor,
  ) {
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Reserva Confirmada',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showInstructorProfile(instructor),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          _getInstructorPhotoUrl(instructor) != null
                          ? NetworkImage(_getInstructorPhotoUrl(instructor)!)
                          : null,
                      child: _getInstructorPhotoUrl(instructor) == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instructor['displayName'] ?? 'Instructor',
                            style: AppTextStyles.h4,
                          ),
                          Text(
                            'Toca para ver perfil',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showInstructorProfile(instructor),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          _getInstructorPhotoUrl(instructor) != null
                          ? NetworkImage(_getInstructorPhotoUrl(instructor)!)
                          : null,
                      child: _getInstructorPhotoUrl(instructor) == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instructor['displayName'] ?? 'Instructor',
                            style: AppTextStyles.h4,
                          ),
                          Text(
                            'Toca para ver perfil',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.success),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(
              Icons.access_time,
              'Horario',
              '${schedule['startTime']} - ${schedule['endTime']}',
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBooking(booking['id']);
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Reserva'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookClass(dynamic schedule, dynamic classInfo) async {
    final api = context.read<ApiService>();
    final price = classInfo['price'];
    final amount = price is num
        ? price.toDouble()
        : double.tryParse(price?.toString() ?? '0') ?? 0;
    try {
      await api.createBooking(scheduleId: schedule['id'], amount: amount);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reserva creada!')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final api = context.read<ApiService>();
    try {
      await api.cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
