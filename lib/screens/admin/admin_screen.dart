import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  List<dynamic> _users = [];
  List<dynamic> _pendingInstructors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    try {
      final users = await api.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingInstructors() async {
    final api = context.read<ApiService>();
    try {
      final pending = await api.getPendingInstructors();
      if (mounted) {
        setState(() => _pendingInstructors = pending);
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> _logout() async {
    final api = context.read<ApiService>();
    await api.logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCreateUserDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Usuario'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _logout();
          } else {
            setState(() => _currentIndex = index);
            if (index == 1) _loadPendingInstructors();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Pendientes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Salir'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildUsersList();
      case 1:
        return _buildPendingList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No hay usuarios', style: AppTextStyles.h4),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(
                  user['role'],
                ).withValues(alpha: 0.2),
                child: Icon(
                  _getRoleIcon(user['role']),
                  color: _getRoleColor(user['role']),
                ),
              ),
              title: Text('${user['firstName']} ${user['lastName']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? ''),
                  const SizedBox(height: 4),
                  _buildRoleBadge(user['role'], user['instructorStatus']),
                ],
              ),
              trailing: user['role'] == 'instructor'
                  ? PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'approve',
                          child: Text('Aprobar'),
                        ),
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Text('Suspender'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'approve') {
                          _approveInstructor(user['id']);
                        } else {
                          _suspendInstructor(user['id']);
                        }
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingInstructors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text('No hay instructores pendientes', style: AppTextStyles.h4),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingInstructors.length,
      itemBuilder: (context, index) {
        final user = _pendingInstructors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withValues(alpha: 0.2),
              child: const Icon(Icons.pending, color: AppColors.warning),
            ),
            title: Text('${user['firstName']} ${user['lastName']}'),
            subtitle: Text(user['email'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                  ),
                  onPressed: () => _approveInstructor(user['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  onPressed: () => _suspendInstructor(user['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role, String? status) {
    Color color = _getRoleColor(role);
    String label = role;
    if (role == 'instructor' && status != null) {
      label = '$status';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.primary;
      case 'instructor':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'instructor':
        return Icons.fitness_center;
      default:
        return Icons.person;
    }
  }

  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String selectedRole = 'client';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text('Crear Usuario', style: AppTextStyles.h3),
              const SizedBox(height: 24),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'client', child: Text('Cliente')),
                  DropdownMenuItem(
                    value: 'instructor',
                    child: Text('Instructor'),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => selectedRole = value ?? 'client',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _createUser({
                    'email': emailController.text,
                    'password': passwordController.text,
                    'firstName': firstNameController.text,
                    'lastName': lastNameController.text,
                    'role': selectedRole,
                  });
                },
                child: const Text('Crear'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createUser(Map<String, dynamic> data) async {
    final api = context.read<ApiService>();
    try {
      await api.createUserAsAdmin(data);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario creado!')));
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

  Future<void> _approveInstructor(String userId) async {
    final api = context.read<ApiService>();
    try {
      await api.approveInstructor(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Instructor aprobado!')));
        _loadData();
        _loadPendingInstructors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _suspendInstructor(String userId) async {
    final api = context.read<ApiService>();
    try {
      await api.suspendInstructor(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Instructor suspendido!')));
        _loadData();
        _loadPendingInstructors();
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
