import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/custom_secondary_button.dart';
import 'package:gr0ve/components/custom_text_field.dart';
import 'package:gr0ve/services/link_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/components/custom_header.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool loading = true;
  List<QuickLink> links = [];
  User? user;

  static const int maxLinks = 10;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);
    user = FirebaseAuth.instance.currentUser;
    final userLinks = await LinkService.getUserLinks();
    setState(() {
      links = List<QuickLink>.from(userLinks);
      loading = false;
    });
  }

  Future<void> _removeLink(QuickLink link) async {
    setState(() {
      links = List<QuickLink>.from(links)..removeWhere((l) => l.id == link.id);
    });
    await LinkService.saveUserLinks(links);
  }

  Future<void> _addLink() async {
    if (links.length >= maxLinks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum of 10 links reached")),
      );
      return;
    }

    String title = '';
    String url = '';
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.link;

    final availableColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    final availableIcons = [
      Icons.link, // generic web link
      Icons.school, // classes / teachers
      Icons.book, // documents / notes
      Icons.directions_bus, // transportation
      Icons.event_available, // events / deadlines
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add New Link'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      hintText: 'Title',
                      controller: TextEditingController(),
                      onChange: (v) => title = v,
                      obscureText: false,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      hintText: 'Link',
                      controller: TextEditingController(),
                      onChange: (v) => url = v,
                      obscureText: false,
                    ),
                    const SizedBox(height: 16),
                    const Text("Pick a color:"),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: availableColors.map((c) {
                        final isSelected = c == selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Pick an icon:"),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      // crossAxisAlignment: WrapMainAlignment.center,
                      children: availableIcons.map((i) {
                        final isSelected = i == selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = i),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withOpacity(0.15)
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              i,
                              color: isSelected
                                  ? selectedColor
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                CustomPrimaryButton(
                  label: "Add",
                  onTap: () {
                    if (title.isNotEmpty && url.isNotEmpty) {
                      Navigator.pop(ctx);
                      final newLink = QuickLink(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        url: url,
                        icon: selectedIcon,
                        color: selectedColor,
                      );
                      setState(() => links.add(newLink));
                      LinkService.saveUserLinks(links);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CustomSecondaryButton(
                  onTap: () => Navigator.pop(ctx),
                  label: 'Cancel',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openLink(QuickLink link) async {
    if (link.url.startsWith("/")) {
      Navigator.pushNamed(context, link.url);
    } else {
      final uri = Uri.parse(link.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // adjust route
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CustomHeader(
            title: "ACCOUNT",
            subtitle: "Manage your info and favorite links",
          ),
          const SizedBox(height: 16),

          // ---- User Info + Logout ----
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.onSurface.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // <-- center vertically
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      user!.email?[0].toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment
                          .center, // <-- vertically center text
                      children: [
                        Text(
                          user!.email ?? 'Anonymous',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user!.isAnonymous ? 'Anonymous account' : 'Logged In',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Buttons stacked vertically and centered
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addLink,
                        tooltip: "Add new link",
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _logout,
                        tooltip: "Logout",
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int columns = 1;
                if (constraints.maxWidth > 900) {
                  columns = 3;
                } else if (constraints.maxWidth > 600) {
                  columns = 2;
                }

                final cardWidth =
                    (constraints.maxWidth - (16 * (columns - 1))) / columns;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: links.map((link) {
                      return SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openLink(link),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.onSurface.withAlpha(12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: link.color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    link.icon,
                                    color: link.color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    link.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeLink(link),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
