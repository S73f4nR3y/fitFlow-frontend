import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_text_styles.dart';
import '../forms/base_form_dialog.dart';

class AddScheduleDialog extends StatefulWidget {
  final String classId;
  final VoidCallback? onSuccess;

  const AddScheduleDialog({super.key, required this.classId, this.onSuccess});

  static Future<void> show(
    BuildContext context,
    String classId, {
    VoidCallback? onSuccess,
  }) {
    return BaseFormDialog.show(
      context: context,
      title: 'Agregar Horario',
      children: [_AddScheduleForm(classId: classId, onSuccess: onSuccess)],
    );
  }

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AddScheduleForm extends StatefulWidget {
  final String classId;
  final VoidCallback? onSuccess;

  const _AddScheduleForm({required this.classId, this.onSuccess});

  @override
  State<_AddScheduleForm> createState() => _AddScheduleFormState();
}

class _AddScheduleFormState extends State<_AddScheduleForm> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  Future<void> _createSchedule() async {
    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiService>();
      await api.createSchedule(
        classId: widget.classId,
        date:
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Horario agregado!')));
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
        _DateTimeTile(
          title: 'Fecha',
          value:
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          icon: Icons.calendar_today,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
        ),
        _DateTimeTile(
          title: 'Hora inicio',
          value: _startTime.format(context),
          icon: Icons.access_time,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _startTime,
            );
            if (time != null) setState(() => _startTime = time);
          },
        ),
        _DateTimeTile(
          title: 'Hora fin',
          value: _endTime.format(context),
          icon: Icons.access_time,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _endTime,
            );
            if (time != null) setState(() => _endTime = time);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createSchedule,
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
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.labelSmall),
      subtitle: Text(value, style: AppTextStyles.body),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }
}
