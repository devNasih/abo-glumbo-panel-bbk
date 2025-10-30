import 'dart:developer';

import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';

import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:app_settings/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'dart:io';

class BookingControlsWidget extends StatefulWidget {
  final BookingModel booking;
  final bool isTracking;

  static final BookingTrackerService _trackerService = BookingTrackerService();

  const BookingControlsWidget({
    super.key,
    required this.booking,
    required this.isTracking,
  });

  @override
  State<BookingControlsWidget> createState() => _BookingControlsWidgetState();
}

class _BookingControlsWidgetState extends State<BookingControlsWidget> {
  bool isCancelBookingButtonBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeCancelButtonState();
  }

  void _initializeCancelButtonState() {
    final isCurrentlyTracking =
        BookingControlsWidget._trackerService.isTracking.value;
    setState(() {
      isCancelBookingButtonBlocked = isCurrentlyTracking;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingCancelSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCancelledSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingCancelFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingCompleteSuccess) {
          setState(() => isCancelBookingButtonBlocked = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCompletedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingCompleteFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingStartWorkingSuccess) {
          setState(() => isCancelBookingButtonBlocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.startedWorkingOnBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingStartWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
              duration: const Duration(
                seconds: 6,
              ), // Give users time to read and act
              action:
                  state.error.contains('Background location permission') ||
                      state.error.contains('Allow all the time')
                  ? SnackBarAction(
                      label: AppLocalizations.of(context)!.openSettings,
                      textColor: Colors.white,
                      onPressed: () => AppSettings.openAppSettings(
                        type: AppSettingsType.location,
                      ),
                    )
                  : null,
            ),
          );
          log('start tracking error: ${state.error}');
        } else if (state is BookingStopWorkingSuccess) {
          setState(() => isCancelBookingButtonBlocked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.stopTrackingBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingStopWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
          log("stop tracking error: ${state.error}");
        }
      },
      builder: (context, state) {
        final isCancelLoading = state is BookingCancelLoading;
        final isCompleteLoading = state is BookingCompleteLoading;
        final isStartWorkingLoading = state is BookingStartWorkingLoading;
        final isStopWorkingLoading = state is BookingStopWorkingLoading;

        return ValueListenableBuilder<bool>(
          valueListenable: BookingControlsWidget._trackerService.isTracking,
          builder: (context, serviceIsTracking, child) {
            final actualIsTracking = serviceIsTracking;
            final currentTrackingBookingId =
                BookingControlsWidget._trackerService.currentBookingId;
            final isThisBookingTracked =
                actualIsTracking &&
                currentTrackingBookingId == widget.booking.id;

            final shouldBlockCancel = actualIsTracking;

            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          onPressed:
                              shouldBlockCancel ||
                                  isCancelLoading ||
                                  isCompleteLoading ||
                                  isStartWorkingLoading ||
                                  isStopWorkingLoading
                              ? null
                              : () => _showCancelBottomSheet(context),
                          label: AppLocalizations.of(context)!.cancelBooking,
                          color: shouldBlockCancel
                              ? Colors.grey
                              : Colors.red.shade50,
                          textColor: shouldBlockCancel
                              ? Colors.grey.shade700
                              : Colors.red.shade700,
                          borderColor: shouldBlockCancel
                              ? Colors.grey.shade200
                              : Colors.red.shade200,
                          isLoading: isCancelLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton(
                          onPressed:
                              (isStartWorkingLoading ||
                                  isStopWorkingLoading ||
                                  isCancelLoading ||
                                  isCompleteLoading ||
                                  (actualIsTracking &&
                                      BookingControlsWidget
                                              ._trackerService
                                              .currentBookingId !=
                                          widget.booking.id))
                              ? null
                              : isThisBookingTracked
                              ? () => _showStopTrackingBottomSheet(context)
                              : () => _showStartTrackingBottomSheet(context),
                          label: isThisBookingTracked
                              ? AppLocalizations.of(context)!.stopTracking
                              : AppLocalizations.of(context)!.startTracking,
                          color: isThisBookingTracked
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          textColor: isThisBookingTracked
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          borderColor: isThisBookingTracked
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                          isLoading:
                              isStartWorkingLoading || isStopWorkingLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isCompleteLoading
                          ? null
                          : () => _showCompleteWorkBottomSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isCompleteLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.completeWork,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required Color color,
    required Color textColor,
    required Color borderColor,
    bool isLoading = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey.shade100 : color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed == null ? Colors.grey.shade300 : borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: onPressed == null
                          ? Colors.grey.shade500
                          : textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  void _showCancelBottomSheet(BuildContext context) {
    final trackerService = BookingControlsWidget._trackerService;
    if (trackerService.isTracking.value) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.cancelBooking,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.cannotCancel,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.ok,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(Icons.cancel_outlined, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.cancelBooking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToCancelThisBooking,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<BookingBloc>().add(
                          CancelBooking(
                            bookingId: widget.booking.id,
                            agentUid: widget.booking.agent?.uid ?? '',
                            agentName: widget.booking.agent?.name ?? '',
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStartTrackingBottomSheet(BuildContext context) {
    final trackerService = BookingControlsWidget._trackerService;
    if (trackerService.isTracking.value &&
        trackerService.currentBookingId != null &&
        trackerService.currentBookingId != widget.booking.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Another booking is already being tracked. Please complete or stop the current tracking before starting a new one.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(Icons.play_circle_outline, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.startTracking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToStartTrackingThisBooking,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        final uid = LocalStore.getUID();
                        if (uid != null) {
                          parentContext.read<BookingBloc>().add(
                            StartWorkingOnBooking(
                              context: parentContext,
                              bookingId: widget.booking.id,
                              uid: uid,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStopTrackingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(Icons.stop_circle_outlined, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.stopTracking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToStopTrackingThisBooking,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<BookingBloc>().add(
                          StopWorkingOnBooking(bookingId: widget.booking.id),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompleteWorkBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CompleteWorkBottomSheet(booking: widget.booking);
      },
    );
  }
}

// Separate StatefulWidget for Complete Work Bottom Sheet with Form Validation
class CompleteWorkBottomSheet extends StatefulWidget {
  final BookingModel booking;

  const CompleteWorkBottomSheet({super.key, required this.booking});

  @override
  State<CompleteWorkBottomSheet> createState() =>
      _CompleteWorkBottomSheetState();
}

class _CompleteWorkBottomSheetState extends State<CompleteWorkBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceCostController = TextEditingController();
  final List<ServiceItem> _serviceItems = [];
  List<File> selectedFiles = [];
  String? _fileError;
  bool _serviceCompleted = false;

  double get _totalCost {
    if (!_serviceCompleted) {
      return widget.booking.service.price?.toDouble() ?? 0;
    }
    double inspectionCost = widget.booking.service.price?.toDouble() ?? 0;

    if (_serviceItems.isNotEmpty) {
      double itemsTotal = _serviceItems.fold(
        0,
        (sum, item) => sum + (item.quantity * item.price),
      );
      return inspectionCost + itemsTotal;
    } else {
      double serviceCost = double.tryParse(_serviceCostController.text) ?? 0;
      return inspectionCost + serviceCost;
    }
  }

  @override
  void dispose() {
    _serviceCostController.dispose();
    for (var item in _serviceItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc'],
      );

      if (result != null) {
        setState(() {
          selectedFiles.addAll(result.files.map((file) => File(file.path!)));
          _fileError = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  IconData _getFileIcon(String path) {
    String ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return Icons.image;
    } else if (ext == 'pdf') {
      return Icons.picture_as_pdf;
    } else {
      return Icons.insert_drive_file;
    }
  }

  bool _isImageFile(String path) {
    String ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(ext);
  }

  void _addServiceItem() {
    setState(() {
      _serviceItems.add(ServiceItem());
    });
  }

  void _removeServiceItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Get the item name for display, or show "Item {index+1}" if empty
        String itemName = _serviceItems[index].nameController.text.isNotEmpty
            ? _serviceItems[index].nameController.text
            : '${AppLocalizations.of(context)!.item} ${index + 1}';

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.removeItem,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.removeItemConfirmation,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              // Show item details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            itemName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_serviceItems[index]
                            .quantityController
                            .text
                            .isNotEmpty ||
                        _serviceItems[index]
                            .priceController
                            .text
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_serviceItems[index]
                              .quantityController
                              .text
                              .isNotEmpty) ...[
                            Text(
                              '${AppLocalizations.of(context)!.qty}: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _serviceItems[index].quantityController.text,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                          if (_serviceItems[index]
                                  .quantityController
                                  .text
                                  .isNotEmpty &&
                              _serviceItems[index]
                                  .priceController
                                  .text
                                  .isNotEmpty)
                            Text(
                              '  ×  ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (_serviceItems[index]
                              .priceController
                              .text
                              .isNotEmpty) ...[
                            Text(
                              '${AppLocalizations.of(context)!.price}: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${_serviceItems[index].priceController.text} ${AppLocalizations.of(context)!.sar}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    // Show total if both qty and price exist
                    if (_serviceItems[index]
                            .quantityController
                            .text
                            .isNotEmpty &&
                        _serviceItems[index]
                            .priceController
                            .text
                            .isNotEmpty) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.total,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${_serviceItems[index].quantity * _serviceItems[index].price} ${AppLocalizations.of(context)!.sar}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _serviceItems[index].dispose();
                  _serviceItems.removeAt(index);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.remove,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm() {
    bool isValid = true;

    if (_serviceCompleted && selectedFiles.isEmpty) {
      setState(() {
        _fileError = AppLocalizations.of(context)!.pleaseUploadFiles;
      });
      isValid = false;
    }

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
    } else {
      isValid = false;
    }

    if (_serviceCompleted && _serviceItems.isNotEmpty) {
      for (var item in _serviceItems) {
        if (!item.isValid()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.pleaseFillAllServiceItemFields,
              ),
              backgroundColor: Colors.red,
            ),
          );
          isValid = false;
          break;
        }
      }
    }

    return isValid;
  }

  void _handleCompleteWithConfirmation() {
    if (_validateForm()) {
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.confirmCompletion,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.confirmCompletionMessage,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                // Mode indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _serviceCompleted
                        ? AppColors.primary.withAlpha(30)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _serviceCompleted
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _serviceCompleted
                            ? Icons.check_circle
                            : Icons.search_outlined,
                        color: _serviceCompleted
                            ? AppColors.primary
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _serviceCompleted
                            ? AppLocalizations.of(context)!.serviceCompleted
                            : AppLocalizations.of(context)!.inspectionOnly,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _serviceCompleted
                              ? AppColors.primary
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cost Breakdown
                Text(
                  AppLocalizations.of(context)!.costBreakdown,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),

                // Inspection Fee (always shown)
                _buildCostRow(
                  label: AppLocalizations.of(context)!.inspectionFee,
                  amount: widget.booking.service.price?.toDouble() ?? 0,
                ),

                // Service completed mode - show additional costs
                if (_serviceCompleted) ...[
                  const Divider(height: 20),

                  // Service Items breakdown
                  if (_serviceItems.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.serviceItems,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._serviceItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.nameController.text} (${item.quantityController.text} × ${double.tryParse(item.priceController.text)?.toStringAsFixed(2) ?? '0'})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Text(
                              '${(item.quantity * item.price).toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]
                  // Service Cost (only if items not added)
                  else if (_serviceCostController.text.isNotEmpty) ...[
                    _buildCostRow(
                      label: AppLocalizations.of(context)!.serviceCost,
                      amount: double.tryParse(_serviceCostController.text) ?? 0,
                    ),
                  ],
                ],

                const Divider(height: 20),

                // Total Cost
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalCost,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${_totalCost.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Files count (if service completed)
                if (_serviceCompleted && selectedFiles.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${selectedFiles.length} ${AppLocalizations.of(context)!.filesAttached}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Confirmation message
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.confirm,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  // Helper method to build cost rows
  Widget _buildCostRow({required String label, required double amount}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _handleComplete() {
    List<BookingServiceItem> items = _serviceCompleted
        ? _serviceItems.map((item) => item.toBookingServiceItem()).toList()
        : [];

    Navigator.of(context).pop();
    context.read<BookingBloc>().add(
      CompleteBooking(
        mode: _serviceCompleted ? 1 : 0,
        bookingId: widget.booking.id,
        selectedFiles: selectedFiles,
        serviceCost: _serviceCompleted && _serviceItems.isEmpty
            ? double.parse(_serviceCostController.text)
            : 0,
        serviceItems: items,
        totalCost: _totalCost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.completeWork,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Service Completed Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _serviceCompleted
                      ? AppColors.primary.withAlpha(30)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _serviceCompleted
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _serviceCompleted
                          ? Icons.check_circle
                          : Icons.search_outlined,
                      color: _serviceCompleted
                          ? AppColors.primary
                          : Colors.grey.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _serviceCompleted
                                ? AppLocalizations.of(context)!.serviceCompleted
                                : AppLocalizations.of(context)!.inspectionOnly,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _serviceCompleted
                                  ? AppColors.primary
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _serviceCompleted
                                ? AppLocalizations.of(
                                    context,
                                  )!.serviceCompletedDescription
                                : AppLocalizations.of(
                                    context,
                                  )!.inspectionOnlyDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _serviceCompleted,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _serviceCompleted = value;
                          if (!value) {
                            _serviceCostController.clear();
                            for (var item in _serviceItems) {
                              item.dispose();
                            }
                            _serviceItems.clear();
                            selectedFiles.clear();
                            _fileError = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Upload Files Section - Only show when service completed
              if (_serviceCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fileError != null
                          ? Colors.red
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${AppLocalizations.of(context)!.uploadFilesTitle}*',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.uploadHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display selected files
                      if (selectedFiles.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedFiles.asMap().entries.map((entry) {
                            int index = entry.key;
                            File file = entry.value;
                            bool isImage = _isImageFile(file.path);

                            return Stack(
                              children: [
                                Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: isImage
                                        ? Image.file(file, fit: BoxFit.cover)
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _getFileIcon(file.path),
                                                size: 40,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: Text(
                                                  file.path.split('/').last,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeFile(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),

                      // Add files button
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickFiles,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _fileError != null
                                  ? Colors.red
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 28,
                                  color: _fileError != null
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedFiles.isEmpty
                                      ? AppLocalizations.of(
                                          context,
                                        )!.tapToUploadFiles
                                      : AppLocalizations.of(
                                          context,
                                        )!.addMoreFiles,
                                  style: TextStyle(
                                    color: _fileError != null
                                        ? Colors.red
                                        : Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_fileError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _fileError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.allowedFileTypes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // Conditional Service Fields - Only show if service completed
              if (_serviceCompleted) ...[
                // Service Cost - Only show if no items added AND service cost is empty
                if (_serviceItems.isEmpty) ...[
                  Text(
                    '${AppLocalizations.of(context)!.serviceCost} *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _serviceCostController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(
                      () {},
                    ), // Triggers rebuild to hide service items
                    validator: (value) {
                      if (!_serviceCompleted || _serviceItems.isNotEmpty) {
                        return null;
                      }
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterServiceCost;
                      }
                      if (double.tryParse(value) == null) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterValidNumber;
                      }
                      if (double.parse(value) <= 0) {
                        return AppLocalizations.of(
                          context,
                        )!.serviceCostMustBeGreaterThanZero;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterServiceCost,
                      prefixIcon: Icon(Icons.money, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Service Items Section - Only show if service cost field is EMPTY
                if (_serviceCostController.text.isEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.serviceItems,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      InkWell(
                        onTap: _addServiceItem,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.addItem,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.serviceItemsCalculationNote,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Service Items list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _serviceItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller:
                                          _serviceItems[index].nameController,
                                      decoration: InputDecoration(
                                        hintText:
                                            '${AppLocalizations.of(context)!.item} ${index + 1}',
                                        isDense: true,
                                        label: Text(
                                          "${AppLocalizations.of(context)!.item} ${index + 1}",
                                        ),

                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      validator: (value) {
                                        if (!_serviceCompleted ||
                                            _serviceItems.isEmpty) {
                                          return null;
                                        }
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.required;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _serviceItems[index]
                                          .quantityController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.qty,
                                        label: Text(
                                          AppLocalizations.of(context)!.qty,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      validator: (value) {
                                        if (!_serviceCompleted ||
                                            _serviceItems.isEmpty) {
                                          return null;
                                        }
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.required;
                                        }
                                        if (double.tryParse(value) == null) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.invalid;
                                        }
                                        if (double.parse(value) <= 0) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.serviceCostMustBeGreaterThanZero;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller:
                                          _serviceItems[index].priceController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.price,
                                        label: Text(
                                          AppLocalizations.of(context)!.price,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      validator: (value) {
                                        if (!_serviceCompleted ||
                                            _serviceItems.isEmpty) {
                                          return null;
                                        }
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.required;
                                        }
                                        if (double.tryParse(value) == null) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.invalid;
                                        }
                                        if (double.parse(value) <= 0) {
                                          return AppLocalizations.of(
                                            context,
                                          )!.serviceCostMustBeGreaterThanZero;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeServiceItem(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              if (_serviceCompleted == false) ...[
                Text(
                  '${AppLocalizations.of(context)!.inspectionFee} ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                IgnorePointer(
                  ignoring: true,
                  child: TextFormField(
                    controller: TextEditingController(
                      text:
                          widget.booking.service.price?.toStringAsFixed(2) ??
                          '0',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterServiceCost,
                      prefixIcon: Icon(Icons.money, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Total Cost
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalCost,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.withAlpha(235),
                      ),
                    ),
                    Text(
                      '${_totalCost.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleCompleteWithConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.complete,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class for service items with validation (UI controller class)
class ServiceItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;

  bool isValid() {
    return nameController.text.isNotEmpty &&
        quantityController.text.isNotEmpty &&
        priceController.text.isNotEmpty &&
        quantity > 0 &&
        price > 0;
  }

  // Convert UI ServiceItem to BookingServiceItem (data class)
  BookingServiceItem toBookingServiceItem() {
    return BookingServiceItem(
      name: nameController.text,
      quantity: quantity,
      price: price,
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
