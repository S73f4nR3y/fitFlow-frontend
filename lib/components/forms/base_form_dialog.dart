import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class BaseFormDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final double? height;
  final bool showHandle;

  const BaseFormDialog({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.height,
    this.showHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    List<Widget>? actions,
    double? height,
    bool showHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BaseFormDialog(
        title: title,
        children: children,
        actions: actions,
        height: height,
        showHandle: showHandle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) ...[
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
            ],
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: 24),
            ...children,
            if (actions != null) ...[
              const SizedBox(height: 24),
              Row(
                children: actions!
                    .map((action) => Expanded(child: action))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }

    return content;
  }
}

class AppFormField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AppFormField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}

class FormSelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const FormSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: options
            .map(
              (option) => DropdownMenuItem<T>(
                value: option,
                child: Text(labelBuilder(option)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class FormActions extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;
  final bool isDestructive;

  const FormActions({
    super.key,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (secondaryLabel != null)
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onSecondary,
              child: Text(secondaryLabel!),
            ),
          ),
        if (secondaryLabel != null) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onPrimary,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
