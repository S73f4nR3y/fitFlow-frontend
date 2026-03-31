import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/instructor_utils.dart';

class InstructorProfileSheet extends StatelessWidget {
  final dynamic instructor;

  const InstructorProfileSheet({super.key, required this.instructor});

  static void show(BuildContext context, {required dynamic instructor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstructorProfileSheet(instructor: instructor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = getInstructorPhotoUrl(instructor);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            instructor['displayName'] ?? 'Instructor',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          if (instructor['bio'] != null &&
              instructor['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              instructor['bio'].toString(),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
