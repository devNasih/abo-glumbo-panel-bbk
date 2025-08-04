import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationSelectorWidget extends StatefulWidget {
  final List<LocationModel> locations;
  final LocationModel? selectedLocation;
  final List<LocationModel>? selectedLocations;
  final Function(LocationModel)? onLocationSelected;
  final Function(List<LocationModel>)? onLocationsSelected;
  final VoidCallback? onUseCurrentLocation;
  final bool isLoading;
  final String? searchHint;
  final String? title;
  final String? noLocationsMessage;
  final String? currentLocationText;
  final bool allowMultipleSelection;

  const LocationSelectorWidget({
    super.key,
    required this.locations,
    this.selectedLocation,
    this.selectedLocations,
    this.onLocationSelected,
    this.onLocationsSelected,
    this.onUseCurrentLocation,
    this.isLoading = false,
    this.searchHint,
    this.title,
    this.noLocationsMessage,
    this.currentLocationText,
    this.allowMultipleSelection = false,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  final TextEditingController searchController = TextEditingController();
  List<LocationModel> filteredLocations = [];
  List<LocationModel> selectedLocations = [];
  bool isArabic = false;

  @override
  void initState() {
    super.initState();
    filteredLocations = widget.locations;

    if (widget.allowMultipleSelection && widget.selectedLocations != null) {
      selectedLocations = List.from(widget.selectedLocations!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIsArabic = AppLocalizations.of(context)?.localeName == 'ar';
    if (isArabic != newIsArabic) {
      isArabic = newIsArabic == true;
    }
    filteredLocations = _removeDuplicates(widget.locations);
  }

  @override
  void didUpdateWidget(LocationSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      filteredLocations = _removeDuplicates(widget.locations);
      _filterLocations(searchController.text);
    }
  }

  List<LocationModel> _removeDuplicates(List<LocationModel> locations) {
    final seen = <String>{};
    return locations.where((location) {
      final name = isArabic ? location.name_ar : location.name;
      if (name == null || name.isEmpty) return true;

      if (seen.contains(name)) {
        return false;
      }
      seen.add(name);
      return true;
    }).toList();
  }

  void _filterLocations(String query) {
    setState(() {
      final uniqueLocations = _removeDuplicates(widget.locations);
      if (query.isEmpty) {
        filteredLocations = uniqueLocations;
      } else {
        filteredLocations = uniqueLocations.where((location) {
          final nameMatch =
              location.name?.toLowerCase().contains(query.toLowerCase()) ??
              false;
          final nameArMatch =
              location.name_ar?.toLowerCase().contains(query.toLowerCase()) ??
              false;
          return nameMatch || nameArMatch;
        }).toList();
      }
    });
  }

  String _getLocationName(LocationModel location) {
    return isArabic
        ? (location.name_ar ?? location.name ?? '')
        : (location.name ?? '');
  }

  bool _isLocationSelected(LocationModel location) {
    if (widget.allowMultipleSelection) {
      return selectedLocations.any((selected) => selected.id == location.id);
    } else {
      return widget.selectedLocation?.id == location.id;
    }
  }

  void _handleLocationTap(LocationModel location) {
    if (widget.allowMultipleSelection) {
      setState(() {
        final index = selectedLocations.indexWhere(
          (selected) => selected.id == location.id,
        );
        if (index >= 0) {
          selectedLocations.removeAt(index);
        } else {
          selectedLocations.add(location);
        }
      });
    } else {
      widget.onLocationSelected?.call(location);
    }
  }

  void _handleDonePressed() {
    if (widget.allowMultipleSelection) {
      widget.onLocationsSelected?.call(selectedLocations);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final safePaddings = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title ??
                        AppLocalizations.of(context)?.selectLocation ??
                        'Select Location',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.allowMultipleSelection &&
                          selectedLocations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedLocations.length} selected',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText:
                      widget.searchHint ??
                      AppLocalizations.of(context)?.searchLocation ??
                      'Search Location',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.grey2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: _filterLocations,
              ),
            ),
            if (widget.onUseCurrentLocation != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.my_location, color: AppColors.secondary),
                ),
                title: Text(
                  widget.currentLocationText ??
                      AppLocalizations.of(context)?.useCurrentLocation ??
                      'Use Current Location',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onUseCurrentLocation!();
                },
              ),
            if (widget.onUseCurrentLocation != null) const Divider(),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLocations.isEmpty
                  ? Center(
                      child: Text(
                        widget.noLocationsMessage ?? 'No locations found',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLocations.length,
                      padding: EdgeInsets.only(
                        bottom:
                            safePaddings.bottom +
                            (widget.allowMultipleSelection ? 80 : 16),
                      ),
                      itemBuilder: (context, index) {
                        final location = filteredLocations[index];
                        final isSelected = _isLocationSelected(location);

                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.grey2,
                          ),
                          title: Text(
                            _getLocationName(location),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? AppColors.secondary : null,
                            ),
                          ),
                          trailing: widget.allowMultipleSelection
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    _handleLocationTap(location);
                                  },
                                  activeColor: AppColors.secondary,
                                )
                              : isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.secondary,
                                )
                              : null,
                          onTap: () {
                            _handleLocationTap(location);
                          },
                        );
                      },
                    ),
            ),

            if (widget.allowMultipleSelection)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _handleDonePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Done (${selectedLocations.length} selected)',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class LocationSelectorHelper {
  static Future<LocationModel?> showLocationSelector({
    required BuildContext context,
    required List<LocationModel> locations,
    LocationModel? selectedLocation,
    VoidCallback? onUseCurrentLocation,
    bool isLoading = false,
    String? searchHint,
    String? title,
    String? noLocationsMessage,
    String? currentLocationText,
  }) async {
    return await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return LocationSelectorWidget(
          locations: locations,
          selectedLocation: selectedLocation,
          onLocationSelected: (location) {
            Navigator.pop(context, location);
          },
          onUseCurrentLocation: onUseCurrentLocation,
          isLoading: isLoading,
          searchHint: searchHint,
          title: title,
          noLocationsMessage: noLocationsMessage,
          currentLocationText: currentLocationText,
          allowMultipleSelection: false,
        );
      },
    );
  }

  static Future<List<LocationModel>?> showMultipleLocationSelector({
    required BuildContext context,
    required List<LocationModel> locations,
    List<LocationModel>? selectedLocations,
    VoidCallback? onUseCurrentLocation,
    bool isLoading = false,
    String? searchHint,
    String? title,
    String? noLocationsMessage,
    String? currentLocationText,
  }) async {
    List<LocationModel>? result;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return LocationSelectorWidget(
          locations: locations,
          selectedLocations: selectedLocations,
          onLocationsSelected: (locations) {
            result = locations;
          },
          onUseCurrentLocation: onUseCurrentLocation,
          isLoading: isLoading,
          searchHint: searchHint,
          title: title,
          noLocationsMessage: noLocationsMessage,
          currentLocationText: currentLocationText,
          allowMultipleSelection: true,
        );
      },
    );

    return result;
  }

  static List<String> getLocationNames(
    List<LocationModel> locations, {
    bool isArabic = false,
  }) {
    return locations.map((location) {
      return isArabic
          ? (location.name_ar ?? location.name ?? '')
          : (location.name ?? '');
    }).toList();
  }
}
