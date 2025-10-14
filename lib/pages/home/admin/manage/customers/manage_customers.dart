import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageCustomersPage extends StatefulWidget {
  const ManageCustomersPage({super.key});

  @override
  State<ManageCustomersPage> createState() => _ManageCustomersPageState();
}

class _ManageCustomersPageState extends State<ManageCustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter chip state - 0: All, 1: Active, 2: Blocked
  int _selectedFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Show confirmation dialog
  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isBlocking,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBlocking ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBlocking ? Icons.block_rounded : Icons.check_circle_rounded,
                  color: isBlocking
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBlocking
                    ? Colors.red.shade600
                    : Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.confirm,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is BlockUnblockCustomer) {
          log('state.isBlocked=${state.isBlocked}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isBlocked
                    ? AppLocalizations.of(context)!.customerBlockedSuccessfully
                    : AppLocalizations.of(
                        context,
                      )!.customerUnblockedSuccessfully,
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: state.isBlocked ? Colors.red : Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state is BlockUnblockCustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.error}: ${state.error}',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.manageCustomers),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Modern Search Bar with shadow and elevation
            Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: AppLocalizations.of(context)!.search,
                  leading: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  trailing: _searchQuery.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            tooltip: AppLocalizations.of(context)!.clear,
                          ),
                        ]
                      : null,
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(
                    theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),

            // Elegant Filter Chips
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 8.0,
                  children: [
                    // All Chip
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list_rounded,
                            size: 16,
                            color: _selectedFilter == 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.all,
                            style: TextStyle(
                              fontWeight: _selectedFilter == 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedFilter == 0,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 0;
                        });
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                      backgroundColor: theme.colorScheme.surface,
                      elevation: _selectedFilter == 0 ? 2 : 0,
                      pressElevation: 4,
                      side: BorderSide(
                        color: _selectedFilter == 0
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: _selectedFilter == 0 ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      showCheckmark: false,
                    ),

                    // Active Chip
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: _selectedFilter == 1
                                ? Colors.green.shade700
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.active,
                            style: TextStyle(
                              fontWeight: _selectedFilter == 1
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedFilter == 1,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 1;
                        });
                      },
                      selectedColor: Colors.green.shade50,
                      backgroundColor: theme.colorScheme.surface,
                      elevation: _selectedFilter == 1 ? 2 : 0,
                      pressElevation: 4,
                      side: BorderSide(
                        color: _selectedFilter == 1
                            ? Colors.green.shade300
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: _selectedFilter == 1 ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      showCheckmark: false,
                    ),

                    // Blocked Chip
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 16,
                            color: _selectedFilter == 2
                                ? Colors.red.shade700
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.blocked,
                            style: TextStyle(
                              fontWeight: _selectedFilter == 2
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedFilter == 2,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 2;
                        });
                      },
                      selectedColor: Colors.red.shade50,
                      backgroundColor: theme.colorScheme.surface,
                      elevation: _selectedFilter == 2 ? 2 : 0,
                      pressElevation: 4,
                      side: BorderSide(
                        color: _selectedFilter == 2
                            ? Colors.red.shade300
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: _selectedFilter == 2 ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      showCheckmark: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Customers List
            Expanded(
              child: StreamBuilder(
                stream: AppServices.getAllCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Loader(size: 50));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noCustomersFound,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final customers = snapshot.data!;

                  // Apply filters
                  final filteredCustomers = customers.where((customer) {
                    // Search filter - includes name, email, and phone
                    bool matchesSearch = true;
                    if (_searchQuery.isNotEmpty) {
                      final name = (customer.name ?? '').toLowerCase();
                      final email = (customer.email ?? '').toLowerCase();
                      final phone = (customer.phone ?? '').toLowerCase();
                      matchesSearch =
                          name.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }

                    // Block status filter
                    bool matchesBlockStatus = true;
                    final isBlocked = customer.isBlocked ?? false;

                    if (_selectedFilter == 1) {
                      // Show only active (not blocked)
                      matchesBlockStatus = !isBlocked;
                    } else if (_selectedFilter == 2) {
                      // Show only blocked
                      matchesBlockStatus = isBlocked;
                    }
                    // If _selectedFilter == 0 (All), matchesBlockStatus stays true

                    return matchesSearch && matchesBlockStatus;
                  }).toList();

                  // Show message if no results found
                  if (filteredCustomers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.noCustomersMatchYourSearch,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.tryAdjustingYourSearchCriteria,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final isBlocked = customer.isBlocked ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isBlocked
                                  ? Colors.red.shade200
                                  : theme.colorScheme.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              // Handle customer tap if needed
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isBlocked
                                            ? [
                                                Colors.red.shade400,
                                                Colors.red.shade300,
                                              ]
                                            : [
                                                Colors.green.shade400,
                                                Colors.green.shade300,
                                              ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isBlocked
                                                      ? Colors.red
                                                      : Colors.green)
                                                  .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        (customer.name ?? 'C')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Customer Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                customer.name ?? 'Unknown',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isBlocked
                                                    ? Colors.red.shade50
                                                    : Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isBlocked
                                                        ? Icons.block_rounded
                                                        : Icons
                                                              .check_circle_rounded,
                                                    size: 14,
                                                    color: isBlocked
                                                        ? Colors.red.shade700
                                                        : Colors.green.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isBlocked
                                                        ? AppLocalizations.of(
                                                            context,
                                                          )!.blocked
                                                        : AppLocalizations.of(
                                                            context,
                                                          )!.active,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isBlocked
                                                          ? Colors.red.shade700
                                                          : Colors
                                                                .green
                                                                .shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (customer.email != null &&
                                            customer.email!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.email_outlined,
                                                size: 14,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  customer.email!,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 13,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (customer.phone != null &&
                                            customer.phone!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.phone_outlined,
                                                  size: 14,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  customer.phone ?? "",
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 13,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Toggle Button with Confirmation
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final confirmed = await _showConfirmationDialog(
                                          context: context,
                                          title: isBlocked
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.unblockCustomer
                                              : AppLocalizations.of(
                                                  context,
                                                )!.blockCustomer,
                                          message: isBlocked
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.areYouSureYouWantToUnBlockThisCustomer
                                              : AppLocalizations.of(
                                                  context,
                                                )!.areYouSureYouWantToBlockThisCustomer,
                                          isBlocking: !isBlocked,
                                        );

                                        if (confirmed == true &&
                                            context.mounted) {
                                          context.read<ManageAppBloc>().add(
                                            CustomerBlockUnblockEvent(
                                              customer.uid,
                                              !isBlocked,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isBlocked
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          isBlocked
                                              ? Icons.check_circle_rounded
                                              : Icons.block_rounded,
                                          color: isBlocked
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
