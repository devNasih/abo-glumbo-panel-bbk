import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/account/notifications.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/bloc/admin_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/sheets/assign_worker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  List<LocationModel> locations = [];

  showAssignToUserBottomSheet(BookingModel booking) {
    // Store references to avoid context issues
    final adminBloc = context.read<AdminBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AssignWorker(
          booking: booking,
          locations: locations,
          onAssignAgent: (user) {
            Navigator.pop(context); // Close the bottom sheet first
            // Use the stored bloc reference
            adminBloc.add(AssignAgentEvent(booking: booking, user: user));
          },
          onRejectOrder: (booking) async {
            Navigator.pop(context); // Close the bottom sheet first

            bool? isConfirmed = await showDialog(
              context: this.context, // Use widget's context
              builder: (dialogContext) {
                return AlertDialog(
                  title: Text(
                    AppLocalizations.of(dialogContext)?.rejectOrder ??
                        "Reject Order",
                  ),
                  content: Text(
                    AppLocalizations.of(
                          dialogContext,
                        )?.areYouSureYouWantToRejectThisOrder ??
                        "Are you sure you want to reject this order?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: Text(
                        AppLocalizations.of(dialogContext)?.cancel ?? "Cancel",
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      child: Text(
                        AppLocalizations.of(dialogContext)?.reject ?? "Reject",
                      ),
                    ),
                  ],
                );
              },
            );

            if (isConfirmed == true) {
              adminBloc.add(RejectOrderEvent(booking: booking));
            }
          },
        );
      },
    );
  }

  @override
  void initState() {
    context.read<AccountBloc>().add(LoadDistrictsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state is LoadDistrictsSuccess) {
              setState(() {
                locations = state.districts;
              });
            }
          },
        ),
        BlocListener<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is AssigningAgent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.assigningBookingTo ??
                        'Assigning booking...',
                  ),
                ),
              );
            } else if (state is AgentAssigned) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking assigned successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AgentAssignmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to assign booking: ${state.error}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: AppLocalizations.of(context)?.retry ?? "Retry",
                    onPressed: () {
                      // You can implement retry logic here if needed
                    },
                  ),
                ),
              );
            } else if (state is RejectingOrder) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.rejectingOrder ??
                        'Rejecting order...',
                  ),
                ),
              );
            } else if (state is OrderRejected) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order rejected successfully!'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (state is OrderRejectionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.failedToRejectOrder ??
                        'Failed to reject order: ${state.error}',
                  ),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: AppLocalizations.of(context)?.retry ?? "Retry",
                    onPressed: () {
                      // You can implement retry logic here if needed
                    },
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, accountState) {
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
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
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
                                    : const Icon(
                                        Icons.circle_outlined,
                                        size: 20,
                                      ),
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            return BookingCards(
                              booking: booking,
                              isAdmin: true,
                              onAssign: () {
                                showAssignToUserBottomSheet(booking);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
