import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/payout_requests.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

class WorkerEarningsPage extends StatefulWidget {
  final String workerId;

  const WorkerEarningsPage({super.key, required this.workerId});

  @override
  State<WorkerEarningsPage> createState() => _WorkerEarningsPageState();
}

class _WorkerEarningsPageState extends State<WorkerEarningsPage> {
  List<TransactionModel> transactions = [];
  TippingModel? tips;
  List<AllTipsModel> tipsList = []; // Add this line
  bool isLoading = true;
  int _transactionsToShow = 5; // Track how many transactions to display
  bool _isLoadingMore = false; // Track if loading more transactions
  final Map<String, Future<BookingModel?>> _bookingFutures =
      {}; // Cache for booking futures

  double cashPayments = 0.0;
  double cardPayments = 0.0;
  double totalEarnings = 0.0;
  double paidAmounts = 0.0;
  double lifetimeEarnings = 0.0;
  double totalTips = 0.0;
  double cashTips = 0.0;
  double cardTips = 0.0;
  double availableCardTips = 0.0;
  double fullcashTips = 0.0;
  double fullcardTips = 0.0;
  double total = 0.0;
  double bonusAmounts = 0.0;
  double availableAmount = 0.0;
  List<ReviewModel> reviews = [];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  @override
  void dispose() {
    // Reset transactions to show when navigating away
    _transactionsToShow = 5;
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    setState(() => isLoading = true);

    debugPrint('💰 Loading earnings data for workerId: ${widget.workerId}');

    try {
      // Execute all independent data fetches in parallel with individual error handling
      final results = await Future.wait([
        AppServices.getWorkerTransactions(widget.workerId).catchError((error) {
          debugPrint('Error fetching transactions: $error');
          return <TransactionModel>[]; // Return empty list on error
        }),
        AppServices.getTipsById(widget.workerId).catchError((error) {
          debugPrint('Error fetching tips list: $error');
          return <AllTipsModel>[]; // Now returns List<AllTipsModel>
        }),
        AppServices.getWorkerTippingData(widget.workerId).catchError((error) {
          debugPrint('Error fetching data tips: $error');
          return TippingModel(); // Return 0.0 on error
        }),
        AppServices.getWorkerPaidAmounts(widget.workerId).catchError((error) {
          debugPrint('Error fetching paid amounts: $error');
          return 0.0; // Return 0.0 on error
        }),
        AppServices.getWorkerBonusAmounts(widget.workerId).catchError((error) {
          debugPrint('Error fetching bonus amounts: $error');
          return 0.0; // Return 0.0 on error
        }),
        AppServices.getWorkerReviewsWithTipAmounts(widget.workerId).catchError((
          error,
        ) {
          debugPrint('Error fetching reviews with tip amounts: $error');
          return <ReviewModel>[];
        }),
      ]);

      // Assign results with null safety
      transactions = (results[0] as List<TransactionModel>?) ?? [];
      tipsList = (results[1] as List<AllTipsModel>?) ?? [];
      tips = results[2] as TippingModel;
      paidAmounts = (results[3] as double?) ?? 0.0;
      bonusAmounts = (results[4] as double?) ?? 0.0;
      reviews = (results[5] as List<ReviewModel>?) ?? [];
      int count = tipsList.length;
      int reviewsCount = reviews.length;

      //get lifetime tips
      for (int i = 0; i < count; i++) {
        if (tipsList[i].paymentMethod?.toLowerCase() == 'cards') {
          fullcardTips += tipsList[i].totalTipAmount ?? 0.0;
        } else {
          fullcashTips += tipsList[i].totalTipAmount ?? 0.0;
        }
      }

      for (int j = 0; j < reviewsCount; j++) {
        if (reviews[j].paymentType?.toLowerCase() == "card") {
          cardTips += reviews[j].tipAmount ?? 0.0;
        } else {
          cashTips += reviews[j].tipAmount ?? 0.0;
        }
      }
      // changing tips to total tips

      availableCardTips = tips?.cardtip ?? 0.0;
      // cashTips = tips?.cashtip ?? 0.0;

      //lifetime total tips
      totalTips = cashTips + cardTips;

      debugPrint('💡 Tip Calculation Summary:');
      debugPrint(
        '   From TippingModel: cardTips=$cardTips, cashTips=$cashTips, total=${cardTips + cashTips}',
      );
      debugPrint(
        '   From tipsList: fullcardTips=$fullcardTips, fullcashTips=$fullcashTips, total=${fullcardTips + fullcashTips}',
      );
      debugPrint('   Discrepancy: ${totalTips - (cardTips + cashTips)}');

      // Sort transactions only if not empty
      if (transactions.isNotEmpty) {
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _calculateEarnings();
    } catch (e) {
      debugPrint('Error loading earnings data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _calculateEarnings() async {
    cashPayments = 0.0;
    cardPayments = 0.0;
    // get payments
    for (var transaction in transactions) {
      if (transaction.paymentStatus.toLowerCase() == 'completed' ||
          transaction.paymentStatus.toLowerCase() == 'paid') {
        if (transaction.paymentMethod.toLowerCase() == 'cash on hands') {
          cashPayments += transaction.amount;
        } else if (transaction.paymentMethod.toLowerCase() == 'cards') {
          cardPayments += transaction.amount;
        }
      }
    }

    lifetimeEarnings =
        cashPayments + cardPayments + cashTips + cardTips + bonusAmounts;
    availableAmount = cardPayments - paidAmounts;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is RequestPayoutLoading) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Loader(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.processing),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (state is RequestPayoutSuccess) {
          // Close loading dialog
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.payoutRequestSuccessful,
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Reload earnings data
          _loadEarningsData();
        }

        if (state is RequestPayoutFailure) {
          // Close loading dialog
          Navigator.of(context).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.earnings),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: isLoading
            ? Center(child: Loader(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadEarningsData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalEarningsCard(),
                      const SizedBox(height: 24),
                      _buildPaymentBreakdown(),

                      const SizedBox(height: 24),
                      _buildPayoutSection(),

                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.lifetimeEarnings,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${lifetimeEarnings.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppLocalizations.of(context)!.asOf} ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.paymentBreakdown,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildPaymentCard(
                title: AppLocalizations.of(context)!.cashPayments,
                amount: cashPayments,
                icon: Icons.money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentCard(
                title: AppLocalizations.of(context)!.cardPayments,
                amount: cardPayments,
                icon: Icons.credit_card,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Check if there's already a pending tip payout request
                  if (tips?.payoutRequested == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.cannotRequestPayoutPendingRequest,
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  _showTipsDialog(
                    context,
                    widget.workerId,
                    tips?.payoutRequested ?? false,
                  );
                },
                child: _buildPaymentCard(
                  title: AppLocalizations.of(context)!.totalTips,
                  amount: totalTips,
                  icon: Icons.star,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PayoutRequests(workerId: widget.workerId),
                    ),
                  );
                },
                child: StreamBuilder(
                  stream: AppServices.getPayoutRequestsById(widget.workerId),
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildPayoutRequestCard(
                        title: AppLocalizations.of(context)!.payoutRequests,
                        amount: 0,
                        icon: Icons.wallet,
                        color: Colors.tealAccent,
                      );
                    }

                    if (asyncSnapshot.hasError) {
                      return _buildPayoutRequestCard(
                        title: AppLocalizations.of(context)!.payoutRequests,
                        amount: 0,
                        icon: Icons.wallet,
                        color: Colors.tealAccent,
                      );
                    }
                    final snapshot = asyncSnapshot.data;
                    final payoutRequestCount = snapshot!.length;
                    if (payoutRequestCount == 0) {
                      return _buildPayoutRequestCard(
                        title: AppLocalizations.of(context)!.payoutRequests,
                        amount: 0,
                        icon: Icons.wallet,
                        color: Colors.tealAccent,
                      );
                    }
                    return _buildPayoutRequestCard(
                      title: AppLocalizations.of(context)!.payoutRequests,
                      amount: payoutRequestCount,
                      icon: Icons.wallet,
                      color: Colors.tealAccent,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTipsDialog(
    BuildContext context,
    String agentId,
    bool payoutRequested,
  ) {
    String? errorMessage; // To hold error messages
    bool isLoading = false; // To show loading state

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              actionsAlignment: MainAxisAlignment.start,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.requestTipPayout,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tips Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildTipRow(
                            context,
                            AppLocalizations.of(context)!.lifetimeTips,
                            cashTips + cardTips,
                            Icons.money,
                            Colors.green,
                          ),
                          const Divider(height: 20),
                          _buildTipRow(
                            context,
                            AppLocalizations.of(context)!.availableForPayout,
                            availableCardTips,
                            Icons.credit_card,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Requirement Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.payoutRequirement,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirmation Text
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.areYouSureYouWantToRequestAPayoutForTheAccumulatedTips,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),

                    // Error Message Display
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Loading Indicator
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      Center(child: Loader(color: AppColors.primary, size: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                eButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  context: context,
                  backgroundColor: Colors.white,
                  widget: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                eButton(
                  onPressed: availableCardTips < 10.00
                      ? () {
                          if (mounted) {
                            setState(() {
                              errorMessage = AppLocalizations.of(
                                context,
                              )!.notEnoughBalanceforRequestingTipPayout;
                            });
                          }
                        }
                      : payoutRequested == true
                      ? () {
                          if (mounted) {
                            setState(() {
                              errorMessage = AppLocalizations.of(
                                context,
                              )!.cannotRequestPayoutPendingRequest;
                            });
                          }
                        }
                      : isLoading
                      ? null
                      : () async {
                          if (payoutRequested == false) {
                            // Clear previous error
                            if (mounted) {
                              setState(() {
                                errorMessage = null;
                                isLoading = true;
                              });
                            }

                            try {
                              await AppFirestore.tippingCollectionRef
                                  .doc(widget.workerId)
                                  .update({'payoutRequested': true});

                              if (context.mounted) {
                                Navigator.of(context).pop();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.payoutRequestSubmittedSuccessfully,
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Display error in dialog
                              setState(() {
                                errorMessage =
                                    '${AppLocalizations.of(context)!.errorRequestingPayout}: ${e.toString()}';
                                isLoading = false;
                              });
                            }
                          } else {
                            null;
                          }
                        },
                  context: context,
                  backgroundColor: Colors.green,
                  widget: Text(
                    AppLocalizations.of(context)!.requestPayout,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to build tip rows
  Widget _buildTipRow(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutRequestCard({
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.requestPayout,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.blue[700],
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.availableBalance,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(cardPayments - paidAmounts).toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // First check if there's a pending earnings payout request
                    final payoutRequests =
                        await AppServices.getPayoutRequestsById(
                          widget.workerId,
                        ).first;

                    // Check if there's a pending earnings payout request
                    bool hasPendingEarningsRequest = false;
                    if (payoutRequests.isNotEmpty) {
                      // Filter for earnings type requests only
                      final earningsRequests = payoutRequests
                          .where((req) => req.type == 'earnings')
                          .toList();

                      if (earningsRequests.isNotEmpty) {
                        // Sort by createdAt to get the most recent
                        earningsRequests.sort((a, b) {
                          if (a.createdAt == null && b.createdAt == null) {
                            return 0;
                          }
                          if (a.createdAt == null) return 1;
                          if (b.createdAt == null) return -1;
                          return b.createdAt!.compareTo(a.createdAt!);
                        });

                        // Check if the most recent earnings request is pending
                        final mostRecentEarningsRequest =
                            earningsRequests.first;
                        hasPendingEarningsRequest =
                            mostRecentEarningsRequest.status == 'P';
                      }
                    }

                    if (hasPendingEarningsRequest) {
                      // Show snackbar if there's a pending earnings request
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.cannotRequestPayoutPendingRequest,
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    // Proceed with normal flow if no pending earnings request
                    final user = AppServices.getWorkerById(widget.workerId);
                    bool hasAtleastOnePayoutAccount = await user.then(
                      (value) => value.payoutAccounts!.isNotEmpty,
                    );
                    hasAtleastOnePayoutAccount
                        ? _showPayoutRequestDialog()
                        : ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.youHaveNoPayoutAccountsgotoprofilesectionandaddanaccount,
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                  },
                  icon: const Icon(Icons.send),
                  label: Text(AppLocalizations.of(context)!.requestPayout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.cashPaymentsMessage(cashPayments.toStringAsFixed(2)),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                AppLocalizations.of(context)!.tipspayoutisdoneseparately,

                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 24, bottom: 24),
          child: Text(
            textAlign: TextAlign.start,
            AppLocalizations.of(context)!.recentTransactions,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    if (transactions.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTransactionsYet,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            SizedBox(height: 32),
          ],
        ),
      );
    }

    // Calculate how many transactions to display
    final displayCount = _transactionsToShow > transactions.length
        ? transactions.length
        : _transactionsToShow;
    final hasMore = displayCount < transactions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ),
        const SizedBox(height: 24),
        // Show More button
        if (hasMore) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingMore
                  ? null
                  : () async {
                      setState(() {
                        _isLoadingMore = true;
                      });

                      // Calculate which new transactions will be shown
                      final currentCount = _transactionsToShow;
                      final nextCount = currentCount + 5;
                      final total = transactions.length;
                      final end = nextCount > total ? total : nextCount;

                      // Pre-fetch data for the new transactions
                      final List<Future<BookingModel?>> futuresToWait = [];
                      for (int i = currentCount; i < end; i++) {
                        final transaction = transactions[i];
                        if (!_bookingFutures.containsKey(
                          transaction.bookingId,
                        )) {
                          final future = AppServices.getBookingById(
                            transaction.bookingId,
                          );
                          _bookingFutures[transaction.bookingId] = future;
                          futuresToWait.add(future);
                        }
                      }

                      // Wait for all new data to load
                      if (futuresToWait.isNotEmpty) {
                        await Future.wait(futuresToWait);
                      } else {
                        // Minimal delay if data was already cached/no new data needed
                        await Future.delayed(const Duration(milliseconds: 300));
                      }

                      if (mounted) {
                        setState(() {
                          _transactionsToShow += 5;
                          _isLoadingMore = false;
                        });
                      }
                    },
              icon: _isLoadingMore ? null : const Icon(Icons.expand_more),
              label: _isLoadingMore
                  ? SizedBox(width: 24, height: 24, child: Loader())
                  : Text(AppLocalizations.of(context)!.showMore),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isCash = transaction.paymentMethod.toLowerCase() == 'cash';
    final isPaid =
        transaction.paymentStatus.toLowerCase() == 'completed' ||
        transaction.paymentStatus.toLowerCase() == 'paid';

    // Use cached future or create new one and cache it
    final future = _bookingFutures.putIfAbsent(
      transaction.bookingId,
      () => AppServices.getBookingById(transaction.bookingId),
    );

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        String customerName = '';
        String serviceName = '';
        String serviceNameAr = '';

        if (snapshot.hasData && snapshot.data != null) {
          customerName = snapshot.data!.customer.name ?? '';
          serviceName = snapshot.data!.service.name ?? '';
          serviceNameAr = snapshot.data!.service.name_ar ?? '';
        }

        return ListTile(
          onTap: snapshot.hasData && snapshot.data != null
              ? () => _showTransactionDetailsBottomSheet(
                  context,
                  transaction,
                  snapshot.data!,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: !isCash
                  ? Colors.green.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCash ? Icons.money : Icons.credit_card,
              color: !isCash ? Colors.green : Colors.purple,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customerName.isNotEmpty) ...{
                Text(
                  customerName,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              },
              if (serviceName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  Directionality.of(context) == TextDirection.rtl
                      ? serviceNameAr
                      : serviceName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          subtitle: Text(
            DateFormat(
              'MMM dd, yyyy • hh:mm a',
            ).format(transaction.createdAt.toDate()),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${transaction.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPaid ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionDetailsBottomSheet(
    BuildContext context,
    TransactionModel transaction,
    BookingModel booking,
  ) {
    final isCash = transaction.paymentMethod.toLowerCase() == 'cash';
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final serviceName = isRtl
        ? (booking.service.name_ar ?? booking.service.name ?? '')
        : (booking.service.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,

      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: double.infinity,

                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCash ? Icons.money : Icons.credit_card,
                              color: isCash ? Colors.purple : Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.transactionDetails,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy • hh:mm a',
                                  ).format(transaction.createdAt.toDate()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
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
              ),

              const Divider(height: 1),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isCash ? Colors.purple[700]! : Colors.green[700]!,
                            isCash ? Colors.purple[500]! : Colors.green[500]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isCash ? Colors.purple : Colors.green)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.paidAmount,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${transaction.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isCash
                                  ? AppLocalizations.of(context)!.cashInHand
                                  : AppLocalizations.of(context)!.card,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Booking & Order IDs
                    _buildCopyableField(
                      context,
                      AppLocalizations.of(context)!.bookingId,
                      transaction.bookingId,
                      Icons.receipt_long,
                    ),
                    const SizedBox(height: 12),
                    _buildCopyableField(
                      context,
                      AppLocalizations.of(context)!.orderId,
                      transaction.orderId,
                      Icons.confirmation_number,
                    ),

                    const SizedBox(height: 24),

                    // Customer Information
                    Text(
                      AppLocalizations.of(context)!.customerInformation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.name,
                      booking.customer.name ?? 'N/A',
                      Icons.person,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.phone,
                      booking.customer.phone ?? 'N/A',
                      Icons.phone,
                    ),

                    const SizedBox(height: 24),

                    // Service Information
                    Text(
                      AppLocalizations.of(context)!.serviceInformation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      AppLocalizations.of(context)!.serviceName,
                      serviceName,
                      Icons.build,
                    ),

                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.close,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.copiedToClipboard,
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.copy, color: Colors.blue[700], size: 20),
            tooltip: AppLocalizations.of(context)!.copy,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPayoutRequestDialog() {
    final TextEditingController amountController = TextEditingController();

    // Add a ValueNotifier to manage error state
    final errorNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.start,
        title: Text(AppLocalizations.of(context)!.requestPayout),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.availableForPayout}: ${AppLocalizations.of(context)!.sar} ${availableAmount.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: errorNotifier,
              builder: (context, errorText, child) {
                return TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Clear error when user types
                    if (errorNotifier.value != null) {
                      errorNotifier.value = null;
                    }
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.amount,
                    prefixText: '${AppLocalizations.of(context)!.sar} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : Colors.grey,
                      ),
                    ),
                    errorText: errorText,
                    helperText: errorText == null
                        ? AppLocalizations.of(
                            context,
                          )!.cashPaymentsAreAlreadyWithYou
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(
                context,
              )!.theAdminWillProcessYourRequestWithin2to3days,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          eButton(
            onPressed: () => Navigator.pop(dialogContext),
            context: context,
            backgroundColor: Colors.white,
            widget: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.black),
            ),
          ),
          eButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);

              // Validate and show error in dialog
              if (amount == null || amount <= 0) {
                errorNotifier.value = AppLocalizations.of(
                  context,
                )!.pleaseEnterAValidAmount;
                return;
              }
              if (amount > availableAmount) {
                errorNotifier.value = AppLocalizations.of(
                  context,
                )!.amountExceedsAvailableBalance;
                return;
              }

              // Close dialog and submit
              Navigator.pop(dialogContext);
              _submitPayoutRequest(amount);
            },
            context: context,
            backgroundColor: Colors.blue[700],
            widget: Text(
              AppLocalizations.of(context)!.submitRequest,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayoutRequest(double amount) async {
    try {
      final bloc = context.read<AccountBloc>();

      bloc.add(
        RequestPayoutEvent(
          widget.workerId,
          amount.toStringAsFixed(2),
          'earnings',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
