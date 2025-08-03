import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AppFirestore {
  // customers collection
  static CollectionReference customersCollectionRef = FirebaseFirestore.instance
      .collection('customers');

  // users collection
  static CollectionReference usersCollectionRef = FirebaseFirestore.instance
      .collection('users');

  // locations collection
  static CollectionReference locationsCollectionRef = FirebaseFirestore.instance
      .collection('locations');

  // categories collection
  static CollectionReference categoriesCollectionRef = FirebaseFirestore
      .instance
      .collection('categories');

  // services collection
  static CollectionReference servicesCollectionRef = FirebaseFirestore.instance
      .collection('services');

  // bookings collection
  static CollectionReference bookingsCollectionRef = FirebaseFirestore.instance
      .collection('bookings');

  // highlighted services collection
  static CollectionReference highlightedServicesCollectionRef =
      FirebaseFirestore.instance.collection('highlighted_services');

  // banners collection
  static CollectionReference bannersCollectionRef = FirebaseFirestore.instance
      .collection('banners');
  // notification collection
  static CollectionReference notificationsCollectionRef = FirebaseFirestore
      .instance
      .collection('notifications');
  static CollectionReference tippingCollectionRef = FirebaseFirestore.instance
      .collection('tipping');
}

class AppFireStorage {
  // services images storage
  static Reference servicesStorageRef = FirebaseStorage.instance.ref(
    'services',
  );
  static Reference bannersStorageRef = FirebaseStorage.instance.ref('banners');

  // agent documents storage
  static Reference agentDocStorageRef = FirebaseStorage.instance.ref(
    'agent_doc',
  );

  // Category images storage
  static Reference categoryStorageRef = FirebaseStorage.instance.ref(
    'category',
  );
}
