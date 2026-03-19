import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/screens/dashboard/list/students_list.dart';
import 'package:drivemate/screens/dashboard/list/license_only_list.dart';
import 'package:drivemate/screens/dashboard/list/endorsement_list.dart';
import 'package:drivemate/screens/dashboard/list/dl_services_list.dart';
import 'package:drivemate/screens/dashboard/list/vehicle_details_list.dart';
import 'package:drivemate/screens/dashboard/recent_activity_screen.dart';
import 'package:drivemate/screens/dashboard/today_schedule_page.dart';
import 'package:drivemate/screens/urgent_tasks/urgent_tasks_list_page.dart';
import 'package:drivemate/screens/recycle_bin/recycle_bin_screen.dart';
import 'package:drivemate/screens/dashboard/import/import_screen.dart';
import 'package:drivemate/screens/dashboard/export/export_screen.dart';
import 'package:drivemate/services/excel_import_service.dart';
import 'package:drivemate/screens/profile/admin/organization_management_page.dart';
import 'package:drivemate/screens/profile/admin/manage_staff_page.dart';
import 'package:drivemate/screens/profile/admin/branches_page.dart';
import 'package:drivemate/screens/profile/admin/manage_vehicles_page.dart';
import 'package:drivemate/screens/profile/about_page.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';

class AllServicesPage extends StatelessWidget {
  const AllServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('All Services'),
        leading: const CustomBackButton(),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Records Management ─────────────────────────────────────
            _buildSectionHeader('Records Management', subColor),
            const SizedBox(height: 12),
            _buildServicesGrid(
                context,
                [
                  _ServiceItem(
                    icon: Icons.school_outlined,
                    label: 'Students',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentList(userId: ''),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.card_membership_outlined,
                    label: 'License Only',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LicenseOnlyList(userId: ''),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.add_card_outlined,
                    label: 'Endorsement',
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EndorsementList(userId: ''),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.build_circle_outlined,
                    label: 'DL Services',
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DlServicesList(userId: ''),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.directions_car_outlined,
                    label: 'RC / Vehicles',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VehicleDetailsList(),
                      ),
                    ),
                  ),
                ],
                cardColor,
                textColor,
                borderColor),

            const SizedBox(height: 24),

            // ── Operations ─────────────────────────────────────────────
            _buildSectionHeader('Operations', subColor),
            const SizedBox(height: 12),
            _buildServicesGrid(
                context,
                [
                  _ServiceItem(
                    icon: Icons.calendar_today_outlined,
                    label: "Today's Schedule",
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TodaySchedulePage(),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.warning_amber_outlined,
                    label: 'Urgent Tasks',
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UrgentTasksListPage(),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.history_outlined,
                    label: 'Recent Activity',
                    color: Colors.blueGrey,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecentActivityScreen(),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.delete_outline,
                    label: 'Recycle Bin',
                    color: Colors.red.shade300,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecycleBinScreen(),
                      ),
                    ),
                  ),
                ],
                cardColor,
                textColor,
                borderColor),

            const SizedBox(height: 24),

            // ── Import & Export ─────────────────────────────────────────
            _buildSectionHeader('Import & Export', subColor),
            const SizedBox(height: 12),
            _buildServicesGrid(
                context,
                [
                  _ServiceItem(
                    icon: Icons.upload_file_outlined,
                    label: 'Import Records',
                    color: Colors.green.shade700,
                    onTap: () => _showImportOptions(context),
                  ),
                  _ServiceItem(
                    icon: Icons.download_outlined,
                    label: 'Export Records',
                    color: Colors.blue.shade700,
                    onTap: () => _showExportOptions(context),
                  ),
                ],
                cardColor,
                textColor,
                borderColor),

            const SizedBox(height: 24),

            // ── Administration ─────────────────────────────────────────
            _buildSectionHeader('Administration', subColor),
            const SizedBox(height: 12),
            _buildServicesGrid(
                context,
                [
                  _ServiceItem(
                    icon: Icons.business_outlined,
                    label: 'Organization',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrganizationManagementPage(),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.people_outline,
                    label: 'Manage Staff',
                    color: Colors.cyan,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageStaffPage(),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.location_city_outlined,
                    label: 'Branches',
                    color: Colors.amber.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BranchesPage(),
                      ),
                    ),
                  ),
                  _ServiceItem(
                    icon: Icons.directions_car_outlined,
                    label: 'School Vehicles',
                    color: Colors.grey,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageVehiclesPage(),
                      ),
                    ),
                  ),
                ],
                cardColor,
                textColor,
                borderColor),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: subColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildServicesGrid(
    BuildContext context,
    List<_ServiceItem> services,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: services.map((service) {
        return _buildServiceCard(
          context,
          service,
          cardColor,
          textColor,
          borderColor,
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    _ServiceItem service,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service.icon,
                  color: service.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Import Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the type of records you want to import from Excel',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                _buildImportOption(
                  context,
                  icon: Icons.school_outlined,
                  label: 'Import Students',
                  subtitle: 'Add students from Excel file',
                  color: Colors.blue,
                  importType: ImportType.student,
                ),
                _buildImportOption(
                  context,
                  icon: Icons.card_membership_outlined,
                  label: 'Import License Only',
                  subtitle: 'Add license only records from Excel',
                  color: Colors.green,
                  importType: ImportType.licenseOnly,
                ),
                _buildImportOption(
                  context,
                  icon: Icons.add_card_outlined,
                  label: 'Import Endorsement',
                  subtitle: 'Add endorsement records from Excel',
                  color: Colors.orange,
                  importType: ImportType.endorsement,
                ),
                _buildImportOption(
                  context,
                  icon: Icons.build_circle_outlined,
                  label: 'Import DL Services',
                  subtitle: 'Add DL service records from Excel',
                  color: Colors.purple,
                  importType: ImportType.dlService,
                ),
                _buildImportOption(
                  context,
                  icon: Icons.directions_car_outlined,
                  label: 'Import Vehicle Details',
                  subtitle: 'Add vehicle details from Excel',
                  color: Colors.teal,
                  importType: ImportType.vehicleDetails,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required ImportType importType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImportScreen(importType: importType),
          ),
        );
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Export Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the type of records you want to export to Excel',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                _buildExportOption(
                  context,
                  icon: Icons.school_outlined,
                  label: 'Export Students',
                  subtitle: 'Export students to Excel',
                  color: Colors.blue,
                  exportType: ImportType.student,
                ),
                _buildExportOption(
                  context,
                  icon: Icons.card_membership_outlined,
                  label: 'Export License Only',
                  subtitle: 'Export license only records to Excel',
                  color: Colors.green,
                  exportType: ImportType.licenseOnly,
                ),
                _buildExportOption(
                  context,
                  icon: Icons.add_card_outlined,
                  label: 'Export Endorsement',
                  subtitle: 'Export endorsement records to Excel',
                  color: Colors.orange,
                  exportType: ImportType.endorsement,
                ),
                _buildExportOption(
                  context,
                  icon: Icons.build_circle_outlined,
                  label: 'Export DL Services',
                  subtitle: 'Export DL service records to Excel',
                  color: Colors.purple,
                  exportType: ImportType.dlService,
                ),
                _buildExportOption(
                  context,
                  icon: Icons.directions_car_outlined,
                  label: 'Export Vehicle Details',
                  subtitle: 'Export vehicle details to Excel',
                  color: Colors.teal,
                  exportType: ImportType.vehicleDetails,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required ImportType exportType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExportScreen(exportType: exportType),
          ),
        );
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
