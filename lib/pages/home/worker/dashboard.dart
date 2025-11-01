import 'dart:async';

import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/notifications.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/contact_bottom_sheet.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/earnings.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/reviews.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/rewards_page.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.workerData});

  final UserModel workerData;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<DashboardDataStream> _dashboardStream;
  late AppServices _appServices;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _appServices = AppServices();
    _dashboardStream = AppServices.getCompleteDashboardStreamWithRefresh(
      widget.workerData.uid ?? "",
      _appServices.dashboardRefreshTrigger,
    );
  }

  /// Get rating quality text
  String _getRatingSubtitle(double rating) {
    final l10n = AppLocalizations.of(context)!;
    if (rating >= 4.5) return l10n.excellent;
    if (rating >= 3.5) return l10n.good;
    if (rating >= 2.5) return l10n.average;
    return l10n.poor;
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Add a small delay to ensure UI updates smoothly
      await Future.delayed(const Duration(milliseconds: 500));

      // Trigger manual refresh through the controller
      _appServices.triggerDashboardRefresh();

      // Wait for stream to emit new data
      await _dashboardStream.first;

      debugPrint('✅ Refresh completed');
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up refresh controller
    _appServices.disposeDashboardRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<DashboardDataStream>(
          stream: _dashboardStream,

          builder: (context, snapshot) {
            // Coordinated loading state - all shimmer together
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            // Error state
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            // Success state - all data displayed together
            if (snapshot.hasData) {
              return _buildSuccessState(snapshot.data!);
            }

            return _buildLoadingState();
          },
        ),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      elevation: 0,
      title: Text(AppLocalizations.of(context)!.dashboard),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotificationsPage()),
          ),
        ),
      ],
    );
  }

  /// Build loading state with shimmer placeholders
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsShimmerSection(),
            const SizedBox(height: 16),
            _buildQuickActionsShimmer(),
            const SizedBox(height: 16),
            _buildStatShimmerCard(),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.error,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build success state with all loaded data
  Widget _buildSuccessState(DashboardDataStream data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(data.stats),
            const SizedBox(height: 16),
            _buildEarningsCard(data.totalEarnings),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build stats section
  Widget _buildStatsSection(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;

    final stats = [
      _StatData(
        title: l10n.newtext,
        subtitle: l10n.requests,
        value: data['latest']?.toString() ?? '0',
        icon: Icons.assignment_outlined,
        color: AppColors.secondary,
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Home(newIndex: 1)),
          (_) => false,
        ),
      ),
      _StatData(
        title: l10n.paymentPending,
        subtitle: l10n.requests,
        value: data['paymentPending']?.toString() ?? '0',
        icon: Icons.monetization_on,
        color: Colors.teal,
        onTap: () {},
      ),
      _StatData(
        title: l10n.completed,
        subtitle: l10n.requests,
        value: data['completed']?.toString() ?? '0',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF10B981),
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => Home(newIndex: 1, selectedFilter: "C"),
          ),
          (_) => false,
        ),
      ),
      _StatData(
        title: l10n.rating,
        subtitle: _getRatingSubtitle(
          double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
        ),
        value: data['rating']?.toString() ?? '0.0',
        icon: Icons.star_outline,
        color: const Color(0xFFFED937),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WorkerReviewsPage(workerId: widget.workerData.uid ?? ""),
          ),
        ),
      ),
    ];

    return _buildStatsGrid(stats);
  }

  /// Build responsive stats grid
  Widget _buildStatsGrid(List<_StatData> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            children: stats
                .asMap()
                .entries
                .map(
                  (entry) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: entry.key == stats.length - 1 ? 0 : 12,
                      ),
                      child: _buildStatCard(entry.value),
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: stats
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == stats.length - 1 ? 0 : 12,
                  ),
                  child: _buildStatCard(entry.value),
                ),
              )
              .toList(),
        );
      },
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(_StatData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(data.icon, color: data.color, size: 28),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            data.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  data.value,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build earnings card
  Widget _buildEarningsCard(double totalEarnings) {
    return _buildStatCard(
      _StatData(
        title: AppLocalizations.of(context)!.earnings,
        subtitle: "",
        value: totalEarnings.toStringAsFixed(2),
        icon: Icons.wallet,
        color: Colors.deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WorkerEarningsPage(workerId: widget.workerData.uid ?? ""),
          ),
        ),
      ),
    );
  }

  /// Build quick actions grid
  Widget _buildQuickActionsGrid() {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.2,
          children: [
            _buildActionButton(
              l10n.support,
              l10n.getHelpAnytime,
              Icons.support_agent_outlined,
              AppColors.red,
              () => showModalBottomSheet(
                context: context,
                builder: (_) => const ContactBottomSheet(),
              ),
            ),
            _buildActionButton(
              l10n.rewards,
              l10n.viewYourRewards,
              Icons.card_giftcard_outlined,
              const Color(0xFFFFA826),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RewardsPage(workerData: widget.workerData),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build action button
  Widget _buildActionButton(
    String label,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== SHIMMER LOADING STATES ==========

  /// Build shimmer section for stats
  Widget _buildStatsShimmerSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final shimmers = List.generate(3, (_) => _buildStatShimmerCard());

        if (isWide) {
          return Row(
            children: shimmers
                .asMap()
                .entries
                .map(
                  (entry) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: entry.key == shimmers.length - 1 ? 0 : 12,
                      ),
                      child: entry.value,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: shimmers
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == shimmers.length - 1 ? 0 : 12,
                  ),
                  child: entry.value,
                ),
              )
              .toList(),
        );
      },
    );
  }

  /// Build quick actions shimmer
  Widget _buildQuickActionsShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.2,
          children: [_buildActionShimmerCard(), _buildActionShimmerCard()],
        );
      },
    );
  }

  /// Build shimmer card for stat
  Widget _buildStatShimmerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 40, height: 40, borderRadius: 12),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 100, height: 16),
                  const SizedBox(height: 4),
                  _buildShimmerBox(width: 60, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildShimmerBox(width: 80, height: 36),
        ],
      ),
    );
  }

  /// Build shimmer card for action button
  Widget _buildActionShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(width: 44, height: 44, borderRadius: 12),
            const Spacer(),
            _buildShimmerBox(width: 100, height: 16),
            const SizedBox(height: 4),
            _buildShimmerBox(width: 80, height: 12),
          ],
        ),
      ),
    );
  }

  /// Build individual shimmer box
  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ========== DATA MODELS ==========

/// Dashboard data container

/// Stat card data model
class _StatData {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
