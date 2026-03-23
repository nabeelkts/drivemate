import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/services/subscription_service.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:intl/intl.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  void _showUserActionDialog(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController daysController = TextEditingController();
    final TextEditingController nameController =
        TextEditingController(text: user['name']);
    final TextEditingController emailController =
        TextEditingController(text: user['email']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Subscription',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${user['companyName']} (${user['role']})',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              if (user['role'] == 'Staff')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Workspace ID: ${user['schoolId']}',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Days',
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                  hintText: '30',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final days = int.tryParse(daysController.text) ?? 30;
                        Navigator.pop(context);
                        final result = await _subscriptionService
                            .updateTrialPeriod(user['schoolId'], days);
                        _showResultSnackBar(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Extend Trial',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final days = int.tryParse(daysController.text) ?? 365;
                        Navigator.pop(context);
                        final result = await _subscriptionService.grantPremium(
                            user['schoolId'], days);
                        _showResultSnackBar(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Grant Premium',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await _subscriptionService.updateUserDetails(
                      user['uid'],
                      {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                      },
                    );
                    _showResultSnackBar(result);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Update Profile',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirm = await _showConfirmDialog(
                      'Revoke Subscription',
                      'Are you sure you want to revoke ${user['companyName']}\'s subscription?',
                    );
                    if (confirm == true) {
                      final result = await _subscriptionService
                          .revokeSubscription(user['schoolId']);
                      _showResultSnackBar(result);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Revoke Subscription',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showCustomConfirmBoolDialog(
      context,
      title,
      message,
      confirmText: 'Confirm',
      cancelText: 'Cancel',
    );
  }

  void _showResultSnackBar(Map<String, dynamic> result) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Operation completed'),
          backgroundColor:
              result['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 13),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Manage Users',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _subscriptionService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading users',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                'No users found',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isPremium = user['subscriptionStatus'] == 'Premium';
              final isExpired = user['isExpired'] as bool;

              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpired
                        ? Colors.red.withOpacity(0.3)
                        : (isPremium
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3)),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isPremium ? Colors.amber : kPrimaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                                  backgroundImage: (user['photoURL'] != null &&
                                          user['photoURL'] != '')
                                      ? NetworkImage(user['photoURL'])
                                      : null,
                                  child: (user['photoURL'] == null ||
                                          user['photoURL'] == '')
                                      ? Text(
                                          user['name'].isNotEmpty
                                              ? user['name'][0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      user['email'],
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (user['role'] == 'Owner'
                                                    ? Colors.purple
                                                    : Colors.teal)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: (user['role'] == 'Owner'
                                                        ? Colors.purple
                                                        : Colors.teal)
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            user['role'].toUpperCase(),
                                            style: TextStyle(
                                              color: user['role'] == 'Owner'
                                                  ? Colors.purple
                                                  : Colors.teal,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isPremium
                                                ? Colors.amber.withOpacity(0.12)
                                                : Colors.blue.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPremium
                                                  ? Colors.amber
                                                  : Colors.blue,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            isPremium ? 'PREMIUM' : 'TRIAL',
                                            style: TextStyle(
                                              color: isPremium
                                                  ? Colors.amber.shade800
                                                  : Colors.blue,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.business, 'Company',
                              user['companyName'], textColor),
                          _buildInfoRow(Icons.phone, 'Mobile',
                              user['companyPhone'], textColor),
                          _buildInfoRow(Icons.location_on, 'Address',
                              user['companyAddress'], textColor),
                          if (user['usedCode'] != 'N/A')
                            _buildInfoRow(Icons.confirmation_number, 'Code',
                                user['usedCode'], textColor),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.warning_amber_rounded
                                        : Icons.timer_outlined,
                                    size: 16,
                                    color: isExpired ? Colors.red : kOrange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isExpired
                                        ? 'Expired'
                                        : '${user['daysLeft']} days left',
                                    style: TextStyle(
                                      color: isExpired
                                          ? Colors.red
                                          : textColor.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showUserActionDialog(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Manage Subscription',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
