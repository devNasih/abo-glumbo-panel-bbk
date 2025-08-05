import 'dart:async';
import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/services/battery_optimization_service.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// App lifecycle observer to monitor app background/foreground state
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final BookingTrackerService _service;

  _AppLifecycleObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _service._onAppEnterBackground();
        break;
      case AppLifecycleState.resumed:
        _service._onAppEnterForeground();
        break;
      case AppLifecycleState.inactive:
        // Do nothing for now
        break;
      case AppLifecycleState.hidden:
        _service._onAppEnterBackground();
        break;
    }
  }
}

class BookingTrackerService {
  static final BookingTrackerService _instance =
      BookingTrackerService._internal();
  factory BookingTrackerService() => _instance;
  BookingTrackerService._internal() {
    _initializeTrackingState();
    _initializeBackgroundAppState();
  }

  final ValueNotifier<bool> isTracking = ValueNotifier(false);
  StreamSubscription<Position>? _positionStream;
  String? _bookingId;
  Timer? _backgroundLocationTimer;
  bool _isAppInBackground = false;
  _AppLifecycleObserver? _lifecycleObserver;

  /// Initialize background app state monitoring
  void _initializeBackgroundAppState() {
    _lifecycleObserver = _AppLifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
  }

  /// Called when app goes to background
  void _onAppEnterBackground() {
    _isAppInBackground = true;
    if (isTracking.value && _bookingId != null) {
      _startBackgroundLocationTimer();
    }
  }

  /// Called when app comes to foreground
  void _onAppEnterForeground() {
    _isAppInBackground = false;
    _stopBackgroundLocationTimer();
    if (isTracking.value && _bookingId != null) {
      _restoreLocationTracking();
    }
  }

  /// Start background location timer for when app is backgrounded
  void _startBackgroundLocationTimer() {
    _stopBackgroundLocationTimer(); // Stop any existing timer

    // For iOS, use shorter intervals due to background app refresh limitations
    final interval = Platform.isIOS ? 30 : 60; // seconds

    _backgroundLocationTimer = Timer.periodic(Duration(seconds: interval), (
      timer,
    ) async {
      if (!isTracking.value || _bookingId == null) {
        timer.cancel();
        return;
      }
      await _updateLocationInBackground();
    });
  }

  /// Stop background location timer
  void _stopBackgroundLocationTimer() {
    _backgroundLocationTimer?.cancel();
    _backgroundLocationTimer = null;
  }

  /// Update location when app is in background
  Future<void> _updateLocationInBackground() async {
    try {
      final uid = LocalStore.getUID();
      if (uid == null) return;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.medium, // Use medium for battery saving
        timeLimit: const Duration(seconds: 10),
      );

      await AppFirestore.usersCollectionRef.doc(uid).set({
        'liveLocation': {
          'accuracy': position.accuracy,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'source': 'background',
        },
      }, SetOptions(merge: true));

      print(
        'Background location updated: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('Error updating background location: $e');
    }
  }

  Future<void> _initializeTrackingState() async {
    try {
      final activeBookingId = LocalStore.getActiveBookingId();
      if (activeBookingId != null && activeBookingId.isNotEmpty) {
        final bookingDoc = await AppFirestore.bookingsCollectionRef
            .doc(activeBookingId)
            .get();

        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data() as Map<String, dynamic>?;
          final isStarted = bookingData?['isStarted'] ?? false;
          final isStartTracking = bookingData?['isStartTracking'] ?? false;

          if (isStarted && isStartTracking) {
            isTracking.value = true;
            _bookingId = activeBookingId;
            // Restart location tracking if it was active
            _restoreLocationTracking();
          } else {
            // Clear invalid active booking ID
            LocalStore.setActiveBookingId('');
          }
        } else {
          // Clear invalid active booking ID
          LocalStore.setActiveBookingId('');
        }
      }
    } catch (e) {
      // If there's an error, reset the state
      LocalStore.setActiveBookingId('');
      isTracking.value = false;
    }
  }

  Future<void> _restoreLocationTracking() async {
    if (!isTracking.value || _bookingId == null) return;

    try {
      final uid = LocalStore.getUID();
      if (uid == null) return;

      // Check if location services are still enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled, cannot restore tracking');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied, cannot restore tracking');
        return;
      }

      // Restart foreground location updates with enhanced settings
      _positionStream?.cancel(); // Cancel any existing stream
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: _getLocationSettings(),
          ).listen(
            (Position position) async {
              await _updateLocationToFirestore(position, uid, 'foreground');
            },
            onError: (error) {
              print('Location stream error during restore: $error');
              // Try to restart after a delay
              Timer(const Duration(seconds: 5), () {
                if (isTracking.value) {
                  _restoreLocationTracking();
                }
              });
            },
          );

      print('Location tracking restored successfully');
    } catch (e) {
      print('Error restoring location tracking: $e');
    }
  }

  Future<void> startWorking({
    required BuildContext context,
    required String bookingId,
    required String uid,
  }) async {
    final docs = await AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'A')
        .where('isStarted', isEqualTo: true)
        .get();

    if (docs.docs.isNotEmpty) {
      throw Exception("You have an active booking already.");
    }

    // Enhanced location permissions check
    await _requestLocationPermissions();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        "Location services disabled. Please enable location services.",
      );
    }

    await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
      'isStarted': true,
      'isStartTracking': true,
      'trackingStartedAt': FieldValue.serverTimestamp(),
    });

    LocalStore.setActiveBookingId(bookingId);
    _bookingId = bookingId;

    // Start foreground location updates with better settings
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: _getLocationSettings(),
        ).listen(
          (Position position) async {
            await _updateLocationToFirestore(position, uid, 'foreground');
          },
          onError: (error) {
            print('Location stream error: $error');
            // Try to restart the stream after a delay
            Timer(const Duration(seconds: 5), () {
              if (isTracking.value) {
                _restoreLocationTracking();
              }
            });
          },
        );

    // Enhanced background fetch configuration
    await _configureBackgroundFetch();

    isTracking.value = true;
  }

  /// Enhanced location permissions request
  Future<void> _requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        "Location permission denied. Please grant location permission to continue.",
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied. Please enable location access in Settings.",
      );
    }

    // For Android 10+ and iOS, request "Always" permission for background location
    if (permission == LocationPermission.whileInUse) {
      if (Platform.isAndroid) {
        // On Android, show dialog explaining why we need always permission
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          throw Exception(
            "Background location permission required. Please select 'Allow all the time' for location access.",
          );
        }
      } else if (Platform.isIOS) {
        // On iOS, the app needs to handle this gracefully
        // The background app refresh will handle background location
        print("iOS: Background location will use background app refresh");
      }
    }

    // Check battery optimization on Android
    if (Platform.isAndroid) {
      await _checkBatteryOptimization();
    }
  }

  /// Check and request battery optimization exemption on Android
  Future<void> _checkBatteryOptimization() async {
    try {
      bool isOptimizationDisabled =
          await BatteryOptimizationService.isBatteryOptimizationDisabled();
      if (!isOptimizationDisabled) {
        print(
          'Battery optimization is enabled, may affect background location',
        );
        // Note: We don't force the user to disable it, but we inform them
        // You can show a dialog here if needed
      }
    } catch (e) {
      print('Error checking battery optimization: $e');
    }
  }

  /// Get optimized location settings based on platform
  LocationSettings _getLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Tracking your location for service delivery",
          notificationTitle: "Abo Glumbo - Location Tracking",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
  }

  /// Update location to Firestore with better error handling
  Future<void> _updateLocationToFirestore(
    Position position,
    String uid,
    String source,
  ) async {
    try {
      await AppFirestore.usersCollectionRef.doc(uid).set({
        'liveLocation': {
          'accuracy': position.accuracy,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'source': source,
          'speed': position.speed,
          'heading': position.heading,
          'altitude': position.altitude,
        },
      }, SetOptions(merge: true));

      print(
        'Location updated ($source): ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('Error updating location to Firestore: $e');
    }
  }

  /// Configure background fetch with enhanced settings
  Future<void> _configureBackgroundFetch() async {
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: Platform.isIOS
              ? 15
              : 30, // iOS needs more frequent updates
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ),
        (String taskId) async {
          print('Background fetch triggered: $taskId');
          backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
        },
        (String taskId) async {
          print('Background fetch timeout: $taskId');
          backgroundFetchHeadlessTask(HeadlessTask(taskId, true));
        },
      );

      await BackgroundFetch.start();
      print('Background fetch configured and started');
    } catch (e) {
      print('Error configuring background fetch: $e');
    }
  }

  Future<void> stopTracking() async {
    // Clean up all tracking resources
    _positionStream?.cancel();
    _positionStream = null;

    _stopBackgroundLocationTimer();

    try {
      await BackgroundFetch.stop();
    } catch (e) {
      print('Error stopping background fetch: $e');
    }

    if (_bookingId != null) {
      try {
        await AppFirestore.bookingsCollectionRef.doc(_bookingId).update({
          'isStarted': false,
          'isStartTracking': false,
          'trackingStoppedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating booking status: $e');
      }
    }

    LocalStore.setActiveBookingId('');
    _bookingId = null;
    isTracking.value = false;

    print('Location tracking stopped');
  }

  /// Dispose resources when service is no longer needed
  void dispose() {
    _positionStream?.cancel();
    _stopBackgroundLocationTimer();
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    BackgroundFetch.stop();
  }
}
