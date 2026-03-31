import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/api_service.dart';

class BookingCard extends StatelessWidget {
  final dynamic booking;
  final VoidCallback? onCancel;
  final bool showCancelButton;

  const BookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = booking['schedule'] ?? {};
    final classEntity = schedule['classEntity'] ?? {};
    final instructor = classEntity['instructor'] ?? {};

    // Get price from class or booking
    final price =
        double.tryParse(classEntity['price']?.toString() ?? '0') ??
        (booking['amount'] ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classEntity['title'] ?? 'Clase',
                    style: AppTextStyles.h4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      booking['status'],
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(booking['status']),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _getStatusColor(booking['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date and Time
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(schedule['date'] ?? '', style: AppTextStyles.bodySmall),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${schedule['startTime'] ?? ''} - ${schedule['endTime'] ?? ''}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),

            // Instructor
            if (instructor['displayName'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    instructor['displayName'],
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Price and Cancel Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),
                if (showCancelButton && booking['status'] == 'confirmed')
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      case 'pending':
        return 'Pendiente';
      default:
        return status ?? 'Desconocido';
    }
  }
}
