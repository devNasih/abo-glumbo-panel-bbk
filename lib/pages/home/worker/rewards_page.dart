import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  final UserModel workerData;
  const RewardsPage({super.key, required this.workerData});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int totalJobsCount = 0;
  double currentRating = 0.0;
  String currentTier = 'Bronze';
  double bonusAmount = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRewardsData();
  }

  Future<void> _fetchRewardsData() async {
    try {
      String uid = LocalStore.getUID() ?? "";
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          totalJobsCount = _toInt(data?['currentMonthJobs']);
          currentRating = _toDouble(data?['rating']);
          currentTier = data?['tier'] ?? 'Bronze';
          bonusAmount = _toDouble(data?['bonusAmount']);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rewards data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    bool isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.rewards,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: Loader())
          : RefreshIndicator(
              onRefresh: _fetchRewardsData,
              child: CustomScrollView(
                slivers: [
                  // Bonus Payout Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _buildBonusPayoutCard(),
                    ),
                  ),

                  // Current Tier Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: _buildCurrentTierCard(),
                    ),
                  ),

                  // Tier Information Section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.05),
                            AppColors.primary.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            24,
                          ),
                          collapsedBackgroundColor: Colors.transparent,
                          backgroundColor: Colors.transparent,
                          iconColor: AppColors.primary,
                          collapsedIconColor: AppColors.primary,
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.emoji_events_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.tierSystem,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          expandedAlignment: isArabic
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          children: [
                            _buildPremiumTierCard(
                              'Bronze',
                              AppLocalizations.of(
                                context,
                              )!.greaterThan3dot5rating,
                              AppLocalizations.of(context)!.nobonus,
                              const Color(0xFF9A6038),
                            ),
                            const SizedBox(height: 12),
                            _buildPremiumTierCard(
                              'Silver',
                              '${AppLocalizations.of(context)!.twentyPlusJobs}, ${AppLocalizations.of(context)!.greaterThan4dot0rating}',
                              AppLocalizations.of(context)!.fivepercentBonus,
                              const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 12),
                            _buildPremiumTierCard(
                              'Gold',
                              '${AppLocalizations.of(context)!.fortyPlusJobs}, ${AppLocalizations.of(context)!.greaterThan4dot5rating}',
                              AppLocalizations.of(context)!.tenpercentBonus,
                              const Color(0xFFD97706),
                            ),
                            const SizedBox(height: 12),
                            _buildPremiumTierCard(
                              'Platinum',
                              '${AppLocalizations.of(context)!.sixtyPlusJobs}, ${AppLocalizations.of(context)!.greaterThan4dot8rating}',
                              AppLocalizations.of(context)!.fifteenpercentBonus,
                              const Color(0xFF6366F1),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.progressResetsMonthly,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentTierCard() {
    double progress = _calculateProgress(
      currentTier,
      totalJobsCount,
      currentRating,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getTierProgressColor(currentTier).withOpacity(0.08),
                    _getTierProgressColor(currentTier).withOpacity(0.02),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.rewards,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTierBenefit(currentTier),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _getTierProgressColor(
                          currentTier,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTierProgressColor(
                            currentTier,
                          ).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTierIcon(currentTier),
                            size: 16,
                            color: _getTierProgressColor(currentTier),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getTierName(currentTier),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _getTierProgressColor(currentTier),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildPremiumStatCard(
                        Icons.work_outline_rounded,
                        AppLocalizations.of(context)!.jobs,
                        totalJobsCount.toString(),
                        const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPremiumStatCard(
                        Icons.star_outline_rounded,
                        AppLocalizations.of(context)!.rating,
                        currentRating.toStringAsFixed(1),
                        const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPremiumStatCard(
                        Icons.payments_outlined,
                        AppLocalizations.of(context)!.bonus,
                        '${bonusAmount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Progress Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getTierProgressColor(
                                    currentTier,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: _getTierProgressColor(currentTier),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.nextTierProgress,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierProgressColor(
                                currentTier,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _getTierProgressColor(currentTier),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getTierProgressColor(currentTier),
                                        _getTierProgressColor(
                                          currentTier,
                                        ).withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTierCard(
    String tierName,
    String criteria,
    String reward,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getTierIconByName(tierName), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTierName(tierName),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  criteria,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  reward,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

  Widget _buildPremiumStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(String tier, int jobs, double rating) {
    switch (tier) {
      case 'Bronze':
        if (rating < 4.0) return 0.0;
        return (jobs / 20.0).clamp(0.0, 1.0);
      case 'Silver':
        if (rating < 4.5) return 0.0;
        return (jobs / 40.0).clamp(0.0, 1.0);
      case 'Gold':
        if (rating < 4.8) return 0.0;
        return (jobs / 60.0).clamp(0.0, 1.0);
      case 'Platinum':
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _getTierBenefit(String tier) {
    switch (tier) {
      case 'Platinum':
        return AppLocalizations.of(
          context,
        )!.fifteenpercentBonusOnEarningsandASpecialBadge;
      case 'Gold':
        return AppLocalizations.of(context)!.tenpercentBonusOnEarnings;
      case 'Silver':
        return AppLocalizations.of(context)!.fivepercentBonusOnEarnings;
      default:
        return AppLocalizations.of(context)!.nobonus;
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

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'Platinum':
        return Icons.military_tech;
      case 'Gold':
        return Icons.workspace_premium;
      case 'Silver':
        return Icons.star;
      case 'Bronze':
        return Icons.shield;
      default:
        return Icons.shield;
    }
  }

  IconData _getTierIconByName(String tierName) {
    switch (tierName) {
      case 'Platinum':
        return Icons.military_tech;
      case 'Gold':
        return Icons.workspace_premium;
      case 'Silver':
        return Icons.star;
      case 'Bronze':
        return Icons.shield;
      default:
        return Icons.shield;
    }
  }

  String _getTierName(String tier) {
    switch (tier) {
      case 'Platinum':
        return AppLocalizations.of(context)!.platinum;
      case 'Gold':
        return AppLocalizations.of(context)!.gold;
      case 'Silver':
        return AppLocalizations.of(context)!.silver;
      case 'Bronze':
        return AppLocalizations.of(context)!.bronze;
      default:
        return AppLocalizations.of(context)!.bronze;
    }
  }

  Widget _buildBonusPayoutCard() {
    return FutureBuilder<double>(
      future: AppServices.getWorkerBonusAmounts(widget.workerData.uid!),
      builder: (context, snapshot) {
        final totalMonthlyBonus = snapshot.data ?? 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(255),
                AppColors.primary.withAlpha(128),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.monthlyBonusEarned,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${totalMonthlyBonus.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Info message about unified wallet
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.bonusIncludedInWallet,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
