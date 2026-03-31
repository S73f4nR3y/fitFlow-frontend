import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/instructor_utils.dart';

class BookingDetailsSheet extends StatelessWidget {
  final dynamic booking;
  final dynamic classInfo;
  final dynamic instructor;
  final dynamic schedule;
  final VoidCallback? onCancelPressed;
  final bool canCancel;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    required this.classInfo,
    required this.instructor,
    required this.schedule,
    this.onCancelPressed,
    this.canCancel = true,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic booking,
    required dynamic classInfo,
    required dynamic instructor,
    required dynamic schedule,
    VoidCallback? onCancelPressed,
    bool canCancel = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailsSheet(
        booking: booking,
        classInfo: classInfo,
        instructor: instructor,
        schedule: schedule,
        onCancelPressed: onCancelPressed,
        canCancel: canCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = getInstructorPhotoUrl(instructor);
    final scheduleDate = schedule['startTime'] != null
        ? DateTime.tryParse(schedule['startTime'].toString())
        : null;
    final price = double.tryParse(classInfo['price']?.toString() ?? '0') ?? 0;

    return Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: booking['status'] == 'confirmed'
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status'] == 'confirmed'
                        ? 'Confirmada'
                        : 'Cancelada',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: booking['status'] == 'confirmed'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(classInfo['title'] ?? 'Clase', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            if (instructor != null) ...[
              InkWell(
                onTap: () => Navigator.pop(context),
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
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
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
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha', style: AppTextStyles.labelSmall),
                      Text(
                        scheduleDate != null
                            ? '${scheduleDate.day}/${scheduleDate.month}/${scheduleDate.year}'
                            : '-',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hora', style: AppTextStyles.labelSmall),
                      Text(
                        scheduleDate != null
                            ? '${scheduleDate.hour.toString().padLeft(2, '0')}:${scheduleDate.minute.toString().padLeft(2, '0')}'
                            : '-',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Precio', style: AppTextStyles.labelSmall),
                      Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancelPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Cancelar Reserva'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
