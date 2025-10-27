import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/payout_requests.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WorkerEarningsPage extends StatefulWidget {
  final String workerId;

  const WorkerEarningsPage({super.key, required this.workerId});

  @override
  State<WorkerEarningsPage> createState() => _WorkerEarningsPageState();
}

class _WorkerEarningsPageState extends State<WorkerEarningsPage> {
  List<TransactionModel> transactions = [];
  TippingModel? tippingData;
  bool isLoading = true;

  double cashPayments = 0.0;
  double cardPayments = 0.0;
  double totalEarnings = 0.0;
  double totalTips = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => isLoading = true);

    transactions = await AppServices.getWorkerTransactions(widget.workerId);
    tippingData = await AppServices.getWorkerTippingData(widget.workerId);
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                      const CircularProgressIndicator(),
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
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadEarningsData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalEarningsCard(),
                      const SizedBox(height: 16),
                      _buildPaymentBreakdown(),

                      const SizedBox(height: 24),
                      _buildPayoutSection(),
                      const SizedBox(height: 24),
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
            AppLocalizations.of(context)!.totalEarnings,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context)!.sar} ${totalEarnings.toStringAsFixed(2)}',
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
              child: _buildPaymentCard(
                title: AppLocalizations.of(context)!.totalTips,
                amount: totalTips,
                icon: Icons.star,
                color: Colors.orange,
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
            '${AppLocalizations.of(context)!.sar} ${amount.toStringAsFixed(2)}',
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
                          '${AppLocalizations.of(context)!.sar} ${(cardPayments + totalTips).toStringAsFixed(2)}',
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
                  onPressed: () => _showPayoutRequestDialog(),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noTransactionsYet,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.recentTransactions,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 10 ? 10 : transactions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isCash = transaction.paymentMethod.toLowerCase() == 'cash';
    final isPaid =
        transaction.paymentStatus.toLowerCase() == 'completed' ||
        transaction.paymentStatus.toLowerCase() == 'paid';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      title: Text(
        "${AppLocalizations.of(context)!.id}: ${transaction.bookingId}",
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${AppLocalizations.of(context)!.sar} ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPaid ? Colors.black87 : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isCash
                  ? AppLocalizations.of(context)!.cashOnHands
                  : AppLocalizations.of(context)!.card,
              style: TextStyle(
                fontSize: 10,
                color: isPaid ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPayoutRequestDialog() {
    final TextEditingController amountController = TextEditingController();
    final availableAmount = cardPayments + totalTips;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during processing
      builder: (dialogContext) => AlertDialog(
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
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.amount,
                prefixText: '${AppLocalizations.of(context)!.sar} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: AppLocalizations.of(
                  context,
                )!.cashPaymentsAreAlreadyWithYou,
              ),
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.pleaseEnterAValidAmount,
                    ),
                  ),
                );
                return;
              }
              if (amount > availableAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.amountExceedsAvailableBalance,
                    ),
                  ),
                );
                return;
              }

              // Close dialog first
              Navigator.pop(dialogContext);

              // Then submit the request
              _submitPayoutRequest(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.submitRequest),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayoutRequest(double amount) async {
    try {
      final bloc = context.read<AccountBloc>();

      bloc.add(RequestPayoutEvent(widget.workerId, amount.toStringAsFixed(2)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
