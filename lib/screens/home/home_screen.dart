import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../auth/login_screen.dart';
import '../instructor/instructor_screen.dart';
import '../admin/admin_screen.dart';
import '../client/client_calendar_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<dynamic> _classes = [];
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String _userRole = 'client';

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
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();

    try {
      String? roleFromPrefs = await api.getUserRole();
      String role = roleFromPrefs ?? 'client';

      if (roleFromPrefs == null) {
        try {
          final userData = await api.getUserProfile();
          role = userData['role'] as String? ?? 'client';
        } catch (e) {
          role = 'client';
        }
      }

      final classes = await api.getClasses();

      if (mounted) {
        setState(() {
          _classes = classes;
          _userRole = role;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final api = context.read<ApiService>();
    await api.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToRoleScreen() {
    if (_userRole == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else if (_userRole == 'instructor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InstructorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_userRole != 'client') {
          _navigateToRoleScreen();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('FitFlow', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            _logout();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientCalendarScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Clases'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Mis Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Salir'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildClassesList();
      case 1:
        return _buildBookingsList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildClassesList() {
    if (_classes.isEmpty) {
      return const Center(child: Text('No hay clases disponibles'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserAndData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final fitClass = _classes[index];
          final instructor = fitClass['instructor'];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fitClass['title'] ?? 'Clase', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    fitClass['description'] ?? '',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (instructor != null)
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
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              backgroundImage:
                                  _getInstructorPhotoUrl(instructor) != null
                                  ? NetworkImage(
                                      _getInstructorPhotoUrl(instructor)!,
                                    )
                                  : null,
                              child: _getInstructorPhotoUrl(instructor) == null
                                  ? const Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: 20,
                                    )
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
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${fitClass['price'] ?? 0}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${fitClass['durationMinutes'] ?? 30} min',
                          style: AppTextStyles.labelSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.people,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${fitClass['maxParticipants'] ?? 20}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _showClassDetails(fitClass);
                    },
                    child: const Text('Ver Detalles'),
                  ),
                ],
              ),
            ),
          );
        },
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
            if (instructor['bio'] != null &&
                instructor['bio'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                instructor['bio'].toString(),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showClassDetails(dynamic fitClass) {
    final instructor = fitClass['instructor'];

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
        child: SingleChildScrollView(
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
              Text(fitClass['title'] ?? 'Clase', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                fitClass['description'] ?? '',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _detailItem(
                    Icons.attach_money,
                    'Precio',
                    '\$${fitClass['price'] ?? 0}',
                  ),
                  _detailItem(
                    Icons.timer,
                    'Duración',
                    '${fitClass['durationMinutes'] ?? 30} min',
                  ),
                  _detailItem(
                    Icons.people,
                    'Cupo',
                    '${fitClass['maxParticipants'] ?? 20}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (instructor != null) ...[
                Text('Instructor', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showInstructorProfile(instructor);
                  },
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
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage:
                              _getInstructorPhotoUrl(instructor) != null
                              ? NetworkImage(
                                  _getInstructorPhotoUrl(instructor)!,
                                )
                              : null,
                          child: _getInstructorPhotoUrl(instructor) == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                )
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
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showScheduleModal(fitClass);
                  },
                  child: const Text('Reservar Clase'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  void _showScheduleModal(dynamic fitClass) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Próximamente horarios disponibles',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_bookings.isEmpty) {
      return const Center(child: Text('No tienes reservas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text('Reserva #${booking['id']?.substring(0, 8)}'),
            subtitle: Text('Status: ${booking['status']}'),
            trailing: booking['status'] == 'confirmed'
                ? IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () async {
                      final api = context.read<ApiService>();
                      await api.cancelBooking(booking['id']);
                      _loadUserAndData();
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _loadMyBookings() async {
    final api = context.read<ApiService>();
    try {
      final bookings = await api.getMyBookings();
      if (mounted) {
        setState(() => _bookings = bookings);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
