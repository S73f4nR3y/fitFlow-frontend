import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../forms/base_form_dialog.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return BaseFormDialog.show(
      context: context,
      title: 'Nueva Clase',
      children: [_CreateClassFormContent(onSuccess: onSuccess)],
    );
  }

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CreateClassFormContent extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _CreateClassFormContent({this.onSuccess});

  @override
  State<_CreateClassFormContent> createState() =>
      _CreateClassFormContentState();
}

class _CreateClassFormContentState extends State<_CreateClassFormContent> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _durationController = TextEditingController(text: '30');
  final _maxController = TextEditingController(text: '20');
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiService>();
      await api.createClass({
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
        ).showSnackBar(const SnackBar(content: Text('Clase creada!')));
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createClass,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear Clase'),
          ),
        ),
      ],
    );
  }
}
