import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:animate_do/animate_do.dart';

class QuickRegisterCard extends StatelessWidget {
  const QuickRegisterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 100),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: cardColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF252525),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: Colors.blue, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Register',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                  children: [
                    _QuickRegisterItem(
                      icon: Icons.school,
                      label: 'Students',
                      route: '/students',
                      textColor: textColor,
                      color: kOrange,
                    ),
                    _QuickRegisterItem(
                      icon: Icons.badge,
                      label: 'License',
                      route: '/license',
                      textColor: textColor,
                      color: Colors.blue,
                    ),
                    _QuickRegisterItem(
                      icon: Icons.add_card,
                      label: 'Endorse',
                      route: '/endorse',
                      textColor: textColor,
                      color: Colors.purple,
                    ),
                    _QuickRegisterItem(
                      icon: Icons.directions_car,
                      label: 'RC',
                      route: '/rc',
                      textColor: textColor,
                      color: Colors.green,
                    ),
                    _QuickRegisterItem(
                      icon: Icons.miscellaneous_services,
                      label: 'DL Services',
                      route: '/dl_services',
                      textColor: textColor,
                      color: Colors.orangeAccent,
                    ),
                    _QuickRegisterItem(
                      icon: Icons.calendar_month,
                      label: 'Test Dates',
                      route: '/test_dates',
                      textColor: textColor,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRegisterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color textColor;
  final Color color;

  const _QuickRegisterItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.textColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
