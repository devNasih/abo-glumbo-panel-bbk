import 'dart:convert';
import 'dart:developer';
import 'package:aboglumbo_bbk_panel/common_widget/warranty_card.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/models/location_selection.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class WarrantyClaims extends StatefulWidget {
  final UserModel? workerData;
  final bookingTrackerService = BookingTrackerService();
  WarrantyClaims({super.key, this.workerData});

  @override
  State<WarrantyClaims> createState() => _WarrantyClaimsState();
}

class _WarrantyClaimsState extends State<WarrantyClaims> {
  CustomerModel? customer;
  bool isAdmin = true;
  List<LocationModel> locations = [];

  List<Region> regions = [];
  Region? selectedRegion;
  City? selectedCity;
  District? selectedDistrict;
  bool isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    if (widget.workerData != null) {
      isAdmin = false;
    }
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => isLoadingLocations = true);
    try {
      // Load JSON from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/saudi_hierarchical.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        regions = jsonData.map((r) => Region.fromJson(r)).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading locations: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingLocations = false);
      }
    }
  }

  // Show assign agent bottom sheet
  void _showAssignAgentBottomSheet({
    required WarrantyModel warranty,
    required BookingModel booking,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssignAgentBottomSheet(
        regions: regions,
        warranty: warranty,
        booking: booking,

        onRejectOrder: (WarrantyModel warranty) {
          AppFirestore.bookingsCollectionRef.doc(booking.id).update({
            'warranty.avaliability': false,
          });
        },
      ),
    );
  }

  // Show confirmation dialog
  Future<Map<String, dynamic>> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool requireReason = false, // NEW: flag to show reason field
  }) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (requireReason) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    maxLength: 300,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Enter reason for ${title.toLowerCase()}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a reason';
                      }
                      if (value.trim().length < 10) {
                        return 'Reason must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop({'confirmed': false}),
              child: Text(
                cancelText ?? AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (requireReason && !formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(dialogContext).pop({
                  'confirmed': true,
                  'reason': reasonController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: requireReason ? Colors.red[600] : null,
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

    return result ?? {'confirmed': false, 'reason': ''};
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(AppLocalizations.of(context)!.warrantyClaims),
        elevation: 0,
      ),
      body: isAdmin ? adminScaffold(context) : technicianScaffold(context),
    );
  }

  // Technician scaffold remains the same as your original
  Widget technicianScaffold(BuildContext context) {
    bool isArabic = Directionality.of(context) == TextDirection.rtl;

    return StreamBuilder<List<WarrantyModel>>(
      stream: AppServices.getWarrantyClaimRequestsStream(
        widget.workerData?.uid ?? "",
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
                    orElse: () => CustomerModel(uid: '', name: 'Unknown',role: 'technician'),
                  );

                  if (claim.bookingId == null || claim.bookingId!.isEmpty) {
                    return warrantyClaimCard(
                      isAdmin: isAdmin,
                      isWorkCompleted: false,
                      currentUser: widget.workerData,
                      onCancel: () {},
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
                                    UserModel(name: 'Unknown', uid: '',role: 'technician'),
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
                          isAdmin: isAdmin,
                          isWorkCompleted: false,
                          onCancel: () {},
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
                                        UserModel(name: "Unknown", uid: "",role: 'technician'),
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
                            orElse: () => UserModel(name: 'Unknown', uid: '',role: 'technician'),
                          )
                          .name;

                      return warrantyClaimCard(
                        isAdmin: isAdmin,
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
                          if (confirmed["confirmed"] == true) {
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
                          if (confirmed["confirmed"] == true) {
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
                          final result = await _showConfirmationDialog(
                            context: context,
                            title: 'Cancel Warranty Claim',
                            message:
                                'Please provide a reason for cancelling this warranty work',
                            requireReason: true, // Enable reason field
                            confirmText: 'Cancel Work',
                          );

                          if (result['confirmed'] == true) {
                            final reason = result['reason'] as String;
                            AppServices.rejectWarrantyClaim(
                              bookingId: claim.bookingId ?? "",
                              technicianUid: claim.technicianId,
                              technicianName: technicianName,
                              reason: reason, // Pass the reason
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Warranty claim cancelled'),
                              ),
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
                                if (confirmed["confirmed"] == true) {
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
                          if (confirmed["confirmed"] == true) {
                            AppFirestore.bookingsCollectionRef
                                .doc(booking.id)
                                .update({
                                  "warranty.claimStatus": true,
                                  "warranty.assignedTechnicianId":
                                      widget.workerData?.uid,
                                  "warranty.updatedAt":
                                      FieldValue.serverTimestamp(),
                                });
                          }
                        },
                        context: context,
                        onReject: () async {
                          final result = await _showConfirmationDialog(
                            context: context,
                            title: 'Reject Warranty Claim',
                            message:
                                'Please provide a reason for rejecting this warranty claim',
                            requireReason: true, // Enable reason field
                            confirmText: 'Reject',
                          );

                          if (result['confirmed'] == true) {
                            final reason = result['reason'] as String;
                            AppServices.rejectWarrantyClaim(
                              bookingId: claim.bookingId ?? "",
                              technicianUid: claim.technicianId,
                              technicianName: technicianName,
                              reason: reason, // Pass the reason
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Warranty claim rejected'),
                              ),
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
    );
  }

  Widget adminScaffold(BuildContext context) {
    bool isArabic = Directionality.of(context) == TextDirection.rtl;

    return StreamBuilder<List<WarrantyModel>>(
      stream: AppServices.getAllWarrantyClaimRequestsStream(),
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
                    orElse: () => CustomerModel(uid: '', name: 'Unknown',role: 'technician'),
                  );

                  if (claim.bookingId == null || claim.bookingId!.isEmpty) {
                    return warrantyClaimCard(
                      isAdmin: isAdmin,
                      isWorkCompleted: false,
                      currentUser: widget.workerData,
                      onCancel: () {},
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
                                    UserModel(name: 'Unknown', uid: '',role: 'technician'),
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
                          isAdmin: isAdmin,
                          isWorkCompleted: false,
                          onCancel: () {},
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
                                        UserModel(name: "Unknown", uid: "",role: 'technician'),
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
                            orElse: () => UserModel(name: 'Unknown', uid: '',role: 'technician'),
                          )
                          .name;

                      return warrantyClaimCard(
                        isAdmin: isAdmin,
                        isWorkCompleted: claim.completed,
                        isAccepted: claim.claimStatus ?? false,
                        isTrackingStarted: claim.isTracking,
                        onAssign:
                            (claim.claimStatus == null ||
                                claim.claimStatus == false)
                            ? () => _showAssignAgentBottomSheet(
                                warranty: claim,
                                booking: booking,
                              )
                            : null,

                        context: context,
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
    );
  }
}
// ============================================
// AGENT ASSIGNMENT BOTTOM SHEET
// ============================================

class AssignAgentBottomSheet extends StatefulWidget {
  final WarrantyModel warranty;
  final BookingModel booking;
  final List<Region> regions; // Changed from List<LocationModel>
  final Function(WarrantyModel warranty) onRejectOrder;

  const AssignAgentBottomSheet({
    super.key,
    required this.warranty,
    required this.booking,
    required this.regions, // Changed parameter
    required this.onRejectOrder,
  });

  @override
  State<AssignAgentBottomSheet> createState() => _AssignAgentBottomSheetState();
}

class _AssignAgentBottomSheetState extends State<AssignAgentBottomSheet> {
  // Hierarchical location selection
  Region? selectedRegion;
  City? selectedCity;
  District? selectedDistrict;

  CategoryModel? categoryModel;
  final Set<String> assigningUsers = {};
  bool isAssigning = false;

  // Global lock to prevent multiple simultaneous assignments
  static bool globalAssignmentLock = false;

  // Stream caching
  Stream<List<UserModel>>? cachedUsersStream;
  Region? lastSelectedRegion;
  City? lastSelectedCity;
  District? lastSelectedDistrict;
  String? lastCategoryId;

  // Search controllers
  final TextEditingController regionSearchController = TextEditingController();
  final TextEditingController citySearchController = TextEditingController();
  final TextEditingController districtSearchController =
      TextEditingController();

  List<Region> filteredRegions = [];
  List<City> filteredCities = [];
  List<District> filteredDistricts = [];

  bool showRegionDropdown = false;
  bool showCityDropdown = false;
  bool showDistrictDropdown = false;

  final Map<String, CategoryModel> categoryCache = {};
  bool categoriesLoaded = false;

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    log('loading category');
    _loadCategory();
    _loadAllCategories();
    log('loaded category, loading user stream');
    _initializeUsersStream();
    log('loaded user stream');

    filteredRegions = widget.regions;
  }

  Future<void> _loadAllCategories() async {
    try {
      final categoriesSnapshot = await AppFirestore.categoriesCollectionRef
          .get();

      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          categoryCache[doc.id] = CategoryModel.fromJson(data);
        }
      }

      if (mounted) {
        setState(() {
          categoriesLoaded = true;
        });
      }

      log('Loaded ${categoryCache.length} categories');
    } catch (e) {
      log('Error loading categories: $e');
    }
  }

  String _getCategoryName(String categoryId, bool isArabic) {
    final category = categoryCache[categoryId];
    if (category == null) return categoryId; // Fallback to ID if not found

    return isArabic
        ? (category.name_ar ?? category.name ?? categoryId)
        : (category.name ?? category.name_ar ?? categoryId);
  }

  List<String> _getJobRoleNames(List<String>? jobRoleIds, bool isArabic) {
    if (jobRoleIds == null || jobRoleIds.isEmpty) return [];

    return jobRoleIds.map((id) => _getCategoryName(id, isArabic)).toList();
  }

  @override
  void dispose() {
    regionSearchController.dispose();
    citySearchController.dispose();
    districtSearchController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _initializeUsersStream() {
    cachedUsersStream = _createUsersStream();
    lastSelectedRegion = selectedRegion;
    lastSelectedCity = selectedCity;
    lastSelectedDistrict = selectedDistrict;
    lastCategoryId = widget.booking.service.category;
  }

  Future<void> _loadCategory() async {
    if (widget.booking.service.category != null) {
      try {
        final docSnapshot = await AppFirestore.categoriesCollectionRef
            .doc(widget.booking.service.category)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              categoryModel = CategoryModel.fromJson(data);
            });
          }
        }
        return;
      } catch (e) {
        log(e.toString());
      }
    }
  }

  Future<void> _showRejectConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmReject),
          content: Text(AppLocalizations.of(context)!.confirmRejectMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                Navigator.of(context).pop(false);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.reject),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onRejectOrder(widget.warranty);
      Navigator.pop(context);
    }
  }

  Future<void> _handleAssignAgent(UserModel user) async {
    final userId = user.uid;
    if (userId == null) return;

    if (globalAssignmentLock) {
      _showSnackBar(
        AppLocalizations.of(context)?.anotherAssignmentInProgress ??
            'Another assignment is in progress. Please wait...',
      );
      return;
    }

    if (isAssigning || assigningUsers.contains(userId)) {
      _showSnackBar(
        AppLocalizations.of(context)?.assignmentInProgress ??
            'Assignment in progress. Please wait...',
      );
      return;
    }

    globalAssignmentLock = true;
    setState(() {
      isAssigning = true;
      assigningUsers.add(userId);
    });

    try {
      _showSnackBar(
        AppLocalizations.of(context)?.assigningTechnician ??
            'Assigning agent...',
      );

      // Verify booking hasn't been assigned to someone else
      final currentBookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
          .get();

      if (currentBookingDoc.exists) {
        final currentData = currentBookingDoc.data() as Map<String, dynamic>;
        final currentAssignedTo = currentData['assignedTo'] as String?;
        final currentStatus = currentData['bookingStatusCode'] as String?;

        if (currentAssignedTo != null &&
            currentAssignedTo.isNotEmpty &&
            currentStatus != 'P') {
          _showSnackBar(
            AppLocalizations.of(
                  context,
                )?.thisBookingAlreadyAssignedToAnotherAgent ??
                'This booking has already been assigned to another agent.',
          );
          Navigator.pop(context);
          return;
        }
      }

      await AppFirestore.bookingsCollectionRef.doc(widget.booking.id).update({
        'warranty.assignedTechnicianId': userId,
      });

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(
        AppLocalizations.of(context)?.failedToAssignAgent ??
            'Failed to assign agent. Please try again.',
      );
    } finally {
      globalAssignmentLock = false;
      if (mounted) {
        setState(() {
          isAssigning = false;
          assigningUsers.remove(userId);
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  Stream<List<UserModel>> _createUsersStream() {
    if (widget.booking.service.category != null) {
      return _getCategoryWiseWorkersStream(
        widget.booking.service.category!,
      ).map((users) => _filterByLocation(users));
    } else {
      Query baseQuery = AppFirestore.usersCollectionRef
          .where('isVerified', isEqualTo: true)
          .where('isAdmin', isNotEqualTo: true);

      return baseQuery.snapshots().map((snapshot) {
        final users = snapshot.docs
            .map(
              (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();
        return _filterByLocation(users);
      });
    }
  }

  Stream<List<UserModel>> _getFilteredUsersStream() {
    if (cachedUsersStream == null ||
        lastSelectedRegion != selectedRegion ||
        lastSelectedCity != selectedCity ||
        lastSelectedDistrict != selectedDistrict ||
        lastCategoryId != widget.booking.service.category) {
      cachedUsersStream = _createUsersStream();
      lastSelectedRegion = selectedRegion;
      lastSelectedCity = selectedCity;
      lastSelectedDistrict = selectedDistrict;
      lastCategoryId = widget.booking.service.category;
    }
    return cachedUsersStream!;
  }

  List<UserModel> _filterByLocation(List<UserModel> users) {
    if (selectedDistrict == null) {
      return users;
    }

    bool isArabic = AppLocalizations.of(context)?.localeName == 'ar';
    String districtName = selectedDistrict!.getName(isArabic);

    return users.where((user) => user.districtName == districtName).toList();
  }

  static Stream<List<UserModel>> _getCategoryWiseWorkersStream(
    String categoryId,
  ) async* {
    log('category wise workers stream started');
    try {
      // Query directly by category ID instead of fetching category name
      Query query = AppFirestore.usersCollectionRef
          .where('isVerified', isEqualTo: true)
          .where('isAdmin', isNotEqualTo: true)
          .where(
            'jobRoles',
            arrayContains: categoryId,
          ); // Use categoryId directly!

      yield* query.snapshots().map((snapshot) {
        log(
          'Found ${snapshot.docs.length} technicians with categoryId: $categoryId',
        );
        return snapshot.docs
            .map(
              (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();
      });

      log('category wise workers stream completed');
    } catch (e) {
      log('Error in getCategoryWiseWorkersStream: $e');
      yield [];
    }
  }

  void _onRegionChanged(Region? newRegion) {
    if (selectedRegion != newRegion) {
      setState(() {
        selectedRegion = newRegion;
        selectedCity = null;
        selectedDistrict = null;
        filteredCities = newRegion?.cities ?? [];
        filteredDistricts = [];
      });
    }
  }

  void _onCityChanged(City? newCity) {
    if (selectedCity != newCity) {
      setState(() {
        selectedCity = newCity;
        selectedDistrict = null;
        filteredDistricts = newCity?.districts ?? [];
      });
    }
  }

  void _onDistrictChanged(District? newDistrict) {
    if (selectedDistrict != newDistrict) {
      setState(() {
        selectedDistrict = newDistrict;
      });
    }
  }

  void _clearFilter() {
    if (selectedRegion != null ||
        selectedCity != null ||
        selectedDistrict != null) {
      setState(() {
        selectedRegion = null;
        selectedCity = null;
        selectedDistrict = null;
        filteredCities = [];
        filteredDistricts = [];
        regionSearchController.clear();
        citySearchController.clear();
        districtSearchController.clear();
        showRegionDropdown = false;
        showCityDropdown = false;
        showDistrictDropdown = false;
      });
    }
  }

  void _filterRegions(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRegions = widget.regions;
      } else {
        filteredRegions = widget.regions.where((region) {
          final nameEn = region.regionEn.toLowerCase();
          final nameAr = region.regionAr.toLowerCase();
          final searchQuery = query.toLowerCase();
          return nameEn.contains(searchQuery) || nameAr.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _filterCities(String query) {
    if (selectedRegion == null) return;

    setState(() {
      if (query.isEmpty) {
        filteredCities = selectedRegion!.cities;
      } else {
        filteredCities = selectedRegion!.cities.where((city) {
          final nameEn = city.cityEn.toLowerCase();
          final nameAr = city.cityAr.toLowerCase();
          final searchQuery = query.toLowerCase();
          return nameEn.contains(searchQuery) || nameAr.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _filterDistricts(String query) {
    if (selectedCity == null) return;

    setState(() {
      if (query.isEmpty) {
        filteredDistricts = selectedCity!.districts;
      } else {
        filteredDistricts = selectedCity!.districts.where((district) {
          final nameEn = district.districtEn.toLowerCase();
          final nameAr = district.districtAr.toLowerCase();
          final searchQuery = query.toLowerCase();
          return nameEn.contains(searchQuery) || nameAr.contains(searchQuery);
        }).toList();
      }
    });
  }

  Widget _buildLocationFilterUI(TextTheme textTheme) {
    bool isArabic = AppLocalizations.of(context)?.localeName == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Region Selector
        _buildDropdownField(
          controller: regionSearchController,
          hintText:
              AppLocalizations.of(context)?.selectProvince ?? 'Select Region',
          selectedValue: selectedRegion?.getName(isArabic),
          showDropdown: showRegionDropdown,
          items: filteredRegions,
          onChanged: (value) {
            _filterRegions(value);
            setState(() {
              showRegionDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              showRegionDropdown = !showRegionDropdown;
            });
          },
          onClear: () {
            setState(() {
              regionSearchController.clear();
              selectedRegion = null;
              selectedCity = null;
              selectedDistrict = null;
              filteredRegions = widget.regions;
              filteredCities = [];
              filteredDistricts = [];
              showRegionDropdown = false;
            });
          },
          itemBuilder: (region) => ListTile(
            dense: true,
            title: Text(
              region.getName(isArabic),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: selectedRegion == region
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: selectedRegion == region
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            trailing: selectedRegion == region
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  )
                : null,
            onTap: () {
              _onRegionChanged(region);
              regionSearchController.text = region.getName(isArabic);
              setState(() {
                showRegionDropdown = false;
              });
            },
          ),
        ),

        if (selectedRegion != null) ...[
          const SizedBox(height: 12),
          // City Selector
          _buildDropdownField(
            controller: citySearchController,
            hintText: AppLocalizations.of(context)?.selectCity ?? 'Select City',
            selectedValue: selectedCity?.getName(isArabic),
            showDropdown: showCityDropdown,
            items: filteredCities,
            onChanged: (value) {
              _filterCities(value);
              setState(() {
                showCityDropdown = value.isNotEmpty;
              });
            },
            onTap: () {
              setState(() {
                showCityDropdown = !showCityDropdown;
              });
            },
            onClear: () {
              setState(() {
                citySearchController.clear();
                selectedCity = null;
                selectedDistrict = null;
                filteredCities = selectedRegion?.cities ?? [];
                filteredDistricts = [];
                showCityDropdown = false;
              });
            },
            itemBuilder: (city) => ListTile(
              dense: true,
              title: Text(
                city.getName(isArabic),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: selectedCity == city
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: selectedCity == city
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: selectedCity == city
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    )
                  : null,
              onTap: () {
                _onCityChanged(city);
                citySearchController.text = city.getName(isArabic);
                setState(() {
                  showCityDropdown = false;
                });
              },
            ),
          ),
        ],

        if (selectedCity != null) ...[
          const SizedBox(height: 12),
          // District Selector
          _buildDropdownField(
            controller: districtSearchController,
            hintText:
                AppLocalizations.of(context)?.selectNeighborhood ??
                'Select District',
            selectedValue: selectedDistrict?.getName(isArabic),
            showDropdown: showDistrictDropdown,
            items: filteredDistricts,
            onChanged: (value) {
              _filterDistricts(value);
              setState(() {
                showDistrictDropdown = value.isNotEmpty;
              });
            },
            onTap: () {
              setState(() {
                showDistrictDropdown = !showDistrictDropdown;
              });
            },
            onClear: () {
              setState(() {
                districtSearchController.clear();
                selectedDistrict = null;
                filteredDistricts = selectedCity?.districts ?? [];
                showDistrictDropdown = false;
              });
            },
            itemBuilder: (district) => ListTile(
              dense: true,
              title: Text(
                district.getName(isArabic),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: selectedDistrict == district
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: selectedDistrict == district
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: selectedDistrict == district
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    )
                  : null,
              onTap: () {
                _onDistrictChanged(district);
                districtSearchController.text = district.getName(isArabic);
                setState(() {
                  showDistrictDropdown = false;
                });
              },
            ),
          ),
        ],

        // Active Filter Display
        if (selectedDistrict != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    maxLines: 2,
                    '${selectedRegion?.getName(isArabic)} > ${selectedCity?.getName(isArabic)} > ${selectedDistrict?.getName(isArabic)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required TextEditingController controller,
    required String hintText,
    String? selectedValue,
    required bool showDropdown,
    required List<T> items,
    required Function(String) onChanged,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required Widget Function(T) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, size: 20),

              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: onClear,
                    )
                  : IconButton(
                      icon: Icon(
                        showDropdown
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                      onPressed: onTap,
                    ),
            ),
            onChanged: onChanged,
            onTap: onTap,
          ),
          if (showDropdown)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...items.map(itemBuilder),
                  if (items.isEmpty && controller.text.isNotEmpty)
                    ListTile(
                      dense: true,
                      title: Text(
                        AppLocalizations.of(context)?.noLocationsFound ??
                            'No locations found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<UserModel> users, TextTheme textTheme) {
    final categoryName = categoryModel?.name;
    final categoryNameAr = categoryModel?.name_ar;
    bool isArabic = AppLocalizations.of(context)?.localeName == 'ar';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_rounded, size: 48),
          const SizedBox(height: 16),
          Text(
            selectedDistrict != null
                ? "${AppLocalizations.of(context)!.no} ${categoryName != null ? (isArabic ? categoryNameAr : categoryName) : (AppLocalizations.of(context)?.agents ?? 'agents')} ${AppLocalizations.of(context)?.availableInSelectedLocation ?? 'available in selected location'}"
                : categoryName != null
                ? '${AppLocalizations.of(context)!.no} ${isArabic ? categoryNameAr : categoryName} ${AppLocalizations.of(context)!.agentsAvailable}'
                : AppLocalizations.of(context)!.noAgentsAvailable,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (selectedDistrict != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearFilter,
              icon: const Icon(Icons.clear_all),
              label: Text(
                AppLocalizations.of(context)?.showAllAgents ??
                    'Show All Agents',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, TextTheme textTheme) {
    final userId = user.uid ?? '';
    final isAssigningThisUser = assigningUsers.contains(userId);
    final isDisabled =
        isAssigning && !isAssigningThisUser || globalAssignmentLock;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    // Get translated job role names
    final jobRoleNames = _getJobRoleNames(
      user.jobRoles?.cast<String>(),
      isArabic,
    );

    return ListTile(
      title: Text(
        user.name ?? '',
        style: TextStyle(color: isDisabled ? Colors.grey.shade600 : null),
      ),
      subtitle: RichText(
        text: TextSpan(
          style: textTheme.labelMedium?.copyWith(
            color: isDisabled ? Colors.grey.shade500 : null,
          ),
          children: [
            if (user.districtName != null) ...[
              WidgetSpan(
                child: Icon(
                  Icons.location_city,
                  size: 15,
                  color: isDisabled ? Colors.grey.shade500 : null,
                ),
              ),
              TextSpan(text: ' ${user.districtName ?? ''}  '),
            ],
            if (jobRoleNames.isNotEmpty) ...[
              WidgetSpan(
                child: Icon(
                  Icons.work_rounded,
                  size: 15,
                  color: isDisabled ? Colors.grey.shade500 : null,
                ),
              ),
              TextSpan(text: ' ${jobRoleNames.join(', ')}'),
            ],
          ],
        ),
      ),
      trailing: isAssigningThisUser
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isDisabled
          ? const Icon(Icons.hourglass_empty, color: Colors.grey, size: 20)
          : null,
      enabled: !isDisabled,
      tileColor: isDisabled ? Colors.grey.withOpacity(0.05) : null,
      onTap: isDisabled ? null : () => _handleAssignAgent(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String? categoryName = categoryModel?.name;
    String? categoryNameAr = categoryModel?.name_ar;
    bool isArabic = AppLocalizations.of(context)?.localeName == 'ar';

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 8, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoryName != null
                        ? '${AppLocalizations.of(context)!.assignTo} ${isArabic ? categoryNameAr : categoryName}'
                        : AppLocalizations.of(context)!.assignToUser,
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  color: Colors.red,
                  onPressed: isAssigning ? null : _showRejectConfirmationDialog,
                  icon: const Icon(Icons.highlight_off_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.filterByLocation,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLocationFilterUI(textTheme)),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: selectedDistrict != null
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: selectedDistrict != null && !isAssigning
                            ? _clearFilter
                            : null,
                        icon: Icon(
                          Icons.clear_rounded,
                          color: selectedDistrict != null
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          size: 20,
                        ),
                        tooltip: AppLocalizations.of(context)!.clearFilter,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _getFilteredUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${AppLocalizations.of(context)?.error ?? 'Error'}: ${snapshot.error}',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              cachedUsersStream = null;
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)?.retry ?? 'Retry',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting ||
                    !categoriesLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return _buildEmptyState(users, textTheme);
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserTile(users[index], textTheme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
