import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/constants/colors.dart';

class ListItemCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onMenuPressed;
  final bool isDark;

  const ListItemCard({
    super.key,
    required this.title,
    required this.subTitle,
    this.imageUrl,
    required this.onTap,
    required this.onMenuPressed,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: kPrimaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(textColor, context),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subTitle,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: subTextColor,
                              size: 20,
                            ),
                            onPressed: onMenuPressed,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color textColor, BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: kPrimaryColor.withOpacity(0.1),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: 44,
                  height: 44,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                  errorWidget: (context, url, error) => _initials(textColor),
                ),
              )
            : _initials(textColor),
      ),
    );
  }

  Widget _initials(Color textColor) {
    return Text(
      title.isNotEmpty ? title[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kPrimaryColor,
      ),
    );
  }
}
