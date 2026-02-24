/* lib/screens/profile/edit_company_profile.dart */
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditCompanyProfile extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isRegistration;

  const EditCompanyProfile(
      {super.key, this.initialData, this.isRegistration = false});

  @override
  State<EditCompanyProfile> createState() => _EditCompanyProfileState();
}

class _EditCompanyProfileState extends State<EditCompanyProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  XFile? _pickedLogo;
  String? _logoUrl;
  bool _isLoading = false;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController = TextEditingController(
        text: data?['companyName'] ?? data?['branchName'] ?? '');
    _phoneController = TextEditingController(
        text: data?['companyPhone'] ?? data?['contactPhone'] ?? '');
    _emailController = TextEditingController(
        text: data?['companyEmail'] ?? data?['contactEmail'] ?? '');
    _addressController = TextEditingController(
        text: data?['companyAddress'] ?? data?['location'] ?? '');
    _logoUrl = data?['companyLogo'] ?? data?['logoUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() {
        _pickedLogo = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isBranch = widget.initialData != null &&
          widget.initialData!['id'] != null &&
          widget.initialData!['id'] != _workspaceController.targetId;

      String? uploadedLogoUrl = _logoUrl;
      if (_pickedLogo != null) {
        final storageService = StorageService();
        uploadedLogoUrl =
            await storageService.uploadCompanyLogo(user.uid, _pickedLogo!);
      }

      if (isBranch) {
        // Update branch subcollection
        final result = await _workspaceController.updateBranchProfile(
          widget.initialData!['id'],
          {
            'branchName': _nameController.text.trim(),
            'contactPhone': _phoneController.text.trim(),
            'contactEmail': _emailController.text.trim(),
            'location': _addressController.text.trim(),
            'logoUrl': uploadedLogoUrl,
          },
          logoFile: _pickedLogo,
        );

        if (!result['success']) {
          throw Exception(result['message']);
        }
      } else {
        // Update main school document
        final data = {
          'companyName': _nameController.text.trim(),
          'companyPhone': _phoneController.text.trim(),
          'companyEmail': _emailController.text.trim(),
          'companyAddress': _addressController.text.trim(),
          'companyLogo': uploadedLogoUrl,
          'hasCompanyProfile': true,
        };

        if (widget.initialData != null && widget.initialData!['id'] != null) {
          // If we have an ID, use it (could be the owner's UID or schoolId)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.initialData!['id'])
              .set(data, SetOptions(merge: true));
        } else {
          // Fallback to current user UID
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(data, SetOptions(merge: true));
        }
      }

      if (mounted) {
        // Refresh workspace data to reflect changes immediately
        await _workspaceController.refreshAppData();

        if (widget.isRegistration) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        } else {
          Fluttertoast.showToast(msg: 'Profile updated successfully');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Company Profile'),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveProfile,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Section
                  _buildLogoSection(isDark, cardColor),
                  const SizedBox(height: 24),

                  // Business Information Section
                  _buildSectionCard(
                    title: 'Business Information',
                    isDark: isDark,
                    cardColor: cardColor,
                    children: [
                      _buildTextField(
                        label: 'Driving School Name',
                        controller: _nameController,
                        hint: 'Enter school name',
                        icon: Icons.business,
                        textColor: textColor,
                        validator: (v) =>
                            v!.isEmpty ? 'Enter school name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        hint: 'Enter phone number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        textColor: textColor,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter phone number'
                            : (v.length < 10 ? 'Enter valid phone' : null),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        hint: 'Enter email address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        textColor: textColor,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter email'
                            : (!v.contains('@') ? 'Enter valid email' : null),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Full Address',
                        controller: _addressController,
                        hint: 'Enter complete address',
                        icon: Icons.location_on,
                        maxLines: 3,
                        textColor: textColor,
                        validator: (v) => v!.isEmpty ? 'Enter address' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required bool isDark,
    required Color cardColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: kPrimaryColor, size: 22),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: textColor.withOpacity(0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: textColor.withOpacity(0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: kPrimaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildLogoSection(bool isDark, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.3),
                      width: 3,
                    ),
                    image: _pickedLogo != null
                        ? DecorationImage(
                            image: FileImage(File(_pickedLogo!.path)),
                            fit: BoxFit.cover,
                          )
                        : (_logoUrl != null && _logoUrl!.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(_logoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_pickedLogo == null &&
                          (_logoUrl == null || _logoUrl!.isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: isDark ? Colors.white54 : Colors.black38,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Logo',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Company Logo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to upload or change logo',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
