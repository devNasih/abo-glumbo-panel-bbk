// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

import 'categories.dart';

class ServiceModel {
  String? id;

  String? name;
  String? name_ar;
  String? nameLocalized({required String languageCode}) {
    if (languageCode == 'ar') {
      return name_ar;
    }
    return name;
  }

  String? description;
  String? description_ar;
  String? descriptionLocalized({required String languageCode}) {
    if (languageCode == 'ar') {
      return description_ar;
    }
    return description;
  }

  String? image;
  double? rating;

  // the price in its lowest form
  double? price;

  String? category;
  String? categoryNameFilled;
  List<String>? specialSection;

  bool isActive;

  // timestamps
  Timestamp? createdAt;
  Timestamp? updatedAt;
  List<String?> locations;

  ServiceModel({
    this.id,
    this.name,
    this.name_ar,
    this.description,
    this.description_ar,
    this.image,
    this.rating,
    this.price,
    this.category,
    this.specialSection,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.categoryNameFilled,
    this.locations = const [],
  });

  // copyWith method
  ServiceModel copyWith({
    String? id,
    String? name,
    String? name_ar,
    String? description,
    String? description_ar,
    String? image,
    double? rating,
    double? price,
    String? category,
    List<String>? specialSection,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
    List<CategoryModel>? categories,
    List<String?>? locations,
  }) {
    String? categoryName;
    if (categories != null && this.category != null) {
      categoryName =
          categories.firstWhere((element) => element.id == this.category).name;
    }
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      name_ar: name_ar ?? this.name_ar,
      description: description ?? this.description,
      description_ar: description_ar ?? this.description_ar,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      category: category ?? this.category,
      specialSection: specialSection ?? this.specialSection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      categoryNameFilled: categoryName,
      locations: locations ?? this.locations,
    );
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      name_ar: json['name_ar'] ?? json['name'],
      description: json['description'],
      description_ar: json['description_ar'] ?? json['description'],
      image: json['image'],
      rating: json['rating'],
      price: (json['price'] != null)
          ? (json['price'] is int
              ? (json['price'] as int).toDouble()
              : json['price'] as double)
          : 0.0,
      category: json['category'],
      specialSection: json['specialSection']?.cast<String>(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isActive: json['isActive'],
      locations: json['locations']?.cast<String?>() ?? [],
    );
  }

  // from firebase query document snapshot
  factory ServiceModel.fromQueryDocumentSnapshot(
      QueryDocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return ServiceModel(
      id: snapshot.id,
      name: data['name'],
      name_ar: data['name_ar'] ?? data['name'],
      description: data['description'],
      description_ar: data['description_ar'] ?? data['description'],
      image: data['image'],
      rating: data['rating'],
      price: (data['price'] != null)
          ? (data['price'] is int
              ? (data['price'] as int).toDouble()
              : data['price'] as double)
          : 0.0,
      category: data['category'],
      specialSection: data['specialSection']?.cast<String>(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      isActive: data['isActive'],
      locations: data['locations']?.cast<String?>() ?? [],
    );
  }

  // from firebase document snapshot
  factory ServiceModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return ServiceModel(
      id: snapshot.id,
      name: data['name'],
      name_ar: data['name_ar'] ?? data['name'],
      description: data['description'],
      description_ar: data['description_ar'] ?? data['description'],
      image: data['image'],
      rating: data['rating'],
      price: (data['price'] != null)
          ? (data['price'] is int
              ? (data['price'] as int).toDouble()
              : data['price'] as double)
          : 0.0,
      category: data['category'],
      specialSection: data['specialSection']?.cast<String>(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      isActive: data['isActive'],
      locations: data['locations']?.cast<String?>() ?? [],
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'name_ar': name_ar,
      'description': description,
      'description_ar': description_ar,
      'image': image,
      'rating': rating,
      'price': price,
      'category': category,
      'specialSection': specialSection,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'locations': locations,
    };
    if (id != null) {
      json['id'] = id;
    }
    return json;
  }

  // to fire edit json
  Map<String, dynamic> toEditJson({required ServiceModel previous}) {
    Map<String, dynamic> json = {};
    if (name != previous.name && name != null) {
      json['name'] = name;
    }
    if (name_ar != previous.name_ar && name_ar != null) {
      json['name_ar'] = name_ar;
    }
    if (description != previous.description && description != null) {
      json['description'] = description;
    }
    if (description_ar != previous.description_ar && description_ar != null) {
      json['description_ar'] = description_ar;
    }
    if (image != previous.image && image != null) {
      json['image'] = image;
    }
    if (rating != previous.rating && rating != null) {
      json['rating'] = rating;
    }
    if (price != previous.price && price != null) {
      json['price'] = price;
    }
    if (category != previous.category && category != null) {
      json['category'] = category;
    }
    if (specialSection != previous.specialSection && specialSection != null) {
      json['specialSection'] = specialSection;
    }
    if (createdAt != previous.createdAt && createdAt != null) {
      json['createdAt'] = createdAt;
    }
    if (updatedAt != previous.updatedAt && updatedAt != null) {
      json['updatedAt'] = updatedAt;
    }
    if (isActive != previous.isActive) {
      json['isActive'] = isActive;
    }
    if (locations != previous.locations) {
      json['locations'] = locations;
    }
    return json;
  }
}
