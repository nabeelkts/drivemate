import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/services/subscription_service.dart';
import 'package:intl/intl.dart';

class ManageCodesPage extends StatefulWidget {
  const ManageCodesPage({super.key});

  @override
  State<ManageCodesPage> createState() => _ManageCodesPageState();
}

class _ManageCodesPageState extends State<ManageCodesPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _durationController =
      TextEditingController(text: '365');
  bool _isGenerating = false;

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);

    final duration = int.tryParse(_durationController.text) ?? 365;
    final result =
        await _subscriptionService.createCode(durationDays: duration);

    setState(() => _isGenerating = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code generated: ${result['code']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to generate code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
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
          'Subscription Codes',
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
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate New Code',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Duration (days)',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    hintText: '365',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kPrimaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Generate Code',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'All Codes',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _subscriptionService.getAllCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading codes',
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                final codes = snapshot.data ?? [];

                if (codes.isEmpty) {
                  return Center(
                    child: Text(
                      'No codes generated yet',
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    final isUsed = code['isUsed'] as bool;
                    final createdAt = code['createdAt'] as Timestamp?;
                    final usedAt = code['usedAt'] as Timestamp?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUsed
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  code['code'] ?? 'N/A',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                color: kPrimaryColor,
                                onPressed: () =>
                                    _copyToClipboard(code['code'] ?? ''),
                              ),
                              if (!isUsed)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red,
                                  onPressed: () async {
                                    final confirm = await _showConfirmDialog(
                                      'Delete Code',
                                      'Are you sure you want to delete this code?',
                                    );
                                    if (confirm == true) {
                                      final result =
                                          await _subscriptionService.deleteCode(code['code'] ?? '');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message'] ?? 'Done'),
                                            backgroundColor: result['success'] == true
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isUsed
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isUsed ? 'USED' : 'AVAILABLE',
                                  style: TextStyle(
                                    color: isUsed ? Colors.red : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Duration: ${code['durationDays']} days',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Created: ${DateFormat('dd/MM/yyyy hh:mm a').format(createdAt.toDate())}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (isUsed && usedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Used: ${DateFormat('dd/MM/yyyy hh:mm a').format(usedAt.toDate())}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
