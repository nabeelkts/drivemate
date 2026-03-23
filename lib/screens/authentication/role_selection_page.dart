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
  final TextEditingController _staffWorkspaceIdController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolIdController.dispose();
    _staffWorkspaceIdController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    setState(() {
      selectedRole = role;
      // Clear text fields when switching roles to avoid confusion
      if (role == 'Staff') {
        _staffWorkspaceIdController.clear();
      } else if (role == 'Student') {
        _schoolIdController.clear();
        _mobileController.clear();
      }
    });
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

        try {
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
            try {
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
            } catch (e) {
              // Continue searching in other schools if permission denied
              continue;
            }
          }

          if (foundSchoolId == null || foundStudentDocId == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student ID and mobile number do not match our records. Please check and try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
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
        } catch (e) {
          if (mounted) {
            String errorMessage = 'Unable to verify student. Please try again.';
            if (e.toString().contains('PERMISSION_DENIED')) {
              errorMessage = 'Unable to access school data. Please ensure the school has enabled student verification.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
            );
          }
          return;
        }
        return;
      }

      if (selectedRole == 'Staff') {
        // Validate that the school exists before saving
        final enteredSchoolId = _staffWorkspaceIdController.text.trim();

        try {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(enteredSchoolId)
              .get();

          if (!schoolDoc.exists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('School with this ID does not exist. Please check and enter the correct School ID.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }

          // Save the validated school ID
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'role': selectedRole,
            'schoolId': enteredSchoolId,
            'hasRoleSelected': true,
          }, SetOptions(merge: true));

          if (mounted) {
            final workspaceController = Get.find<WorkspaceController>();
            await workspaceController.initializeWorkspace();

            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } catch (e) {
          if (mounted) {
            String errorMessage = 'Unable to verify school. Please try again.';
            if (e.toString().contains('PERMISSION_DENIED')) {
              errorMessage = 'Cannot access this school. The school owner may have restricted access or the School ID is incorrect.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
            );
          }
          return;
        }
        return;
      }

      // Owner flow
      final schoolId = user.uid;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': selectedRole,
        'schoolId': schoolId,
        'hasRoleSelected': true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const EditCompanyProfile(isRegistration: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on screen dimensions
    final bool isSmallScreen = screenWidth < 380 || screenHeight < 700;
    final bool isMediumScreen = screenWidth >= 380 && screenWidth < 500;
    final double horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
    final double titleFontSize = isSmallScreen ? 22.0 : (isMediumScreen ? 25.0 : 28.0);
    final double subtitleFontSize = isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 16.0);
    final double cardPadding = isSmallScreen ? 12.0 : 20.0;
    final double iconSize = isSmallScreen ? 24.0 : 32.0;
    final double roleFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);
    final double sectionSpacing = isSmallScreen ? 24.0 : 40.0;
    final double inputSpacing = isSmallScreen ? 8.0 : 12.0;
    final double buttonHeight = isSmallScreen ? 48.0 : 54.0;
    final double buttonFontSize = isSmallScreen ? 16.0 : 18.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.05),
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          color: textColor,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tell us how you will use Drivemate',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: subtitleFontSize,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      _buildRoleCardRow(
                        'Owner', Icons.business, theme, 
                        cardPadding, iconSize, roleFontSize, screenWidth,
                      ),
                      SizedBox(height: inputSpacing * 2),
                      _buildFormFields(
                        context, isDark, textColor, 
                        inputSpacing, roleFontSize,
                      ),
                      SizedBox(height: sectionSpacing),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleCardRow(
    String role1, IconData icon1, ThemeData theme,
    double cardPadding, double iconSize, double roleFontSize, double screenWidth,
  ) {
    // For very small screens, use vertical layout
    if (screenWidth < 320) {
      return Column(
        children: [
          _buildRoleCard(role1, icon1, theme, cardPadding, iconSize, roleFontSize),
          const SizedBox(height: 12),
          _buildRoleCard('Staff', Icons.person_outline, theme, cardPadding, iconSize, roleFontSize),
          const SizedBox(height: 12),
          _buildRoleCard('Student', Icons.school_outlined, theme, cardPadding, iconSize, roleFontSize),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: _buildRoleCard(role1, icon1, theme, cardPadding, iconSize, roleFontSize)),
        const SizedBox(width: 12),
        Expanded(child: _buildRoleCard('Staff', Icons.person_outline, theme, cardPadding, iconSize, roleFontSize)),
        const SizedBox(width: 12),
        Expanded(child: _buildRoleCard('Student', Icons.school_outlined, theme, cardPadding, iconSize, roleFontSize)),
      ],
    );
  }

  Widget _buildFormFields(
    BuildContext context, bool isDark, Color textColor,
    double inputSpacing, double labelFontSize,
  ) {
    if (selectedRole == 'Staff') {
      return _buildStaffFields(isDark, textColor, inputSpacing, labelFontSize);
    } else if (selectedRole == 'Student') {
      return _buildStudentFields(isDark, textColor, inputSpacing, labelFontSize);
    } else {
      return _buildOwnerInfo(isDark, textColor, labelFontSize);
    }
  }

  Widget _buildStaffFields(bool isDark, Color textColor, double inputSpacing, double labelFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workspace Link',
          style: TextStyle(
            color: textColor,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: inputSpacing),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _staffWorkspaceIdController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Get School ID from your Owner',
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.link, color: kPrimaryColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Valid School ID required'
                : (v.trim() == FirebaseAuth.instance.currentUser?.uid
                    ? 'Cannot use personal UID'
                    : null),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentFields(bool isDark, Color textColor, double inputSpacing, double labelFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Verification',
          style: TextStyle(
            color: textColor,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: inputSpacing),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _schoolIdController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter your ID from  Driving School',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.badge_outlined, color: kPrimaryColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Student ID required'
                    : null,
              ),
              SizedBox(height: inputSpacing),
              TextFormField(
                controller: _mobileController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter Mobile Number',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.phone_outlined, color: kPrimaryColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Mobile number required'
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(bool isDark, Color textColor, double labelFontSize) {
    return Container(
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
              'As an Owner, you can manage your school, staff, and students.',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: labelFontSize - 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon, ThemeData theme, 
      [double? cardPadding, double? iconSize, double? roleFontSize]) {
    bool isSelected = selectedRole == role;
    final isDark = theme.brightness == Brightness.dark;
    
    final double padding = cardPadding ?? 20.0;
    final double iSize = iconSize ?? 32.0;
    final double rFontSize = roleFontSize ?? 18.0;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChanged(role),
        child: Container(
          padding: EdgeInsets.all(padding),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iSize,
                color: isSelected ? Colors.white : kPrimaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                role,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: rFontSize,
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
