import 'package:cloud_firestore/cloud_firestore.dart';

class DbService {
  final _db = FirebaseFirestore.instance;

  /// Ensures a collection exists by creating a hidden placeholder document if empty
  Future<void> _ensureCollection(String name) async {
    final snapshot = await _db.collection(name).limit(1).get();
    if (snapshot.docs.isEmpty) {
      // add a dummy document
      await _db.collection(name).add({
        "_init": true,
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Created missing collection: $name");
    }
  }

  // ---------------- CATEGORIES ----------------
  Stream<QuerySnapshot> readCategories() {
    return _db.collection("shop_categories").orderBy("priority", descending: true).snapshots();
  }

  Future createCategories({required Map<String, dynamic> data}) async {
    await _ensureCollection("shop_categories");
    await _db.collection("shop_categories").add(data);
  }

  Future updateCategories({required String docId, required Map<String, dynamic> data}) async {
    await _db.collection("shop_categories").doc(docId).update(data);
  }

  Future deleteCategories({required String docId}) async {
    await _db.collection("shop_categories").doc(docId).delete();
  }

  // ---------------- PRODUCTS ----------------
  Stream<QuerySnapshot> readProducts() {
    return _db.collection("shop_products").orderBy("category", descending: true).snapshots();
  }

  Future createProduct({required Map<String, dynamic> data}) async {
    await _ensureCollection("shop_products");
    await _db.collection("shop_products").add(data);
  }

  Future updateProduct({required String docId, required Map<String, dynamic> data}) async {
    await _db.collection("shop_products").doc(docId).update(data);
  }

  Future deleteProduct({required String docId}) async {
    await _db.collection("shop_products").doc(docId).delete();
  }

  // ---------------- PROMOS & BANNERS ----------------
  Stream<QuerySnapshot> readPromos(bool isPromo) {
    final collection = isPromo ? "shop_promos" : "shop_banners";
    print("📡 Reading from: $collection");
    return _db.collection(collection).snapshots();
  }

  Future createPromos({required Map<String, dynamic> data, required bool isPromo}) async {
    final collection = isPromo ? "shop_promos" : "shop_banners";
    await _ensureCollection(collection);
    await _db.collection(collection).add(data);
  }

  Future updatePromos({required Map<String, dynamic> data, required bool isPromo, required String id}) async {
    final collection = isPromo ? "shop_promos" : "shop_banners";
    await _db.collection(collection).doc(id).update(data);
  }

  Future deletePromos({required bool isPromo, required String id}) async {
    final collection = isPromo ? "shop_promos" : "shop_banners";
    await _db.collection(collection).doc(id).delete();
  }

  // ---------------- COUPONS ----------------
  Stream<QuerySnapshot> readCouponCode() {
    return _db.collection("shop_coupons").snapshots();
  }

  Future createCouponCode({required Map<String, dynamic> data}) async {
    await _ensureCollection("shop_coupons");
    await _db.collection("shop_coupons").add(data);
  }

  Future updateCouponCode({required String docId, required Map<String, dynamic> data}) async {
    await _db.collection("shop_coupons").doc(docId).update(data);
  }

  Future deleteCouponCode({required String docId}) async {
    await _db.collection("shop_coupons").doc(docId).delete();
  }

  // ---------------- ORDERS ----------------
  Stream<QuerySnapshot> readOrders() {
    return _db.collection("shop_orders").orderBy("created_at", descending: true).snapshots();
  }

  Future updateOrderStatus({required String docId, required Map<String, dynamic> data}) async {
    await _db.collection("shop_orders").doc(docId).update(data);
  }
}
