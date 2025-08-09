import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:aboglumbo_bbk_panel/services/battery_optimization_service.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

/// Enhanced location tracking widget with comprehensive controls and status
class LocationTrackingWidget extends StatefulWidget {
  final String bookingId;
  final String uid;

  const LocationTrackingWidget({
    super.key,
    required this.bookingId,
    required this.uid,
  });

  @override
  State<LocationTrackingWidget> createState() => _LocationTrackingWidgetState();
}

class _LocationTrackingWidgetState extends State<LocationTrackingWidget> {
  final BookingTrackerService _trackerService = BookingTrackerService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _batteryOptimizationChecked = false;

  @override
  void initState() {
    super.initState();
    _checkBatteryOptimization();
  }

  /// Check battery optimization status on Android
  Future<void> _checkBatteryOptimization() async {
    try {
      final isDisabled =
          await BatteryOptimizationService.isBatteryOptimizationDisabled();
      setState(() {
        _batteryOptimizationChecked = isDisabled;
      });
    } catch (e) {
      print('Error checking battery optimization: $e');
    }
  }

  /// Start location tracking with comprehensive error handling
  Future<void> _startTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _trackerService.startWorking(
        context: context,
        bookingId: widget.bookingId,
        uid: widget.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location tracking started successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Stop location tracking
  Future<void> _stopTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _trackerService.stopTracking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location tracking stopped'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Show error dialog with helpful information
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error),
              const SizedBox(height: 16),
              if (error.contains('permission') ||
                  error.contains('Privacy & Security'))
                Text(
                  'Please grant location permission in Settings and select "Allow all the time" for background tracking.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (error.contains('services'))
                Text(
                  'Please enable location services in your device settings.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (error.contains('PlatformException') && error.contains('1'))
                Text(
                  'This is an iOS location permission error. Please check your location settings.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  /// Show battery optimization dialog for Android users
  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'For reliable background location tracking, please disable battery optimization for this app. This ensures location updates continue even when the app is in the background.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await BatteryOptimizationService.requestDisableBatteryOptimization();
                _checkBatteryOptimization();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Location Tracking',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status indicator
            ValueListenableBuilder<bool>(
              valueListenable: _trackerService.isTracking,
              builder: (context, isTracking, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isTracking
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTracking ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: isTracking
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTracking ? 'Tracking Active' : 'Tracking Inactive',
                        style: TextStyle(
                          color: isTracking
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Battery optimization warning (Android only)
            if (!_batteryOptimizationChecked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.battery_alert, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Battery optimization is enabled. This may affect background location tracking.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showBatteryOptimizationDialog,
                      child: const Text('Fix'),
                    ),
                  ],
                ),
              ),

            if (!_batteryOptimizationChecked) const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Control buttons
            ValueListenableBuilder<bool>(
              valueListenable: _trackerService.isTracking,
              builder: (context, isTracking, child) {
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : isTracking
                            ? _stopTracking
                            : _startTracking,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(isTracking ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          isTracking
                              ? AppLocalizations.of(context)!.stopTracking
                              : AppLocalizations.of(context)!.startTracking,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTracking
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            // Help text
            Text(
              'Location tracking helps customers track your progress. Make sure to keep location services enabled.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
