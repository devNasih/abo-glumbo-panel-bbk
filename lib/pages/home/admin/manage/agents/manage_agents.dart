import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/agents/agent_info.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageAgents extends StatefulWidget {
  const ManageAgents({super.key});

  @override
  State<ManageAgents> createState() => _ManageAgentsState();
}

class _ManageAgentsState extends State<ManageAgents> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter chip state - 0: All, 1: Verified, 2: Pending
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
    required bool isApproval,
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
                  color: isApproval ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isApproval ? Icons.check_circle_rounded : Icons.block_rounded,
                  color: isApproval
                      ? Colors.green.shade600
                      : Colors.red.shade600,
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
                backgroundColor: isApproval
                    ? Colors.green.shade600
                    : Colors.red.shade600,
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
        if (state is AgentApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isApproved
                    ? AppLocalizations.of(context)!.agentApproved
                    : AppLocalizations.of(context)!.agentDisapproved,
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: state.isApproved ? Colors.green : Colors.red,
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
          title: Text(AppLocalizations.of(context)!.manageWorkers),
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

            // Elegant Filter Chips - Choice Chips for exclusive selection
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

                    // Verified Chip - Now with GREEN colors
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _selectedFilter == 1
                                ? Colors.green.shade700
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.verified,
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

                    // Pending Chip
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending_rounded,
                            size: 16,
                            color: _selectedFilter == 2
                                ? Colors.orange.shade700
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.pending,
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
                      selectedColor: Colors.orange.shade50,
                      backgroundColor: theme.colorScheme.surface,
                      elevation: _selectedFilter == 2 ? 2 : 0,
                      pressElevation: 4,
                      side: BorderSide(
                        color: _selectedFilter == 2
                            ? Colors.orange.shade300
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

            // Agent List
            Expanded(
              child: StreamBuilder(
                stream: AppServices.getAllAgentsStream(),
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
                            AppLocalizations.of(context)!.noAgentsFound,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final agents = snapshot.data!;

                  // Apply filters
                  final filteredAgents = agents.where((agent) {
                    // Search filter - includes name and email
                    bool matchesSearch = true;
                    if (_searchQuery.isNotEmpty) {
                      final name = (agent.name ?? '').toLowerCase();
                      final email = (agent.email ?? '').toLowerCase();
                      matchesSearch =
                          name.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }

                    // Verification status filter
                    bool matchesVerification = true;
                    final isVerified = agent.isVerified ?? false;

                    if (_selectedFilter == 1) {
                      // Show only verified
                      matchesVerification = isVerified;
                    } else if (_selectedFilter == 2) {
                      // Show only pending
                      matchesVerification = !isVerified;
                    }
                    // If _selectedFilter == 0 (All), matchesVerification stays true

                    return matchesSearch && matchesVerification;
                  }).toList();

                  // Show message if no results found
                  if (filteredAgents.isEmpty) {
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
                            )!.noWorkersMatchYourFilters,
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
                    itemCount: filteredAgents.length,
                    itemBuilder: (context, index) {
                      final agent = filteredAgents[index];
                      final isVerified = agent.isVerified ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isVerified
                                  ? Colors.green.shade200
                                  : theme.colorScheme.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgentInfo(agent: agent),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar - GREEN for verified
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isVerified
                                            ? [
                                                Colors.green.shade400,
                                                Colors.green.shade300,
                                              ]
                                            : [
                                                Colors.orange.shade400,
                                                Colors.orange.shade300,
                                              ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isVerified
                                                      ? Colors.green
                                                      : Colors.orange)
                                                  .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        (agent.name ?? 'A')
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

                                  // Agent Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                agent.name ?? 'Unknown',
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
                                                color: isVerified
                                                    ? Colors.green.shade50
                                                    : Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isVerified
                                                        ? Icons.verified_rounded
                                                        : Icons.pending_rounded,
                                                    size: 14,
                                                    color: isVerified
                                                        ? Colors.green.shade700
                                                        : Colors
                                                              .orange
                                                              .shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isVerified
                                                        ? AppLocalizations.of(
                                                            context,
                                                          )!.verified
                                                        : AppLocalizations.of(
                                                            context,
                                                          )!.pending,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isVerified
                                                          ? Colors
                                                                .green
                                                                .shade700
                                                          : Colors
                                                                .orange
                                                                .shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (agent.email != null &&
                                            agent.email!.isNotEmpty)
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
                                                  agent.email!,
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
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Toggle Button with Confirmation
                                  if (agent.uid != null)
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () async {
                                          final confirmed =
                                              await _showConfirmationDialog(
                                                context: context,
                                                title: isVerified
                                                    ? AppLocalizations.of(
                                                        context,
                                                      )!.disapproveAgent
                                                    : AppLocalizations.of(
                                                        context,
                                                      )!.approveAgent,
                                                message: isVerified
                                                    ? AppLocalizations.of(
                                                        context,
                                                      )!.areYouSureYouWantToDisapproveAgent
                                                    : AppLocalizations.of(
                                                        context,
                                                      )!.areYouSureYouWantToApproveThisAgent,
                                                isApproval: !isVerified,
                                              );

                                          if (confirmed == true &&
                                              context.mounted) {
                                            context.read<ManageAppBloc>().add(
                                              ApproveRejectAgentEvent(
                                                agent.uid!,
                                                !isVerified,
                                              ),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isVerified
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            isVerified
                                                ? Icons.block_rounded
                                                : Icons.check_circle_rounded,
                                            color: isVerified
                                                ? Colors.red.shade600
                                                : Colors.green.shade600,
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
