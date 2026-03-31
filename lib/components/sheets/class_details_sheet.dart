import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/instructor_utils.dart';

class ClassDetailsSheet extends StatelessWidget {
  final dynamic fitClass;
  final VoidCallback? onInstructorTap;
  final VoidCallback? onBookPressed;

  const ClassDetailsSheet({
    super.key,
    required this.fitClass,
    this.onInstructorTap,
    this.onBookPressed,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic fitClass,
    VoidCallback? onInstructorTap,
    VoidCallback? onBookPressed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassDetailsSheet(
        fitClass: fitClass,
        onInstructorTap: onInstructorTap,
        onBookPressed: onBookPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructor = fitClass['instructor'];
    final photoUrl = instructor != null
        ? getInstructorPhotoUrl(instructor)
        : null;

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
            if (instructor != null) ...[
              const SizedBox(height: 16),
              Text('Instructor', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              InkWell(
                onTap: onInstructorTap,
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
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBookPressed,
                child: const Text('Reservar Clase'),
              ),
            ),
          ],
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
}
