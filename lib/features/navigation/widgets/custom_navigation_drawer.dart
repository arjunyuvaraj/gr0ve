import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';
import 'package:gr0ve/features/navigation/models/navigation_item.dart';

// WIDGET: Custom Navigation Drawer for the main app navigation
// UI: Displays the app logo, title, and a list of navigation items
class CustomNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationItem> navigationItems;
  final Map<String, int> unreadCounts;
  final Map<String, int> unreadAnnouncementsByClub;
  final bool isDarkMode;

  const CustomNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.navigationItems,
    required this.unreadCounts,
    required this.unreadAnnouncementsByClub,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.onSurface.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        isDarkMode
                            ? "assets/appicon_dark.png"
                            : "assets/app_icon.png",
                        width: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'gr0ve'.capitalized,
                    style: context.text.displayLarge?.copyWith(fontSize: 48),
                  ),
                ],
              ),
            ),

            Divider(
              thickness: 1,
              color: context.colors.onSurface.withOpacity(0.1),
              indent: 20,
              endIndent: 20,
            ),

            const SizedBox(height: 8),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(
                  navigationItems.length,
                  (index) => _buildDrawerItem(context, navigationItems[index], index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, NavigationItem item, int index) {
    final isSelected = selectedIndex == index;

    // Calculate unread count
    int unreadCount = 0;
    if (item.showClubNotifications) {
      // Sum all club announcement counts
      unreadCount = unreadAnnouncementsByClub.values.fold(
        0,
        (sum, count) => sum + count,
      );
    } else if (item.unreadCountKey != null) {
      unreadCount = unreadCounts[item.unreadCountKey] ?? 0;
    }

    final hasUnread = unreadCount > 0;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface.withAlpha(140),
              ),
              if (hasUnread)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (item.isAdminOnly) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: context.colors.primary.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => onDestinationSelected(index),
    );
  }
}
