import 'dart:developer';
import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_controllers.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/warranty_controllers.dart';
import 'package:aboglumbo_bbk_panel/pages/chat_screen.dart';
import 'package:aboglumbo_bbk_panel/services/chat_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:collection/collection.dart';

class BookingInfo extends StatefulWidget {
  final BookingModel booking;
  final bool isAdmin;
  final bool isWarranty;
  final bool isInAdminMode;

  const BookingInfo({
    super.key,
    required this.booking,
    required this.isAdmin,
    this.isWarranty = false,
    this.isInAdminMode = false,
  });

  @override
  State<BookingInfo> createState() => _BookingInfoState();
}

class _BookingInfoState extends State<BookingInfo> {
  bool isInitiatingChat = false;
  Future<void> handleChatButton() async {
    if (isInitiatingChat) return;

    setState(() {
      isInitiatingChat = true;
    });

    try {
      final chatService = TechnicianChatService();
      String chatId;

      // Fetch the latest booking data from Firestore to check chatroomId
      final bookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
          .get();

      String? latestChatroomId;
      if (bookingDoc.exists) {
        final data = bookingDoc.data() as Map<String, dynamic>?;
        latestChatroomId = data?['chatroomId'] as String?;
      }

      // Check if chatroomId exists in Firestore AND verify it exists in Realtime Database
      bool chatExists = false;
      if (latestChatroomId != null && latestChatroomId.isNotEmpty) {
        // Verify the chat actually exists in Realtime Database using the service method
        chatExists = await chatService.chatExists(latestChatroomId);

        if (chatExists) {
          log(
            '✅ Chat verified in both Firestore and Realtime Database: $latestChatroomId',
          );
        } else {
          log(
            '⚠️ Chat ID exists in Firestore but not in Realtime Database. Will create new chat.',
          );
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: AlertDialog(
              backgroundColor: Colors.white,
              content: SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 24, child: Loader()),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.loadingChat,

                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (chatExists) {
        chatId = latestChatroomId!;
        log('✅ Using existing chat: $chatId');
        // Small delay to show the message
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        log('🔄 Initiating new chat...');
        // Get technician info
        String technicianName;
        String technicianPhoto;
        if (widget.isWarranty) {
          final tech = widget.booking.warranty?.assignedTechnician;
          technicianName = widget.isAdmin
              ? "Admin"
              : tech?.name ?? "Technician";
          technicianPhoto = widget.isAdmin ? "" : tech?.profileUrl ?? "";
        } else {
          technicianName = widget.isAdmin
              ? "Admin"
              : widget.booking.agent?.name ?? "Technician";
          technicianPhoto = widget.isAdmin
              ? ""
              : widget.booking.agent?.profileUrl ?? "";
        }
        // Create new chat
        chatId = await chatService.initiateChat(
          bookingId: widget.booking.id,
          customerId: widget.booking.customer.uid,
          customerName: widget.booking.customer.name ?? "Customer",
          customerPhoto: "",
          technicianName: technicianName,
          technicianPhoto: technicianPhoto,
        );
        log('✅ Chat created with ID: $chatId');
      }

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate to chat screen
      if (mounted) {
        String technicianName;
        String technicianPhoto;
        if (widget.isWarranty) {
          final tech = widget.booking.warranty?.assignedTechnician;
          technicianName = widget.isAdmin
              ? "Admin"
              : tech?.name ?? "Technician";
          technicianPhoto = widget.isAdmin ? "" : tech?.profileUrl ?? "";
        } else {
          technicianName = widget.isAdmin
              ? "Admin"
              : widget.booking.agent?.name ?? "Technician";
          technicianPhoto = widget.isAdmin
              ? ""
              : widget.booking.agent?.profileUrl ?? "";
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianChatScreen(
              isAdmin: widget.isAdmin,
              chatId: chatId,
              participantName: widget.booking.customer.name ?? "Customer",
              participantId: widget.booking.customer.uid,
              participantPhoto: "",
              technicianName: technicianName,
              technicianPhoto: technicianPhoto,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLocalizations.of(context)!.failedToStartChat}: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      log('❌ Chat error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isInitiatingChat = false;
        });
      }
    }
  }

  void openDirections() {
    final addresses = widget.booking.customer.addresses;
    final selectedAddress =
        addresses.where((a) => a.isSelected == true).isNotEmpty
        ? addresses.firstWhere((a) => a.isSelected == true)
        : null;

    if (selectedAddress != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query='
          '${selectedAddress.lat},${selectedAddress.lon}';
      launchUrlString(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final safePadding = MediaQuery.of(context).padding;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppLocalizations.of(context)!.bookingInfo),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 16,
          left: 16 + safePadding.left,
          right: 16 + safePadding.right,
          bottom: 16 + safePadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review and Tip Card
            if (!widget.isInAdminMode &&
                ((widget.booking.bookingStatusCode.toLowerCase() == 'a' &&
                        !widget.isAdmin) ||
                    (!widget.isAdmin &&
                        widget.isWarranty &&
                        widget.booking.warranty!.warrantyStatusCode
                                .toLowerCase() ==
                            's'))) ...{
              StreamBuilder<DocumentSnapshot>(
                stream: AppFirestore.bookingsCollectionRef
                    .doc(widget.booking.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  String? chatroomId = widget.booking.chatroomId;

                  // Update chatroomId from stream if available
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    chatroomId = data?['chatroomId'] as String?;
                  }
                  if (widget.booking.bookingStatusCode.toLowerCase() != 'a' &&
                      widget.booking.warranty!.warrantyStatusCode
                              .toLowerCase() !=
                          's') {
                    return SizedBox.shrink();
                  }
                  return _buildChatWithCustomerButton(
                    context,
                    colorScheme,
                    chatroomId,
                    widget.isWarranty,
                  );
                },
              ),

              const SizedBox(height: 16),
            },

            // Booking controls (Normal)
            if (!widget.isInAdminMode &&
                !widget.isWarranty &&
                (widget.booking.bookingStatusCode.toLowerCase() == 'a')
            //  &&
            // (widget.booking.agent?.uid == LocalStore.getUID() ||
            //     (LocalStore.getCachedUserData()?.adminAccessLevel == 1))
            )
              StreamBuilder<DocumentSnapshot>(
                stream: AppFirestore.bookingsCollectionRef
                    .doc(widget.booking.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  log("normal booking controls");
                  log("isInadminmode : ${widget.isInAdminMode.toString()}");
                  log("isWarranty : ${widget.isWarranty.toString()}");
                  log(
                    "bookingStatusCode : ${widget.booking.bookingStatusCode.toString()}",
                  );
                  bool isTracking = widget.booking.isStartTracking ?? false;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    isTracking = data?['isStartTracking'] ?? false;
                  }

                  return BookingControlsWidget(
                    booking: widget.booking,
                    isTracking: isTracking,
                    onTrackingStarted: openDirections,
                  );
                },
              ),

            // Warranty controls (Warranty)
            if (widget.isWarranty && widget.booking.warranty != null) ...[
              Builder(
                builder: (context) {
                  final warrantyStatus =
                      widget.booking.warranty?.warrantyStatusCode;
                  log("warranty controls");
                  log("isInadminmode : ${widget.isInAdminMode.toString()}");
                  log("isWarranty : ${widget.isWarranty.toString()}");
                  log("warrantyStatusCode : $warrantyStatus");

                  // Warranty tracking controls (when warranty is started)
                  if (!widget.isInAdminMode &&
                      warrantyStatus == 'S' &&
                      (widget.booking.warranty?.assignedTechnician?.uid ==
                              LocalStore.getUID() ||
                          (LocalStore.getCachedUserData()?.adminAccessLevel ==
                              1))) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: AppFirestore.bookingsCollectionRef
                          .doc(widget.booking.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        bool isTracking =
                            widget.booking.isStartTracking ?? false;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          isTracking = data?['isStartTracking'] ?? false;
                        }

                        return WarrantyControlsWidget(
                          booking: widget.booking,
                          isTracking: isTracking,
                          isAdmin: widget.isAdmin,
                          onTrackingStarted: openDirections,
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],

            // Service card
            _buildServiceCard(context, locale, textTheme, colorScheme),
            const SizedBox(height: 16),

            // Customer info
            _buildCustomerInfoCard(context, textTheme, colorScheme),

            // Issue media
            if ((widget.booking.issueImage != null &&
                    widget.booking.issueImage!.isNotEmpty) ||
                (widget.booking.issueVideo != null &&
                    widget.booking.issueVideo!.isNotEmpty))
              const SizedBox(height: 16),
            if ((widget.booking.issueImage != null &&
                    widget.booking.issueImage!.isNotEmpty) ||
                (widget.booking.issueVideo != null &&
                    widget.booking.issueVideo!.isNotEmpty))
              _buildIssueMediaCard(context, textTheme, colorScheme),
            const SizedBox(height: 16),

            if (widget.booking.bookingStatusCode.toLowerCase() == 'c' &&
                widget.booking.completionData != null) ...[
              _buildCompletionDataCard(context, textTheme, colorScheme),
              const SizedBox(height: 16),
            ],
            if (widget.booking.review != null) ...[
              _buildReviewCard(context, textTheme, colorScheme),
              const SizedBox(height: 16),
              _buildTipCard(context, textTheme, colorScheme),
              const SizedBox(height: 16),
            ],
            if (widget.isAdmin &&
                widget.booking.warranty != null &&
                widget.booking.warranty!.rejectedTechnicians != null &&
                widget.booking.warranty!.rejectedTechnicians!.isNotEmpty) ...[
              _buildWarrantyRejectedTechniciansCard(
                context,
                textTheme,
                colorScheme,
              ),
              const SizedBox(height: 16),
            ],

            // Timeline
            _buildBookingTimelineCard(
              context,
              textTheme,
              colorScheme,
              widget.isWarranty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyRejectedTechniciansCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_off_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.warrantyRejectedTechnicians,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // List of rejected technicians
            ...widget.booking.warranty!.rejectedTechnicians!.map((tech) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Technician Name
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.technicianName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.name ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Technician Phone Number
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.phone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tech.phone ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Call Button
                        IconButton(
                          icon: const Icon(Icons.phone, size: 18),
                          color: Colors.green,
                          onPressed: () async {
                            if (tech.phone != null && tech.phone!.isNotEmpty) {
                              final phoneUrl = 'tel:${tech.phone}';
                              if (await canLaunchUrlString(phoneUrl)) {
                                await launchUrlString(phoneUrl);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.couldNotLaunchPhone,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cancellation Reason
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.reasonforrejection,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.reason ?? 'No reason provided',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancelled Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.cancelledDate,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.rejectedAt != null
                          ? _formatDateLocalized(
                              tech.rejectedAt!.toDate(),
                              context,
                            )
                          : 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATED CHAT BUTTON - Accepts chatroomId parameter from StreamBuilder
  Widget _buildChatWithCustomerButton(
    BuildContext context,
    ColorScheme colorScheme,
    String? chatroomId,
    bool isWarranty,
  ) {
    final bool hasChatRoom = chatroomId != null && chatroomId.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInitiatingChat ? null : handleChatButton,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasChatRoom ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  hasChatRoom
                      ? AppLocalizations.of(context)!.continueChat
                      : AppLocalizations.of(context)!.chatWithCustomer,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String locale,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.handyman_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.serviceInfo,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.bookingId,
              value: widget.booking.id,
              textTheme: textTheme,
              colorScheme: colorScheme,
              needCopyButton: true,
            ),
            const SizedBox(height: 16),

            // Service Name
            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.serviceName,
              value: locale == 'en'
                  ? (widget.booking.service.name ?? '')
                  : (widget.booking.service.name_ar ?? ''),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // Service Description
            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.serviceDescription,
              value: locale == 'en'
                  ? (widget.booking.service.description ?? '')
                  : (widget.booking.service.description_ar ?? ''),
              textTheme: textTheme,
              colorScheme: colorScheme,
              isDescription: true,
            ),
            const SizedBox(height: 16),

            // Price with prominent styling
            _buildPriceSection(context, textTheme, colorScheme),
            const SizedBox(height: 16),

            // Payment Mode
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    bool isDescription = false,
    bool needCopyButton = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  maxLines: isDescription ? null : 2,
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isDescription ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    height: isDescription ? 1.4 : 1.2,
                  ),
                ),
              ),
              if (needCopyButton) ...{
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                    },
                    icon: Icon(Icons.copy),
                    iconSize: 16,
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.inspectionFee,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.booking.service.price} ${AppLocalizations.of(context)!.sar}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final addresses = widget.booking.customer.addresses;
    AddressModel? selectedAddress =
        addresses.where((a) => a.isSelected == true).isNotEmpty
        ? addresses.firstWhere((a) => a.isSelected == true)
        : null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.customerInfo,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCustomerInfoRow(
              icon: Icons.person,
              label: AppLocalizations.of(context)!.customerName,
              value: (widget.booking.customer.name ?? 'N/A'),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildCustomerInfoRowWithButton(
              icon: Icons.call_rounded,
              label: AppLocalizations.of(context)!.phoneNumber,
              value: selectedAddress != null
                  ? (selectedAddress.phoneNumber)
                  : (widget.booking.customer.phone ?? 'N/A'),
              buttonIcon: Icons.call,
              buttonLabel: AppLocalizations.of(context)!.call,
              onButtonPressed: () => launchUrlString(
                'tel:${selectedAddress?.phoneNumber ?? widget.booking.customer.phone}',
              ),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildCustomerInfoRowWithButton(
              icon: Icons.location_on,
              label: AppLocalizations.of(context)!.location,
              value: selectedAddress != null
                  ? '${selectedAddress.streetName}'
                  : 'N/A',
              buttonIcon: Icons.directions,
              buttonLabel: AppLocalizations.of(context)!.directions,
              onButtonPressed: () {
                if (selectedAddress != null) {
                  final url =
                      'https://www.google.com/maps/search/?api=1&query='
                      '${selectedAddress.lat},${selectedAddress.lon}';
                  launchUrlString(url);
                }
              },
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    bool isClickable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isClickable
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isClickable
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIssueMediaCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: colorScheme.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.issueMedia,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (widget.booking.issueImage != null &&
                widget.booking.issueImage!.isNotEmpty)
              const SizedBox(height: 20),

            // Images Section
            if (widget.booking.issueImage != null &&
                widget.booking.issueImage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(widget.booking.issueImage!, context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.image,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (widget.booking.issueVideo != null &&
                widget.booking.issueVideo!.isNotEmpty)
              const SizedBox(height: 16),

            if (widget.booking.issueVideo != null &&
                widget.booking.issueVideo!.isNotEmpty)
              GestureDetector(
                onTap: () =>
                    _showFullScreenVideo(widget.booking.issueVideo!, context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.video,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600]!,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey[600]!,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _showFullScreenVideo(String videoUrl, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.issueVideo,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: CachedVideoPlayer(
              videoUrl: videoUrl,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoRowWithButton({
    required IconData icon,
    required String label,
    required String value,
    required IconData buttonIcon,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: Icon(buttonIcon, size: 16),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                textStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingTimelineCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isWarranty,
  ) {
    List<Map<String, dynamic>> timelineItems = [];

    // Get current technician's cancellation date (if they cancelled)
    DateTime? currentTechCancelledAt;

    if (!widget.isAdmin && isWarranty) {
      final currentTechId = FirebaseAuth.instance.currentUser?.uid;
      if (currentTechId != null &&
          widget.booking.warranty?.rejectedTechnicians != null) {
        final cancelledByCurrentTech = widget
            .booking
            .warranty!
            .rejectedTechnicians!
            .firstWhereOrNull((tech) => tech.uid == currentTechId);

        if (cancelledByCurrentTech != null) {
          currentTechCancelledAt = cancelledByCurrentTech.rejectedAt!.toDate();
        }
      }
    }

    if (isWarranty) {
      // ==========================================
      // WARRANTY BOOKING TIMELINE ONLY
      // ==========================================

      // Created (original booking)
      if (widget.booking.createdAt != null) {
        final eventDate = widget.booking.createdAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.createdAt,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.customerSubmittedBookingRequest,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Original service completed
      if (widget.booking.completedAt != null) {
        final eventDate = widget.booking.completedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.originalServiceCompleted,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.serviceHasBeenSuccessfullyCompleted,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty requested - always show this regardless of technician cancellation
      if (widget.booking.warranty?.requestedOn != null) {
        final eventDate = widget.booking.warranty!.requestedOn!.toDate();
        timelineItems.add({
          'title': AppLocalizations.of(context)!.warrantyRepairRequested,
          'time': _formatDateLocalized(eventDate, context),
          'description': AppLocalizations.of(
            context,
          )!.customerRequestedRepairUnderWarranty,
          'status': 'completed',
          'date': eventDate,
        });
      }

      // Warranty accepted
      if (widget.booking.warranty?.acceptedAt != null) {
        final eventDate = widget.booking.warranty!.acceptedAt!;
        final eventDateTime = eventDate.toDate();

        if (currentTechCancelledAt == null ||
            eventDateTime.isBefore(currentTechCancelledAt) ||
            eventDateTime.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.warrantyRepairAccepted,
            'time': _formatDateLocalized(eventDateTime, context),
            'description': AppLocalizations.of(
              context,
            )!.technicianAcceptedTheRequest,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty tracking started
      if (widget.booking.trackingStartedAt != null) {
        final eventDate = widget.booking.trackingStartedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.trackingStartedAt,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.serviceTrackingInitiated,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty tracking stopped
      if (widget.booking.trackingStoppedAt != null) {
        final eventDate = widget.booking.trackingStoppedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.trackingStoppedAt,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(context)!.serviceTrackingStopped,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty completed
      if (widget.booking.warranty?.completedAt != null) {
        final eventDate = widget.booking.warranty!.completedAt!;
        final eventDateTime = eventDate.toDate();

        if (currentTechCancelledAt == null ||
            eventDateTime.isBefore(currentTechCancelledAt) ||
            eventDateTime.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.warrantyRepairCompleted,
            'time': _formatDateLocalized(eventDateTime, context),
            'description': AppLocalizations.of(
              context,
            )!.technicianCompletedTheRequest,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty rejected technicians - For technician view
      if (!widget.isAdmin &&
          widget.booking.warranty?.rejectedTechnicians != null &&
          widget.booking.warranty!.rejectedTechnicians!.isNotEmpty) {
        final currentTechId = LocalStore.getUID();

        if (currentTechId != null) {
          final currentTechCancellation = widget
              .booking
              .warranty!
              .rejectedTechnicians!
              .firstWhereOrNull((tech) => tech.uid == currentTechId);

          if (currentTechCancellation != null) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.youCancelledThisRequest,
              'time': _formatDateLocalized(
                currentTechCancellation.rejectedAt!.toDate(),
                context,
              ),
              'description': AppLocalizations.of(
                context,
              )!.youDeclinedThisWarrantyRequest,
              'status': 'cancelled',
              'date': currentTechCancellation.rejectedAt!,
            });
          }
        }
      }

      // Warranty rejected technicians - For admin view
      if (widget.isAdmin &&
          widget.booking.warranty?.rejectedTechnicians != null &&
          widget.booking.warranty!.rejectedTechnicians!.isNotEmpty) {
        for (var tech in widget.booking.warranty!.rejectedTechnicians!) {
          final eventDate = tech.rejectedAt!;
          final eventDateTime = eventDate.toDate();

          if (currentTechCancelledAt == null ||
              eventDateTime.isBefore(currentTechCancelledAt) ||
              eventDateTime.isAtSameMomentAs(currentTechCancelledAt)) {
            final workerName =
                tech.name ?? AppLocalizations.of(context)!.unknownTechnician;

            timelineItems.add({
              'title': AppLocalizations.of(context)!.technicianCancelled,
              'time': _formatDateLocalized(eventDateTime, context),
              'description':
                  '${AppLocalizations.of(context)!.cancelledByTechnician}: $workerName',
              'status': 'cancelled',
              'date': eventDate,
            });
          }
        }
      }

      // Warranty rejected by admin
      if (widget.booking.warranty?.rejectedAt != null) {
        final eventDate = widget.booking.warranty!.rejectedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          final warrantyStatus =
              widget.booking.warranty?.warrantyStatusCode.toLowerCase() ?? '';
          final isAdminRejection =
              warrantyStatus == 's' || warrantyStatus == 'x';

          timelineItems.add({
            'title': isAdminRejection
                ? AppLocalizations.of(context)!.warrantyRejectedByAdmin
                : AppLocalizations.of(context)!.warrantyRejectedByTechnician,
            'time': _formatDateLocalized(eventDate, context),
            'description': isAdminRejection
                ? AppLocalizations.of(
                    context,
                  )!.warrantyRequestWasRejectedByAdmin
                : AppLocalizations.of(
                    context,
                  )!.warrantyRequestWasRejectedByTechnician,
            'status': 'rejected',
            'date': eventDate,
          });
        }
      }

      // Warranty expired
      if (widget.booking.warranty?.expiredOn != null) {
        final eventDate = widget.booking.warranty!.expiredOn!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.warrantyExpired,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.warrantyPeriodHasExpired,
            'status': 'rejected',
            'date': eventDate,
          });
        }
      }
    } else {
      // ==========================================
      // NORMAL BOOKING TIMELINE ONLY
      // ==========================================

      // Created
      if (widget.booking.createdAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.createdAt,
          'time': _formatDateLocalized(
            widget.booking.createdAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.customerSubmittedBookingRequest,
          'status': 'completed',
          'date': widget.booking.createdAt!.toDate(),
        });
      }

      // Accepted
      if (widget.booking.acceptedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.acceptedAt,
          'time': _formatDateLocalized(
            widget.booking.acceptedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.serviceProviderConfirmedAppointment,
          'status': 'completed',
          'date': widget.booking.acceptedAt!.toDate(),
        });
      }

      // Tracking started
      if (widget.booking.trackingStartedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.trackingStartedAt,
          'time': _formatDateLocalized(
            widget.booking.trackingStartedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(context)!.serviceTrackingInitiated,
          'status': 'completed',
          'date': widget.booking.trackingStartedAt!.toDate(),
        });
      }

      // Tracking stopped
      if (widget.booking.trackingStoppedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.trackingStoppedAt,
          'time': _formatDateLocalized(
            widget.booking.trackingStoppedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(context)!.serviceTrackingStopped,
          'status': 'completed',
          'date': widget.booking.trackingStoppedAt!.toDate(),
        });
      }

      // Completed
      if (widget.booking.completedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.completedAt,
          'time': _formatDateLocalized(
            widget.booking.completedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.serviceHasBeenSuccessfullyCompleted,
          'status': 'completed',
          'date': widget.booking.completedAt!.toDate(),
        });
      }

      // Rejected
      if (widget.booking.bookingStatusCode.toLowerCase() == 'r') {
        final isAdminRejection = widget.booking.rejectedBy == "Admin";

        timelineItems.add({
          'title': isAdminRejection
              ? AppLocalizations.of(context)!.cancelledByAdmin
              : AppLocalizations.of(context)!.rejectedAt,
          'time': _formatDateLocalized(
            widget.booking.rejectedAt!.toDate(),
            context,
          ),
          'description': isAdminRejection
              ? '${AppLocalizations.of(context)!.cancelledBy}: ${AppLocalizations.of(context)!.admin}'
              : AppLocalizations.of(
                  context,
                )!.bookingWasRejectedByServiceProvider,
          'status': 'rejected',
          'date': widget.booking.rejectedAt!.toDate(),
        });
      }

      // Cancelled by customer
      if (widget.booking.bookingStatusCode.toLowerCase() == 'xc') {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.cancelledByCustomer,
          'time': _formatDateLocalized(
            widget.booking.cancelledAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.bookingWasCancelledByCustomer,
          'status': 'rejected',
          'date': widget.booking.cancelledAt!.toDate(),
        });
      }

      // Worker cancellations (admin only)
      if (widget.isAdmin && widget.booking.cancelledWorkers.isNotEmpty) {
        for (var worker in widget.booking.cancelledWorkers) {
          final workerName = worker.agentName.isNotEmpty
              ? worker.agentName
              : AppLocalizations.of(context)!.unknownTechnician;

          timelineItems.add({
            'title': AppLocalizations.of(context)!.technicianCancelled,
            'time': _formatDateLocalized(worker.cancelledAt.toDate(), context),
            'description':
                '${AppLocalizations.of(context)!.cancelledByTechnician}: $workerName',
            'status': 'cancelled',
            'date': worker.cancelledAt.toDate(),
          });
        }
      }
    }

    // Sort ALL events by actual date (chronological order)
    timelineItems.sort((a, b) {
      final aDate = a['date'];
      final bDate = b['date'];

      // Convert Timestamp to DateTime if needed
      final aDateTime = aDate is DateTime
          ? aDate
          : (aDate as Timestamp).toDate();
      final bDateTime = bDate is DateTime
          ? bDate
          : (bDate as Timestamp).toDate();

      return aDateTime.compareTo(bDateTime);
    });

    // === ADD CURRENT/PENDING STATUS (ONLY if technician hasn't cancelled) ===

    if (currentTechCancelledAt == null) {
      bool isInProgress =
          widget.booking.trackingStartedAt != null &&
          widget.booking.trackingStoppedAt == null;

      if (isWarranty) {
        // Warranty current status
        // Only show pending status if warranty is not completed, rejected, or expired
        final warrantyStatusCode = widget.booking.warranty!.warrantyStatusCode
            .toLowerCase();
        final isWarrantyActive =
            widget.booking.warranty?.completedAt == null &&
            widget.booking.warranty?.rejectedAt == null &&
            warrantyStatusCode != 'e' && // Not expired
            warrantyStatusCode != 'x' && // Not rejected
            warrantyStatusCode != 'c'; // Not completed

        if (isWarrantyActive) {
          if (isInProgress) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.serviceInProgress,
              'time': AppLocalizations.of(context)!.current,
              'description': AppLocalizations.of(
                context,
              )!.serviceIsCurrentlyBeingPerformed,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else if (widget.booking.warranty?.acceptedAt != null) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.waitingForServiceProvider,
              'time': AppLocalizations.of(context)!.pending,
              'description': AppLocalizations.of(
                context,
              )!.waitingForTechnicianToStartService,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else {
            // Check if there are any rejected technicians
            final hasRejectedTechnicians =
                widget.booking.warranty?.rejectedTechnicians != null &&
                widget.booking.warranty!.rejectedTechnicians!.isNotEmpty;

            if (hasRejectedTechnicians) {
              // After technician rejection, waiting for admin to reassign
              timelineItems.add({
                'title': AppLocalizations.of(context)!.waitingForAdmin,
                'time': AppLocalizations.of(context)!.pending,
                'description': AppLocalizations.of(
                  context,
                )!.waitingForAdminToReassign,
                'status': 'current',
                'date': DateTime.now(),
              });
            } else {
              // Initial state, waiting for technician to accept
              timelineItems.add({
                'title': AppLocalizations.of(
                  context,
                )!.waitingForServiceProvider,
                'time': AppLocalizations.of(context)!.pending,
                'description': AppLocalizations.of(
                  context,
                )!.waitingForServiceProviderResponse,
                'status': 'current',
                'date': DateTime.now(),
              });
            }
          }
        }
      } else {
        // Normal booking current status
        if (widget.booking.completedAt == null &&
            widget.booking.rejectedAt == null &&
            widget.booking.bookingStatusCode.toLowerCase() != 'xc' &&
            widget.booking.bookingStatusCode.toLowerCase() != 'r') {
          if (isInProgress) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.serviceInProgress,
              'time': AppLocalizations.of(context)!.current,
              'description': AppLocalizations.of(
                context,
              )!.serviceIsCurrentlyBeingPerformed,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else if (widget.booking.acceptedAt != null) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.waitingForServiceProvider,
              'time': AppLocalizations.of(context)!.pending,
              'description': AppLocalizations.of(
                context,
              )!.waitingForTechnicianToStartService,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.waitingForAcceptance,
              'time': AppLocalizations.of(context)!.pending,
              'description': AppLocalizations.of(
                context,
              )!.waitingForServiceProviderResponse,
              'status': 'current',
              'date': DateTime.now(),
            });
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.bookingTimeline,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ...timelineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == timelineItems.length - 1;

              return _buildTimelineItem(
                title: item['title']!,
                time: item['time']!,
                description: item['description']!,
                status: item['status']!,
                isLast: isLast,
                colorScheme: colorScheme,
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to format dates (you might already have this in your project)
  String _formatDateLocalized(DateTime date, BuildContext context) {
    return LocalizationHelper().formatDateLocalized(date, context);
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required String description,
    required String status,
    required bool isLast,
    required ColorScheme colorScheme,
  }) {
    Color getStatusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'current':
          return colorScheme.primary;
        case 'rejected':
          return Colors.red;
        case 'cancelled':
          return Colors.orange;
        case 'pending':
        default:
          return colorScheme.outline;
      }
    }

    IconData getStatusIcon() {
      switch (status) {
        case 'completed':
          return Icons.check_circle;
        case 'current':
          return Icons.radio_button_checked;
        case 'rejected':
          return Icons.cancel;
        case 'cancelled':
          return Icons.block;
        case 'pending':
        default:
          return Icons.radio_button_unchecked;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(getStatusIcon(), size: 20, color: getStatusColor()),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: colorScheme.outline.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Timeline content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == 'pending'
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: status == 'pending'
                        ? colorScheme.onSurface.withOpacity(0.4)
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String imageUrl, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.issueImage,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 24,
                    child: Loader(size: 14, color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 100, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.failedToLoadImage,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionDataCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (widget.booking.completionData == null) {
      return const SizedBox.shrink();
    }

    final completionData = widget.booking.completionData!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.completionDetails,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.booking.paymentCompleted) ...[
              _buildInfoRow(
                context,
                label: AppLocalizations.of(context)!.transactionId,
                value: widget.booking.orderId ?? "",
                textTheme: textTheme,
                colorScheme: colorScheme,
                needCopyButton: true,
              ),
              const SizedBox(height: 16),
            ],

            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.invoiceType,
              value: completionData.mode == 0
                  ? AppLocalizations.of(context)!.inspection
                  : AppLocalizations.of(context)!.fullService,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),

            // Upload Files
            if (completionData.fileUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.uploadFilesTitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildFileLinks(context, completionData.fileUrls, colorScheme),
            ],

            // Service Items
            if (completionData.serviceItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.serviceItems,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: completionData.serviceItems
                        .asMap()
                        .entries
                        .map(
                          (entry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 12,
                                    child: Text(
                                      entry.value.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'x${entry.value.quantity.toInt()}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      '${AppLocalizations.of(context)!.sar} ${entry.value.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (entry.key !=
                                  completionData.serviceItems.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Divider(
                                    color: colorScheme.outline.withOpacity(0.2),
                                    height: 1,
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],

            // Service Cost
            if (completionData.serviceCost > 0) ...[
              const SizedBox(height: 12),
              _buildCostRow(
                context,
                label: AppLocalizations.of(context)!.serviceCost,
                amount: completionData.serviceCost,
                colorScheme: colorScheme,
              ),
            ],

            const SizedBox(height: 12),
            _buildCostRow(
              context,
              label: AppLocalizations.of(context)!.inspectionFee,
              amount: widget.booking.service.price ?? 0.0,
              colorScheme: colorScheme,
            ),

            // Payment Mode (before total)
            if (widget.booking.bookingStatusCode.toLowerCase() == 'c' &&
                widget.booking.paymentCompleted) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                label: AppLocalizations.of(context)!.paymentMode,
                value: widget.booking.paymentModeCode.toLowerCase() == 'c'
                    ? AppLocalizations.of(context)!.card
                    : widget.booking.paymentModeCode.toLowerCase() == 'a'
                    ? AppLocalizations.of(context)!.applePay
                    : AppLocalizations.of(context)!.cashInHand,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ],

            // Total Cost
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.booking.paymentCompleted
                        ? AppLocalizations.of(context)!.amountPaid
                        : AppLocalizations.of(context)!.amountToBePaid,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.sar} ${completionData.totalCost.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(
    BuildContext context, {
    required String label,
    required double amount,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          '${AppLocalizations.of(context)!.sar} ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFileLinks(
    BuildContext context,
    List<String> fileUrls,
    ColorScheme colorScheme,
  ) {
    return fileUrls
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == fileUrls.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => launchUrlString(entry.value),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(entry.value),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFileName(entry.value),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  IconData _getFileIcon(String fileUrl) {
    String lowerUrl = fileUrl.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx')) {
      return Icons.description;
    } else if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.attachment;
  }

  String _getFileName(String fileUrl) {
    return "file ${int.tryParse((fileUrl.split('/').last.split('?').first.split("_").elementAt(3).substring(0, 1)))! + 1}${(fileUrl.split('/').last.split('?').first.split("_").elementAt(3).substring(1))}";
  }

  Widget _buildReviewCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final review = widget.booking.review;
    if (review == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.reviews, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.review,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 30,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: review.rating != null ? review.rating!.toInt() : 0,
                itemBuilder: (context, index) {
                  return Icon(Icons.star, color: Colors.amber, size: 20);
                },
              ),
            ),
            const SizedBox(height: 16),
            if (review.review.isNotEmpty) ...[
              Text(
                '"${review.review}"',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context)!.noReview,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final review = widget.booking.review;
    if (review == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.monetization_on, color: AppColors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.tip,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (review.tipAmount != null && review.tipAmount! > 0) ...[
              _buildInfoRow(
                value:
                    '${review.tipAmount} ${AppLocalizations.of(context)!.sar}',
                textTheme: textTheme,
                colorScheme: colorScheme,
                context,
                label: AppLocalizations.of(context)!.amount,
              ),
              SizedBox(height: 16),
              _buildInfoRow(
                value: review.paymentType?.toLowerCase() == 'cash'
                    ? AppLocalizations.of(context)!.cashInHand
                    : review.paymentType?.toLowerCase() == 'card'
                    ? AppLocalizations.of(context)!.card
                    : AppLocalizations.of(context)!.unknown,

                textTheme: textTheme,
                colorScheme: colorScheme,
                context,
                label: AppLocalizations.of(context)!.paymentMode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
