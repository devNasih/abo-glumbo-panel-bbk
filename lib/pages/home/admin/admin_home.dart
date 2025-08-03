import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/account/notifications.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final List<Map<String, String>> bookingStatus = [
    {'code': 'P', 'name': 'Pending'},
    {'code': 'A', 'name': 'Accepted'},
    {'code': 'R', 'name': 'Rejected'},
    {'code': 'C', 'name': 'Completed'},
    {'code': 'X', 'name': 'Cancelled'},
  ];

  String selectedBookingStatus = 'P';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          AppLocalizations.of(context)?.manageOrders ?? "Manage Orders",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chips bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SizedBox(
                height: 52,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: bookingStatus.map((status) {
                      final code = status['code']!;
                      final isSelected = selectedBookingStatus == code;
                      final label = LocalizationHelper()
                          .getLocalizedBookingStatus(code, context);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 20,
                                )
                              : const Icon(Icons.circle_outlined, size: 20),
                          label: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          onPressed: () {
                            if (selectedBookingStatus != code) {
                              setState(() {
                                selectedBookingStatus = code;
                              });
                            }
                          },
                          backgroundColor: isSelected
                              ? colorScheme.primary.withOpacity(0.15)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Booking list
            Expanded(
              child: StreamBuilder(
                stream: AppServices.getBookingsStreamByStatus(
                  selectedBookingStatus,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: textTheme.bodyMedium,
                      ),
                    );
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hourglass_empty_rounded,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${AppLocalizations.of(context)?.no ?? 'No'} ${LocalizationHelper().getLocalizedBookingStatus(selectedBookingStatus, context)} ${AppLocalizations.of(context)?.bookings ?? 'bookings'}",
                            style: textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return BookingCards(booking: booking);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
