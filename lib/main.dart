import 'package:aboglumbo_bbk_panel/firebase_options.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/splash.dart';
import 'package:aboglumbo_bbk_panel/providers.dart';
import 'package:aboglumbo_bbk_panel/services/notification.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

// Enhanced Background Fetch Handler
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool timeout = task.timeout;

  print('Background fetch executing: $taskId, timeout: $timeout');

  if (timeout) {
    print('Background fetch timeout for task: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }

  try {
    final String? bookingId = LocalStore.getActiveBookingId();
    final String? uid = LocalStore.getUID();

    if (bookingId == null || bookingId.isEmpty || uid == null) {
      print(
        'No active booking or user ID, skipping background location update',
      );
      BackgroundFetch.finish(taskId);
      return;
    }

    // Check if location services are available
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services disabled, skipping background update');
      BackgroundFetch.finish(taskId);
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('Location permission denied, skipping background update');
      BackgroundFetch.finish(taskId);
      return;
    }

    // Get current position with timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );

    // Update location in Firestore
    await AppFirestore.usersCollectionRef.doc(uid).set({
      'liveLocation': {
        'accuracy': position.accuracy,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'background_fetch',
        'taskId': taskId,
      },
    }, SetOptions(merge: true));

    print(
      'Background location updated successfully: ${position.latitude}, ${position.longitude}',
    );
  } catch (e) {
    print('Error in background fetch: $e');
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

final String hiveBoxName = 'myBox';
GlobalKey<NavigatorState>? navigatorKey = GlobalKey();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox(hiveBoxName);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationServices.initializeNotifications();
  await NotificationServices.setupFCMListeners();
  await NotificationServices.checkForInitialMessage();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  try {
    // Register headless background fetch task
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

    // Configure background fetch with platform-specific settings
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
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        print('Foreground background fetch: $taskId');
        backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
      },
      (String taskId) async {
        print('Background fetch timeout: $taskId');
        backgroundFetchHeadlessTask(HeadlessTask(taskId, true));
      },
    );

    print('Background fetch registration successful');
  } catch (e) {
    print('Background Fetch registration failed: $e');
  }
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  static Box box = Hive.box(hiveBoxName);
  final GlobalKey<NavigatorState>? navigatorKey;
  const MyApp({super.key, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountBloc(),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          return MultiBlocProvider(
            providers: providers,
            child: MaterialApp(
              title: 'Worker Console',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: state.locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
                scaffoldBackgroundColor: AppColors.bgWhite,
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Colors.white,
                  indicatorColor: Colors.transparent,
                  labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return GoogleFonts.dmSans(
                        color: AppColors.darkGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      );
                    }
                    return GoogleFonts.dmSans(
                      color: AppColors.grey,
                      fontSize: 10,
                    );
                  }),
                ),
                dialogTheme: DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                appBarTheme: AppBarTheme(
                  centerTitle: false,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  titleSpacing: 0,
                  titleTextStyle: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                searchBarTheme: SearchBarThemeData(
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(Colors.white),
                  textStyle: WidgetStatePropertyAll(
                    GoogleFonts.dmSans(color: Colors.black45, fontSize: 14),
                  ),
                  constraints: const BoxConstraints(
                    minHeight: 50,
                    maxHeight: 50,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                bottomSheetTheme: const BottomSheetThemeData(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                useMaterial3: true,
              ),
              home: SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
