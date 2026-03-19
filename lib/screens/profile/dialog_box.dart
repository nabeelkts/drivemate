import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/profile/action_button.dart';

void showCustomConfirmationDialog(
    BuildContext context, String title, String content, Function onConfirm,
    {String confirmText = 'Confirm', String cancelText = 'Cancel'}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
          decoration: BoxDecoration(
            //color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                  // color: kBlack,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ActionButton(
                      text: cancelText,
                      backgroundColor: const Color(0xFFFFF1F1),
                      textColor: const Color(0xFFFF0000),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: confirmText,
                      backgroundColor: const Color(0xFFF6FFF0),
                      textColor: kBlack,
                      onPressed: () async {
                        try {
                          final result = onConfirm();
                          if (result is Future) {
                            await result;
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          // If there's an error, still try to close the dialog
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<T?> showCustomStatefulDialogResult<T>(
  BuildContext context,
  String title,
  Widget Function(
          BuildContext, void Function(void Function()), void Function(T?))
      contentBuilder, {
  String? confirmText,
  String? cancelText,
  T Function()? onConfirmResult,
  VoidCallback? onCancel,
}) {
  return showDialog<T>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 16),
                contentBuilder(ctx, setDialogState, (T? value) {
                  Navigator.of(ctx).pop(value);
                }),
                if (confirmText != null || cancelText != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          text: cancelText ?? 'Cancel',
                          backgroundColor: const Color(0xFFFFF1F1),
                          textColor: const Color(0xFFFF0000),
                          onPressed:
                              onCancel ?? () => Navigator.of(ctx).pop(null),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ActionButton(
                          text: confirmText ?? 'Confirm',
                          backgroundColor: const Color(0xFFF6FFF0),
                          textColor: kBlack,
                          onPressed: () {
                            final result = onConfirmResult?.call();
                            Navigator.of(ctx).pop(result);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<bool?> showCustomConfirmBoolDialog(
    BuildContext context, String title, String content,
    {String confirmText = 'Confirm', String cancelText = 'Cancel'}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ActionButton(
                      text: cancelText,
                      backgroundColor: const Color(0xFFFFF1F1),
                      textColor: const Color(0xFFFF0000),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: confirmText,
                      backgroundColor: const Color(0xFFF6FFF0),
                      textColor: kBlack,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showCustomInfoDialog(
  BuildContext context,
  String title,
  String content, {
  String buttonText = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: buttonText,
                      backgroundColor: const Color(0xFFF6FFF0),
                      textColor: kBlack,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showCustomStatefulDialog(
  BuildContext context,
  String title,
  Widget Function(BuildContext, void Function(void Function()))
      contentBuilder, {
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 16),
                contentBuilder(ctx, setDialogState),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: cancelText,
                        backgroundColor: const Color(0xFFFFF1F1),
                        textColor: const Color(0xFFFF0000),
                        onPressed: onCancel ?? () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ActionButton(
                        text: confirmText,
                        backgroundColor: const Color(0xFFF6FFF0),
                        textColor: kBlack,
                        onPressed: onConfirm ?? () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
