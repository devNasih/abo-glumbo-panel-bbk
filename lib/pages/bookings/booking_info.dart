import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_controllers.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            BookingControlsWidget(
              booking: booking,
              isTracking: false,
              isLoading: false,
              onCancelBooking: () {},
              onCompleteWork: () {},
              onStartTracking: () {},
              onStopTracking: () {},
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
          AppLocalizations.of(context)!.price,
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
              value: selectedAddress != null
                  ? (selectedAddress.fullName)
                  : (booking.customer.name ?? 'N/A'),
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
                AppLocalizations.of(context)!.images,
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
                        child: const Center(child: CircularProgressIndicator()),
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
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
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
    // Build timeline items based on actual booking data
    List<Map<String, String>> timelineItems = [];

    // Always show booking creation
    if (booking.createdAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.createdAt,
        'time': _formatDateLocalized(booking.createdAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.customerSubmittedBookingRequest,
        'status': 'completed',
      });
    }

    // Show acceptance if exists
    if (booking.acceptedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.acceptedAt,
        'time': _formatDateLocalized(booking.acceptedAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.serviceProviderConfirmedAppointment,
        'status': 'completed',
      });
    }

    // Show tracking started if exists
    if (booking.trackingStartedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.trackingStartedAt,
        'time': _formatDateLocalized(
          booking.trackingStartedAt!.toDate(),
          context,
        ),
        'description': AppLocalizations.of(context)!.serviceTrackingInitiated,
        'status': 'completed',
      });
    }

    // Show completion if exists
    if (booking.completedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.completedAt,
        'time': _formatDateLocalized(booking.completedAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.serviceHasBeenSuccessfullyCompleted,
        'status': 'completed',
      });
    }

    // Show rejection if exists
    if (booking.rejectedAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.rejectedAt,
        'time': _formatDateLocalized(booking.rejectedAt!.toDate(), context),
        'description': AppLocalizations.of(
          context,
        )!.bookingWasRejectedByServiceProvider,
        'status': 'rejected',
      });
    }

    // Show cancellation if exists
    if (booking.cancelledAt != null) {
      timelineItems.add({
        'title': AppLocalizations.of(context)!.cancelledAt,
        'time': _formatDateLocalized(booking.cancelledAt!.toDate(), context),
        'description': AppLocalizations.of(context)!.bookingWasCancelled,
        'status': 'cancelled',
      });
    }

    // If no completion/rejection/cancellation, show current status
    if (booking.completedAt == null &&
        booking.rejectedAt == null &&
        booking.cancelledAt == null) {
      if (booking.trackingStartedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.serviceInProgress,
          'time': AppLocalizations.of(context)!.current,
          'description': AppLocalizations.of(
            context,
          )!.serviceIsCurrentlyBeingPerformed,
          'status': 'current',
        });
      } else if (booking.acceptedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.waitingForServiceProvider,
          'time': AppLocalizations.of(context)!.pending,
          'description': AppLocalizations.of(
            context,
          )!.waitingForTechnicianToStartService,
          'status': 'current',
        });
      } else {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.waitingForAcceptance,
          'time': AppLocalizations.of(context)!.pending,
          'description': AppLocalizations.of(
            context,
          )!.waitingForServiceProviderResponse,
          'status': 'current',
        });
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
            // Header with icon
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

            // Timeline Items
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
            }).toList(),
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
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
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
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 100, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
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
}
