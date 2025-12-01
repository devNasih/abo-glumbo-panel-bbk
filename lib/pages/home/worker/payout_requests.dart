import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayoutRequests extends StatelessWidget {
  final String? workerId;
  const PayoutRequests({super.key, this.workerId});

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'C':
        return Colors.green;
      case 'P':
        return Colors.orange;
      case 'R':
      case 'X':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'C':
        return Icons.check_circle;
      case 'P':
        return Icons.access_time;
      case 'R':
      case 'X':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String? status, BuildContext context) {
    switch (status) {
      case 'C':
        return AppLocalizations.of(context)!.completed;
      case 'P':
        return AppLocalizations.of(context)!.pending;
      case 'R':
        return AppLocalizations.of(context)!.rejected;
      case 'X':
        return AppLocalizations.of(context)!.cancelled;
      default:
        return AppLocalizations.of(context)!.pending;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '--';
    try {
      final date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return '--';
    }
  }

  String _formatCurrency(BuildContext context, String? amount) {
    if (amount == null || amount.isEmpty) {
      return '0.00 ${AppLocalizations.of(context)!.sar}';
    }
    try {
      final value = double.parse(amount);
      return '${value.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}';
    } catch (e) {
      return '$amount ${AppLocalizations.of(context)!.sar}';
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.start,
        title: Text(AppLocalizations.of(context)!.cancel),
        content: Text(
          AppLocalizations.of(
            context,
          )!.areYouSureYouWantToCancelThisPayoutRequest,
        ),
        actions: [
          eButton(
            onPressed: () => Navigator.pop(context, false),
            context: context,
            backgroundColor: Colors.white,
            widget: Text(
              AppLocalizations.of(context)!.back,
              style: TextStyle(color: Colors.black),
            ),
          ),
          eButton(
            onPressed: () => Navigator.pop(context, true),
            context: context,
            backgroundColor: Colors.red,
            widget: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.payoutRequests),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: AppServices.getPayoutRequestsById(workerId ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.error,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final payoutRequests = snapshot.data ?? [];

          if (payoutRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.payoutRequests,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.noPayoutRequestsFound,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payoutRequests.length,
            itemBuilder: (context, index) {
              final payoutRequest = payoutRequests[index];
              final statusColor = _getStatusColor(payoutRequest.status);
              final statusText = _getStatusText(payoutRequest.status, context);

              return Dismissible(
                key: Key(payoutRequest.id ?? 'payout_$index'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmation(context);
                },
                onDismissed: (direction) async {
                  // Delete from Firestore
                  if (payoutRequest.id != null) {
                    await AppServices.deletePayoutRequest(
                      payoutRequest.id ?? "",
                    );
                  }

                  // Show snackbar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.payoutRequestCancelled,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row - Amount and Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Amount
                              Text(
                                _formatCurrency(context, payoutRequest.amount),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(payoutRequest.status),
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Request Details
                          if (payoutRequest.createdAt != null &&
                              payoutRequest.status!.toLowerCase() == 'p')
                            _buildInfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: AppLocalizations.of(context)!.requestedOn,
                              value: _formatDate(payoutRequest.createdAt),
                            ),

                          if (payoutRequest.approvedAt != null &&
                              payoutRequest.status!.toLowerCase() == 'c')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildInfoRow(
                                icon: Icons.update,
                                label: AppLocalizations.of(context)!.approvedOn,
                                value: _formatDate(payoutRequest.approvedAt),
                              ),
                            ),
                          if (payoutRequest.status!.toLowerCase() == 'r') ...{
                            _buildInfoRow(
                              icon: Icons.update,
                              label: AppLocalizations.of(context)!.rejectedOn,
                              value: _formatDate(payoutRequest.updatedAt),
                            ),
                          },
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
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
