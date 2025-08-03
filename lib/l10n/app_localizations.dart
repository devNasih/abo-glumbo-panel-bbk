import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Abo Glumbo'**
  String get appName;

  /// No description provided for @appLoginCaption.
  ///
  /// In en, this message translates to:
  /// **'Your go-to app for finding qualified professionals.'**
  String get appLoginCaption;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @byContinuingYouAgreeToOur.
  ///
  /// In en, this message translates to:
  /// **'By Continuing you agree to our'**
  String get byContinuingYouAgreeToOur;

  /// No description provided for @termsOfUseAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **' Terms of use & privacy policy'**
  String get termsOfUseAndPrivacyPolicy;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @manageOrders.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get manageOrders;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @areYouSureYouWantToRejectThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get areYouSureYouWantToRejectThisOrder;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectingOrder.
  ///
  /// In en, this message translates to:
  /// **'Rejecting Order'**
  String get rejectingOrder;

  /// No description provided for @failedToRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject order'**
  String get failedToRejectOrder;

  /// No description provided for @assigningBookingTo.
  ///
  /// In en, this message translates to:
  /// **'Assigning Booking to'**
  String get assigningBookingTo;

  /// No description provided for @failedToAssignBookingTo.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign booking to'**
  String get failedToAssignBookingTo;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get completeOrder;

  /// No description provided for @areYouSureYouWantToCompleteThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to complete this order?'**
  String get areYouSureYouWantToCompleteThisOrder;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @completingOrder.
  ///
  /// In en, this message translates to:
  /// **'Completing Order'**
  String get completingOrder;

  /// No description provided for @failedToCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete order'**
  String get failedToCompleteOrder;

  /// No description provided for @yourAccountHasBeenDeactivatedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated by admin'**
  String get yourAccountHasBeenDeactivatedByAdmin;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign To'**
  String get assignTo;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'agent'**
  String get agent;

  /// No description provided for @assignToUser.
  ///
  /// In en, this message translates to:
  /// **'Assign to user'**
  String get assignToUser;

  /// No description provided for @noAgentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Agents Available'**
  String get noAgentsAvailable;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled For'**
  String get scheduledFor;

  /// No description provided for @noPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'No Pending Orders'**
  String get noPendingOrders;

  /// No description provided for @noAcceptedOrders.
  ///
  /// In en, this message translates to:
  /// **'No Accepted Orders'**
  String get noAcceptedOrders;

  /// No description provided for @noRejectedOrders.
  ///
  /// In en, this message translates to:
  /// **'No Rejected Orders'**
  String get noRejectedOrders;

  /// No description provided for @noCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'No Completed Orders'**
  String get noCompletedOrders;

  /// No description provided for @noCancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'No Canceled Orders'**
  String get noCancelledOrders;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @highlightedServices.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Services'**
  String get highlightedServices;

  /// No description provided for @manageBanners.
  ///
  /// In en, this message translates to:
  /// **'Manage Banners'**
  String get manageBanners;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @bannerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Banner Deleted'**
  String get bannerDeleted;

  /// No description provided for @failedToDeleteBanner.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete Banner'**
  String get failedToDeleteBanner;

  /// No description provided for @failedToSaveBanner.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Banner'**
  String get failedToSaveBanner;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @showInPrimaryBanner.
  ///
  /// In en, this message translates to:
  /// **'Show In Primary Banner'**
  String get showInPrimaryBanner;

  /// No description provided for @ifDisabledItWillShowInSecondaryBanner.
  ///
  /// In en, this message translates to:
  /// **'If disabled, it will show in secondary banner'**
  String get ifDisabledItWillShowInSecondaryBanner;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @failedToSaveHighlightedService.
  ///
  /// In en, this message translates to:
  /// **'Failed to save Highlighted service'**
  String get failedToSaveHighlightedService;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @noServicesSelected.
  ///
  /// In en, this message translates to:
  /// **'No services selected'**
  String get noServicesSelected;

  /// No description provided for @failedToSaveService.
  ///
  /// In en, this message translates to:
  /// **'Failed to save service'**
  String get failedToSaveService;

  /// No description provided for @pleaseVerifyYourIqama.
  ///
  /// In en, this message translates to:
  /// **'Please verify your iqama by checking the confirmation box'**
  String get pleaseVerifyYourIqama;

  /// No description provided for @uploadYourIqama.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Iqama'**
  String get uploadYourIqama;

  /// No description provided for @locationPermissionsAreDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permissions Are Denied'**
  String get locationPermissionsAreDenied;

  /// No description provided for @locationPermissionsArePermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permissions Are Permanently Denied'**
  String get locationPermissionsArePermanentlyDenied;

  /// No description provided for @errorDetectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error Detecting Location'**
  String get errorDetectingLocation;

  /// No description provided for @errorGettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error Getting Address'**
  String get errorGettingAddress;

  /// No description provided for @pleaseSelectYourIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Please Select Your ID Document'**
  String get pleaseSelectYourIdDocument;

  /// No description provided for @pleaseSelectAtLeastOneJobRole.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one job role'**
  String get pleaseSelectAtLeastOneJobRole;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @otpAutoVerified.
  ///
  /// In en, this message translates to:
  /// **'OTP Auto Verified'**
  String get otpAutoVerified;

  /// No description provided for @somethingWentWrongTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong, Try Again'**
  String get somethingWentWrongTryAgain;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP Sent'**
  String get otpSent;

  /// No description provided for @anErrorOccurredPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred, Please Try Again Later'**
  String get anErrorOccurredPleaseTryAgainLater;

  /// No description provided for @pleaseEnterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please Enter A Valid Phone Number'**
  String get pleaseEnterAValidPhoneNumber;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOtp;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterTheOtpSentToTheNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter The OTP Sent To The Number '**
  String get enterTheOtpSentToTheNumber;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myBooking.
  ///
  /// In en, this message translates to:
  /// **'My Booking'**
  String get myBooking;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @searchHere.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get searchHere;

  /// No description provided for @availableServices.
  ///
  /// In en, this message translates to:
  /// **'Available Services'**
  String get availableServices;

  /// No description provided for @failedToLoadLocations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load locations'**
  String get failedToLoadLocations;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @profileManagement.
  ///
  /// In en, this message translates to:
  /// **'Profile Management'**
  String get profileManagement;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name Is Required'**
  String get nameIsRequired;

  /// No description provided for @enterAValidName.
  ///
  /// In en, this message translates to:
  /// **'Enter A Valid Name'**
  String get enterAValidName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email Is Aequired'**
  String get emailIsRequired;

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter A Valid Email'**
  String get enterAValidEmail;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @locationIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Is Required'**
  String get locationIsRequired;

  /// No description provided for @buildingNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Building Number Is Required'**
  String get buildingNumberIsRequired;

  /// No description provided for @streetName.
  ///
  /// In en, this message translates to:
  /// **'Street Name'**
  String get streetName;

  /// No description provided for @streetNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Street Name is Required'**
  String get streetNameIsRequired;

  /// No description provided for @districtName.
  ///
  /// In en, this message translates to:
  /// **'District Name'**
  String get districtName;

  /// No description provided for @districtNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'District Name is Required'**
  String get districtNameIsRequired;

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'City Name'**
  String get cityName;

  /// No description provided for @cityNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'City Name Is Required'**
  String get cityNameIsRequired;

  /// No description provided for @postcode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postcode;

  /// No description provided for @postcodeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Postcode Is Required'**
  String get postcodeIsRequired;

  /// No description provided for @extensionNumber.
  ///
  /// In en, this message translates to:
  /// **'Extension Number'**
  String get extensionNumber;

  /// No description provided for @extensionNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Extension Number Is Required'**
  String get extensionNumberIsRequired;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully'**
  String get accountCreatedSuccessfully;

  /// No description provided for @failedToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account'**
  String get failedToCreateAccount;

  /// No description provided for @pleaseFillTheInputBelowHereToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please fill the input below here to continue'**
  String get pleaseFillTheInputBelowHereToContinue;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @failedToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get failedToLoadContent;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No Address'**
  String get noAddress;

  /// No description provided for @searchForAService.
  ///
  /// In en, this message translates to:
  /// **'Search for a service'**
  String get searchForAService;

  /// No description provided for @jobCategories.
  ///
  /// In en, this message translates to:
  /// **'Job Categories'**
  String get jobCategories;

  /// No description provided for @failedToLoadDataPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Please try again later.'**
  String get failedToLoadDataPleaseTryAgainLater;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found.'**
  String get noBookingsFound;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get searchServices;

  /// No description provided for @noServicesInYourWishlist.
  ///
  /// In en, this message translates to:
  /// **'No services in your wishlist'**
  String get noServicesInYourWishlist;

  /// No description provided for @failedToSaveBooking.
  ///
  /// In en, this message translates to:
  /// **'Failed to save booking'**
  String get failedToSaveBooking;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afterNoon.
  ///
  /// In en, this message translates to:
  /// **'After noon'**
  String get afterNoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @serviceBookedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service Booked Successfully'**
  String get serviceBookedSuccessfully;

  /// No description provided for @checkForBookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Check your booking status in \'My Bookings\' section'**
  String get checkForBookingStatus;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @completeYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Booking'**
  String get completeYourBooking;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @availableTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slot'**
  String get availableTimeSlot;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add Notes'**
  String get addNotes;

  /// No description provided for @cashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash In Hand'**
  String get cashInHand;

  /// No description provided for @netBankingUpiCard.
  ///
  /// In en, this message translates to:
  /// **'Net banking / UPI /Card'**
  String get netBankingUpiCard;

  /// No description provided for @pleaseSelectADate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectADate;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reviewSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted Successfully.'**
  String get reviewSubmittedSuccessfully;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get anErrorOccurred;

  /// No description provided for @submitAReview.
  ///
  /// In en, this message translates to:
  /// **'Submit A Review'**
  String get submitAReview;

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @writeYourReviewHere.
  ///
  /// In en, this message translates to:
  /// **'Write your review here'**
  String get writeYourReviewHere;

  /// No description provided for @pleaseWriteAReview.
  ///
  /// In en, this message translates to:
  /// **'Please write a review'**
  String get pleaseWriteAReview;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Canceled'**
  String get bookingCancelled;

  /// No description provided for @failedToCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel booking'**
  String get failedToCancelBooking;

  /// No description provided for @areYouSureToWantCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to want cancel booking?'**
  String get areYouSureToWantCancelBooking;

  /// No description provided for @youWillBeRefundedTheFullAmount.
  ///
  /// In en, this message translates to:
  /// **'You will be refunded the full amount'**
  String get youWillBeRefundedTheFullAmount;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @failedToLoadServices.
  ///
  /// In en, this message translates to:
  /// **'Failed to load services'**
  String get failedToLoadServices;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write A Review'**
  String get writeAReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted'**
  String get reviewSubmitted;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get requestService;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Service Description'**
  String get serviceDescription;

  /// No description provided for @serviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Service Info'**
  String get serviceInfo;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @customerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer Info'**
  String get customerInfo;

  /// No description provided for @bookingInfo.
  ///
  /// In en, this message translates to:
  /// **'Booking Info'**
  String get bookingInfo;

  /// No description provided for @agentInfo.
  ///
  /// In en, this message translates to:
  /// **'Agent Info'**
  String get agentInfo;

  /// No description provided for @reviewInfo.
  ///
  /// In en, this message translates to:
  /// **'Review Info'**
  String get reviewInfo;

  /// No description provided for @issueImage.
  ///
  /// In en, this message translates to:
  /// **'Issue Image'**
  String get issueImage;

  /// No description provided for @issueVideo.
  ///
  /// In en, this message translates to:
  /// **'Issue Video'**
  String get issueVideo;

  /// No description provided for @tapToZoom.
  ///
  /// In en, this message translates to:
  /// **'Tap to zoom'**
  String get tapToZoom;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @buildingNumber.
  ///
  /// In en, this message translates to:
  /// **'Building Number'**
  String get buildingNumber;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @postCode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postCode;

  /// No description provided for @bookedFor.
  ///
  /// In en, this message translates to:
  /// **'Booked For'**
  String get bookedFor;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentMode;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @bookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Booking Status'**
  String get bookingStatus;

  /// No description provided for @bookingNote.
  ///
  /// In en, this message translates to:
  /// **'Booking Note'**
  String get bookingNote;

  /// No description provided for @bookedAt.
  ///
  /// In en, this message translates to:
  /// **'Booked At'**
  String get bookedAt;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed On'**
  String get reviewedAt;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @manageServices.
  ///
  /// In en, this message translates to:
  /// **'Manage Services'**
  String get manageServices;

  /// No description provided for @manageHighlightedServices.
  ///
  /// In en, this message translates to:
  /// **'Manage Highlighted Services'**
  String get manageHighlightedServices;

  /// No description provided for @manageAgents.
  ///
  /// In en, this message translates to:
  /// **'Manage Agents'**
  String get manageAgents;

  /// No description provided for @pleaseEnterYourEmailToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email to reset password'**
  String get pleaseEnterYourEmailToResetPassword;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your Password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @areYouSureYouWantToApproveAgent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve'**
  String get areYouSureYouWantToApproveAgent;

  /// No description provided for @areYouSureYouWantToDisapproveAgent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disapprove'**
  String get areYouSureYouWantToDisapproveAgent;

  /// No description provided for @yesText.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesText;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleArabic.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get titleArabic;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameArabic.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get nameArabic;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionArabic.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get descriptionArabic;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please Enter A Valid Email Address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @emailNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email Not Registered'**
  String get emailNotRegistered;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid Email Format'**
  String get invalidEmailFormat;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get tooManyRequests;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Reset Password Error'**
  String get resetPasswordError;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Password'**
  String get incorrectPassword;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account Disabled'**
  String get accountDisabled;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid Credentials'**
  String get invalidCredentials;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login Error'**
  String get loginError;

  /// No description provided for @passwordMustBeAtleast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password Must Be At Least 6 Characters Long'**
  String get passwordMustBeAtleast6Characters;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get cancelled;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @bookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked On'**
  String get bookedOn;

  /// No description provided for @agentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Agents Available'**
  String get agentsAvailable;

  /// No description provided for @acceptedAt.
  ///
  /// In en, this message translates to:
  /// **'Accepted At'**
  String get acceptedAt;

  /// No description provided for @rejectedAt.
  ///
  /// In en, this message translates to:
  /// **'Rejected At'**
  String get rejectedAt;

  /// No description provided for @cancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Canceled At'**
  String get cancelledAt;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get completedAt;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @cashOnHands.
  ///
  /// In en, this message translates to:
  /// **'Cash On Hands'**
  String get cashOnHands;

  /// No description provided for @ext.
  ///
  /// In en, this message translates to:
  /// **'Ext'**
  String get ext;

  /// No description provided for @serviceAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service Added Successfully'**
  String get serviceAddedSuccessfully;

  /// No description provided for @serviceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Service Updated Successfully'**
  String get serviceUpdatedSuccessfully;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// No description provided for @pleaseEnterAName.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Name'**
  String get pleaseEnterAName;

  /// No description provided for @pleaseEnterNameInArabic.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Arabic Name'**
  String get pleaseEnterNameInArabic;

  /// No description provided for @textMustBeInArabic.
  ///
  /// In en, this message translates to:
  /// **'Text Must Be In Arabic'**
  String get textMustBeInArabic;

  /// No description provided for @pleaseEnterADescription.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Description'**
  String get pleaseEnterADescription;

  /// No description provided for @pleaseEnterDescriptionInArabic.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Description In Arabic'**
  String get pleaseEnterDescriptionInArabic;

  /// No description provided for @descriptionMustBeInArabic.
  ///
  /// In en, this message translates to:
  /// **'Description Must Be In Arabic'**
  String get descriptionMustBeInArabic;

  /// No description provided for @pleaseEnterAPrice.
  ///
  /// In en, this message translates to:
  /// **'Please Enter A Price'**
  String get pleaseEnterAPrice;

  /// No description provided for @pleaseSelectACategory.
  ///
  /// In en, this message translates to:
  /// **'Please Select Category'**
  String get pleaseSelectACategory;

  /// No description provided for @highlightedServiceAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Service Added Successfully'**
  String get highlightedServiceAddedSuccessfully;

  /// No description provided for @highlightedServiceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Service Updated Successfully'**
  String get highlightedServiceUpdatedSuccessfully;

  /// No description provided for @selectServices.
  ///
  /// In en, this message translates to:
  /// **'Select Services'**
  String get selectServices;

  /// No description provided for @addHighlightedService.
  ///
  /// In en, this message translates to:
  /// **'Add Highlighted Service'**
  String get addHighlightedService;

  /// No description provided for @editHighlightedService.
  ///
  /// In en, this message translates to:
  /// **'Edit Highlighted Service'**
  String get editHighlightedService;

  /// No description provided for @pleaseEnterATitle.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Title'**
  String get pleaseEnterATitle;

  /// No description provided for @pleaseEnterTheTitleInArabic.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Arabic Title'**
  String get pleaseEnterTheTitleInArabic;

  /// No description provided for @addBanner.
  ///
  /// In en, this message translates to:
  /// **'Add Banner'**
  String get addBanner;

  /// No description provided for @editBanner.
  ///
  /// In en, this message translates to:
  /// **'Edit Banner'**
  String get editBanner;

  /// No description provided for @labelIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Label Is Required'**
  String get labelIsRequired;

  /// No description provided for @urlIsRequired.
  ///
  /// In en, this message translates to:
  /// **'URL Is Required'**
  String get urlIsRequired;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @bannerAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Banner Added Successfully'**
  String get bannerAddedSuccessfully;

  /// No description provided for @bannerUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Banner Updated Successfully'**
  String get bannerUpdatedSuccessfully;

  /// No description provided for @doYouWantToUploadThisImage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to upload this image?'**
  String get doYouWantToUploadThisImage;

  /// No description provided for @pleaseSelectAnImage.
  ///
  /// In en, this message translates to:
  /// **'Please Select An Image'**
  String get pleaseSelectAnImage;

  /// No description provided for @hasBeenApprovedAsAnAgent.
  ///
  /// In en, this message translates to:
  /// **'has been approved as an agent'**
  String get hasBeenApprovedAsAnAgent;

  /// No description provided for @hasBeenDisapprovedAsAnAgent.
  ///
  /// In en, this message translates to:
  /// **'has been disapproved as an agent'**
  String get hasBeenDisapprovedAsAnAgent;

  /// No description provided for @jobRoles.
  ///
  /// In en, this message translates to:
  /// **'Job Roles'**
  String get jobRoles;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @jobRolesAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Job Roles Are Required'**
  String get jobRolesAreRequired;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Confirm Your Password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords Do Not Match'**
  String get passwordsDoNotMatch;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @selectJobRoles.
  ///
  /// In en, this message translates to:
  /// **'Select Job Roles'**
  String get selectJobRoles;

  /// No description provided for @failedToDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect location'**
  String get failedToDetectLocation;

  /// No description provided for @failedToGetAddress.
  ///
  /// In en, this message translates to:
  /// **'Failed to get address'**
  String get failedToGetAddress;

  /// No description provided for @addCustomJobRoles.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Job Roles'**
  String get addCustomJobRoles;

  /// No description provided for @enterAdditionalJobRoles.
  ///
  /// In en, this message translates to:
  /// **'Enter Additional Job Roles'**
  String get enterAdditionalJobRoles;

  /// No description provided for @detectCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Detect Current Location'**
  String get detectCurrentLocation;

  /// No description provided for @failedToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get failedToGetLocation;

  /// No description provided for @cannotCompleteTasksScheduledForTheFuture.
  ///
  /// In en, this message translates to:
  /// **'Cannot complete tasks scheduled for the future'**
  String get cannotCompleteTasksScheduledForTheFuture;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @failedToLoadUserData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data'**
  String get failedToLoadUserData;

  /// No description provided for @areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone'**
  String get areYouSureYouWantToDeleteYourAccountThisActionCannotBeUndone;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @bookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking Accepted'**
  String get bookingAccepted;

  /// No description provided for @yourBookingRequestHasBeenAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been accepted! Our team will contact you shortly.'**
  String get yourBookingRequestHasBeenAccepted;

  /// No description provided for @bookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking Rejected'**
  String get bookingRejected;

  /// No description provided for @yourBookingRequestHasBeenRejected.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your booking request has been rejected. Please try again or contact support.'**
  String get yourBookingRequestHasBeenRejected;

  /// No description provided for @sendingNotification.
  ///
  /// In en, this message translates to:
  /// **'Sending notification to customer'**
  String get sendingNotification;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to customer'**
  String get notificationSent;

  /// No description provided for @bookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Booking Completed'**
  String get bookingCompleted;

  /// No description provided for @yourBookingHasBeenCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your booking has been completed!'**
  String get yourBookingHasBeenCompleted;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pleaseWaitAccountVerification.
  ///
  /// In en, this message translates to:
  /// **'Your account is being verified by the admin, check back later'**
  String get pleaseWaitAccountVerification;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @deleteRegistrationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your registration?'**
  String get deleteRegistrationConfirmation;

  /// No description provided for @phoneNumberAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already exists'**
  String get phoneNumberAlreadyExists;

  /// No description provided for @keepImage.
  ///
  /// In en, this message translates to:
  /// **'Keep Image'**
  String get keepImage;

  /// No description provided for @keepImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Do you want to keep the selected image without cropping?'**
  String get keepImageDescription;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @pleaseSelectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get pleaseSelectAtLeastOneService;

  /// No description provided for @deleteBannerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this banner?'**
  String get deleteBannerConfirmation;

  /// No description provided for @selectLocations.
  ///
  /// In en, this message translates to:
  /// **'Select Locations'**
  String get selectLocations;

  /// No description provided for @tapToSelectLocations.
  ///
  /// In en, this message translates to:
  /// **'Tap to select locations'**
  String get tapToSelectLocations;

  /// No description provided for @locationsSelected.
  ///
  /// In en, this message translates to:
  /// **'Locations Selected'**
  String get locationsSelected;

  /// No description provided for @locationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location Selected'**
  String get locationSelected;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocation;

  /// No description provided for @noLocationsFound.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get noLocationsFound;

  /// No description provided for @accountVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently under review by our admin team.'**
  String get accountVerificationPending;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @enterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterAValidPhoneNumber;

  /// No description provided for @manageTips.
  ///
  /// In en, this message translates to:
  /// **'Manage Tips'**
  String get manageTips;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get startWork;

  /// No description provided for @pleaseEnterSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Please enter sort order'**
  String get pleaseEnterSortOrder;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @categoryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully'**
  String get categoryAddedSuccessfully;

  /// No description provided for @categoryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully'**
  String get categoryUpdatedSuccessfully;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number is invalid'**
  String get phoneNumberInvalid;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @pleaseSelectALocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectALocation;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get justNow;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists'**
  String get emailAlreadyExists;

  /// No description provided for @tippingCleared.
  ///
  /// In en, this message translates to:
  /// **'Tipping cleared'**
  String get tippingCleared;

  /// No description provided for @failedToClearTipping.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear tipping'**
  String get failedToClearTipping;

  /// No description provided for @manageTipping.
  ///
  /// In en, this message translates to:
  /// **'Manage Tipping'**
  String get manageTipping;

  /// No description provided for @noTipsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tips available'**
  String get noTipsAvailable;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @tipInfo.
  ///
  /// In en, this message translates to:
  /// **'Tip info'**
  String get tipInfo;

  /// No description provided for @totalTips.
  ///
  /// In en, this message translates to:
  /// **'Total tips'**
  String get totalTips;

  /// No description provided for @lastTipAmount.
  ///
  /// In en, this message translates to:
  /// **'Last tip amount'**
  String get lastTipAmount;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @agentId.
  ///
  /// In en, this message translates to:
  /// **'Agent ID'**
  String get agentId;

  /// No description provided for @sendAndClearWallet.
  ///
  /// In en, this message translates to:
  /// **'Send & Clear Wallet'**
  String get sendAndClearWallet;

  /// No description provided for @clearWallet.
  ///
  /// In en, this message translates to:
  /// **'Clear Wallet'**
  String get clearWallet;

  /// No description provided for @clearWalletWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The agent will receive the total amount in their wallet, and it will be reset to zero.'**
  String get clearWalletWarning;

  /// No description provided for @areYouSureYouWantToSend.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to send'**
  String get areYouSureYouWantToSend;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @andClearTheirWallet.
  ///
  /// In en, this message translates to:
  /// **'and clear their wallet'**
  String get andClearTheirWallet;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied forever'**
  String get locationPermissionDeniedForever;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @completeWork.
  ///
  /// In en, this message translates to:
  /// **'Complete Work'**
  String get completeWork;

  /// No description provided for @locationServiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Location service is required'**
  String get locationServiceRequired;

  /// No description provided for @pleaseEnableLocationService.
  ///
  /// In en, this message translates to:
  /// **'Please enable location service'**
  String get pleaseEnableLocationService;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @bioMetricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get bioMetricAuthentication;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking'**
  String get startTracking;

  /// No description provided for @stopTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking'**
  String get stopTracking;

  /// No description provided for @youHaveActiveBooking.
  ///
  /// In en, this message translates to:
  /// **'You have an active booking'**
  String get youHaveActiveBooking;

  /// No description provided for @areYouSureYouWantToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to start tracking for this booking? This will enable location monitoring.'**
  String get areYouSureYouWantToStartTracking;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @areYouSureYouWantToStopTracking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop tracking for this booking? Location monitoring will be disabled.'**
  String get areYouSureYouWantToStopTracking;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @failedToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Failed to start tracking'**
  String get failedToStartTracking;

  /// No description provided for @trackingStarted.
  ///
  /// In en, this message translates to:
  /// **'Tracking started'**
  String get trackingStarted;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @trackingNote.
  ///
  /// In en, this message translates to:
  /// **'Note: If you’re starting the work, please click the “Start Tracking” button. In case the button gets cut off or changes, make sure to click “Start Tracking” again.'**
  String get trackingNote;

  /// No description provided for @filterByLocation.
  ///
  /// In en, this message translates to:
  /// **'Filter by Location'**
  String get filterByLocation;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// No description provided for @inSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'In Selected Location'**
  String get inSelectedLocation;

  /// No description provided for @totalAgents.
  ///
  /// In en, this message translates to:
  /// **'Total Agents'**
  String get totalAgents;

  /// No description provided for @filteredBy.
  ///
  /// In en, this message translates to:
  /// **'Filtered by'**
  String get filteredBy;

  /// No description provided for @showAllAgents.
  ///
  /// In en, this message translates to:
  /// **'Show All Agents'**
  String get showAllAgents;

  /// No description provided for @notificationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Notification Language'**
  String get notificationLanguage;

  /// No description provided for @areYouSureYouWantToCancelThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get areYouSureYouWantToCancelThisBooking;

  /// No description provided for @bookingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Booking Timeline'**
  String get bookingTimeline;

  /// No description provided for @trackingStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Tracking started at'**
  String get trackingStartedAt;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @enableBiometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get enableBiometricAuthentication;

  /// No description provided for @notificationLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Notification language updated'**
  String get notificationLanguageUpdated;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @issueMedia.
  ///
  /// In en, this message translates to:
  /// **'Issue Media'**
  String get issueMedia;

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading Video'**
  String get loadingVideo;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Category already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @errorLoadingDistricts.
  ///
  /// In en, this message translates to:
  /// **'Error loading districts'**
  String get errorLoadingDistricts;

  /// No description provided for @noLocationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No locations available'**
  String get noLocationsAvailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter Password to Confirm'**
  String get enterPasswordToConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone'**
  String get deleteAccountWarning;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @walletClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Wallet cleared successfully'**
  String get walletClearedSuccessfully;

  /// No description provided for @biometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometric not supported'**
  String get biometricNotSupported;

  /// No description provided for @pleaseAuthenticateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to continue'**
  String get pleaseAuthenticateToContinue;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric not available'**
  String get biometricNotAvailable;

  /// No description provided for @biometricTemporarilyLocked.
  ///
  /// In en, this message translates to:
  /// **'Biometric temporarily locked'**
  String get biometricTemporarilyLocked;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedErrorOccurred;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'Ago'**
  String get ago;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @languageCode.
  ///
  /// In en, this message translates to:
  /// **'Language Code'**
  String get languageCode;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @adminStatus.
  ///
  /// In en, this message translates to:
  /// **'Admin Status'**
  String get adminStatus;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @systemInformation.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInformation;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @assignedRoles.
  ///
  /// In en, this message translates to:
  /// **'Assigned Roles'**
  String get assignedRoles;

  /// No description provided for @noAgentsFound.
  ///
  /// In en, this message translates to:
  /// **'No agents found'**
  String get noAgentsFound;

  /// No description provided for @agentApproved.
  ///
  /// In en, this message translates to:
  /// **'Agent Approved'**
  String get agentApproved;

  /// No description provided for @agentDisapproved.
  ///
  /// In en, this message translates to:
  /// **'Agent Disapproved'**
  String get agentDisapproved;

  /// No description provided for @deleteBanner.
  ///
  /// In en, this message translates to:
  /// **'Delete Banner'**
  String get deleteBanner;

  /// No description provided for @invalidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid Image URL'**
  String get invalidImageUrl;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Image load error'**
  String get imageLoadError;

  /// No description provided for @imageCropError.
  ///
  /// In en, this message translates to:
  /// **'Image crop error'**
  String get imageCropError;

  /// No description provided for @errorAddingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error adding category'**
  String get errorAddingCategory;

  /// No description provided for @errorUpdatingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error updating category'**
  String get errorUpdatingCategory;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @failedToSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification to customer'**
  String get failedToSendNotification;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
