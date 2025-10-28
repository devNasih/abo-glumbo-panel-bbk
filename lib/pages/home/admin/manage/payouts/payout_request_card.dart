import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/payout_request.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class PayoutRequestCard extends StatefulWidget {
  final PayoutRequestModel payoutRequest;
  const PayoutRequestCard({super.key, required this.payoutRequest});

  @override
  State<PayoutRequestCard> createState() => _PayoutRequestCardState();
}

class _PayoutRequestCardState extends State<PayoutRequestCard> {
  UserModel? _workerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkerData();
  }

  Future<void> _fetchWorkerData() async {
    final workerData = await AppFirestore.usersCollectionRef
        .doc(widget.payoutRequest.userId)
        .get();

    if (mounted) {
      setState(() {
        _workerData = UserModel.fromJson(
          workerData.data() as Map<String, dynamic>,
        );
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor() {
    switch (widget.payoutRequest.status?.toLowerCase()) {
      case 'p':
        return Colors.orange;
      case 'c':
        return Colors.green;
      case 'r':
      case 'x':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BuildContext context) {
    switch (widget.payoutRequest.status?.toLowerCase()) {
      case 'p':
        return AppLocalizations.of(context)!.pending;
      case 'c':
        return AppLocalizations.of(context)!.completed;
      case 'r':
        return AppLocalizations.of(context)!.rejected;
      case 'x':
        return AppLocalizations.of(context)!.cancelled;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  Future<bool> _updatePaidAmount() async {
    try {
      final userDoc = await AppFirestore.usersCollectionRef
          .doc(widget.payoutRequest.userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        return false;
      }
      if (userData['paidAmounts'] == null) {
        await AppFirestore.usersCollectionRef
            .doc(widget.payoutRequest.userId)
            .update({
              'paidAmounts':
                  double.tryParse(widget.payoutRequest.amount ?? "") ?? 0.0,
            });
      } else {
        await AppFirestore.usersCollectionRef
            .doc(widget.payoutRequest.userId)
            .update({
              'paidAmounts': FieldValue.increment(
                double.tryParse(widget.payoutRequest.amount ?? "") ?? 0.0,
              ),
            });
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving/rejecting agent: $e');
      }
      return false;
    }
  }

  Future<void> _showApprovalDialog(BuildContext parentContext) async {
    final transactionController = TextEditingController();
    PlatformFile? selectedFile;

    await showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<ManageAppBloc>(parentContext),
          child: BlocConsumer<ManageAppBloc, ManageAppState>(
            listener: (context, state) {
              if (state is PayoutApprovalSuccess) {
                _updatePaidAmount();

                Navigator.of(dialogContext).pop();
                Navigator.of(parentContext).pop(); // Close bottom sheet
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PayoutApprovalError) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isUploading = state is ApprovingPayout;

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.approvePayout,
                          style: const TextStyle(
                            fontSize: 18,
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
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.pleaseProvideTransactionDetails,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Transaction Number Field
                          TextField(
                            controller: transactionController,
                            enabled: !isUploading,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.transactionNumber,
                              hintText: AppLocalizations.of(
                                context,
                              )!.enterTransactionNumber,
                              prefixIcon: const Icon(Icons.receipt_long),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 20),

                          // File Upload Section
                          Text(
                            AppLocalizations.of(context)!.uploadProof,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: isUploading
                                ? null
                                : () async {
                                    FilePickerResult? result = await FilePicker
                                        .platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'jpg',
                                            'jpeg',
                                            'png',
                                            'pdf',
                                            'doc',
                                            'docx',
                                          ],
                                        );

                                    if (result != null) {
                                      setDialogState(() {
                                        selectedFile = result.files.first;
                                      });
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedFile != null
                                      ? Colors.green
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedFile != null
                                        ? Icons.check_circle
                                        : Icons.upload_file,
                                    color: selectedFile != null
                                        ? Colors.green
                                        : Colors.grey[600],
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedFile != null
                                              ? selectedFile!.name
                                              : AppLocalizations.of(
                                                  context,
                                                )!.tapToSelectFile,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: selectedFile != null
                                                ? Colors.black87
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedFile != null
                                              ? '${(selectedFile!.size / 1024).toStringAsFixed(2)} KB'
                                              : AppLocalizations.of(
                                                  context,
                                                )!.pdfImageOrDocument,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.supportedFormats,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: isUploading
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () {
                                if (transactionController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.transactionNumberRequired,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (selectedFile == null) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.fileRequired,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Dispatch approval event to ManageAppBloc
                                context.read<ManageAppBloc>().add(
                                  ApprovePayoutEvent(
                                    payoutRequestId: widget.payoutRequest.id!,
                                    transactionNumber: transactionController
                                        .text
                                        .trim(),
                                    proofFile: selectedFile!,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: isUploading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(AppLocalizations.of(context)!.approve),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showRejectDialog(BuildContext parentContext) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<ManageAppBloc>(parentContext),
          child: BlocConsumer<ManageAppBloc, ManageAppState>(
            listener: (context, state) {
              if (state is PayoutRejectionSuccess) {
                Navigator.of(dialogContext).pop();
                Navigator.of(parentContext).pop(); // Close bottom sheet
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is PayoutRejectionError) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isProcessing = state is RejectingPayout;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(dialogContext)!.rejectPayout,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(dialogContext)!.rejectConfirmation,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: reasonController,
                      enabled: !isProcessing,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(dialogContext)!.reason,
                        hintText: AppLocalizations.of(
                          dialogContext,
                        )!.enterTheReason,
                        prefixIcon: const Icon(Icons.comment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isProcessing
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      AppLocalizations.of(dialogContext)!.cancel,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () {
                            if (reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      dialogContext,
                                    )!.pleaseProvideARejectionReason,
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Dispatch rejection event to ManageAppBloc
                            context.read<ManageAppBloc>().add(
                              RejectPayoutEvent(
                                payoutRequestId: widget.payoutRequest.id!,
                                reason: reasonController.text.trim(),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(AppLocalizations.of(dialogContext)!.reject),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final bool isPending = widget.payoutRequest.status?.toLowerCase() == 'p';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (bottomSheetContext) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Payout Amount Header
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.payoutAmount,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${AppLocalizations.of(context)!.sar} ${widget.payoutRequest.amount}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor().withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      _getStatusText(context),
                                      style: TextStyle(
                                        color: _getStatusColor(),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),
                            Divider(color: Colors.grey[300], height: 1),
                            const SizedBox(height: 24),

                            // Worker Information Section
                            _buildSectionTitle(
                              AppLocalizations.of(context)!.workerInformation,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.person_outline,
                              AppLocalizations.of(context)!.name,
                              _workerData?.name ?? 'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.email_outlined,
                              AppLocalizations.of(context)!.email,
                              _workerData?.email ?? 'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.phone_outlined,
                              AppLocalizations.of(context)!.phone,
                              _workerData?.phone ?? 'N/A',
                            ),

                            const SizedBox(height: 24),
                            Divider(color: Colors.grey[300], height: 1),
                            const SizedBox(height: 24),

                            // Bank Account Details Section
                            _buildSectionTitle(
                              AppLocalizations.of(context)!.bankAccountDetails,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.account_circle_outlined,
                              AppLocalizations.of(context)!.accountHolderName,
                              widget
                                      .payoutRequest
                                      .payoutAccount
                                      ?.accountHolderName ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.account_balance_outlined,
                              AppLocalizations.of(context)!.bankName,
                              widget.payoutRequest.payoutAccount?.bankName ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.numbers_outlined,
                              AppLocalizations.of(context)!.accountNumber,
                              widget
                                      .payoutRequest
                                      .payoutAccount
                                      ?.accountNumber ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.code_outlined,
                              AppLocalizations.of(context)!.ifscCode,
                              widget.payoutRequest.payoutAccount?.ifscCode ??
                                  'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.account_balance_wallet_outlined,
                              AppLocalizations.of(context)!.accountType,
                              widget.payoutRequest.payoutAccount?.accountType ??
                                  'N/A',
                            ),

                            const SizedBox(height: 24),
                            Divider(color: Colors.grey[300], height: 1),
                            const SizedBox(height: 16),

                            // Request Date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${AppLocalizations.of(context)!.requestedOn}: ${_formatDate(widget.payoutRequest.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 80), // Space for buttons
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons (Only show if status is pending)
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showRejectDialog(context),
                                icon: const Icon(Icons.close, size: 20),
                                label: Text(
                                  AppLocalizations.of(context)!.reject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showApprovalDialog(context),
                                icon: const Icon(Icons.check, size: 20),
                                label: Text(
                                  AppLocalizations.of(context)!.approve,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
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
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Left Side: Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.payoutAmount,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.sar} ${widget.payoutRequest.amount}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _workerData?.name ?? 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Side: Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(), width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(context),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.payoutRequest.status?.toLowerCase()) {
      case 'p':
        return Icons.schedule;
      case 'c':
        return Icons.check_circle;
      case 'r':
      case 'x':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    date = date.toDate();
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }
}
