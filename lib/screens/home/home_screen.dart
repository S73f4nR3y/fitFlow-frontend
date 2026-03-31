import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../components/cards/booking_card.dart';
import '../../components/cards/class_card.dart';
import '../../components/sheets/instructor_profile_sheet.dart';
import '../../components/sheets/class_details_sheet.dart';
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

  // Pagination for bookings
  int _bookingsPage = 1;
  int _bookingsTotalPages = 1;
  bool _isLoadingMoreBookings = false;
  final ScrollController _bookingsScrollController = ScrollController();

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
    _bookingsScrollController.addListener(() {
      if (_bookingsScrollController.position.pixels >=
          _bookingsScrollController.position.maxScrollExtent - 200) {
        _loadMoreBookings();
      }
    });
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
            if (index == 1) _loadMyBookings();
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

          return ClassCard(
            fitClass: fitClass,
            onTap: () => _showClassDetails(fitClass),
            onInstructorTap: instructor != null
                ? () => _showInstructorProfile(instructor)
                : null,
            showButton: true,
            buttonText: 'Ver Detalles',
            onButtonPressed: () => _showClassDetails(fitClass),
          );
        },
      ),
    );
  }

  void _showInstructorProfile(dynamic instructor) {
    InstructorProfileSheet.show(context, instructor: instructor);
  }

  void _showClassDetails(dynamic fitClass) {
    final instructor = fitClass['instructor'];
    ClassDetailsSheet.show(
      context,
      fitClass: fitClass,
      onInstructorTap: () {
        Navigator.pop(context);
        _showInstructorProfile(instructor);
      },
      onBookPressed: () {
        Navigator.pop(context);
        _showScheduleModal(fitClass);
      },
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
      controller: _bookingsScrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          _bookings.length + (_bookingsPage < _bookingsTotalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _bookings.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final booking = _bookings[index];

        return BookingCard(
          booking: booking,
          onCancel: () async {
            final api = context.read<ApiService>();
            await api.cancelBooking(booking['id']);
            _loadMyBookings();
          },
        );
      },
    );
  }

  Future<void> _loadMyBookings() async {
    final api = context.read<ApiService>();
    try {
      final result = await api.getMyBookings(page: 1, pageSize: 10);
      if (mounted) {
        setState(() {
          _bookings = result['data'] ?? [];
          _bookingsPage = 1;
          _bookingsTotalPages = result['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadMoreBookings() async {
    if (_isLoadingMoreBookings || _bookingsPage >= _bookingsTotalPages) return;

    setState(() => _isLoadingMoreBookings = true);

    final api = context.read<ApiService>();
    try {
      final result = await api.getMyBookings(
        page: _bookingsPage + 1,
        pageSize: 10,
      );
      if (mounted) {
        setState(() {
          _bookings.addAll(result['data'] ?? []);
          _bookingsPage = _bookingsPage + 1;
          _isLoadingMoreBookings = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more bookings: $e');
      if (mounted) setState(() => _isLoadingMoreBookings = false);
    }
  }
}
