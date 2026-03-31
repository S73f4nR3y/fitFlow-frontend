import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../forms/base_form_dialog.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return BaseFormDialog.show(
      context: context,
      title: 'Crear Usuario',
      children: [_CreateUserFormContent(onSuccess: onSuccess)],
    );
  }

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CreateUserFormContent extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _CreateUserFormContent({this.onSuccess});

  @override
  State<_CreateUserFormContent> createState() => _CreateUserFormContentState();
}

class _CreateUserFormContentState extends State<_CreateUserFormContent> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'client';
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (_firstNameController.text.isEmpty || _emailController.text.isEmpty)
      return;

    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiService>();
      await api.createUserAsAdmin({
        'email': _emailController.text,
        'password': _passwordController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'role': _selectedRole,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario creado!')));
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppFormField(label: 'Nombre', controller: _firstNameController),
        AppFormField(label: 'Apellido', controller: _lastNameController),
        AppFormField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AppFormField(
          label: 'Password',
          controller: _passwordController,
          obscureText: true,
        ),
        AppFormField(
          label: 'Rol',
          controller: TextEditingController(text: _selectedRole),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createUser,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear Usuario'),
          ),
        ),
      ],
    );
  }
}
