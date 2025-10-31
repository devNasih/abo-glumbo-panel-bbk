import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_controllers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BookingInfo extends StatelessWidget {
  final BookingModel booking;
  const BookingInfo({super.key, required this.booking});

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
          icon: Icon(Icons.close_rounded),
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
            if ((booking.bookingStatusCode.toLowerCase() == 'a') &&
                (booking.agent?.uid == LocalStore.getUID()))
              StreamBuilder<DocumentSnapshot>(
                stream: AppFirestore.bookingsCollectionRef
                    .doc(booking.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  bool isTracking = booking.isStartTracking ?? false;

                  // Use real-time data if available, otherwise fallback to original booking data
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    isTracking = data?['isStartTracking'] ?? false;
                  }

                  return BookingControlsWidget(
                    booking: booking,
                    isTracking: isTracking,
                  );
                },
              ),
            _buildServiceCard(context, locale, textTheme, colorScheme),
            const SizedBox(height: 16),
            _buildCustomerInfoCard(context, textTheme, colorScheme),
            if ((booking.issueImage != null &&
                    booking.issueImage!.isNotEmpty) ||
                (booking.issueVideo != null && booking.issueVideo!.isNotEmpty))
              const SizedBox(height: 16),
            if ((booking.issueImage != null &&
                    booking.issueImage!.isNotEmpty) ||
                (booking.issueVideo != null && booking.issueVideo!.isNotEmpty))
              _buildIssueMediaCard(context, textTheme, colorScheme),
            const SizedBox(height: 16),

            // Add this after _buildIssueMediaCard and before _buildBookingTimelineCard
            if (booking.bookingStatusCode.toLowerCase() == 'c' &&
                booking.paymentCompleted &&
                booking.completionData != null) ...[
              _buildCompletionDataCard(context, textTheme, colorScheme),
              const SizedBox(height: 16),
            ],

            _buildBookingTimelineCard(context, textTheme, colorScheme),
          ],
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
              value: booking.id,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),

            // Service Name
            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.serviceName,
              value: locale == 'en'
                  ? (booking.service.name ?? '')
                  : (booking.service.name_ar ?? ''),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // Service Description
            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.serviceDescription,
              value: locale == 'en'
                  ? (booking.service.description ?? '')
                  : (booking.service.description_ar ?? ''),
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
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isDescription ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
              height: isDescription ? 1.4 : 1.2,
            ),
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
              '${booking.service.price} ${AppLocalizations.of(context)!.sar}',
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
    final addresses = booking.customer.addresses;
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
              value:
                  //  selectedAddress != null
                  // ? (selectedAddress.fullName)
                  // :
                  (booking.customer.name ?? 'N/A'),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildCustomerInfoRowWithButton(
              icon: Icons.call_rounded,
              label: AppLocalizations.of(context)!.phoneNumber,
              value: selectedAddress != null
                  ? (selectedAddress.phoneNumber)
                  : (booking.customer.phone ?? 'N/A'),
              buttonIcon: Icons.call,
              buttonLabel: AppLocalizations.of(context)!.call,
              onButtonPressed: () => launchUrlString(
                'tel:${selectedAddress?.phoneNumber ?? booking.customer.phone}',
              ),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildCustomerInfoRowWithButton(
              icon: Icons.location_on,
              label: AppLocalizations.of(context)!.address,
              value: selectedAddress != null
                  ? '${selectedAddress.buildingNumber}\n${selectedAddress.streetName}'
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
            if (booking.issueImage != null && booking.issueImage!.isNotEmpty)
              const SizedBox(height: 20),

            // Images Section
            if (booking.issueImage != null && booking.issueImage!.isNotEmpty)
              Text(
                AppLocalizations.of(context)!.image,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            const SizedBox(height: 8),
            if (booking.issueImage != null && booking.issueImage!.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullScreenImage(booking.issueImage!, context),
                child: Container(
                  height: MediaQuery.of(context).size.width * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: booking.issueImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(child: Loader(size: 12)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.failedToLoadImage,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (booking.issueVideo != null && booking.issueVideo!.isNotEmpty)
              const SizedBox(height: 16),

            if (booking.issueVideo != null && booking.issueVideo!.isNotEmpty)
              Text(
                AppLocalizations.of(context)!.video,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            if (booking.issueVideo != null && booking.issueVideo!.isNotEmpty)
              const SizedBox(height: 8),
            if (booking.issueVideo != null && booking.issueVideo!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: CachedVideoPlayer(videoUrl: booking.issueVideo!),
              ),
          ],
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
  ) {
    // We store raw DateTime for sorting later
    List<Map<String, dynamic>> timelineItems = [];

    // Created
    if (booking.createdAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.createdAt,
        'time': _formatDateLocalized(booking.createdAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.customerSubmittedBookingRequest,
        'status': 'completed',
        'date': booking.createdAt!.toDate(),
      });
    }

    // Accepted
    if (booking.acceptedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.acceptedAt,
        'time': _formatDateLocalized(booking.acceptedAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.serviceProviderConfirmedAppointment,
        'status': 'completed',
        'date': booking.acceptedAt!.toDate(),
      });
    }

    // Tracking started
    if (booking.trackingStartedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.trackingStartedAt,
        'time': _formatDateLocalized(
          booking.trackingStartedAt!.toDate(),
          context,
        ),
        'description': AppLocalizations.of(context)!.serviceTrackingInitiated,
        'status': 'completed',
        'date': booking.trackingStartedAt!.toDate(),
      });
    }

    // Completed
    if (booking.completedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.completedAt,
        'time': _formatDateLocalized(booking.completedAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.serviceHasBeenSuccessfullyCompleted,
        'status': 'completed',
        'date': booking.completedAt!.toDate(),
      });
    }
    if (booking.bookingStatusCode.toLowerCase() == 'r') {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.rejectedAt,
        'time': _formatDateLocalized(booking.rejectedAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.bookingWasRejectedByServiceProvider,
        'status': 'rejected',
        'date': booking.rejectedAt!.toDate(),
      });
    }
    if (booking.bookingStatusCode.toLowerCase() == 'xc') {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.cancelledByCustomer,
        'time': _formatDateLocalized(booking.cancelledAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.bookingWasCancelledByCustomer,
        'status': 'rejected',
        'date': booking.cancelledAt!.toDate(),
      });
    }

    // Worker cancellations
    if (booking.cancelledWorkers.isNotEmpty) {
      for (var worker in booking.cancelledWorkers) {
        final workerName = worker.agentName.isNotEmpty
            ? worker.agentName
            : AppLocalizations.of(context)!.unknownWorker;

        timelineItems.add({
          'title': AppLocalizations.of(context)!.workerCancelled,
          'time': _formatDateLocalized(worker.cancelledAt.toDate(), context),
          'description':
              '${AppLocalizations.of(context)!.cancelledByWorker}: $workerName',
          'status': 'cancelled',
          'date': worker.cancelledAt.toDate(),
        });
      }
    }

    // Admin cancellation

    // If no completion/rejection/cancellation, add current status
    if (booking.completedAt == null &&
        booking.rejectedAt == null &&
        booking.bookingStatusCode.toLowerCase() != 'xc' &&
        booking.bookingStatusCode.toLowerCase() != 'xx') {
      if (booking.trackingStartedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.serviceInProgress,
          'time': AppLocalizations.of(context)!.current,
          'description': AppLocalizations.of(
            context,
          )!.serviceIsCurrentlyBeingPerformed,
          'status': 'current',
          'date': DateTime.now(),
        });
      } else if (booking.acceptedAt != null) {
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

    // Sort events by actual date
    timelineItems.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

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

            // Render timeline
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
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
                placeholder: (context, url) =>
                    Center(child: Loader(size: 14, color: Colors.white)),
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
    if (booking.completionData == null) {
      return const SizedBox.shrink();
    }

    final completionData = booking.completionData!;

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
            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.transactionId,
              value: booking.orderId ?? "",
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 16),
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

            if (completionData.serviceCost <= 0) ...[
              const SizedBox(height: 12),
              _buildCostRow(
                context,
                label: AppLocalizations.of(context)!.inspectionFee,
                amount: completionData.totalCost,
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
                    AppLocalizations.of(context)!.amountPaid,
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
            if (booking.bookingStatusCode.toLowerCase() == 'c' &&
                booking.paymentCompleted) ...{
              _buildInfoRow(
                context,
                label: AppLocalizations.of(context)!.paymentMode,
                value: booking.paymentModeCode.toLowerCase() == 'c'
                    ? AppLocalizations.of(context)!.card
                    : booking.paymentModeCode.toLowerCase() == 'a'
                    ? AppLocalizations.of(context)!.applePay
                    : AppLocalizations.of(context)!.cashOnHands,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            },
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
}
