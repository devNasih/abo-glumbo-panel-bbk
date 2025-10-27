import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/stat_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';

import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  final UserModel workerData;
  const RewardsPage({super.key, required this.workerData});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<String> categoryIds = [];
  List<String> categories = [];
  Map<String, Map<String, dynamic>> statsCache = {};

  @override
  void initState() {
    super.initState();
    categories = widget.workerData.jobRoles ?? [];
    _fetchCategoryIds(widget.workerData.jobRoles ?? []);
  }

  Future<void> _fetchCategoryIds(List<String> jobRoles) async {
    List<String> ids = [];
    for (String role in jobRoles) {
      String? catId = await AppServices.getCategoryIdByJobRoleOnce(role);
      if (catId != null) {
        ids.add(catId);
      }
    }
    setState(() {
      categoryIds = ids;
    });

    await _fetchAllStats();
  }

  Future<void> _fetchAllStats() async {
    String uid = LocalStore.getUID() ?? "";
    Map<String, Map<String, dynamic>> cache = {};
    for (String catId in categoryIds) {
      try {
        var snapshot = await StatServices.getStatsOnce(uid, catId);
        if (snapshot.isNotEmpty) {
          cache[catId] = snapshot;
        }
      } catch (e) {
        log('Error fetching stats for $catId: $e');
      }
    }
    setState(() {
      statsCache = cache;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.rewards,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: categoryIds.isEmpty || statsCache.isEmpty
          ? Center(child: Loader())
          : CustomScrollView(
              slivers: [
                // Tier Information Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ExpansionTile(
                      collapsedBackgroundColor: Colors.white,
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.tierSystem,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      expandedAlignment: isArabic
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      children: [
                        _buildMinimalTierRow(
                          AppLocalizations.of(context)!.bronze,
                          AppLocalizations.of(context)!.greaterThan3dot5rating,
                          AppLocalizations.of(context)!.nobonus,
                        ),
                        _buildDivider(),
                        _buildMinimalTierRow(
                          AppLocalizations.of(context)!.silver,
                          '${AppLocalizations.of(context)!.greaterThan20jobsPerMonth}, ${AppLocalizations.of(context)!.greaterThan4dot0rating}',
                          AppLocalizations.of(context)!.fivepercentBonus,
                        ),
                        _buildDivider(),
                        _buildMinimalTierRow(
                          AppLocalizations.of(context)!.gold,
                          '${AppLocalizations.of(context)!.greaterThan40jobsPerMonth}, ${AppLocalizations.of(context)!.greaterThan4dot5rating}',
                          AppLocalizations.of(context)!.tenpercentBonus,
                        ),
                        _buildDivider(),
                        _buildMinimalTierRow(
                          AppLocalizations.of(context)!.silver,
                          '${AppLocalizations.of(context)!.greaterThan60jobsPerMonth}, ${AppLocalizations.of(context)!.greaterThan4dot8rating}',
                          AppLocalizations.of(context)!.fifteenpercentBonus,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.progressResetsMonthly,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      String categoryId = categoryIds[index];
                      Map<String, dynamic>? data = statsCache[categoryId];

                      if (data == null) {
                        return const SizedBox.shrink();
                      }

                      final rating = data['rating'] ?? 0.0;
                      final jobs = data['jobs'] ?? 0;

                      String tier;
                      double progress;
                      String benefit;

                      if (rating >= 4.8 && jobs >= 60) {
                        tier = 'Platinum';
                        progress = 1.0;
                        benefit = '15% bonus + Special badge';
                      } else if (rating >= 4.5 && jobs >= 40) {
                        tier = 'Gold';
                        progress = jobs / 60.0;
                        benefit = '10% bonus on earnings';
                      } else if (rating >= 4.0 && jobs >= 20) {
                        tier = 'Silver';
                        progress = jobs / 40.0;
                        benefit = '5% bonus on earnings';
                      } else {
                        tier = 'Bronze';
                        progress = jobs / 20.0;
                        benefit = 'No Bonus';
                      }
                      progress = progress.clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.workerData.jobRoles?[index] ?? "",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getMinimalTierColor(tier),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tier.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getTierTextColor(tier),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    AppLocalizations.of(context)!.jobs,
                                    jobs.toString(),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade200,
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    AppLocalizations.of(context)!.rating,
                                    rating.toStringAsFixed(1),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade200,
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    AppLocalizations.of(context)!.bonus,
                                    '0',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.nextTierProgress,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade100,
                                    color: _getTierProgressColor(tier),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Benefit
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: categoryIds.length),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMinimalTierRow(String tierName, String criteria, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              tierName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criteria,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  reward,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getMinimalTierColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFFF5F3FF);
      case 'Gold':
        return const Color(0xFFFFFBEB);
      case 'Silver':
        return const Color(0xFFF8F9FA);
      case 'Bronze':
        return const Color(0xFFFEF3EC);
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getTierTextColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFF6366F1);
      case 'Gold':
        return const Color(0xFFD97706);
      case 'Silver':
        return const Color(0xFF64748B);
      case 'Bronze':
        return const Color(0xFF9A6038);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getTierProgressColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFF6366F1);
      case 'Gold':
        return const Color(0xFFD97706);
      case 'Silver':
        return const Color(0xFF64748B);
      case 'Bronze':
        return const Color(0xFF9A6038);
      default:
        return Colors.grey.shade400;
    }
  }
}
