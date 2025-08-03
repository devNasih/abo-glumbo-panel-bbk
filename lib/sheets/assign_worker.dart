import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignWorker extends StatefulWidget {
  final BookingModel booking;
  final List<LocationModel> locations;
  final Function(UserModel user) onAssignAgent;
  final Function(BookingModel booking) onRejectOrder;
  const AssignWorker({
    super.key,
    required this.booking,
    required this.locations,
    required this.onAssignAgent,
    required this.onRejectOrder,
  });

  @override
  State<AssignWorker> createState() => _AssignWorkerState();
}

class _AssignWorkerState extends State<AssignWorker> {
  String? selectedLocationId;
  List<CategoryModel>? categories;

  Query getFilteredQuery() {
    Query baseQuery = widget.booking.service.category != null
        ? AppFirestore.usersCollectionRef
              .where('isVerified', isEqualTo: true)
              .where('isAdmin', isNotEqualTo: true)
              .where('jobRoles', arrayContains: widget.booking.service.category)
        : AppFirestore.usersCollectionRef
              .where('isVerified', isEqualTo: true)
              .where('isAdmin', isNotEqualTo: true);

    if (selectedLocationId != null) {
      final selectedLocation = widget.locations.firstWhere(
        (loc) => loc.id == selectedLocationId,
        orElse: () => LocationModel(id: '', name: '', name_ar: ''),
      );

      String locationName = Directionality.of(context) == TextDirection.ltr
          ? selectedLocation.name?.trim() ?? ''
          : selectedLocation.name_ar?.trim() ?? '';
      return baseQuery.where('districtName', isEqualTo: locationName);
    }
    return baseQuery;
  }

  void onLocationChanged(String? newLocationId) {
    setState(() {
      selectedLocationId = newLocationId;
    });
  }

  void clearFilter() {
    setState(() {
      selectedLocationId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String? categoryName;
    String? categoryNameAr;
    if (categories != null && widget.booking.service.category != null) {
      try {
        final category = categories?.firstWhere(
          (cat) => cat.id == widget.booking.service.category,
        );
        categoryName = category?.name;
        categoryNameAr = category?.name_ar;
      } catch (e) {
        debugPrint(
          '❌ Category not found for ID: ${widget.booking.service.category}',
        );
      }
    }

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
                  onPressed: () {
                    widget.onRejectOrder(widget.booking);
                  },
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
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: selectedLocationId,
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
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                AppLocalizations.of(context)!.allLocations,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            ...widget.locations.map((location) {
                              return DropdownMenuItem<String?>(
                                value: location.name,
                                child: Text(
                                  Directionality.of(context) ==
                                          TextDirection.ltr
                                      ? (location.name ?? '')
                                      : (location.name_ar ?? ''),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedLocationId = newValue;
                            });
                            onLocationChanged?.call(newValue);
                          },
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
                        onPressed: selectedLocationId != null
                            ? clearFilter
                            : null,
                        icon: Icon(
                          Icons.clear_rounded,
                          color: selectedLocationId != null
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

                if (selectedLocationId != null) ...[
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
                            (loc) => loc.id == selectedLocationId,
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
                'users_${selectedLocationId}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
              ),
              stream: AppServices.getCatagoryWiseWorkersStream(
                widget.booking.service.category ?? '',
              ),
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
                  return Center(child: Loader(size: 32));
                }

                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          selectedLocationId != null
                              ? "${AppLocalizations.of(context)!.no} ${categoryName != null ? (Directionality.of(context) == TextDirection.ltr ? categoryName : categoryNameAr) : 'agents'} available in selected location"
                              : categoryName != null
                              ? "${AppLocalizations.of(context)!.no} ${Directionality.of(context) == TextDirection.ltr ? categoryName : categoryNameAr} ${AppLocalizations.of(context)!.agentsAvailable}"
                              : AppLocalizations.of(context)!.noAgentsAvailable,
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (selectedLocationId != null) ...[
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
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final user = docs[index];
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
                      onTap: () => widget.onAssignAgent(user),
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
