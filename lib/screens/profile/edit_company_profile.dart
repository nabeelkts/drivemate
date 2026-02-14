/* lib/screens/profile/edit_company_profile.dart */
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mds/screens/widget/base_form_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

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
  late TextEditingController _addressController;
  XFile? _pickedLogo;
  String? _logoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialData?['companyName'] ?? '');
    _phoneController =
        TextEditingController(text: widget.initialData?['companyPhone'] ?? '');
    _addressController = TextEditingController(
        text: widget.initialData?['companyAddress'] ?? '');
    _logoUrl = widget.initialData?['companyLogo'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
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

      String? uploadedLogoUrl = _logoUrl;
      if (_pickedLogo != null) {
        final storageService = StorageService();
        uploadedLogoUrl =
            await storageService.uploadCompanyLogo(user.uid, _pickedLogo!);
      }

      final data = {
        'companyName': _nameController.text.trim(),
        'companyPhone': _phoneController.text.trim(),
        'companyAddress': _addressController.text.trim(),
        'companyLogo': uploadedLogoUrl,
        'hasCompanyProfile': true,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        if (widget.isRegistration) {
          // Await workspace initialization before going home
          final workspaceController = Get.find<WorkspaceController>();
          await workspaceController.initializeWorkspace();

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        } else {
          Fluttertoast.showToast(msg: 'Company profile updated successfully');
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
    return BaseFormWidget(
      title: 'Company Profile',
      onBack: () => Navigator.pop(context),
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _saveProfile,
          icon: const Icon(Icons.check, color: kWhite),
          tooltip: 'Submit',
        ),
      ],
      floatingActionButton: null,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildLogoPicker(),
              const SizedBox(height: 20),
              FormSection(
                title: 'Business Information',
                children: [
                  FormTextField(
                    label: 'Driving School Name',
                    controller: _nameController,
                    placeholder: 'Enter school name',
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                  ),
                  FormTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    placeholder: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Enter phone'
                        : (v.length < 10 ? 'Enter valid phone' : null),
                  ),
                  FormTextField(
                    label: 'Address',
                    controller: _addressController,
                    placeholder: 'Enter full address',
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Enter address' : null,
                  ),
                ],
              ),
              const SizedBox(height: 100), // Extra space for FAB
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: _pickLogo,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: kPrimaryColor.withOpacity(0.5), width: 2),
                    image: _pickedLogo != null
                        ? DecorationImage(
                            image: FileImage(File(_pickedLogo!.path)),
                            fit: BoxFit.cover)
                        : (_logoUrl != null && _logoUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_logoUrl!),
                                fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_pickedLogo == null &&
                          (_logoUrl == null || _logoUrl!.isEmpty))
                      ? Icon(Icons.business,
                          size: 60,
                          color: isDark ? Colors.white54 : Colors.black26)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Company Logo',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
