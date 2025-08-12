import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/account/notifications.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/bloc/admin_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
    final adminBloc = context.read<AdminBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _AssignUserBottomSheet(
          booking: booking,
          locations: locations,
          onAssignAgent:
              ({required BookingModel booking, required UserModel user}) {
                adminBloc.add(AssignAgentEvent(booking: booking, user: user));
              },
          onRejectOrder: (BookingModel booking) {
            adminBloc.add(RejectOrderEvent(booking: booking));
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
            if (state is AgentAssigned) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.assignedAgent != null
                        ? '${AppLocalizations.of(context)?.bookingAssignedTo ?? "Booking assigned to"} ${state.assignedAgent!.name ?? AppLocalizations.of(context)?.agent ?? "Agent"}!'
                        : AppLocalizations.of(
                                context,
                              )?.bookingAssignmentSuccessful ??
                              'Booking assigned successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AgentAssignmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppLocalizations.of(context)?.failedToAssignBookingTo ?? "Failed to assign booking"}: ${state.error}',
                  ),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: AppLocalizations.of(context)?.retry ?? "Retry",
                    onPressed: () {},
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
                  content: Text(
                    AppLocalizations.of(context)?.orderRejected ??
                        'Order rejected successfully!',
                  ),
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
                    onPressed: () {},
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

class _AssignUserBottomSheet extends StatefulWidget {
  final BookingModel booking;
  final List<LocationModel> locations;
  final Function({required BookingModel booking, required UserModel user})
  onAssignAgent;
  final Function(BookingModel booking) onRejectOrder;

  const _AssignUserBottomSheet({
    required this.booking,
    required this.locations,
    required this.onAssignAgent,
    required this.onRejectOrder,
  });

  @override
  State<_AssignUserBottomSheet> createState() => _AssignUserBottomSheetState();
}

class _AssignUserBottomSheetState extends State<_AssignUserBottomSheet> {
  // Active booking statuses that indicate the worker is actually busy (excludes cancelled 'X')
  // This ensures cancelled bookings don't block new assignments to the same worker
  static const List<String> _activeBookingStatuses = [
    'P',
    'A',
  ]; // Pending, Accepted (not Cancelled 'X')
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeKeyFormat = DateFormat('HH:mm_yyyy-MM-dd');

  String? selectedLocationId;
  CategoryModel? categoryModel;

  final Set<String> _assigningUsers = <String>{};
  bool _isAssigning = false;

  static bool _globalAssignmentLock = false;

  static final Map<String, Set<String>> _recentAssignments = {};

  Stream<List<UserModel>>? _cachedUsersStream;
  String? _lastLocationId;
  String? _lastCategoryId;

  final TextEditingController _locationSearchController =
      TextEditingController();
  List<LocationModel> _filteredLocations = [];
  bool _showLocationDropdown = false;

  // Cache for conflict data to avoid repeated database calls
  final Map<String, Map<String, dynamic>> _conflictCache = {};
  bool _conflictsLoaded = false;
  DateTime? _cacheTimestamp;

  @override
  void initState() {
    super.initState();

    // Clear any stale cache data from previous sessions
    _conflictCache.clear();
    _conflictsLoaded = false;
    _cacheTimestamp = null;

    // Clean up old assignments from memory
    _cleanupOldAssignments();

    _loadCategory();
    _initializeUsersStream();
    _filteredLocations = widget.locations;
  }

  @override
  void dispose() {
    _locationSearchController.dispose();

    _cleanupOldAssignments();

    super.dispose();
  }

  void _cleanupOldAssignments() {
    final now = DateTime.now();
    // Reduce cutoff time to 1 hour for more aggressive cleanup
    final cutoffTime = now.subtract(const Duration(hours: 1));

    _recentAssignments.removeWhere((userId, timeSet) {
      timeSet.removeWhere((timeKey) {
        try {
          final parts = timeKey.split('_');
          if (parts.length == 2) {
            final timePart = parts[0];
            final datePart = parts[1];

            final timeComponents = timePart.split(':');
            final dateComponents = datePart.split('-');

            if (timeComponents.length == 2 && dateComponents.length == 3) {
              final bookingTime = DateTime(
                int.parse(dateComponents[0]),
                int.parse(dateComponents[1]),
                int.parse(dateComponents[2]),
                int.parse(timeComponents[0]),
                int.parse(timeComponents[1]),
              );

              return bookingTime.isBefore(cutoffTime);
            }
          }
        } catch (e) {
          // Error parsing time key during cleanup - remove invalid entries
          return true;
        }
        return false;
      });

      return timeSet.isEmpty;
    });

    // Reset global assignment lock if it's stuck
    if (_globalAssignmentLock) {
      _globalAssignmentLock = false;
    }
  }

  void _initializeUsersStream() {
    _cachedUsersStream = _createUsersStream();
    _lastLocationId = selectedLocationId;
    _lastCategoryId = widget.booking.service.category;
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
            return;
          }
        }
      } catch (e) {
        // Category not found
      }
    }
  }

  Future<void> _preloadConflictData(List<UserModel> users) async {
    // Check if cache is stale (older than 2 minutes)
    final now = DateTime.now();
    final cacheStale =
        _cacheTimestamp == null ||
        now.difference(_cacheTimestamp!).inMinutes > 2;

    if (_conflictsLoaded && !cacheStale) return;

    // Clear cache if it's stale
    if (cacheStale) {
      _conflictCache.clear();
      _conflictsLoaded = false;
    }

    try {
      final bookingScheduledTime = widget.booking.bookingDateTime.toDate();

      // Get current booking's cancelled workers in one call
      final currentBookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
          .get();

      List<String> cancelledWorkerUids = [];
      Map<String, Map<String, dynamic>> cancelledWorkersDetails = {};

      if (currentBookingDoc.exists) {
        final data = currentBookingDoc.data() as Map<String, dynamic>;
        final cancelledUids = data['cancelledWorkerUids'] as List?;
        final cancelledWorkers = data['cancelledWorkers'] as List?;

        if (cancelledUids != null) {
          cancelledWorkerUids = cancelledUids.cast<String>();
        }

        if (cancelledWorkers != null) {
          for (final worker in cancelledWorkers) {
            final uid = worker['uid'] as String?;
            if (uid != null) {
              cancelledWorkersDetails[uid] = {
                'agentName': worker['agentName'] as String?,
                'cancelledAt': worker['cancelledAt'] as Timestamp?,
              };
            }
          }
        }
      }

      // Get all active bookings for all users in one query
      final userIds = users
          .map((u) => u.uid)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (userIds.isNotEmpty) {
        final existingBookings = await AppFirestore.bookingsCollectionRef
            .where('assignedTo', whereIn: userIds)
            .where('bookingStatusCode', whereIn: _activeBookingStatuses)
            .get(); // Process conflicts for each user
        for (final user in users) {
          final userId = user.uid;
          if (userId == null) continue;

          Map<String, dynamic> conflictResult = {'hasConflict': false};

          // Check for active booking conflicts
          for (final doc in existingBookings.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final assignedTo = data['assignedTo'] as String?;
            final existingBookingTime = data['bookingDateTime'] as Timestamp?;
            final existingBookingId = doc.id;

            if (assignedTo != userId ||
                existingBookingId == widget.booking.id) {
              continue;
            }

            if (existingBookingTime != null) {
              final existingScheduledDateTime = existingBookingTime.toDate();

              if (_isTimeConflict(
                existingScheduledDateTime,
                bookingScheduledTime,
              )) {
                conflictResult = {
                  'hasConflict': true,
                  'conflictType': 'active_booking',
                  'conflictTime': _timeFormat.format(existingScheduledDateTime),
                  'conflictDate': _dateFormat.format(existingScheduledDateTime),
                  'bookingId': existingBookingId,
                };
                break;
              }
            }
          }

          // Check if worker cancelled this specific booking
          if (!conflictResult['hasConflict'] &&
              cancelledWorkerUids.contains(userId)) {
            final workerDetails = cancelledWorkersDetails[userId];
            final cancellationTime = workerDetails?['cancelledAt'] != null
                ? (workerDetails!['cancelledAt'] as Timestamp).toDate()
                : bookingScheduledTime;

            conflictResult = {
              'hasConflict': true,
              'conflictType': 'worker_cancelled_this_booking',
              'conflictTime': _timeFormat.format(cancellationTime),
              'conflictDate': _dateFormat.format(cancellationTime),
              'bookingId': widget.booking.id,
              'workerName':
                  workerDetails?['agentName'] ??
                  AppLocalizations.of(context)?.unknownWorker ??
                  'Unknown Worker',
            };
          }

          // Check local session conflicts
          if (!conflictResult['hasConflict']) {
            final timeKey = _timeKeyFormat.format(bookingScheduledTime);
            final userRecentAssignments = _recentAssignments[userId] ?? {};

            if (userRecentAssignments.contains(timeKey)) {
              conflictResult = {
                'hasConflict': true,
                'conflictType': 'local_session',
                'conflictTime': _timeFormat.format(bookingScheduledTime),
                'conflictDate': _dateFormat.format(bookingScheduledTime),
                'bookingId': 'local_session_conflict',
              };
            }
          }

          _conflictCache[userId] = conflictResult;
        }
      }

      _conflictsLoaded = true;
      _cacheTimestamp = DateTime.now();
    } catch (e) {
      // Handle error silently
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
      widget.onRejectOrder(widget.booking);
      Navigator.pop(context);
    }
  }

  Future<Map<String, dynamic>> _checkTimeConflicts(String userId) async {
    try {
      final bookingScheduledTime = widget.booking.bookingDateTime.toDate();

      // Check for active bookings (Pending and Accepted, not Cancelled)
      final existingBookings = await AppFirestore.bookingsCollectionRef
          .where('assignedTo', isEqualTo: userId)
          .where('bookingStatusCode', whereIn: _activeBookingStatuses)
          .get();

      for (final doc in existingBookings.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingBookingTime = data['bookingDateTime'] as Timestamp?;
        final existingBookingId = doc.id;

        if (existingBookingId == widget.booking.id) {
          continue;
        }

        if (existingBookingTime != null) {
          final existingScheduledDateTime = existingBookingTime.toDate();

          if (_isTimeConflict(
            existingScheduledDateTime,
            bookingScheduledTime,
          )) {
            return {
              'hasConflict': true,
              'conflictType': 'active_booking',
              'conflictTime': _timeFormat.format(existingScheduledDateTime),
              'conflictDate': _dateFormat.format(existingScheduledDateTime),
              'bookingId': existingBookingId,
            };
          }
        }
      }

      // Check if worker has cancelled THIS specific booking
      final currentBookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
          .get();

      if (currentBookingDoc.exists) {
        final data = currentBookingDoc.data() as Map<String, dynamic>;
        final cancelledWorkerUids = data['cancelledWorkerUids'] as List?;

        // If this worker has cancelled this specific booking, mark them
        if (cancelledWorkerUids != null &&
            cancelledWorkerUids.contains(userId)) {
          // Find the worker's cancellation details from this booking
          final cancelledWorkers = data['cancelledWorkers'] as List?;
          String? workerName;
          DateTime? cancellationTime;

          if (cancelledWorkers != null) {
            for (final worker in cancelledWorkers) {
              if (worker['uid'] == userId) {
                workerName = worker['agentName'] as String?;
                // If there's a cancellation timestamp, use it; otherwise use booking time
                if (worker['cancelledAt'] != null) {
                  cancellationTime = (worker['cancelledAt'] as Timestamp)
                      .toDate();
                } else {
                  cancellationTime = (data['bookingDateTime'] as Timestamp)
                      .toDate();
                }
                break;
              }
            }
          }

          // Use cancellation time or booking time for display
          final displayTime = cancellationTime ?? bookingScheduledTime;

          return {
            'hasConflict': true,
            'conflictType': 'worker_cancelled_this_booking',
            'conflictTime': _timeFormat.format(displayTime),
            'conflictDate': _dateFormat.format(displayTime),
            'bookingId': widget.booking.id,
            'workerName':
                workerName ??
                AppLocalizations.of(context)?.unknownWorker ??
                'Unknown Worker',
          };
        }
      }

      final timeKey = _timeKeyFormat.format(bookingScheduledTime);
      final userRecentAssignments = _recentAssignments[userId] ?? {};

      if (userRecentAssignments.contains(timeKey)) {
        return {
          'hasConflict': true,
          'conflictType': 'local_session',
          'conflictTime': _timeFormat.format(bookingScheduledTime),
          'conflictDate': _dateFormat.format(bookingScheduledTime),
          'bookingId': 'local_session_conflict',
        };
      }

      return {'hasConflict': false};
    } catch (e) {
      return {'hasConflict': false};
    }
  }

  bool _isTimeConflict(DateTime existingBookingTime, DateTime newBookingTime) {
    if (existingBookingTime.year == newBookingTime.year &&
        existingBookingTime.month == newBookingTime.month &&
        existingBookingTime.day == newBookingTime.day) {
      if (existingBookingTime.hour == newBookingTime.hour &&
          existingBookingTime.minute == newBookingTime.minute) {
        return true;
      }
    }

    return false;
  }

  Future<void> _handleAssignAgent(UserModel user) async {
    final userId = user.uid;
    if (userId == null) return;

    if (_globalAssignmentLock) {
      _showSnackBar(
        AppLocalizations.of(context)?.anotherAssignmentInProgress ??
            'Another assignment is in progress. Please wait...',
      );
      return;
    }

    if (_isAssigning || _assigningUsers.contains(userId)) {
      _showSnackBar(
        AppLocalizations.of(context)?.assignmentInProgress ??
            'Assignment in progress. Please wait...',
      );
      return;
    }

    _globalAssignmentLock = true;

    setState(() {
      _isAssigning = true;
      _assigningUsers.add(userId);
    });

    try {
      _showSnackBar(
        AppLocalizations.of(context)?.checkingAvailabilityAndAssigning ??
            'Checking availability and assigning...',
      );

      // Use cached conflict data if available, otherwise check in real-time
      Map<String, dynamic> conflictResult;
      if (_conflictCache.containsKey(userId)) {
        conflictResult = _conflictCache[userId]!;
      } else {
        conflictResult = await _checkTimeConflicts(userId);
      }

      if (conflictResult['hasConflict'] == true) {
        final conflictType = conflictResult['conflictType'] as String;
        final conflictTime = conflictResult['conflictTime'] as String;
        final conflictDate = conflictResult['conflictDate'] as String;

        if (conflictType == 'worker_cancelled_this_booking') {
          final workerName = conflictResult['workerName'] as String;
          _showWorkerCancelledThisBookingDialog(
            user.name ?? AppLocalizations.of(context)?.agent ?? 'Agent',
            conflictTime,
            conflictDate,
            workerName,
          );
        } else if (conflictType == 'worker_cancelled') {
          final workerName = conflictResult['workerName'] as String;
          _showWorkerCancelledRestrictedDialog(
            user.name ?? AppLocalizations.of(context)?.agent ?? 'Agent',
            conflictTime,
            conflictDate,
            workerName,
          );
        } else {
          _showTimeConflictDialog(
            user.name ?? AppLocalizations.of(context)?.agent ?? 'Agent',
            conflictTime,
            conflictDate,
          );
        }
        return;
      }

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

      // Track this assignment to prevent duplicate assignments
      final bookingScheduledTime = widget.booking.bookingDateTime.toDate();
      final timeKey = _timeKeyFormat.format(bookingScheduledTime);

      if (_recentAssignments[userId] == null) {
        _recentAssignments[userId] = <String>{};
      }
      _recentAssignments[userId]!.add(timeKey);

      // Assign the agent
      widget.onAssignAgent(booking: widget.booking, user: user);

      // Clear cache since assignment state has changed
      _conflictCache.clear();
      _conflictsLoaded = false;
      _cacheTimestamp = null;

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(
        AppLocalizations.of(context)?.failedToAssignAgent ??
            'Failed to assign agent. Please try again.',
      );
    } finally {
      _globalAssignmentLock = false;

      if (mounted) {
        setState(() {
          _isAssigning = false;
          _assigningUsers.remove(userId);
        });
      }
    }
  }

  Future<void> _showTimeConflictDialog(
    String agentName,
    String conflictTime,
    String conflictDate,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.access_time_filled_rounded,
                          size: 32,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        AppLocalizations.of(context)?.timeConflictDetected ??
                            'Time Conflict!',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)?.agentUnavailable ??
                            'Agent is not available',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)?.agent ??
                                        'Agent',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    agentName,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade50,
                              Colors.red.shade100.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                        context,
                                      )?.alreadyBookedAt ??
                                      'Already booked at',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    conflictTime,
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    conflictDate,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blue.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.workerCannotBeAssignedMultipleTimes ??
                                    'This agent is already booked for another job at this time. Please choose a different agent or reschedule the booking.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.blue.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: colorScheme.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)?.gotIt ?? 'Got it',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWorkerCancelledThisBookingDialog(
    String agentName,
    String conflictTime,
    String conflictDate,
    String workerName,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_off_rounded,
                          size: 32,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        AppLocalizations.of(
                              context,
                            )?.workerPreviouslyCancelled ??
                            'Worker Previously Cancelled',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.thisAgentCancelledSameBookingBefore ??
                            'This agent cancelled this same booking before',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.person_off_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.previouslyCancelledAgent ??
                                        'Previously Cancelled Agent',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    agentName,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade50,
                              Colors.orange.shade100.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.orange.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                        context,
                                      )?.cancelledThisBookingOn ??
                                      'Cancelled this booking on',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    conflictTime,
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    conflictDate,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.agentPreviouslyCancelledWarning ??
                                    'This agent previously cancelled this same booking request. You can still assign them, but consider choosing a more reliable agent.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.swap_horiz_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        AppLocalizations.of(context)?.chooseDifferentAgent ??
                            'Choose Different Agent',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWorkerCancelledRestrictedDialog(
    String agentName,
    String conflictTime,
    String conflictDate,
    String workerName,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          size: 32,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        AppLocalizations.of(context)?.workerRestrictedTitle ??
                            'Worker Restricted',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.cannotAssignCancelledWorker ??
                            'Cannot assign cancelled worker',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.person_off_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Restricted Agent',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    agentName,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade50,
                              Colors.red.shade100.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                        context,
                                      )?.lastCancellationOn ??
                                      'Last cancellation on',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    conflictTime,
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    conflictDate,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: Colors.red.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.workerCancelledRestrictionMessage ??
                                    'This agent has previously cancelled a booking and is now restricted from new assignments. Please choose a different agent.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: colorScheme.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)?.understood ??
                                'Understood',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      return getCategoryWiseWorkersStream(
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

  Stream<List<UserModel>> getFilteredUsersStream() {
    if (_cachedUsersStream == null ||
        _lastLocationId != selectedLocationId ||
        _lastCategoryId != widget.booking.service.category) {
      _cachedUsersStream = _createUsersStream();
      _lastLocationId = selectedLocationId;
      _lastCategoryId = widget.booking.service.category;

      // Reset conflict cache when users stream changes
      _conflictCache.clear();
      _conflictsLoaded = false;
      _cacheTimestamp = null;
    }

    return _cachedUsersStream!;
  }

  List<UserModel> _filterByLocation(List<UserModel> users) {
    final validLocationId = validatedSelectedLocationId;
    if (validLocationId == null) return users;

    final selectedLocation = widget.locations.firstWhere(
      (loc) => getLocationKey(loc) == validLocationId,
      orElse: () => LocationModel(id: '', name: '', name_ar: ''),
    );

    String locationName = AppLocalizations.of(context)?.localeName == 'en'
        ? selectedLocation.name?.trim() ?? ''
        : selectedLocation.name_ar?.trim() ?? '';

    return users.where((user) => user.districtName == locationName).toList();
  }

  static Stream<List<UserModel>> getCategoryWiseWorkersStream(
    String categoryId,
  ) async* {
    try {
      final docSnapshot = await AppFirestore.categoriesCollectionRef
          .doc(categoryId)
          .get();

      if (!docSnapshot.exists) {
        yield [];
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>?;
      String categoryName = data?['name'] ?? '';

      if (categoryName.isEmpty) {
        yield [];
        return;
      }

      Query query = AppFirestore.usersCollectionRef
          .where('isVerified', isEqualTo: true)
          .where('isAdmin', isNotEqualTo: true)
          .where('jobRoles', arrayContains: categoryName);

      yield* query.snapshots().map((snapshot) {
        return snapshot.docs
            .map(
              (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
            )
            .toList();
      });
    } catch (e) {
      yield [];
    }
  }

  void onLocationChanged(String? newLocationId) {
    if (selectedLocationId != newLocationId) {
      setState(() {
        selectedLocationId = newLocationId;
        // Reset conflict cache when location changes
        _conflictCache.clear();
        _conflictsLoaded = false;
        _cacheTimestamp = null;
      });
    }
  }

  String getLocationKey(LocationModel location) {
    if (location.id != null && location.id!.isNotEmpty) {
      return location.id!;
    }

    return location.name ?? location.name_ar ?? 'unknown_${location.hashCode}';
  }

  String? get validatedSelectedLocationId {
    if (selectedLocationId == null) return null;

    final locationExists = widget.locations.any(
      (loc) => getLocationKey(loc) == selectedLocationId,
    );
    return locationExists ? selectedLocationId : null;
  }

  void clearFilter() {
    if (selectedLocationId != null) {
      setState(() {
        selectedLocationId = null;
        // Reset conflict cache when clearing filter
        _conflictCache.clear();
        _conflictsLoaded = false;
        _cacheTimestamp = null;
      });
    }
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = widget.locations;
      } else {
        _filteredLocations = widget.locations.where((location) {
          final name = location.name?.toLowerCase() ?? '';
          final nameAr = location.name_ar?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || nameAr.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _selectLocationFromSearch(LocationModel location) {
    setState(() {
      selectedLocationId = getLocationKey(location);
      _locationSearchController.text =
          AppLocalizations.of(context)?.localeName == 'en'
          ? location.name ?? ''
          : location.name_ar ?? '';
      _showLocationDropdown = false;
      // Reset conflict cache when selecting new location
      _conflictCache.clear();
      _conflictsLoaded = false;
      _cacheTimestamp = null;
    });
  }

  void _clearLocationSearch() {
    setState(() {
      _locationSearchController.clear();
      selectedLocationId = null;
      _filteredLocations = widget.locations;
      _showLocationDropdown = false;
      // Reset conflict cache when clearing location search
      _conflictCache.clear();
      _conflictsLoaded = false;
      _cacheTimestamp = null;
    });
  }

  Widget _buildLocationDisplay() {
    if (validatedSelectedLocationId == null) return const SizedBox.shrink();

    final selectedLocation = widget.locations.firstWhere(
      (loc) => getLocationKey(loc) == validatedSelectedLocationId,
      orElse: () =>
          LocationModel(id: '', name: 'Unknown', name_ar: 'غير معروف'),
    );

    final locationName = AppLocalizations.of(context)?.localeName == 'en'
        ? selectedLocation.name ?? 'Unknown'
        : selectedLocation.name_ar ?? 'غير معروف';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
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
            Text(
              "${AppLocalizations.of(context)!.filterByLocation}: $locationName",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(List<UserModel> users, TextTheme textTheme) {
    final categoryName = categoryModel?.name;
    final categoryNameAr = categoryModel?.name_ar;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_rounded, size: 48),
          const SizedBox(height: 16),
          Text(
            validatedSelectedLocationId != null
                ? "${AppLocalizations.of(context)!.no} ${categoryName != null ? (AppLocalizations.of(context)?.localeName == 'en' ? categoryName : categoryNameAr) : AppLocalizations.of(context)?.agents ?? 'agents'} ${AppLocalizations.of(context)?.availableInSelectedLocation ?? 'available in selected location'}"
                : categoryName != null
                ? "${AppLocalizations.of(context)!.no} ${AppLocalizations.of(context)?.localeName == 'en' ? categoryName : categoryNameAr} ${AppLocalizations.of(context)!.agentsAvailable}"
                : AppLocalizations.of(context)!.noAgentsAvailable,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (validatedSelectedLocationId != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: clearFilter,
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

  Widget _buildUserTile(
    UserModel user,
    TextTheme textTheme, {
    bool isLoadingConflicts = false,
  }) {
    final userId = user.uid ?? '';
    final isAssigningThisUser = _assigningUsers.contains(userId);

    final isDisabled =
        _isAssigning || isAssigningThisUser || _globalAssignmentLock;

    // Get conflict data from cache, but if still loading, show as no conflict
    final conflictData = isLoadingConflicts
        ? {'hasConflict': false}
        : (_conflictCache[userId] ?? {'hasConflict': false});
    final hasConflict = conflictData['hasConflict'] == true;
    final conflictTime = conflictData['conflictTime'] as String?;
    final conflictType = conflictData['conflictType'] as String?;

    final isTileDisabled = isDisabled || hasConflict;

    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.name ?? '',
              style: TextStyle(
                color: isTileDisabled ? Colors.grey.shade600 : null,
              ),
            ),
          ),
          if (hasConflict && conflictTime != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: conflictType == 'worker_cancelled_this_booking'
                    ? Colors.orange.withOpacity(0.2)
                    : conflictType == 'worker_cancelled'
                    ? Colors.red.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: conflictType == 'worker_cancelled_this_booking'
                      ? Colors.orange.withOpacity(0.6)
                      : conflictType == 'worker_cancelled'
                      ? Colors.red.withOpacity(0.6)
                      : Colors.red.withOpacity(0.6),
                ),
              ),
              child: Text(
                conflictType == 'worker_cancelled_this_booking'
                    ? AppLocalizations.of(context)?.cancelledThisBooking ??
                          'Cancelled This Booking'
                    : conflictType == 'worker_cancelled'
                    ? AppLocalizations.of(context)?.workerCancelled ??
                          'Cancelled Worker'
                    : '${AppLocalizations.of(context)?.busyAt ?? 'Busy at'} $conflictTime',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: conflictType == 'worker_cancelled_this_booking'
                      ? Colors.orange.shade700
                      : conflictType == 'worker_cancelled'
                      ? Colors.red.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: RichText(
        text: TextSpan(
          style: textTheme.labelMedium?.copyWith(
            color: isTileDisabled ? Colors.grey.shade500 : null,
          ),
          children: [
            if (user.districtName != null) ...[
              WidgetSpan(
                child: Icon(
                  Icons.location_city,
                  size: 15,
                  color: isTileDisabled ? Colors.grey.shade500 : null,
                ),
              ),
              TextSpan(text: " ${user.districtName ?? ''} "),
            ],
            if (user.jobRoles != null) ...[
              WidgetSpan(
                child: Icon(
                  Icons.work_rounded,
                  size: 15,
                  color: isTileDisabled ? Colors.grey.shade500 : null,
                ),
              ),
              TextSpan(text: " ${user.jobRoles?.join(', ') ?? ''}"),
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
          : hasConflict
          ? Icon(
              conflictType == 'worker_cancelled_this_booking'
                  ? Icons.person_off_rounded
                  : conflictType == 'worker_cancelled'
                  ? Icons.block
                  : Icons.block,
              color: conflictType == 'worker_cancelled_this_booking'
                  ? Colors.orange
                  : conflictType == 'worker_cancelled'
                  ? Colors.red
                  : Colors.red,
              size: 22,
            )
          : isDisabled
          ? Icon(Icons.hourglass_empty, color: Colors.grey, size: 20)
          : null,

      enabled: !isTileDisabled,

      tileColor: hasConflict
          ? conflictType == 'worker_cancelled_this_booking'
                ? Colors.orange.withOpacity(0.05)
                : conflictType == 'worker_cancelled'
                ? Colors.red.withOpacity(0.05)
                : Colors.red.withOpacity(0.05)
          : isDisabled
          ? Colors.grey.withOpacity(0.05)
          : null,

      onTap: isTileDisabled
          ? null
          : () {
              if (isTileDisabled) {
                return;
              }
              _handleAssignAgent(user);
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    String? categoryName = categoryModel?.name;
    String? categoryNameAr = categoryModel?.name_ar;

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
                        ? "${AppLocalizations.of(context)!.assignTo} ${AppLocalizations.of(context)?.localeName == 'en' ? categoryName : categoryNameAr}"
                        : AppLocalizations.of(context)!.assignToUser,
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  color: Colors.red,
                  onPressed: _isAssigning
                      ? null
                      : _showRejectConfirmationDialog,
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
              children: [
                Text(
                  AppLocalizations.of(context)!.filterByLocation,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _locationSearchController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: InputBorder.none,
                                hintText: AppLocalizations.of(
                                  context,
                                )!.searchLocation,
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon:
                                    _locationSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: _clearLocationSearch,
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          _showLocationDropdown
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showLocationDropdown =
                                                !_showLocationDropdown;
                                          });
                                        },
                                      ),
                              ),
                              onChanged: (value) {
                                _filterLocations(value);
                                setState(() {
                                  _showLocationDropdown = value.isNotEmpty;
                                });
                              },
                              onTap: () {
                                setState(() {
                                  _showLocationDropdown = true;
                                });
                              },
                            ),
                            if (_showLocationDropdown)
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
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
                                    ..._filteredLocations.map((location) {
                                      final locationName =
                                          AppLocalizations.of(
                                                context,
                                              )?.localeName ==
                                              'en'
                                          ? location.name ?? 'Unknown Location'
                                          : location.name_ar ??
                                                'مكان غير معروف';
                                      final isSelected =
                                          getLocationKey(location) ==
                                          selectedLocationId;

                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          locationName,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : null,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? Icon(
                                                Icons.check_circle,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                size: 20,
                                              )
                                            : null,
                                        onTap: () =>
                                            _selectLocationFromSearch(location),
                                      );
                                    }),
                                    if (_filteredLocations.isEmpty &&
                                        _locationSearchController
                                            .text
                                            .isNotEmpty)
                                      ListTile(
                                        dense: true,
                                        title: Text(
                                          'No locations found',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: validatedSelectedLocationId != null
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed:
                            (validatedSelectedLocationId != null &&
                                !_isAssigning)
                            ? () {
                                clearFilter();
                                _clearLocationSearch();
                              }
                            : null,
                        icon: Icon(
                          Icons.clear_rounded,
                          color: validatedSelectedLocationId != null
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
                _buildLocationDisplay(),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),

          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: getFilteredUsersStream(),
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
                          '${AppLocalizations.of(context)?.error ?? "Error"}: ${snapshot.error}',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _cachedUsersStream = null;
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

                // Single loading state for both users and conflicts
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !_conflictsLoaded) {
                  // Preload conflict data when users are loaded but conflicts aren't
                  if (snapshot.hasData && !_conflictsLoaded) {
                    final users = snapshot.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _preloadConflictData(users).then((_) {
                        if (mounted) {
                          setState(
                            () {},
                          ); // Refresh UI after conflicts are loaded
                        }
                      });
                    });
                  }

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.1),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? (AppLocalizations.of(
                                            context,
                                          )?.loadingAgents ??
                                          'Loading agents...')
                                    : (AppLocalizations.of(
                                            context,
                                          )?.checkingAvailability ??
                                          'Checking agent availability...'),
                                style: textTheme.bodySmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return _buildEmptyState(users, textTheme);
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserTile(user, textTheme);
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
