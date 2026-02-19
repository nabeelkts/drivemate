import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  String _selectedCategoryId = 'fuel';
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  static const List<Map<String, String>> categories = [
    {'id': 'fuel', 'label': 'Fuel'},
    {'id': 'maintenance', 'label': 'Maintenance'},
    {'id': 'insurance', 'label': 'Insurance'},
    {'id': 'rent', 'label': 'Rent'},
    {'id': 'salaries', 'label': 'Salaries'},
    {'id': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not logged in')));
      return;
    }
    setState(() => _saving = true);
    final categoryLabel = categories.firstWhere(
        (c) => c['id'] == _selectedCategoryId,
        orElse: () => {'label': 'Other'})['label']!;

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;
    final branchId = _workspaceController.currentBranchId.value;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('expenses')
          .add({
        'category': _selectedCategoryId,
        'categoryLabel': categoryLabel,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'timestamp': Timestamp.fromDate(_selectedDate),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'targetId': targetId,
        'branchId': branchId.isNotEmpty ? branchId : targetId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Expense added')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        title: Text('Add Expense', style: TextStyle(color: textColor)),
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: textColor),
                  ),
                  value: _selectedCategoryId,
                  items: [
                    for (var c in categories)
                      DropdownMenuItem(
                          value: c['id'], child: Text(c['label']!)),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedCategoryId = v ?? 'other'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (Rs.)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: textColor),
                  ),
                  style: TextStyle(color: textColor),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(v.trim()) == null ||
                        double.parse(v.trim()) <= 0)
                      return 'Enter valid amount';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(color: textColor),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: TextStyle(color: textColor)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: textColor),
                  ),
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
