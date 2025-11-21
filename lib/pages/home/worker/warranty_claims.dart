import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/warranty_card.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WarrantyClaims extends StatefulWidget {
  final UserModel workerData;
  final bookingTrackerService = BookingTrackerService();
  WarrantyClaims({super.key, required this.workerData});

  @override
  State<WarrantyClaims> createState() => _WarrantyClaimsState();
}

class _WarrantyClaimsState extends State<WarrantyClaims> {
  CustomerModel? customer;

  @override
  void initState() {
    super.initState();
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelText ?? AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(confirmText ?? AppLocalizations.of(context)!.confirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Shimmer skeleton loader for warranty cards
  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top status ribbon shimmer
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (_, __) => _buildShimmerCard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isArabic = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(AppLocalizations.of(context)!.warrantyClaims),
        elevation: 0,
      ),
      body: StreamBuilder<List<WarrantyModel>>(
        stream: AppServices.getWarrantyClaimRequestsStream(
          widget.workerData.uid ?? "",
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "${AppLocalizations.of(context)!.no} ${AppLocalizations.of(context)!.warrantyClaims}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final claims = snapshot.data ?? [];

          return StreamBuilder<Map<String, dynamic>>(
            stream: AppServices.getAllCustomersAndTechniciansStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoader();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${AppLocalizations.of(context)!.no} ${AppLocalizations.of(context)!.customer}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final combinedData = snapshot.data ?? {};
              final customerList =
                  combinedData['customers'] as List<CustomerModel>? ?? [];
              final technicianList =
                  combinedData['technicians'] as List<UserModel>? ?? [];

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey(claims.length),
                  itemCount: claims.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final claim = claims[index];
                    final custId = claim.customerId;
                    final customerData = customerList.firstWhere(
                      (cust) => cust.uid == custId,
                      orElse: () => CustomerModel(uid: '', name: 'Unknown'),
                    );

                    if (claim.bookingId == null || claim.bookingId!.isEmpty) {
                      return warrantyClaimCard(
                        isWorkCompleted: false,
                        currentUser: widget.workerData,
                        onCancel: () async {
                          final confirmed = await _showConfirmationDialog(
                            context: context,
                            title: 'Cancel Warranty Claim',
                            message:
                                'Are you sure you want to cancel this warranty claim?',
                          );
                          if (confirmed) {
                            // Handle cancel action
                          }
                        },
                        isAccepted: false,
                        isTrackingStarted: false,
                        onStartWork: () {},
                        onStopTracking: () {},
                        onCompleteWork: () {},
                        onAccept: () {},
                        context: context,
                        onReject: () {},
                        warranty: WarrantyModel(),
                        bookingId: '',
                        bookingName: 'Booking info not available',
                        customerName: customerData.name ?? '',
                        technicianName:
                            technicianList
                                .firstWhere(
                                  (tech) => tech.uid == claim.technicianId,
                                  orElse: () =>
                                      UserModel(name: 'Unknown', uid: ''),
                                )
                                .name ??
                            '',
                        serviceCompletedDate: claim.createdAt,
                      );
                    }

                    return FutureBuilder<BookingModel?>(
                      future: AppServices.getBooking(claim.bookingId!),
                      builder: (context, bookingSnapshot) {
                        if (bookingSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: _buildShimmerCard(),
                          );
                        }
                        if (bookingSnapshot.hasError ||
                            !bookingSnapshot.hasData) {
                          return warrantyClaimCard(
                            isWorkCompleted: false,
                            onCancel: () async {
                              final confirmed = await _showConfirmationDialog(
                                context: context,
                                title: 'Cancel Warranty Claim',
                                message:
                                    'Are you sure you want to cancel this warranty claim?',
                              );
                              if (confirmed) {
                                // Handle cancel action
                              }
                            },
                            currentUser: widget.workerData,
                            isAccepted: false,
                            isTrackingStarted: false,
                            onStartWork: () {},
                            onCompleteWork: () {},
                            onAccept: () {},
                            context: context,
                            onStopTracking: () {},
                            onReject: () {},
                            warranty: claim,
                            bookingId: claim.bookingId ?? "",
                            bookingName: "Booking info not available",
                            customerName: customerData.name ?? "",
                            technicianName:
                                technicianList
                                    .firstWhere(
                                      (tech) => tech.uid == claim.technicianId,
                                      orElse: () =>
                                          UserModel(name: "Unknown", uid: ""),
                                    )
                                    .name ??
                                "",
                            serviceCompletedDate: claim.createdAt,
                          );
                        }
                        final booking = bookingSnapshot.data!;
                        final technicianName = technicianList
                            .firstWhere(
                              (tech) => tech.uid == claim.technicianId,
                              orElse: () => UserModel(name: 'Unknown', uid: ''),
                            )
                            .name;

                        return warrantyClaimCard(
                          isWorkCompleted: claim.completed,
                          isAccepted: claim.claimStatus ?? false,
                          isTrackingStarted: claim.isTracking,
                          onCompleteWork: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Complete Work',
                              message:
                                  'Are you sure you want to mark this warranty work as completed?',
                            );
                            if (confirmed) {
                              await widget.bookingTrackerService
                                  .stopTrackingWarranty();
                              AppFirestore.bookingsCollectionRef
                                  .doc(booking.id)
                                  .update({
                                    "warranty.completed": true,
                                    "warranty.updatedAt":
                                        FieldValue.serverTimestamp(),
                                  });
                            }
                          },
                          onStartWork: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Start Work',
                              message:
                                  'Are you ready to start working on this warranty claim?',
                            );
                            if (confirmed) {
                              final uid = LocalStore.getUID();
                              if (uid != null) {
                                try {
                                  await widget.bookingTrackerService
                                      .startWorkingWarranty(
                                        context: context,
                                        bookingId: booking.id,
                                        uid: uid,
                                      );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            }
                          },
                          onCancel: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Cancel Warranty Claim',
                              message:
                                  'Are you sure you want to cancel this warranty claim?',
                            );
                            if (confirmed) {
                              AppServices.rejectWarrantyClaim(
                                bookingId: claim.bookingId ?? "",
                                technicianUid: claim.technicianId,
                                technicianName: technicianName,
                              );
                            }
                          },
                          onStopTracking: booking.isStartTracking == false
                              ? null
                              : () async {
                                  final confirmed = await _showConfirmationDialog(
                                    context: context,
                                    title: 'Stop Tracking',
                                    message:
                                        'Do you want to stop tracking for this warranty work?',
                                  );
                                  if (confirmed) {
                                    await widget.bookingTrackerService
                                        .stopTrackingWarranty();
                                  }
                                },
                          onAccept: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Accept Warranty Claim',
                              message:
                                  'Do you want to accept this warranty claim?',
                            );
                            if (confirmed) {
                              AppFirestore.bookingsCollectionRef
                                  .doc(booking.id)
                                  .update({
                                    "warranty.claimStatus": true,
                                    "warranty.updatedAt":
                                        FieldValue.serverTimestamp(),
                                  });
                            }
                          },
                          context: context,
                          onReject: () async {
                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              title: 'Reject Warranty Claim',
                              message:
                                  'Are you sure you want to reject this warranty claim? This action cannot be undone.',
                            );
                            if (confirmed) {
                              AppServices.rejectWarrantyClaim(
                                bookingId: claim.bookingId ?? "",
                                technicianUid: claim.technicianId,
                                technicianName: technicianName,
                              );
                            }
                          },
                          warranty: claim,
                          bookingId: booking.id,
                          bookingName: isArabic
                              ? booking.service.name_ar ?? ""
                              : booking.service.name ?? "",
                          customerName: customerData.name ?? "",
                          technicianName: technicianName ?? "",
                          serviceCompletedDate: claim.createdAt,
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
