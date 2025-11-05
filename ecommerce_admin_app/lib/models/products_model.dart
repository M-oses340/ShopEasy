import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsModel {
  final String name;
  final String description;
  final String image;
  final double old_price;
  final double new_price;
  final String category;
  final String id;
  final int maxQuantity;

  ProductsModel({
    required this.name,
    required this.description,
    required this.image,
    required this.old_price,
    required this.new_price,
    required this.category,
    required this.id,
    required this.maxQuantity,
  });

  factory ProductsModel.fromJson(Map<String, dynamic>? json, String id) {
    if (json == null) {
      return ProductsModel(
        name: '',
        description: '',
        image: '',
        old_price: 0,
        new_price: 0,
        category: '',
        id: id,
        maxQuantity: 0,
      );
    }

    return ProductsModel(
      name: json['name']?.toString() ?? '',
      description: json['desc']?.toString() ?? 'no description',
      image: json['image']?.toString() ?? '',
      new_price: (json['new_price'] is num)
          ? (json['new_price'] as num).toDouble()
          : 0.0,
      old_price: (json['old_price'] is num)
          ? (json['old_price'] as num).toDouble()
          : 0.0,
      category: json['category']?.toString() ?? '',
      maxQuantity: (json['quantity'] is int)
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      id: id,
    );
  }

  static List<ProductsModel> fromJsonList(List<QueryDocumentSnapshot> list) {
    return list.map((doc) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        return ProductsModel.fromJson(data, doc.id);
      } else {
        return ProductsModel(
          name: '',
          description: '',
          image: '',
          old_price: 0,
          new_price: 0,
          category: '',
          id: doc.id,
          maxQuantity: 0,
        );
      }
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'desc': description,
      'image': image,
      'old_price': old_price,
      'new_price': new_price,
      'category': category,
      'quantity': maxQuantity,
    };
  }
}
