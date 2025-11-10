import 'package:cloud_firestore/cloud_firestore.dart';

class DbService {
  // Singleton pattern
  DbService._privateConstructor();
  static final DbService instance = DbService._privateConstructor();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ensures a collection exists by creating a hidden placeholder document if empty
  Future<void> _ensureCollection(String collection) async {
    final snapshot = await _db.collection(collection).limit(1).get();
    if (snapshot.docs.isEmpty) {
      await _db.collection(collection).add({
        "_init": true,
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Created missing collection: $collection");
    }
  }

  /// Generic Create
  Future<void> createDoc(String collection, Map<String, dynamic> data) async {
    await _ensureCollection(collection);
    await _db.collection(collection).add(data);
  }

  /// Generic Update
  Future<void> updateDoc(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  /// Generic Delete
  Future<void> deleteDoc(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  /// Generic Stream Reader with optional ordering
  Stream<QuerySnapshot> readCollection(
      String collection, {
        String? orderBy,
        bool descending = false,
      }) {
    Query ref = _db.collection(collection);
    if (orderBy != null) ref = ref.orderBy(orderBy, descending: descending);
    return ref.snapshots();
  }

  /// Promo/Banner helper
  String _promoOrBannerCollection(bool isPromo) => isPromo ? "shop_promos" : "shop_banners";

  // ---------------- COLLECTION-SPECIFIC METHODS ----------------

  // Categories
  Stream<QuerySnapshot> readCategories() => readCollection("shop_categories", orderBy: "priority", descending: true);
  Future createCategory(Map<String, dynamic> data) => createDoc("shop_categories", data);
  Future updateCategory(String docId, Map<String, dynamic> data) => updateDoc("shop_categories", docId, data);
  Future deleteCategory(String docId) => deleteDoc("shop_categories", docId);

  // Products
  Stream<QuerySnapshot> readProducts() => readCollection("shop_products", orderBy: "category", descending: true);
  Future createProduct(Map<String, dynamic> data) => createDoc("shop_products", data);
  Future updateProduct(String docId, Map<String, dynamic> data) => updateDoc("shop_products", docId, data);
  Future<void> deleteProduct({required String docId}) =>
      deleteDoc("shop_products", docId);



  // Coupons
  Stream<QuerySnapshot> readCoupons() => readCollection("shop_coupons");
  Future createCoupon(Map<String, dynamic> data) => createDoc("shop_coupons", data);
  Future updateCoupon(String docId, Map<String, dynamic> data) => updateDoc("shop_coupons", docId, data);
  Future deleteCoupon(String docId) => deleteDoc("shop_coupons", docId);

  // Promos / Banners
  Stream<QuerySnapshot> readPromos(bool isPromo) => readCollection(_promoOrBannerCollection(isPromo));
  Future createPromo(bool isPromo, Map<String, dynamic> data) => createDoc(_promoOrBannerCollection(isPromo), data);
  Future updatePromo(bool isPromo, String docId, Map<String, dynamic> data) =>
      updateDoc(_promoOrBannerCollection(isPromo), docId, data);
  Future deletePromo(bool isPromo, String docId) =>
      deleteDoc(_promoOrBannerCollection(isPromo), docId);


  // Orders
  Stream<QuerySnapshot> readOrders() => readCollection("shop_orders", orderBy: "created_at", descending: true);
  Future<void> updateOrderStatus({
    required String docId,
    required Map<String, dynamic> data,
  }) =>
      updateDoc("shop_orders", docId, data);

}
