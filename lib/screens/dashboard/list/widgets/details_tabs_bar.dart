import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';

class DetailsTabItem {
  final String label;
  final IconData icon;
  const DetailsTabItem({required this.label, required this.icon});
}

class DetailsTabsBar extends StatelessWidget {
  final List<DetailsTabItem> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const DetailsTabsBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isActive = activeIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tabs[index].label),
              selected: isActive,
              onSelected: (selected) {
                if (selected) onChanged(index);
              },
              avatar: Icon(
                tabs[index].icon,
                size: 16,
                color: isActive ? Colors.white : Colors.grey,
              ),
              selectedColor: kPrimaryColor, // keep primary for consistency
              labelStyle: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey : Colors.black87),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }),
      ),
    );
  }
}
