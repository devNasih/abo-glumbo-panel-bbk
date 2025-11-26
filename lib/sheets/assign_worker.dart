import 'dart:convert';
import 'dart:developer';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/searchable_dropdown.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/location_selection.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/widgets/conflict_widgets.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/conflict_check_services.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';

class AssignUserBottomSheet extends StatefulWidget {
  final BookingModel booking;
  final Function({required BookingModel booking, required UserModel user})
  onAssignAgent;
  final Function(BookingModel booking) onRejectOrder;
  final bool isWarranty;

  const AssignUserBottomSheet({
    super.key,
    required this.booking,
    required this.onAssignAgent,
    required this.onRejectOrder,
    this.isWarranty = false,
  });

  @override
  State<AssignUserBottomSheet> createState() => _AssignUserBottomSheetState();
}

class _AssignUserBottomSheetState extends State<AssignUserBottomSheet> {
  // Services
  late final ConflictCheckService _conflictService;

  // Location state
  List<Region> _regions = [];
  Region? _selectedRegion;
  City? _selectedCity;
  District? _selectedDistrict;
  bool _isDataFullyLoaded = false;

  // Loading states
  final ValueNotifier<bool> _isLoadingLocations = ValueNotifier(true);
  final ValueNotifier<bool> _isLoadingCategory = ValueNotifier(true);
  final ValueNotifier<bool> _isAssigning = ValueNotifier(false);

  // Data
  CategoryModel? _categoryModel;
  final Map<String, CategoryModel> _categoryCache = {};

  // Stream management
  Stream<List<UserModel>>? _cachedUsersStream;
  String? _lastLocationKey;

  bool _hasPreloadedConflicts = false;
  List<UserModel>? _lastPreloadedUsers;

  @override
  void initState() {
    super.initState();
    _conflictService = ConflictCheckService();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([_loadCategory(), _loadLocations()]);
  }

  @override
  void dispose() {
    _conflictService.dispose();
    _isLoadingLocations.dispose();
    _isLoadingCategory.dispose();
    _isAssigning.dispose();
    super.dispose();
  }

  Future<void> _loadCategory() async {
    _isLoadingCategory.value = true;
    try {
      if (widget.booking.service.category != null) {
        final doc = await AppFirestore.categoriesCollectionRef
            .doc(widget.booking.service.category)
            .get();

        if (doc.exists && mounted) {
          _categoryModel = CategoryModel.fromJson(
            doc.data() as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      log('Error loading category: $e');
    } finally {
      if (mounted) _isLoadingCategory.value = false;
    }
  }

  Future<void> _loadLocations() async {
    _isLoadingLocations.value = true;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/saudi_hierarchical.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      if (mounted) {
        _regions = jsonData.map((r) => Region.fromJson(r)).toList();
      }
    } catch (e) {
      log('Error loading locations: $e');
    } finally {
      if (mounted) _isLoadingLocations.value = false;
    }
  }

  Future<void> _loadCategories(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return;

    final uncachedIds = categoryIds
        .where((id) => !_categoryCache.containsKey(id))
        .toList();

    if (uncachedIds.isEmpty) return;

    try {
      final categories = await AppServices.getCategoriesByIds(uncachedIds);
      for (var category in categories) {
        if (category.id != null) {
          _categoryCache[category.id!] = category;
        }
      }
    } catch (e) {
      log('Error loading categories: $e');
    }
  }

  String _getJobRoleNames(List<String>? jobRoleIds, bool isArabic) {
    if (jobRoleIds == null || jobRoleIds.isEmpty) return '';

    return jobRoleIds
        .map((id) {
          final category = _categoryCache[id];
          if (category == null) return null;
          return isArabic ? category.name_ar : category.name;
        })
        .where((name) => name != null)
        .join(', ');
  }

  Future<void> _preloadConflictData(List<UserModel> users) async {
    if (!mounted || _conflictService.isCacheValid || _hasPreloadedConflicts) {
      return;
    }
    if (_lastPreloadedUsers != null &&
        _usersAreEqual(_lastPreloadedUsers!, users)) {
      return;
    }

    _hasPreloadedConflicts = true;
    _lastPreloadedUsers = users;

    try {
      // Load job role categories
      final jobRoleIds = users
          .expand((u) => u.jobRoles ?? [])
          .whereType<String>()
          .toSet()
          .toList();

      await _loadCategories(jobRoleIds);

      // Get the list of UIDs to check for conflicts
      List<String> conflictUids = [];

      if (widget.isWarranty) {
        // For warranties, only get rejected technician UIDs
        final currentBookingDoc = await AppFirestore.bookingsCollectionRef
            .doc(widget.booking.id)
            .get();

        if (currentBookingDoc.exists) {
          final data = currentBookingDoc.data() as Map<String, dynamic>?;
          final warrantyData = data?['warranty'] as Map<String, dynamic>?;
          final rejectedTechnicians =
              warrantyData?['rejectedTechnicians'] as List?;

          if (rejectedTechnicians != null) {
            for (var tech in rejectedTechnicians) {
              final uid = tech['uid'] as String?;
              if (uid != null) {
                conflictUids.add(uid);
              }
            }
          }
        }
      } else {
        // For normal bookings, get cancelled worker UIDs
        final currentBookingDoc = await AppFirestore.bookingsCollectionRef
            .doc(widget.booking.id)
            .get();

        if (currentBookingDoc.exists) {
          final data = currentBookingDoc.data() as Map<String, dynamic>?;
          final uids = data?['cancelledWorkerUids'] as List?;
          if (uids != null) {
            conflictUids.addAll(uids.cast<String>());
          }
        }
      }

      // Batch check conflicts with the appropriate UIDs
      final userIds = users.map((u) => u.uid).whereType<String>().toList();

      await _conflictService.batchCheckConflicts(
        userIds: userIds,
        booking: widget.booking,
        cancelledWorkerUids: conflictUids,
      );
    } catch (e) {
      log('Error preloading conflicts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDataFullyLoaded = true;
        });
      }
    }
  }

  bool _usersAreEqual(List<UserModel> list1, List<UserModel> list2) {
    if (list1.length != list2.length) return false;

    final ids1 = list1.map((u) => u.uid).toSet();
    final ids2 = list2.map((u) => u.uid).toSet();

    return ids1.length == ids2.length && ids1.containsAll(ids2);
  }

  Future<void> _handleAssignAgent(UserModel user) async {
    final userId = user.uid;
    if (userId == null) return;

    if (_isAssigning.value) {
      _showSnackBar(
        AppLocalizations.of(context)?.assignmentInProgress ??
            'Assignment in progress',
      );
      return;
    }

    _isAssigning.value = true;

    try {
      _showSnackBar(
        AppLocalizations.of(context)?.checkingAvailabilityAndAssigning ??
            'Checking availability...',
      );

      // Get conflict data
      final conflicts = await _conflictService.batchCheckConflicts(
        userIds: [userId],
        booking: widget.booking,
        cancelledWorkerUids: [],
      );

      final conflictData = conflicts[userId];

      if (conflictData?.hasConflict == true) {
        await _showConflictDialog(user, conflictData!);
        return;
      }

      // Verify booking not already assigned
      final currentDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
          .get();

      if (currentDoc.exists) {
        final data = currentDoc.data() as Map<String, dynamic>;
        final assignedTo = data['assignedTo'] as String?;
        final status = data['bookingStatusCode'] as String?;

        if (assignedTo != null && assignedTo.isNotEmpty && status != 'P') {
          _showSnackBar(
            AppLocalizations.of(
              context,
            )!.thisBookingAlreadyAssignedToAnotherAgent,
          );
          Navigator.pop(context);
          return;
        }
      }

      // Track assignment and execute
      _conflictService.trackAssignment(
        userId,
        widget.booking.bookingDateTime.toDate(),
      );
      _conflictService.invalidateCache();

      widget.onAssignAgent(booking: widget.booking, user: user);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(
        AppLocalizations.of(context)?.failedToAssignAgent ??
            'Failed to assign agent',
      );
    } finally {
      if (mounted) _isAssigning.value = false;
    }
  }

  Future<void> _showConflictDialog(
    UserModel user,
    ConflictData conflictData,
  ) async {
    final agentName =
        user.name ?? AppLocalizations.of(context)?.agent ?? 'Agent';

    if (conflictData.type == ConflictType.workerCancelledThisBooking) {
      await ConflictDialogs.showWorkerCancelledDialog(
        context,
        agentName: agentName,
        conflictTime: conflictData.conflictTime!,
        conflictDate: conflictData.conflictDate!,
        isThisBooking: true,
      );
    } else if (conflictData.type == ConflictType.workerCancelled) {
      await ConflictDialogs.showWorkerCancelledDialog(
        context,
        agentName: agentName,
        conflictTime: conflictData.conflictTime!,
        conflictDate: conflictData.conflictDate!,
        isThisBooking: false,
      );
    } else {
      await ConflictDialogs.showTimeConflictDialog(
        context,
        agentName: agentName,
        conflictTime: conflictData.conflictTime!,
        conflictDate: conflictData.conflictDate!,
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  Stream<List<UserModel>> _createUsersStream() {
    final categoryId = widget.booking.service.category;

    if (categoryId != null) {
      return _getCategoryWiseWorkersStream(categoryId).map(_filterByLocation);
    }

    return AppFirestore.usersCollectionRef
        .where('isVerified', isEqualTo: true)
        .where('isAdmin', isNotEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map(
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
          return _filterByLocation(users);
        });
  }

  Stream<List<UserModel>> _getCategoryWiseWorkersStream(
    String categoryId,
  ) async* {
    try {
      final doc = await AppFirestore.categoriesCollectionRef
          .doc(categoryId)
          .get();

      if (!doc.exists) {
        yield [];
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final catId = data?['id'] ?? '';

      if (catId.isEmpty) {
        yield [];
        return;
      }

      yield* AppFirestore.usersCollectionRef
          .where('isVerified', isEqualTo: true)
          .where('isAdmin', isNotEqualTo: true)
          .where('jobRoles', arrayContains: catId)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) =>
                      UserModel.fromJson(doc.data() as Map<String, dynamic>),
                )
                .toList();
          });
    } catch (e) {
      log('Error in category stream: $e');
      yield [];
    }
  }

  List<UserModel> _filterByLocation(List<UserModel> users) {
    if (_selectedRegion == null &&
        _selectedCity == null &&
        _selectedDistrict == null) {
      return users;
    }

    return users.where((user) {
      final location = user.detailedLocation;
      if (location == null) return false;

      if (_selectedRegion != null &&
          location.regionId != _selectedRegion!.regionId) {
        return false;
      }

      if (_selectedCity != null && location.cityId != _selectedCity!.cityId) {
        return false;
      }

      if (_selectedDistrict != null &&
          location.neighborhoodId != _selectedDistrict!.districtId) {
        return false;
      }

      return true;
    }).toList();
  }

  Stream<List<UserModel>> _getFilteredUsersStream() {
    final locationKey =
        '${_selectedRegion?.regionId}_${_selectedCity?.cityId}_${_selectedDistrict?.districtId}';

    if (_cachedUsersStream == null || _lastLocationKey != locationKey) {
      _cachedUsersStream = _createUsersStream();
      _lastLocationKey = locationKey;
      _conflictService.invalidateCache();

      // NEW: Reset preload flag when stream changes
      _hasPreloadedConflicts = false;
      _lastPreloadedUsers = null;
      _isDataFullyLoaded = false;
    }

    return _cachedUsersStream!;
  }

  Future<void> _showRejectConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.start,
        title: Text(AppLocalizations.of(context)!.confirmReject),
        content: Text(AppLocalizations.of(context)!.confirmRejectMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              Navigator.of(context).pop(false);
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onRejectOrder(widget.booking);
      Navigator.pop(context);
    }
  }

  Future<void> _showLocationFilterDialog() async {
    Region? tempRegion = _selectedRegion;
    City? tempCity = _selectedCity;
    District? tempDistrict = _selectedDistrict;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(AppLocalizations.of(context)!.filterByLocation),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdown<Region>(
                    label: AppLocalizations.of(context)!.province,
                    value: tempRegion,
                    items: _regions,
                    itemLabel: (region) =>
                        region.getName(LocalStore.getUserlanguage() == 'ar'),
                    onChanged: (region) {
                      setDialogState(() {
                        tempRegion = region;
                        tempCity = null;
                        tempDistrict = null;
                      });
                    },
                    hintText: AppLocalizations.of(
                      context,
                    )!.typeProvinceNameToSearch,
                  ),
                  if (tempRegion != null) ...[
                    const SizedBox(height: 16),
                    SearchableDropdown<City>(
                      label: AppLocalizations.of(context)!.city,
                      value: tempCity,
                      items: tempRegion!.cities,
                      itemLabel: (city) =>
                          city.getName(LocalStore.getUserlanguage() == 'ar'),
                      onChanged: (city) {
                        setDialogState(() {
                          tempCity = city;
                          tempDistrict = null;
                        });
                      },
                      hintText: AppLocalizations.of(
                        context,
                      )!.typeCityNameToSearch,
                    ),
                  ],
                  if (tempCity != null) ...[
                    const SizedBox(height: 16),
                    SearchableDropdown<District>(
                      label: AppLocalizations.of(context)!.neighborhood,
                      value: tempDistrict,
                      items: tempCity!.districts,
                      itemLabel: (district) => district.getName(
                        LocalStore.getUserlanguage() == 'ar',
                      ),
                      onChanged: (district) {
                        setDialogState(() {
                          tempDistrict = district;
                        });
                      },
                      hintText: AppLocalizations.of(
                        context,
                      )!.typeNeighborhoodNameToSearch,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            eButton(
              backgroundColor: Colors.grey,
              context: context,
              onPressed: () => Navigator.of(context).pop(false),
              text: AppLocalizations.of(context)!.cancel,
              textColor: Colors.black,
            ),
            eButton(
              backgroundColor: Colors.blue,
              context: context,
              onPressed: () => Navigator.of(context).pop(true),
              text: AppLocalizations.of(context)!.apply,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _selectedRegion = tempRegion;
        _selectedCity = tempCity;
        _selectedDistrict = tempDistrict;
        _conflictService.invalidateCache();
      });
    }
  }

  void _clearFilter() {
    if (_selectedRegion != null ||
        _selectedCity != null ||
        _selectedDistrict != null) {
      setState(() {
        _selectedRegion = null;
        _selectedCity = null;
        _selectedDistrict = null;
        _conflictService.invalidateCache();
        _hasPreloadedConflicts = false;
        _lastPreloadedUsers = null;
        _isDataFullyLoaded = false;
      });
    }
  }

  String _getSelectedLocationText() {
    final isArabic = LocalStore.getUserlanguage() == 'ar';
    final parts = <String>[];

    if (_selectedDistrict != null) {
      parts.add(_selectedDistrict!.getName(isArabic));
    }
    if (_selectedCity != null) {
      parts.add(_selectedCity!.getName(isArabic));
    }
    if (_selectedRegion != null) {
      parts.add(_selectedRegion!.getName(isArabic));
    }

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingCategory,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 24, child: Loader()),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.loading ?? 'Loading...',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textTheme),
              _buildLocationFilter(textTheme),
              const Divider(height: 1),
              Expanded(child: _buildUserList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    final categoryName = _categoryModel?.name;
    final categoryNameAr = _categoryModel?.name_ar;
    final isArabic = LocalStore.getUserlanguage() == 'ar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              categoryName != null
                  ? '${AppLocalizations.of(context)!.assignTo} ${isArabic ? categoryNameAr : categoryName}'
                  : AppLocalizations.of(context)!.assignToUser,
              style: textTheme.titleLarge,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isAssigning,
            builder: (context, isAssigning, _) {
              return IconButton.filledTonal(
                color: Colors.red,
                onPressed: isAssigning ? null : _showRejectConfirmationDialog,
                icon: const Icon(Icons.highlight_off_rounded),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFilter(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.filterByLocation,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _isAssigning,
            builder: (context, isAssigning, _) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isAssigning ? null : _showLocationFilterDialog,
                  icon: const Icon(Icons.location_on_outlined, size: 20),
                  label: Text(AppLocalizations.of(context)!.filterByLocation),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              );
            },
          ),
          if (_selectedRegion != null ||
              _selectedCity != null ||
              _selectedDistrict != null)
            _buildSelectedLocationChip(),
        ],
      ),
    );
  }

  Widget _buildSelectedLocationChip() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getSelectedLocationText(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isAssigning,
              builder: (context, isAssigning, _) {
                return IconButton(
                  onPressed: isAssigning ? null : _clearFilter,
                  icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                  tooltip: AppLocalizations.of(context)!.clearFilter,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<UserModel>>(
      stream: _getFilteredUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  '${AppLocalizations.of(context)?.error ?? "Error"}: ${snapshot.error}',
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _cachedUsersStream = null;
                      _isDataFullyLoaded = false;
                      _hasPreloadedConflicts = false;
                      _lastPreloadedUsers = null;
                    });
                  },
                  child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const UserListShimmer();
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return _buildEmptyState();
        }

        // Trigger preload without causing rebuild flicker
        if (!_hasPreloadedConflicts && !_conflictService.isCacheValid) {
          Future.microtask(() {
            if (mounted && !_hasPreloadedConflicts) {
              _preloadConflictData(users);
            }
          });
        }

        // KEY CHANGE: Single condition check - show shimmer until fully loaded
        if (!_isDataFullyLoaded) {
          return const UserListShimmer();
        }

        // Only show the actual list when everything is ready
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _UserTile(
              user: users[index],
              conflictService: _conflictService,
              onAssign: _handleAssignAgent,
              isAssigning: _isAssigning,
              categoryCache: _categoryCache,
              getJobRoleNames: _getJobRoleNames,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final textTheme = Theme.of(context).textTheme;
    final categoryName = _categoryModel?.name;
    final categoryNameAr = _categoryModel?.name_ar;
    final isArabic = LocalStore.getUserlanguage() == 'ar';
    final hasLocationFilter =
        _selectedRegion != null ||
        _selectedCity != null ||
        _selectedDistrict != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_rounded, size: 48),
          const SizedBox(height: 16),
          Text(
            hasLocationFilter
                ? "${AppLocalizations.of(context)!.no} ${categoryName != null ? (isArabic ? categoryNameAr : categoryName) : AppLocalizations.of(context)?.agents ?? 'agents'} ${AppLocalizations.of(context)?.availableInSelectedLocation ?? 'available in selected location'}"
                : categoryName != null
                ? "${AppLocalizations.of(context)!.no} ${isArabic ? categoryNameAr : categoryName} ${AppLocalizations.of(context)!.agentsAvailable}"
                : AppLocalizations.of(context)!.noAgentsAvailable,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (hasLocationFilter) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearFilter,
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
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final ConflictCheckService conflictService;
  final Function(UserModel) onAssign;
  final ValueNotifier<bool> isAssigning;
  final Map<String, CategoryModel> categoryCache;
  final String Function(List<String>?, bool) getJobRoleNames;

  const _UserTile({
    required this.user,
    required this.conflictService,
    required this.onAssign,
    required this.isAssigning,
    required this.categoryCache,
    required this.getJobRoleNames,
  });

  @override
  Widget build(BuildContext context) {
    final userId = user.uid ?? '';
    final textTheme = Theme.of(context).textTheme;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return ValueListenableBuilder<bool>(
      valueListenable: isAssigning,
      builder: (context, assigning, _) {
        final conflictData = conflictService.getConflictData(userId);
        final hasConflict = conflictData?.hasConflict ?? false;
        final isDisabled = assigning || hasConflict;

        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.name ?? '',
                  style: TextStyle(
                    color: isDisabled ? Colors.grey.shade600 : null,
                  ),
                ),
              ),
              if (hasConflict && conflictData != null)
                _buildConflictBadge(context, conflictData),
            ],
          ),
          subtitle: _buildSubtitle(context, textTheme, isArabic, isDisabled),
          trailing: _buildTrailing(conflictData, assigning),
          tileColor: _getTileColor(conflictData),
          enabled: !isDisabled,
          onTap: isDisabled ? null : () => onAssign(user),
        );
      },
    );
  }

  Widget _buildConflictBadge(BuildContext context, ConflictData data) {
    final color = data.type == ConflictType.workerCancelledThisBooking
        ? Colors.orange
        : Colors.red;

    String label;
    if (data.type == ConflictType.workerCancelledThisBooking) {
      label =
          AppLocalizations.of(context)?.cancelledThisBooking ??
          'Cancelled This Booking';
    } else if (data.type == ConflictType.workerCancelled) {
      label =
          AppLocalizations.of(context)?.technicianCancelled ??
          'Cancelled Worker';
    } else {
      label =
          '${AppLocalizations.of(context)?.busyAt ?? 'Busy at'} ${data.conflictTime}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    TextTheme textTheme,
    bool isArabic,
    bool isDisabled,
  ) {
    return RichText(
      text: TextSpan(
        style: textTheme.labelMedium?.copyWith(
          color: isDisabled ? Colors.grey.shade500 : null,
        ),
        children: [
          if (user.detailedLocation != null) ...[
            WidgetSpan(
              child: Icon(
                Icons.location_city,
                size: 15,
                color: isDisabled ? Colors.grey.shade500 : null,
              ),
            ),
            TextSpan(
              text: isArabic
                  ? " ${user.detailedLocation?.neighborhoodAr}, ${user.detailedLocation?.cityAr}, ${user.detailedLocation?.regionAr} "
                  : " ${user.detailedLocation?.neighborhoodEn}, ${user.detailedLocation?.cityEn}, ${user.detailedLocation?.regionEn} ",
            ),
          ],
          if (user.jobRoles != null) ...[
            WidgetSpan(
              child: Icon(
                Icons.work_rounded,
                size: 15,
                color: isDisabled ? Colors.grey.shade500 : null,
              ),
            ),
            TextSpan(text: " ${getJobRoleNames(user.jobRoles, isArabic)}"),
          ],
        ],
      ),
    );
  }

  Widget? _buildTrailing(ConflictData? data, bool assigning) {
    if (assigning) {
      return SizedBox(width: 24, height: 24, child: Loader());
    }

    if (data?.hasConflict == true) {
      final color = data!.type == ConflictType.workerCancelledThisBooking
          ? Colors.orange
          : Colors.red;
      final icon = data.type == ConflictType.workerCancelledThisBooking
          ? Icons.person_off_rounded
          : Icons.block;

      return Icon(icon, color: color, size: 22);
    }

    return null;
  }

  Color? _getTileColor(ConflictData? data) {
    if (data?.hasConflict != true) return null;

    final color = data!.type == ConflictType.workerCancelledThisBooking
        ? Colors.orange
        : Colors.red;

    return color.withOpacity(0.05);
  }
}

class UserListShimmer extends StatelessWidget {
  final int itemCount;

  const UserListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildShimmerTile(),
    );
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          height: 20,
          width: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
