import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  List<QueryDocumentSnapshot> categories = [];
  StreamSubscription<QuerySnapshot>? _categorySubscription;

  List<QueryDocumentSnapshot> products = [];
  StreamSubscription<QuerySnapshot>? _productsSubscription;

  List<QueryDocumentSnapshot> orders = [];
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  int totalCategories = 0;
  int totalProducts = 0;
  int totalOrders = 0;
  int ordersDelivered = 0;
  int ordersCancelled = 0;
  int ordersOnTheWay = 0;
  int orderPendingProcess = 0;

  AdminProvider() {
    getCategories();
    getProducts();
    readOrders();
  }

  // GET all the categories
  void getCategories() {
    _categorySubscription?.cancel();
    _categorySubscription = DbService.instance.readCategories().listen((snapshot) {
      categories = snapshot.docs;
      totalCategories = snapshot.docs.length;
      notifyListeners();
    });
  }

  // GET all the products
  void getProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = DbService.instance.readProducts().listen((snapshot) {
      products = snapshot.docs;
      totalProducts = snapshot.docs.length;
      notifyListeners();
    });
  }

  // Read all the orders
  void readOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = DbService.instance.readOrders().listen((snapshot) {
      orders = snapshot.docs;
      totalOrders = snapshot.docs.length;
      setOrderStatusCount();
      notifyListeners();
    });
  }

  // Count orders by status
  void setOrderStatusCount() {
    ordersDelivered = 0;
    ordersCancelled = 0;
    ordersOnTheWay = 0;
    orderPendingProcess = 0;

    for (final order in orders) {
      switch (order["status"]) {
        case "DELIVERED":
          ordersDelivered++;
          break;
        case "CANCELLED":
          ordersCancelled++;
          break;
        case "ON_THE_WAY":
          ordersOnTheWay++;
          break;
        default:
          orderPendingProcess++;
      }
    }
  }

  void cancelProvider() {
    _ordersSubscription?.cancel();
    _productsSubscription?.cancel();
    _categorySubscription?.cancel();
  }

  @override
  void dispose() {
    cancelProvider();
    super.dispose();
  }
}
