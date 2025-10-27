
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/notifications.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/contact_bottom_sheet.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/earnings.dart';
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
  List<TransactionModel> transactions = [];
  TippingModel? tippingData;
  bool isLoading = true;

  double cashPayments = 0.0;
  double cardPayments = 0.0;
  double totalEarnings = 0.0;
  double totalTips = 0.0;
  // Key to track refresh state
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Stream key to force rebuild
  int _refreshKey = 0;
  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => isLoading = true);

    transactions = await AppServices.getWorkerTransactions(
      widget.workerData.uid ?? "",
    );
    tippingData = await AppServices.getWorkerTippingData(
      widget.workerData.uid ?? "",
    );

    _calculateEarnings();
    setState(() => isLoading = false);
  }

  void _calculateEarnings() {
    cashPayments = 0.0;
    cardPayments = 0.0;

    for (var transaction in transactions) {
      if (transaction.paymentStatus.toLowerCase() == 'completed' ||
          transaction.paymentStatus.toLowerCase() == 'paid') {
        if (transaction.paymentMethod.toLowerCase() == 'cash') {
          cashPayments += transaction.amount;
        } else if (transaction.paymentMethod.toLowerCase() == 'card') {
          cardPayments += transaction.amount;
        }
      }
    }

    totalTips = tippingData?.totalTip ?? 0.0;
    totalEarnings = cashPayments + cardPayments + totalTips;
  }

  Future<void> _handleRefresh() async {
    _loadEarningsData();
    // Add a small delay to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));

    // Trigger a rebuild by updating the key
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Performance Stats
                _buildStatsSection(),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(),
                const SizedBox(height: 16),
                _buildEarningsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsSection() {
    return !isLoading
        ? _buildStatCard(
            _StatData(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerEarningsPage(
                      workerId: widget.workerData.uid ?? "",
                    ),
                  ),
                );
              },
              title: AppLocalizations.of(context)!.earnings,
              subtitle: "",
              value: totalEarnings.toString(),
              icon: Icons.wallet,
              color: Colors.deepPurple,
            ),
          )
        : _buildStatShimmerCard();
  }

  Widget _buildStatsSection() {
    return StreamBuilder(
      key: ValueKey(_refreshKey), // Force stream to rebuild
      stream: AppServices.getallstats(widget.workerData.uid ?? ""),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return _buildStatsShimmerSection();
        }
        if (asyncSnapshot.hasError) {
          return Center(
            child: Text(
              '${AppLocalizations.of(context)!.error}: ${asyncSnapshot.error}',
            ),
          );
        }
        // return _buildStatsShimmerSection();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final stats = [
              _StatData(
                title: AppLocalizations.of(context)!.newtext,
                subtitle: AppLocalizations.of(context)!.requests,
                value: asyncSnapshot.data!['latest'].toString(),
                icon: Icons.assignment_outlined,
                color: AppColors.secondary,
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Home(newIndex: 1)),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              _StatData(
                title: AppLocalizations.of(context)!.completed,
                subtitle: AppLocalizations.of(context)!.requests,
                value: asyncSnapshot.data!['completed'].toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) =>
                          Home(newIndex: 1, selectedFilter: "C"),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              _StatData(
                onTap: () {},
                title: AppLocalizations.of(context)!.rating,
                subtitle: "",
                value: asyncSnapshot.data!['rating'].toString(),
                icon: Icons.star_outline,
                color: const Color.fromRGBO(254, 217, 55, 1),
              ),
            ];

            if (isWide) {
              return Row(
                children: stats.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: entry.key == stats.length - 1 ? 0 : 12,
                      ),
                      child: _buildStatCard(entry.value),
                    ),
                  );
                }).toList(),
              );
            } else {
              return Column(
                children: stats.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == stats.length - 1 ? 0 : 12,
                    ),
                    child: _buildStatCard(entry.value),
                  );
                }).toList(),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard(_StatData data) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 28),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: data.title,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '\n${data.subtitle}',
                        style: TextStyle(
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
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
              AppLocalizations.of(context)!.support,
              AppLocalizations.of(context)!.getHelpAnytime,
              Icons.support_agent_outlined,
              AppColors.red,
              () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const ContactBottomSheet(),
                );
              },
            ),
            _buildActionButton(
              AppLocalizations.of(context)!.rewards,
              AppLocalizations.of(context)!.viewYourRewards,
              Icons.card_giftcard_outlined,
              const Color.fromARGB(255, 255, 168, 38),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RewardsPage(workerData: widget.workerData),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    String label,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback? ontap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
          onTap: ontap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  subtitle,
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

  Widget _buildStatsShimmerSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final stats = List.generate(3, (index) => _buildStatShimmerCard());

        if (isWide) {
          return Row(
            children: stats.asMap().entries.map((entry) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: entry.key == stats.length - 1 ? 0 : 12,
                  ),
                  child: entry.value,
                ),
              );
            }).toList(),
          );
        } else {
          return Column(
            children: stats.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == stats.length - 1 ? 0 : 12,
                ),
                child: entry.value,
              );
            }).toList(),
          );
        }
      },
    );
  }

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
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 40, height: 40, borderRadius: 12),
              SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
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
          _buildShimmerBox(width: 30, height: 30),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

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

class _StatData {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _StatData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
