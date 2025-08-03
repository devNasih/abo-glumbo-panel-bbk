import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/account/notifications.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class WorkerHome extends StatefulWidget {
  const WorkerHome({super.key});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> {
  final List<Map<String, String>> bookingStatus = [
    {'code': 'A', 'name': 'To Do'},
    {'code': 'C', 'name': 'Completed'},
  ];
  String selectedBookingStatus = 'A';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SizedBox(
                height: 52,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: bookingStatus.map((status) {
                      final code = status['code']!;
                      final name = status['name']!;
                      final isSelected = selectedBookingStatus == code;
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
                            LocalizationHelper().localizedBookingStatus(
                              name,
                              context: context,
                            ),
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

            Expanded(
              child: StreamBuilder<List<BookingModel>>(
                stream: AppServices.getBookingsStream(
                  bookingStatusCode: selectedBookingStatus,
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
                            Icons.hourglass_empty,
                            size: 100,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${AppLocalizations.of(context)?.no} ${selectedBookingStatus == 'A' ? AppLocalizations.of(context)?.pending : AppLocalizations.of(context)?.completed} ${AppLocalizations.of(context)?.orders}",
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
