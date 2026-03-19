import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/profile/edit_company_profile.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String selectedRole = 'Owner';
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolIdController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (selectedRole == 'Staff' && !_formKey.currentState!.validate()) return;
    if (selectedRole == 'Student' && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (selectedRole == 'Student') {
        // For student, verify student ID and mobile number match an existing student
        final studentId = _schoolIdController.text.trim();
        final mobileNumber = _mobileController.text.trim();

        // Search for the student in all schools
        final schoolsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Owner')
            .get();

        String? foundSchoolId;
        String? foundStudentDocId;

        for (final schoolDoc in schoolsSnapshot.docs) {
          final schoolId = schoolDoc.id;
          // Search in this school's students collection
          final studentQuery = await FirebaseFirestore.instance
              .collection('users')
              .doc(schoolId)
              .collection('students')
              .where('studentId', isEqualTo: studentId)
              .limit(1)
              .get();

          if (studentQuery.docs.isNotEmpty) {
            final studentData = studentQuery.docs.first.data();
            final storedMobile = studentData['mobileNumber']?.toString() ?? '';
            // Normalize mobile numbers for comparison
            final normalizedInput =
                mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
            final normalizedStored =
                storedMobile.replaceAll(RegExp(r'[^0-9]'), '');

            if (normalizedInput == normalizedStored) {
              foundSchoolId = schoolId;
              foundStudentDocId = studentQuery.docs.first.id;
              break;
            }
          }
        }

        if (foundSchoolId == null || foundStudentDocId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Student ID and mobile number do not match our records'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Store the student's info in user's document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': selectedRole,
          'schoolId': foundSchoolId,
          'studentDocId': foundStudentDocId,
          'studentId': studentId,
          'hasRoleSelected': true,
        }, SetOptions(merge: true));

        if (mounted) {
          final workspaceController = Get.find<WorkspaceController>();
          await workspaceController.initializeWorkspace();

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
        return;
      }

      final schoolId =
          selectedRole == 'Owner' ? user.uid : _schoolIdController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': selectedRole,
        'schoolId': schoolId,
        'hasRoleSelected': true,
      }, SetOptions(merge: true));

      if (mounted) {
        if (selectedRole == 'Owner') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const EditCompanyProfile(isRegistration: true),
            ),
          );
        } else {
          // Await workspace initialization before going home
          final workspaceController = Get.find<WorkspaceController>();
          await workspaceController.initializeWorkspace();

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us how you will use Drivemate',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildRoleCard('Owner', Icons.business, theme),
                  const SizedBox(width: 16),
                  _buildRoleCard('Staff', Icons.person_outline, theme),
                  const SizedBox(width: 16),
                  _buildRoleCard('Student', Icons.school_outlined, theme),
                ],
              ),
              const SizedBox(height: 32),
              if (selectedRole == 'Staff') ...[
                Text(
                  'Workspace Link',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _schoolIdController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter School ID from your Admin',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.link, color: kPrimaryColor),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Valid School ID required'
                        : (v.trim() == FirebaseAuth.instance.currentUser?.uid
                            ? 'Cannot use personal UID'
                            : null),
                  ),
                ),
              ] else if (selectedRole == 'Student') ...[
                Text(
                  'Student Verification',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _schoolIdController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter Student ID from your Driving School',
                          hintStyle:
                              TextStyle(color: textColor.withOpacity(0.5)),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.badge_outlined, color: kPrimaryColor),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Student ID required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobileController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter Mobile Number',
                          hintStyle:
                              TextStyle(color: textColor.withOpacity(0.5)),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.phone_outlined, color: kPrimaryColor),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Mobile number required'
                            : null,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'As an Owner, you can manage your school, staff, and subscriptions.',
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon, ThemeData theme) {
    bool isSelected = selectedRole == role;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor
                : (isDark ? Colors.grey.shade900 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? kPrimaryColor
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : kPrimaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                role,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
