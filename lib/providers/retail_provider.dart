import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/models/customer.dart';
import '../data/models/sale.dart';
import '../data/models/payment.dart';
import '../data/models/stock_movement.dart';
import '../data/repositories/retail_repository.dart';

class RetailProvider extends ChangeNotifier {
  final RetailRepository _repository;

  RetailProvider(this._repository);

  String? _businessId;
  List<Product> _products = [];
  List<StockMovement> _movements = [];
  List<Customer> _customers = [];
  List<Sale> _sales = [];
  List<Payment> _payments = [];
  bool _isLoading = false;

  String? get businessId => _businessId;
  List<Product> get products => _products;
  List<StockMovement> get movements => _movements;
  List<Customer> get customers => _customers;
  List<Sale> get sales => _sales;
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  // --- COMPUTED DASHBOARD METRICS ---
  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  int get lowStockCount => lowStockProducts.length;

  int get outOfStockCount => _products.where((p) => p.isOutOfStock).length;

  double get totalInventoryCostValue =>
      _products.fold(0.0, (acc, p) => acc + (p.purchasePrice * p.currentStock));

  double get totalInventoryRetailValue =>
      _products.fold(0.0, (acc, p) => acc + (p.sellingPrice * p.currentStock));

  double get totalOutstandingReceivables =>
      _customers.fold(0.0, (acc, c) => acc + c.outstandingAmount);

  // Today's Sales
  List<Sale> get todaySales {
    final now = DateTime.now();
    return _sales.where((s) {
      return !s.voided &&
          s.createdAt.year == now.year &&
          s.createdAt.month == now.month &&
          s.createdAt.day == now.day;
    }).toList();
  }

  double get todaySalesTotal =>
      todaySales.fold(0.0, (acc, s) => acc + s.grandTotal);

  int get todaySalesCount => todaySales.length;

  // Recent 10 sales
  List<Sale> get recentSales => _sales.take(10).toList();

  // Load all collections for business
  Future<void> loadAll(String businessId) async {
    _businessId = businessId;
    _isLoading = true;
    notifyListeners();

    _products = await _repository.getProducts(businessId);
    _movements = await _repository.getStockMovements(businessId);
    _customers = await _repository.getCustomers(businessId);
    _sales = await _repository.getSales(businessId);
    _payments = await _repository.getPayments(businessId);

    _isLoading = false;
    notifyListeners();
  }

  // --- SALE OPERATIONS ---
  Future<Sale> createSale({
    required String? customerId,
    required String customerName,
    String? customerPhone,
    required List<SaleItem> items,
    required double discount,
    required double tax,
    required double grandTotal,
    required String paymentStatus,
    required double amountPaid,
    required String paymentMethod,
    required String createdBy,
  }) async {
    if (_businessId == null) throw Exception('No business selected');

    final sale = await _repository.createSaleTransaction(
      businessId: _businessId!,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      paymentStatus: paymentStatus,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      createdBy: createdBy,
    );

    // Refresh memory cache
    await loadAll(_businessId!);
    return sale;
  }

  Future<void> voidSale({
    required String saleId,
    required String voidReason,
    required String createdBy,
  }) async {
    if (_businessId == null) return;
    await _repository.voidSaleTransaction(
      businessId: _businessId!,
      saleId: saleId,
      voidReason: voidReason,
      createdBy: createdBy,
    );
    await loadAll(_businessId!);
  }

  // --- PRODUCT OPERATIONS ---
  Future<Product> addProduct(Product product) async {
    if (_businessId == null) throw Exception('No business selected');
    final newProd = await _repository.addProduct(_businessId!, product);
    await loadAll(_businessId!);
    return newProd;
  }

  Future<void> updateProduct(Product product) async {
    if (_businessId == null) return;
    await _repository.updateProduct(_businessId!, product);
    await loadAll(_businessId!);
  }

  Future<void> deleteProduct(String productId) async {
    if (_businessId == null) return;
    await _repository.deleteProduct(_businessId!, productId);
    await loadAll(_businessId!);
  }

  Future<void> adjustStock({
    required String productId,
    required int quantityDelta,
    required String reason,
    required String createdBy,
  }) async {
    if (_businessId == null) return;
    await _repository.adjustStockTransaction(
      businessId: _businessId!,
      productId: productId,
      quantityDelta: quantityDelta,
      reason: reason,
      createdBy: createdBy,
    );
    await loadAll(_businessId!);
  }

  // --- CUSTOMER OPERATIONS ---
  Future<Customer> addCustomer(Customer customer) async {
    if (_businessId == null) throw Exception('No business selected');
    final newCust = await _repository.addCustomer(_businessId!, customer);
    await loadAll(_businessId!);
    return newCust;
  }

  // --- PAYMENT OPERATIONS ---
  Future<Payment> recordPayment({
    String? saleId,
    String? customerId,
    required String customerName,
    required double amount,
    required String method,
    String? note,
  }) async {
    if (_businessId == null) throw Exception('No business selected');
    final payment = await _repository.recordPayment(
      businessId: _businessId!,
      saleId: saleId,
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      method: method,
      note: note,
    );
    await loadAll(_businessId!);
    return payment;
  }

  // Reset to demo
  Future<void> resetDemo() async {
    if (_businessId == null) return;
    await _repository.resetToDemoData(_businessId!);
    await loadAll(_businessId!);
  }
}
