import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageAdmins extends StatefulWidget {
  const ManageAdmins({super.key});

  @override
  State<ManageAdmins> createState() => _ManageAdminsState();
}

class _ManageAdminsState extends State<ManageAdmins>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0 = All, 1 = Full Admin, 2 = Customer Service
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<bool?> _showRevokeConfirmationDialog({
    required BuildContext context,
    required String adminName,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: AlertDialog(
                backgroundColor: Colors.white,
                actionsAlignment: MainAxisAlignment.start,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.remove_moderator_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Revoke Admin Access',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Are you sure you want to revoke admin access for $adminName?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                actions: [
                  eButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    text: AppLocalizations.of(context)!.cancel,
                    context: context,
                    textColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                  eButton(
                    text: 'Revoke',
                    onPressed: () => Navigator.of(context).pop(true),
                    context: context,
                    textColor: Colors.white,
                    backgroundColor: Colors.red.shade600,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _revokeAdminAccess(UserModel admin) async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20, child: Loader()),
                  const SizedBox(height: 16),
                  Text(
                    'Revoking admin access...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(admin.uid)
          .update({
            'isAdmin': false,
            'isGrantedAdminByMain': false,
            'adminAccessLevel': FieldValue.delete(),
            'grantedAdminAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin access revoked for ${admin.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
            elevation: 6,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade600,
            elevation: 6,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text(
          'Manage Admins',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {});
            },
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header gradient section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.bgWhite],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Modern Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Hero(
                    tag: 'search_bar_admins',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search admins...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.clear,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Enhanced Filter Chips
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context: context,
                          label: AppLocalizations.of(context)!.all,
                          icon: Icons.apps_rounded,
                          isSelected: _selectedFilter == 0,
                          onTap: () => setState(() => _selectedFilter = 0),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          context: context,
                          label: 'Full Admin',
                          icon: Icons.admin_panel_settings_rounded,
                          isSelected: _selectedFilter == 1,
                          onTap: () => setState(() => _selectedFilter = 1),
                          color: Colors.green,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          context: context,
                          label: 'Customer Service',
                          icon: Icons.support_agent_rounded,
                          isSelected: _selectedFilter == 2,
                          onTap: () => setState(() => _selectedFilter = 2),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Admins List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: AppServices.getAllAgentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 25, child: Loader()),
                        const SizedBox(height: 10),
                        Text(
                          'Loading admins...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    context: context,
                    icon: Icons.error_outline_rounded,
                    title: AppLocalizations.of(context)!.error,
                    subtitle: '${snapshot.error}',
                    color: theme.colorScheme.error,
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    context: context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'No Admins Found',
                    subtitle: 'No admin users available',
                    color: theme.colorScheme.primary,
                  );
                }

                final allUsers = snapshot.data!;

                // Filter only users with granted admin access (excluding main admin)
                final admins = allUsers.where((user) {
                  // Exclude main admin account
                  if (user.phone == '111111111') {
                    return false;
                  }
                  // Only show users with granted admin access
                  return user.isGrantedAdminByMain == true;
                }).toList();

                if (admins.isEmpty) {
                  return _buildEmptyState(
                    context: context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'No Granted Admins',
                    subtitle:
                        'No technicians have been granted admin access yet',
                    color: theme.colorScheme.primary,
                  );
                }

                // Apply filters
                final filteredAdmins = admins.where((admin) {
                  bool matchesSearch = true;
                  if (_searchQuery.isNotEmpty) {
                    final name = (admin.name ?? '').toLowerCase();
                    final email = (admin.email ?? '').toLowerCase();
                    final phone = (admin.phone ?? '').toLowerCase();
                    matchesSearch =
                        name.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        phone.contains(_searchQuery);
                  }

                  bool matchesAccessLevel = true;
                  if (_selectedFilter == 1) {
                    matchesAccessLevel = admin.adminAccessLevel == 1;
                  } else if (_selectedFilter == 2) {
                    matchesAccessLevel = admin.adminAccessLevel == 2;
                  }

                  return matchesSearch && matchesAccessLevel;
                }).toList();

                if (filteredAdmins.isEmpty) {
                  return _buildEmptyState(
                    context: context,
                    icon: Icons.search_off_rounded,
                    title: 'No Admins Match Your Filters',
                    subtitle: 'Try adjusting your search criteria',
                    color: theme.colorScheme.primary,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 100,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: filteredAdmins.length,
                  itemBuilder: (context, index) {
                    return _buildAdminCard(
                      context: context,
                      admin: filteredAdmins[index],
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _selectedFilter = 0;
            });
          },
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 4,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            AppLocalizations.of(context)!.resetFilters,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required BuildContext context,
    required UserModel admin,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isFullAdmin = admin.adminAccessLevel == 1;
    final accessLevelColor = isFullAdmin ? Colors.green : Colors.orange;
    final accessLevelLabel = isFullAdmin ? 'Full Admin' : 'Customer Service';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          elevation: 3,
          shadowColor: accessLevelColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  accessLevelColor.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accessLevelColor.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accessLevelColor.shade400,
                              accessLevelColor.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accessLevelColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            ((admin.name == null || admin.name!.isEmpty)
                                    ? 'A'
                                    : admin.name!)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Admin Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              admin.name ?? 'Unknown',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accessLevelColor.shade400,
                                    accessLevelColor.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: accessLevelColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFullAdmin
                                        ? Icons.admin_panel_settings_rounded
                                        : Icons.support_agent_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    accessLevelLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Revoke Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final confirmed =
                                await _showRevokeConfirmationDialog(
                                  context: context,
                                  adminName: admin.name ?? 'this user',
                                );

                            if (confirmed == true && context.mounted) {
                              await _revokeAdminAccess(admin);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.remove_moderator_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Additional Info
                  if (admin.email != null && admin.email!.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      text: admin.email!,
                    ),
                  if (admin.phone != null && admin.phone!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildInfoRow(
                        icon: Icons.phone_outlined,
                        text: '+966${admin.phone!}',
                      ),
                    ),
                  if (admin.grantedAdminAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        text:
                            'Granted: ${DateFormat('MMM dd, yyyy').format(admin.grantedAdminAt!.toDate())}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
