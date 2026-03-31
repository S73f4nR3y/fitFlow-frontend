import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ClassDetailSheet extends StatelessWidget {
  final dynamic fitClass;
  final VoidCallback? onEdit;
  final VoidCallback? onAddSchedule;
  final VoidCallback? onDelete;

  const ClassDetailSheet({
    super.key,
    required this.fitClass,
    this.onEdit,
    this.onAddSchedule,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic fitClass,
    VoidCallback? onEdit,
    VoidCallback? onAddSchedule,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassDetailSheet(
        fitClass: fitClass,
        onEdit: onEdit,
        onAddSchedule: onAddSchedule,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fitClass['title'] ?? 'Clase', style: AppTextStyles.h2),
                  const SizedBox(height: 16),
                  Text(
                    fitClass['description'] ?? '',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit?.call();
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onAddSchedule?.call(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Horario'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      label: const Text(
                        'Eliminar Clase',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
