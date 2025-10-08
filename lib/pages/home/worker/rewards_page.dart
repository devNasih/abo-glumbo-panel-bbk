import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/stat_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  final UserModel workerData;
  const RewardsPage({super.key, required this.workerData});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final Map<String, dynamic> workerStats = {
    'Electrician': {'jobs': 25, 'rating': 4.2, 'earnings': 500.0},
    'Flooring': {'jobs': 10, 'rating': 4.5, 'earnings': 120.0},
    'Plumber': {'jobs': 15, 'rating': 4.1, 'earnings': 300.0},
    'A/C': {'jobs': 15, 'rating': 4.1, 'earnings': 300.0},
  };
  List<String> categoryIds = [];
  List<String> categories = [];

  // Cache for stats per categoryId
  Map<String, Map<String, dynamic>> statsCache = {};

  @override
  void initState() {
    super.initState();
    categories = widget.workerData.jobRoles ?? [];
    // Fetch all category IDs for the worker's job roles on init
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

    // After fetching categoryIds, fetch stats once for each
    await _fetchAllStats();
  }

  Future<void> _fetchAllStats() async {
    String uid = LocalStore.getUID() ?? "";
    Map<String, Map<String, dynamic>> cache = {};
    for (String catId in categoryIds) {
      try {
        // Get stats once as a snapshot (statServices may need a method for one-time fetch)
        // Using a single get instead of stream for caching
        var snapshot = await StatServices.getStatsOnce(uid, catId);
        if (snapshot != null) {
          cache[catId] = snapshot;
          log('Fetched stats for $catId: $snapshot');
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(AppLocalizations.of(context)!.rewards),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTierInfoRow('Bronze', 'Rating ≥ 3.5', 'No bonus'),
                _buildTierInfoRow(
                  'Silver',
                  '≥ 20 jobs/month & Rating ≥ 4.0',
                  '5% bonus',
                ),
                _buildTierInfoRow(
                  'Gold',
                  '≥ 40 jobs/month & Rating ≥ 4.5',
                  '10% bonus',
                ),
                _buildTierInfoRow(
                  'Platinum',
                  '≥ 60 jobs/month & Rating ≥ 4.8',
                  '15% bonus + Special badge',
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress resets monthly. Maintain high ratings and complete more jobs to unlock bigger rewards.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // List of cards
          Expanded(
            child: categoryIds.isEmpty
                ? Center(child: Loader())
                : statsCache.isEmpty
                ? Center(child: Loader())
                : ListView.builder(
                    itemCount: categoryIds.length,
                    itemBuilder: (context, index) {
                      String categoryId = categoryIds[index];
                      Map<String, dynamic>? data = statsCache[categoryId];

                      if (data == null) {
                        return Center(child: Text('No data for this category'));
                      }

                      final rating = data['rating'] ?? 0.0;
                      final jobs = data['jobs'] ?? 0;

                      log('Rating: $rating, Jobs: $jobs');
                      log('Category: $categoryId');

                      String tier;
                      double progress;
                      String description;

                      if (rating >= 4.5 && jobs >= 60) {
                        tier = 'Platinum';
                        progress = 1.0;
                        description = '15% bonus + Special badge';
                      } else if (rating >= 4.0 && rating < 4.5 && jobs >= 40) {
                        tier = 'Gold';
                        progress = jobs / 60.0;
                        description = '10% bonus + Priority access to jobs';
                      } else if (rating >= 3.5 && rating < 4.0 && jobs >= 20) {
                        tier = 'Silver';
                        progress = jobs / 40.0;
                        description = '5% bonus';
                      } else {
                        // Below 3.5 rating is Bronze tier, no job condition needed
                        tier = 'Bronze';
                        progress = jobs / 20.0;
                        description = 'No bonus';
                      }
                      progress = progress.clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _getTierShadow(tier),
                              offset: const Offset(0, 5),
                              blurRadius: 12,
                            ),
                          ],
                          border: Border.all(
                            color: _getTierColor(tier).withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.workerData.jobRoles?[index] ?? "",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _getTierTextColor(tier),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTierColor(
                                        tier,
                                      ).withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      tier,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildStatRow(
                                'Jobs done (this month):',
                                jobs.toString(),
                              ),
                              _buildStatRow(
                                'Rating:',
                                rating.toStringAsFixed(1),
                              ),
                              _buildStatRow(
                                'Earnings:',
                                '₹500',
                              ), // Optionally make this dynamic
                              const SizedBox(height: 15),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  color: _getTierColor(tier),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Progress towards next tier',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _getTierColor(tier),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFFCCAFFF); // luxury purple/blue highlight
      case 'Gold':
        return const Color(0xFFFFD700); // true gold
      case 'Silver':
        return const Color(0xFFC0C0C0); // true silver
      case 'Bronze':
        return const Color(0xFFCD7F32); // true bronze
      default:
        return Colors.grey.shade600; // fallback for Basic tier
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierShadow(String tier) {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFFBCC5F6).withOpacity(0.2);
      case 'Gold':
        return const Color(0xFFE3C86A).withOpacity(0.23);
      case 'Silver':
        return Colors.grey.shade400.withOpacity(0.21);
      case 'Bronze':
        return const Color(0xFFB97A57).withOpacity(0.18);
      default:
        return Colors.grey.shade400.withOpacity(0.14);
    }
  }

  Color _getTierTextColor(String tier) {
    switch (tier) {
      case 'Gold':
        return const Color(0xFF776300);
      case 'Platinum':
        return const Color(0xFF4C3990);
      case 'Silver':
        return const Color(0xFF707275);
      case 'Bronze':
        return const Color(0xFF834202);
      default:
        return Colors.black87;
    }
  }

  Widget _buildTierInfoRow(String tierName, String criteria, String reward) {
    final Color tierColor = _getTierColor(tierName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              tierName,
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: '$criteria → '),
                  TextSpan(
                    text: reward,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
