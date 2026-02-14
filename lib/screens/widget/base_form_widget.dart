import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds/constants/colors.dart';

class BaseFormWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const BaseFormWidget({
    required this.title,
    required this.children,
    this.onBack,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color ??
                (isDark ? Colors.white : Colors.black),
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ??
            (isDark ? Colors.white : Colors.black),
        elevation: 0,
        actions: actions,
        leading: onBack != null
            ? Center(
                child: CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  radius: 15,
                  child: Center(
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: kWhite,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: kPrimaryColor,
                          size: 15,
                        ),
                        onPressed: onBack,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: children,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const FormSection({
    required this.title,
    required this.children,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color ??
                  (isDark ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class FormTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool readOnly;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const FormTextField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<TextInputFormatter> formatters = [];
    TextCapitalization capitalization = TextCapitalization.none;
    TextInputType actualKeyboardType = keyboardType;
    int? effectiveMaxLength = maxLength;

    final normalizedLabel = label.toLowerCase();
    if (normalizedLabel.contains('mobile') ||
        normalizedLabel.contains('emergency')) {
      effectiveMaxLength = 10;
      actualKeyboardType = TextInputType.phone;
      formatters.add(LengthLimitingTextInputFormatter(10));
    } else if (normalizedLabel.contains('pin')) {
      effectiveMaxLength = 6;
      actualKeyboardType = TextInputType.number;
      formatters.add(LengthLimitingTextInputFormatter(6));
    } else if (actualKeyboardType == TextInputType.text) {
      capitalization = TextCapitalization.words;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);
    final labelColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
        (isDark ? Colors.white70 : Colors.black54);
    final hintColor = theme.hintColor.withOpacity(0.3);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: placeholder,
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 16,
                        ),
                      ),
                      keyboardType: actualKeyboardType,
                      readOnly: readOnly,
                      maxLength: effectiveMaxLength,
                      maxLines: maxLines,
                      textCapitalization: capitalization,
                      inputFormatters: formatters,
                      validator: validator ??
                          (value) {
                            final v = value?.trim() ?? '';
                            if (normalizedLabel.contains('mobile') ||
                                normalizedLabel.contains('emergency')) {
                              if (normalizedLabel.contains('emergency') &&
                                  v.isEmpty) return null;
                              if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                                return 'Invalid number';
                              }
                            } else if (normalizedLabel.contains('pin')) {
                              if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                                return 'Invalid PIN';
                              }
                            } else if (v.isEmpty &&
                                !normalizedLabel.contains('optional') &&
                                !placeholder
                                    .toLowerCase()
                                    .contains('optional')) {
                              return 'Required';
                            }
                            return null;
                          },
                      onChanged: onChanged,
                    ),
                  ),
                  if (controller.text.isNotEmpty && !readOnly)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ],
        );
      },
    );
  }
}
