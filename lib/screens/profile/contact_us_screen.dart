import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedType = 'Complaint';
  final List<String> _types = ['Complaint', 'Suggestion'];
  final List<XFile> _attachments = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  final String _adminEmail = 'drivemate.mds@gmail.com'; // Validated admin email

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_attachments.length >= 5) {
      Fluttertoast.showToast(msg: 'You can only attach up to 5 images.');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Applied our image compression standard
      );
      if (image != null) {
        setState(() {
          _attachments.add(image);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error picking image: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _sendEmail() async {
    if (_messageController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a message to send.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final List<String> attachmentPaths =
          _attachments.map((file) => file.path).toList();

      final Email email = Email(
        body: _messageController.text.trim(),
        subject: 'MDS App: $_selectedType',
        recipients: [_adminEmail],
        attachmentPaths: attachmentPaths,
        isHTML: false,
      );

      await FlutterEmailSender.send(email);

      Fluttertoast.showToast(msg: 'Opening email client...');

      // Clear form after successful handoff
      if (mounted) {
        setState(() {
          _messageController.clear();
          _attachments.clear();
        });
      }
    } catch (error) {
      Fluttertoast.showToast(msg: 'Failed to open email client: $error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Contact Us',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback Type Dropdown
            Text(
              'What would you like to tell us?',
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor, fontSize: 16),
                  icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                  items: _types.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message Field
            Text(
              'Description',
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              maxLines: 6,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Please detail your $_selectedType here...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                fillColor: cardColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attachments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attachments (${_attachments.length}/5)',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                if (_attachments.length < 5)
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.attach_file,
                        size: 18, color: kPrimaryColor),
                    label: const Text('Add Image',
                        style: TextStyle(color: kPrimaryColor)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_attachments.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_attachments[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeAttachment(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 40, color: textColor.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'No attachments added',
                      style: TextStyle(color: textColor.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Send via Email client',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
