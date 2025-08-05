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
  String? selectedLocationId;
  CategoryModel? categoryModel;
  bool isLoadingCategory = true;

  @override
  void initState() {
    super.initState();
    _loadCategory();

    debugPrint('📍 Location data debug:');
    for (int i = 0; i < widget.locations.length; i++) {
      final loc = widget.locations[i];
      debugPrint(
        '  Location $i: id=${loc.id}, name=${loc.name}, name_ar=${loc.name_ar}',
      );
    }
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
              isLoadingCategory = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint(
          '❌ Category not found for ID: ${widget.booking.service.category}',
        );
      }
    }

    setState(() {
      isLoadingCategory = false;
    });
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

  Stream<List<UserModel>> getFilteredUsersStream() {
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

  List<UserModel> _filterByLocation(List<UserModel> users) {
    final validLocationId = validatedSelectedLocationId;
    if (validLocationId == null) return users;

    final selectedLocation = widget.locations.firstWhere(
      (loc) => getLocationKey(loc) == validLocationId,
      orElse: () => LocationModel(id: '', name: '', name_ar: ''),
    );

    String locationName = Directionality.of(context) == TextDirection.ltr
        ? selectedLocation.name?.trim() ?? ''
        : selectedLocation.name_ar?.trim() ?? '';

    return users.where((user) => user.districtName == locationName).toList();
  }

  static Stream<List<UserModel>> getCategoryWiseWorkersStream(
    String categoryId,
  ) async* {
    final docSnapshot = await AppFirestore.categoriesCollectionRef
        .doc(categoryId)
        .get();
    final data = docSnapshot.data() as Map<String, dynamic>?;
    String categoryName = data?['name'] ?? '';

    Query query = AppFirestore.usersCollectionRef
        .where('isVerified', isEqualTo: true)
        .where('isAdmin', isNotEqualTo: true)
        .where('jobRoles', arrayContains: categoryName);

    yield* query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  void onLocationChanged(String? newLocationId) {
    setState(() {
      selectedLocationId = newLocationId;
    });
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
    setState(() {
      selectedLocationId = null;
    });
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
                        ? "${AppLocalizations.of(context)!.assignTo} ${Directionality.of(context) == TextDirection.ltr ? categoryName : categoryNameAr}"
                        : AppLocalizations.of(context)!.assignToUser,
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  color: Colors.red,
                  onPressed: _showRejectConfirmationDialog,
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
                        child: DropdownButtonFormField<String>(
                          value: validatedSelectedLocationId,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                            hintText: AppLocalizations.of(
                              context,
                            )!.selectLocation,
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                AppLocalizations.of(context)!.allLocations,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            ...widget.locations.map((location) {
                              return DropdownMenuItem<String>(
                                value: getLocationKey(location),
                                child: Text(
                                  Directionality.of(context) ==
                                          TextDirection.ltr
                                      ? location.name ?? 'Unknown Location'
                                      : location.name_ar ?? 'مكان غير معروف',
                                  style: textTheme.bodyMedium,
                                ),
                              );
                            }),
                          ],
                          onChanged: onLocationChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: selectedLocationId != null
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: validatedSelectedLocationId != null
                            ? clearFilter
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

                if (validatedSelectedLocationId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${AppLocalizations.of(context)!.filterByLocation}: ${widget.locations.firstWhere(
                            (loc) => getLocationKey(loc) == validatedSelectedLocationId,
                            orElse: () => LocationModel(id: '', name: 'Unknown', name_ar: 'غير معروف'),
                          ).name}",
                          style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),

          Expanded(
            child: StreamBuilder<List<UserModel>>(
              key: ValueKey(
                'users_${validatedSelectedLocationId}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
              ),
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
                        Text('Error: ${snapshot.error}'),
                        TextButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          validatedSelectedLocationId != null
                              ? "${AppLocalizations.of(context)!.no} ${categoryName != null ? (Directionality.of(context) == TextDirection.ltr ? categoryName : categoryNameAr) : 'agents'} available in selected location"
                              : categoryName != null
                              ? "${AppLocalizations.of(context)!.no} ${Directionality.of(context) == TextDirection.ltr ? categoryName : categoryNameAr} ${AppLocalizations.of(context)!.agentsAvailable}"
                              : AppLocalizations.of(context)!.noAgentsAvailable,
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (validatedSelectedLocationId != null) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: clearFilter,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Show All Agents'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.name ?? ''),
                      subtitle: RichText(
                        text: TextSpan(
                          style: textTheme.labelMedium,
                          children: [
                            if (user.districtName != null) ...[
                              const WidgetSpan(
                                child: Icon(Icons.location_city, size: 15),
                              ),
                              TextSpan(text: " ${user.districtName ?? ''} "),
                            ],
                            if (user.jobRoles != null) ...[
                              const WidgetSpan(
                                child: Icon(Icons.work_rounded, size: 15),
                              ),
                              TextSpan(
                                text: " ${user.jobRoles?.join(', ') ?? ''}",
                              ),
                            ],
                          ],
                        ),
                      ),
                      onTap: () {
                        widget.onAssignAgent(
                          booking: widget.booking,
                          user: user,
                        );
                        Navigator.pop(context);
                      },
                    );
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
