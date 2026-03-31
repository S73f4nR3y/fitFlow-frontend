import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/instructor_utils.dart';

class ClassCard extends StatelessWidget {
  final dynamic fitClass;
  final VoidCallback? onTap;
  final VoidCallback? onInstructorTap;
  final bool showInstructor;
  final bool showPriceTag;
  final bool showButton;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const ClassCard({
    super.key,
    required this.fitClass,
    this.onTap,
    this.onInstructorTap,
    this.showInstructor = true,
    this.showPriceTag = true,
    this.showButton = false,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final instructor = fitClass['instructor'];
    final price = double.tryParse(fitClass['price']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fitClass['title'] ?? 'Clase',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fitClass['type'] ?? 'group',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (fitClass['description'] != null &&
                  fitClass['description'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  fitClass['description'],
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (showInstructor && instructor != null) ...[
                const SizedBox(height: 12),
                _buildInstructorRow(instructor),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    Icons.access_time,
                    '${fitClass['durationMinutes'] ?? 30} min',
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    Icons.people,
                    '${fitClass['maxParticipants'] ?? 20}',
                  ),
                  if (showPriceTag) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showButton && buttonText != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    child: Text(buttonText!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorRow(dynamic instructor) {
    final photoUrl = getInstructorPhotoUrl(instructor);

    return InkWell(
      onTap: onInstructorTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructor['displayName'] ?? 'Instructor',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
