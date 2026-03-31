import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../forms/base_form_dialog.dart';

class EditClassDialog extends StatefulWidget {
  final dynamic fitClass;
  final VoidCallback? onSuccess;

  const EditClassDialog({super.key, required this.fitClass, this.onSuccess});

  static Future<void> show(
    BuildContext context,
    dynamic fitClass, {
    VoidCallback? onSuccess,
  }) {
    return BaseFormDialog.show(
      context: context,
      title: 'Editar Clase',
      height: MediaQuery.of(context).size.height * 0.75,
      children: [_EditClassForm(fitClass: fitClass, onSuccess: onSuccess)],
    );
  }

  @override
  State<EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<EditClassDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _EditClassForm extends StatefulWidget {
  final dynamic fitClass;
  final VoidCallback? onSuccess;

  const _EditClassForm({required this.fitClass, this.onSuccess});

  @override
  State<_EditClassForm> createState() => _EditClassFormState();
}

class _EditClassFormState extends State<_EditClassForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _maxController;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.fitClass['title'] ?? '',
    );
    _descController = TextEditingController(
      text: widget.fitClass['description'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.fitClass['price']?.toString() ?? '0',
    );
    _durationController = TextEditingController(
      text: widget.fitClass['durationMinutes']?.toString() ?? '30',
    );
    _maxController = TextEditingController(
      text: widget.fitClass['maxParticipants']?.toString() ?? '20',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _updateClass() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiService>();
      await api.updateClass(widget.fitClass['id'], {
        'title': _titleController.text,
        'description': _descController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'durationMinutes': int.tryParse(_durationController.text) ?? 30,
        'maxParticipants': int.tryParse(_maxController.text) ?? 20,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clase actualizada!')));
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

  Future<void> _deleteClass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Clase'),
        content: const Text('¿Estás seguro de eliminar esta clase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final api = context.read<ApiService>();
      await api.deleteClass(widget.fitClass['id']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clase eliminada!')));
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppFormField(label: 'Título de la clase', controller: _titleController),
        AppFormField(
          label: 'Descripción',
          controller: _descController,
          maxLines: 3,
        ),
        Row(
          children: [
            Expanded(
              child: AppFormField(
                label: 'Precio',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppFormField(
                label: 'Duración (min)',
                controller: _durationController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        AppFormField(
          label: 'Máximo participantes',
          controller: _maxController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isDeleting ? null : _deleteClass,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Eliminar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateClass,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
