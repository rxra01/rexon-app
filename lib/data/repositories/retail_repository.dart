import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/business.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/payment.dart';
import '../models/stock_movement.dart';
import 'demo_data.dart';

/// Hybrid Retail Repository: Cloud Firestore (PRD §9) + Offline SharedPreferences Cache
class RetailRepository {
  final _uuid = const Uuid();
  SharedPreferences? _prefs;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _businessesCol =>
      _firestore.collection('businesses');

  DocumentReference<Map<String, dynamic>> _bizDoc(String businessId) =>
      _businessesCol.doc(businessId);

  CollectionReference<Map<String, dynamic>> _productsCol(String businessId) =>
      _bizDoc(businessId).collection('products');

  CollectionReference<Map<String, dynamic>> _customersCol(String businessId) =>
      _bizDoc(businessId).collection('customers');

  CollectionReference<Map<String, dynamic>> _salesCol(String businessId) =>
      _bizDoc(businessId).collection('sales');

  CollectionReference<Map<String, dynamic>> _paymentsCol(String businessId) =>
      _bizDoc(businessId).collection('payments');

  CollectionReference<Map<String, dynamic>> _stockMovementsCol(String businessId) =>
      _bizDoc(businessId).collection('stock_movements');

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _key(String businessId, String collection) => 'rexon_${businessId}_$collection';

  // --- BUSINESS SETUP & PROFILE ---
  Future<Business?> getBusiness(String businessId) async {
    await init();

    // 1. Check local storage for instantaneous load
    final raw = _prefs?.getString('rexon_business_$businessId');
    Business? localBiz;
    if (raw != null) {
      try {
        localBiz = Business.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('[RetailRepository] Error parsing local business: $e');
      }
    }

    // 2. Fetch latest from Cloud Firestore
    try {
      final doc = await _bizDoc(businessId).get();
      if (doc.exists && doc.data() != null) {
        final cloudBiz = Business.fromJson(doc.data()!);
        await _prefs?.setString('rexon_business_$businessId', jsonEncode(cloudBiz.toJson()));
        return cloudBiz;
      } else if (localBiz != null) {
        // Push pre-existing local profile up to Firestore
        await _bizDoc(businessId).set(localBiz.toJson(), SetOptions(merge: true));
        debugPrint('[RetailRepository] Synced local business profile to Firestore: $businessId');
        return localBiz;
      }
    } catch (e) {
      debugPrint('[RetailRepository] Firestore getBusiness note: $e');
    }

    if (localBiz != null) return localBiz;

    // 3. Fallback: Seed demo business if demo ID requested
    if (businessId == DemoData.demoBusinessId) {
      final demo = DemoData.business;
      await saveBusiness(demo);
      await _seedDemoCollections(demo.id);
      return demo;
    }

    return null;
  }

  Future<void> saveBusiness(Business business) async {
    await init();

    // 1. Save to local cache
    await _prefs?.setString('rexon_business_${business.id}', jsonEncode(business.toJson()));

    // 2. Persist to Cloud Firestore (PRD §9: businesses/{businessId})
    try {
      await _bizDoc(business.id).set(business.toJson(), SetOptions(merge: true));
      debugPrint('[RetailRepository] Successfully saved business ${business.id} to Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore saveBusiness error: $e');
    }
  }

  // --- PRODUCTS & INVENTORY ---
  Future<List<Product>> getProducts(String businessId) async {
    await init();

    // 1. Try fetching from Cloud Firestore
    try {
      final snap = await _productsCol(businessId).get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((doc) => Product.fromJson(doc.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _saveProductsLocally(businessId, list);
        return list;
      } else {
        // If Firestore has 0 docs, check if local storage has products to sync up
        final raw = _prefs?.getString(_key(businessId, 'products'));
        if (raw != null) {
          final localList = (jsonDecode(raw) as List<dynamic>)
              .map((i) => Product.fromJson(i as Map<String, dynamic>))
              .toList();
          if (localList.isNotEmpty) {
            final batch = _firestore.batch();
            for (final p in localList) {
              batch.set(_productsCol(businessId).doc(p.id), p.toJson(), SetOptions(merge: true));
            }
            await batch.commit();
            debugPrint('[RetailRepository] Synced ${localList.length} local products to Firestore.');
            return localList;
          }
        }
      }
    } catch (e) {
      debugPrint('[RetailRepository] Firestore getProducts note: $e');
    }

    // 2. Fallback to local cache
    final raw = _prefs?.getString(_key(businessId, 'products'));
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('[RetailRepository] Error parsing local products: $e');
      }
    }
    return [];
  }

  Future<void> _saveProductsLocally(String businessId, List<Product> products) async {
    await _prefs?.setString(
      _key(businessId, 'products'),
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );
  }

  Future<Product> addProduct(String businessId, Product product) async {
    await init();
    final products = await getProducts(businessId);
    final newProduct = product.copyWith(
      sku: product.sku.trim().isEmpty ? 'SKU-${1000 + products.length + 1}' : product.sku.trim(),
    );
    products.insert(0, newProduct);
    await _saveProductsLocally(businessId, products);

    // Save to Cloud Firestore
    try {
      await _productsCol(businessId).doc(newProduct.id).set(newProduct.toJson());
      debugPrint('[RetailRepository] Added product ${newProduct.id} to Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore addProduct error: $e');
    }

    // Record initial stock opening movement if currentStock > 0
    if (newProduct.currentStock > 0) {
      await _recordStockMovement(
        businessId,
        StockMovement(
          id: _uuid.v4(),
          businessId: businessId,
          productId: newProduct.id,
          productName: newProduct.name,
          type: 'opening',
          quantityChange: newProduct.currentStock,
          reason: 'Initial Opening Stock',
          createdAt: DateTime.now(),
          createdBy: 'owner',
        ),
      );
    }

    return newProduct;
  }

  Future<void> updateProduct(String businessId, Product updated) async {
    await init();
    final products = await getProducts(businessId);
    final idx = products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      products[idx] = updated;
      await _saveProductsLocally(businessId, products);
    }

    // Update in Cloud Firestore
    try {
      await _productsCol(businessId).doc(updated.id).set(updated.toJson(), SetOptions(merge: true));
      debugPrint('[RetailRepository] Updated product ${updated.id} in Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore updateProduct error: $e');
    }
  }

  Future<void> deleteProduct(String businessId, String productId) async {
    await init();
    final products = await getProducts(businessId);
    products.removeWhere((p) => p.id == productId);
    await _saveProductsLocally(businessId, products);

    // Delete in Cloud Firestore
    try {
      await _productsCol(businessId).doc(productId).delete();
      debugPrint('[RetailRepository] Deleted product $productId from Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore deleteProduct error: $e');
    }
  }

  // --- ATOMIC STOCK ADJUSTMENT ---
  Future<void> adjustStockTransaction({
    required String businessId,
    required String productId,
    required int quantityDelta,
    required String reason,
    required String createdBy,
  }) async {
    await init();
    final products = await getProducts(businessId);
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx == -1) throw Exception('Product not found: $productId');

    final product = products[idx];
    final newStock = (product.currentStock + quantityDelta).clamp(0, 999999);
    final updatedProduct = product.copyWith(currentStock: newStock, updatedAt: DateTime.now());
    products[idx] = updatedProduct;

    // Record movement
    final movement = StockMovement(
      id: _uuid.v4(),
      businessId: businessId,
      productId: productId,
      productName: product.name,
      type: 'adjustment',
      quantityChange: quantityDelta,
      reason: reason,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    await _saveProductsLocally(businessId, products);
    await _recordStockMovementLocally(businessId, movement);

    // Atomic Cloud Firestore Batch Commit
    try {
      final batch = _firestore.batch();
      batch.set(_productsCol(businessId).doc(productId), updatedProduct.toJson(), SetOptions(merge: true));
      batch.set(_stockMovementsCol(businessId).doc(movement.id), movement.toJson());
      await batch.commit();
      debugPrint('[RetailRepository] Committed adjustStock batch to Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore adjustStock error: $e');
    }
  }

  // --- STOCK MOVEMENTS AUDIT TRAIL ---
  Future<List<StockMovement>> getStockMovements(String businessId, {String? productId}) async {
    await init();

    // 1. Try Cloud Firestore
    try {
      Query<Map<String, dynamic>> query = _stockMovementsCol(businessId);
      if (productId != null) {
        query = query.where('productId', isEqualTo: productId);
      }
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) => StockMovement.fromJson(d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (productId == null) {
          await _saveStockMovementsLocally(businessId, list);
        }
        return list;
      } else if (productId == null) {
        final raw = _prefs?.getString(_key(businessId, 'stock_movements'));
        if (raw != null) {
          final localList = (jsonDecode(raw) as List<dynamic>)
              .map((i) => StockMovement.fromJson(i as Map<String, dynamic>))
              .toList();
          if (localList.isNotEmpty) {
            final batch = _firestore.batch();
            for (final m in localList) {
              batch.set(_stockMovementsCol(businessId).doc(m.id), m.toJson(), SetOptions(merge: true));
            }
            await batch.commit();
            debugPrint('[RetailRepository] Synced ${localList.length} stock movements to Firestore.');
            return localList;
          }
        }
      }
    } catch (e) {
      debugPrint('[RetailRepository] Firestore getStockMovements note: $e');
    }

    // 2. Fallback to local cache
    final raw = _prefs?.getString(_key(businessId, 'stock_movements'));
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final movements = list.map((item) => StockMovement.fromJson(item as Map<String, dynamic>)).toList();
        if (productId != null) {
          return movements.where((m) => m.productId == productId).toList();
        }
        return movements;
      } catch (e) {
        debugPrint('[RetailRepository] Error parsing local stock movements: $e');
      }
    }
    return [];
  }

  Future<void> _saveStockMovementsLocally(String businessId, List<StockMovement> movements) async {
    await _prefs?.setString(
      _key(businessId, 'stock_movements'),
      jsonEncode(movements.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _recordStockMovementLocally(String businessId, StockMovement movement) async {
    final movements = await getStockMovements(businessId);
    movements.insert(0, movement);
    await _saveStockMovementsLocally(businessId, movements);
  }

  Future<void> _recordStockMovement(String businessId, StockMovement movement) async {
    await _recordStockMovementLocally(businessId, movement);

    // Save to Cloud Firestore
    try {
      await _stockMovementsCol(businessId).doc(movement.id).set(movement.toJson());
      debugPrint('[RetailRepository] Recorded stock movement in Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore _recordStockMovement error: $e');
    }
  }

  // --- CUSTOMERS ---
  Future<List<Customer>> getCustomers(String businessId) async {
    await init();

    // 1. Try Cloud Firestore
    try {
      final snap = await _customersCol(businessId).get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) => Customer.fromJson(d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _saveCustomersLocally(businessId, list);
        return list;
      } else {
        final raw = _prefs?.getString(_key(businessId, 'customers'));
        if (raw != null) {
          final localList = (jsonDecode(raw) as List<dynamic>)
              .map((i) => Customer.fromJson(i as Map<String, dynamic>))
              .toList();
          if (localList.isNotEmpty) {
            final batch = _firestore.batch();
            for (final c in localList) {
              batch.set(_customersCol(businessId).doc(c.id), c.toJson(), SetOptions(merge: true));
            }
            await batch.commit();
            debugPrint('[RetailRepository] Synced ${localList.length} local customers to Firestore.');
            return localList;
          }
        }
      }
    } catch (e) {
      debugPrint('[RetailRepository] Firestore getCustomers note: $e');
    }

    // 2. Fallback to local cache
    final raw = _prefs?.getString(_key(businessId, 'customers'));
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => Customer.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('[RetailRepository] Error parsing local customers: $e');
      }
    }
    return [];
  }

  Future<void> _saveCustomersLocally(String businessId, List<Customer> customers) async {
    await _prefs?.setString(
      _key(businessId, 'customers'),
      jsonEncode(customers.map((c) => c.toJson()).toList()),
    );
  }

  Future<Customer> addCustomer(String businessId, Customer customer) async {
    await init();
    final customers = await getCustomers(businessId);
    customers.insert(0, customer);
    await _saveCustomersLocally(businessId, customers);

    // Save to Cloud Firestore
    try {
      await _customersCol(businessId).doc(customer.id).set(customer.toJson());
      debugPrint('[RetailRepository] Added customer ${customer.id} to Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore addCustomer error: $e');
    }

    return customer;
  }

  // --- SALES & INVOICES (ATOMIC TRANSACTION) ---
  Future<List<Sale>> getSales(String businessId) async {
    await init();

    // 1. Try Cloud Firestore
    try {
      final snap = await _salesCol(businessId).get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) => Sale.fromJson(d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _saveSalesLocally(businessId, list);
        return list;
      } else {
        final raw = _prefs?.getString(_key(businessId, 'sales'));
        if (raw != null) {
          final localList = (jsonDecode(raw) as List<dynamic>)
              .map((i) => Sale.fromJson(i as Map<String, dynamic>))
              .toList();
          if (localList.isNotEmpty) {
            final batch = _firestore.batch();
            for (final s in localList) {
              batch.set(_salesCol(businessId).doc(s.id), s.toJson(), SetOptions(merge: true));
            }
            await batch.commit();
            debugPrint('[RetailRepository] Synced ${localList.length} local sales to Firestore.');
            return localList;
          }
        }
      }
    } catch (e) {
      debugPrint('[RetailRepository] Firestore getSales note: $e');
    }

    // 2. Fallback to local cache
    final raw = _prefs?.getString(_key(businessId, 'sales'));
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => Sale.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('[RetailRepository] Error parsing local sales: $e');
      }
    }
    return [];
  }

  Future<void> _saveSalesLocally(String businessId, List<Sale> sales) async {
    await _prefs?.setString(
      _key(businessId, 'sales'),
      jsonEncode(sales.map((s) => s.toJson()).toList()),
    );
  }

  Future<String> getNextInvoiceNumber(String businessId) async {
    final sales = await getSales(businessId);
    final count = sales.length + 1;
    return 'INV-${count.toString().padLeft(4, '0')}';
  }

  /// ATOMIC SALE CREATION TRANSACTION (Adhering strictly to PRD §6.5 & §7)
  /// In one atomic step:
  /// 1. Decrements stock for each product
  /// 2. Creates immutable stock_movement records
  /// 3. Updates customer outstanding dues (if partial/unpaid)
  /// 4. Creates payment record (if amountPaid > 0)
  /// 5. Saves invoice document
  Future<Sale> createSaleTransaction({
    required String businessId,
    required String? customerId,
    required String customerName,
    required String? customerPhone,
    required List<SaleItem> items,
    required double discount,
    required double tax,
    required double grandTotal,
    required String paymentStatus, // "paid", "partial", "unpaid"
    required double amountPaid,
    required String paymentMethod,
    required String createdBy,
  }) async {
    await init();
    final sales = await getSales(businessId);
    final products = await getProducts(businessId);
    final customers = await getCustomers(businessId);
    final invoiceNumber = 'INV-${(sales.length + 1).toString().padLeft(4, '0')}';
    final saleId = _uuid.v4();

    // 1. Decrement stock & prepare stock movements
    final movementsToRecord = <StockMovement>[];
    for (final item in items) {
      final pIndex = products.indexWhere((p) => p.id == item.productId);
      if (pIndex != -1) {
        final prod = products[pIndex];
        final newStock = prod.currentStock - item.quantity;
        products[pIndex] = prod.copyWith(currentStock: newStock, updatedAt: DateTime.now());

        movementsToRecord.add(
          StockMovement(
            id: _uuid.v4(),
            businessId: businessId,
            productId: item.productId,
            productName: item.productName,
            type: 'sale',
            quantityChange: -item.quantity,
            reason: 'Sale #$invoiceNumber',
            referenceId: saleId,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
        );
      }
    }

    // 2. Update customer outstanding dues if not walk-in
    final balanceDue = grandTotal - amountPaid;
    Customer? updatedCustomer;
    if (customerId != null && balanceDue > 0) {
      final cIndex = customers.indexWhere((c) => c.id == customerId);
      if (cIndex != -1) {
        final cust = customers[cIndex];
        updatedCustomer = cust.copyWith(
          outstandingAmount: cust.outstandingAmount + balanceDue,
        );
        customers[cIndex] = updatedCustomer;
      }
    }

    // 3. Create Sale record
    final sale = Sale(
      id: saleId,
      businessId: businessId,
      invoiceNumber: invoiceNumber,
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
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    // 4. Create Payment if money received
    Payment? payment;
    if (amountPaid > 0) {
      payment = Payment(
        id: _uuid.v4(),
        businessId: businessId,
        saleId: saleId,
        customerId: customerId,
        customerName: customerName,
        amount: amountPaid,
        method: paymentMethod,
        note: 'Payment for #$invoiceNumber',
        createdAt: DateTime.now(),
      );
    }

    // 5. Persist to Local Storage
    sales.insert(0, sale);
    await _saveSalesLocally(businessId, sales);
    await _saveProductsLocally(businessId, products);
    await _saveCustomersLocally(businessId, customers);
    if (payment != null) {
      final payments = await getPayments(businessId);
      payments.insert(0, payment);
      await _savePaymentsLocally(businessId, payments);
    }

    final existingMovements = await getStockMovements(businessId);
    existingMovements.insertAll(0, movementsToRecord);
    await _saveStockMovementsLocally(businessId, existingMovements);

    // 6. Atomically commit to Cloud Firestore (PRD §7)
    try {
      final batch = _firestore.batch();

      // Sale invoice doc
      batch.set(_salesCol(businessId).doc(sale.id), sale.toJson());

      // Decrement stock for products
      for (final item in items) {
        final pRef = _productsCol(businessId).doc(item.productId);
        batch.set(pRef, {
          'currentStock': FieldValue.increment(-item.quantity),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      // Stock movements
      for (final mov in movementsToRecord) {
        batch.set(_stockMovementsCol(businessId).doc(mov.id), mov.toJson());
      }

      // Customer outstanding dues
      if (customerId != null && balanceDue > 0) {
        final cRef = _customersCol(businessId).doc(customerId);
        batch.set(cRef, {
          'outstandingAmount': FieldValue.increment(balanceDue),
        }, SetOptions(merge: true));
      }

      // Payment doc
      if (payment != null) {
        batch.set(_paymentsCol(businessId).doc(payment.id), payment.toJson());
      }

      await batch.commit();
      debugPrint('[RetailRepository] Committed createSaleTransaction batch to Firestore: ${sale.id}');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore createSaleTransaction error: $e');
    }

    return sale;
  }

  /// ATOMIC VOID INVOICE TRANSACTION (Adhering to PRD §6.5)
  /// Reverses stock decrements with reason and restores customer dues balance
  Future<void> voidSaleTransaction({
    required String businessId,
    required String saleId,
    required String voidReason,
    required String createdBy,
  }) async {
    await init();
    final sales = await getSales(businessId);
    final saleIdx = sales.indexWhere((s) => s.id == saleId);
    if (saleIdx == -1) throw Exception('Invoice not found: $saleId');

    final sale = sales[saleIdx];
    if (sale.voided) throw Exception('Invoice is already voided');

    final products = await getProducts(businessId);
    final customers = await getCustomers(businessId);
    final movementsToRecord = <StockMovement>[];

    // 1. Re-add stock
    for (final item in sale.items) {
      final pIdx = products.indexWhere((p) => p.id == item.productId);
      if (pIdx != -1) {
        final prod = products[pIdx];
        products[pIdx] = prod.copyWith(
          currentStock: prod.currentStock + item.quantity,
          updatedAt: DateTime.now(),
        );

        movementsToRecord.add(
          StockMovement(
            id: _uuid.v4(),
            businessId: businessId,
            productId: item.productId,
            productName: item.productName,
            type: 'adjustment',
            quantityChange: item.quantity,
            reason: 'Voided #${sale.invoiceNumber}: $voidReason',
            referenceId: sale.id,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
        );
      }
    }

    // 2. Reverse customer outstanding balance
    final balanceDue = sale.grandTotal - sale.amountPaid;
    Customer? updatedCustomer;
    if (sale.customerId != null && balanceDue > 0) {
      final cIdx = customers.indexWhere((c) => c.id == sale.customerId);
      if (cIdx != -1) {
        final cust = customers[cIdx];
        updatedCustomer = cust.copyWith(
          outstandingAmount: (cust.outstandingAmount - balanceDue).clamp(0.0, double.infinity),
        );
        customers[cIdx] = updatedCustomer;
      }
    }

    // 3. Mark sale voided
    final voidedSale = sale.copyWith(
      voided: true,
      voidReason: voidReason,
    );
    sales[saleIdx] = voidedSale;

    // Persist locally
    await _saveSalesLocally(businessId, sales);
    await _saveProductsLocally(businessId, products);
    await _saveCustomersLocally(businessId, customers);
    final existingMovements = await getStockMovements(businessId);
    existingMovements.insertAll(0, movementsToRecord);
    await _saveStockMovementsLocally(businessId, existingMovements);

    // Persist to Cloud Firestore via Batch
    try {
      final batch = _firestore.batch();
      batch.set(_salesCol(businessId).doc(sale.id), {
        'voided': true,
        'voidReason': voidReason,
      }, SetOptions(merge: true));

      for (final item in sale.items) {
        final pRef = _productsCol(businessId).doc(item.productId);
        batch.set(pRef, {
          'currentStock': FieldValue.increment(item.quantity),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      for (final mov in movementsToRecord) {
        batch.set(_stockMovementsCol(businessId).doc(mov.id), mov.toJson());
      }

      if (updatedCustomer != null && sale.customerId != null) {
        batch.set(_customersCol(businessId).doc(sale.customerId!), {
          'outstandingAmount': FieldValue.increment(-balanceDue),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('[RetailRepository] Committed voidSaleTransaction batch to Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore voidSaleTransaction error: $e');
    }
  }

  // --- PAYMENTS ---
  Future<List<Payment>> getPayments(String businessId) async {
    await init();

    // 1. Try Cloud Firestore
    try {
      final snap = await _paymentsCol(businessId).get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) => Payment.fromJson(d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _savePaymentsLocally(businessId, list);
        return list;
      } else {
        final raw = _prefs?.getString(_key(businessId, 'payments'));
        if (raw != null) {
          final localList = (jsonDecode(raw) as List<dynamic>)
              .map((i) => Payment.fromJson(i as Map<String, dynamic>))
              .toList();
          if (localList.isNotEmpty) {
            final batch = _firestore.batch();
            for (final pay in localList) {
              batch.set(_paymentsCol(businessId).doc(pay.id), pay.toJson(), SetOptions(merge: true));
            }
            await batch.commit();
            debugPrint('[RetailRepository] Synced ${localList.length} local payments to Firestore.');
            return localList;
          }
        }
      }
    } catch (e) {
      debugPrint('[RetailRepository] Firestore getPayments note: $e');
    }

    // 2. Fallback to local cache
    final raw = _prefs?.getString(_key(businessId, 'payments'));
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((item) => Payment.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('[RetailRepository] Error parsing local payments: $e');
      }
    }
    return [];
  }

  Future<void> _savePaymentsLocally(String businessId, List<Payment> payments) async {
    await _prefs?.setString(
      _key(businessId, 'payments'),
      jsonEncode(payments.map((p) => p.toJson()).toList()),
    );
  }

  Future<Payment> recordPayment({
    required String businessId,
    String? saleId,
    String? customerId,
    required String customerName,
    required double amount,
    required String method,
    String? note,
  }) async {
    await init();
    final payments = await getPayments(businessId);
    final payment = Payment(
      id: _uuid.v4(),
      businessId: businessId,
      saleId: saleId,
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      method: method,
      note: note,
      createdAt: DateTime.now(),
    );

    payments.insert(0, payment);
    await _savePaymentsLocally(businessId, payments);

    // Update customer dues
    Customer? updatedCustomer;
    if (customerId != null) {
      final customers = await getCustomers(businessId);
      final cIdx = customers.indexWhere((c) => c.id == customerId);
      if (cIdx != -1) {
        final cust = customers[cIdx];
        updatedCustomer = cust.copyWith(
          outstandingAmount: (cust.outstandingAmount - amount).clamp(0.0, double.infinity),
        );
        customers[cIdx] = updatedCustomer;
        await _saveCustomersLocally(businessId, customers);
      }
    }

    // Update sale if linked
    Sale? updatedSale;
    if (saleId != null) {
      final sales = await getSales(businessId);
      final sIdx = sales.indexWhere((s) => s.id == saleId);
      if (sIdx != -1) {
        final sale = sales[sIdx];
        final newAmountPaid = sale.amountPaid + amount;
        final newStatus = newAmountPaid >= sale.grandTotal ? 'paid' : 'partial';
        updatedSale = sale.copyWith(
          amountPaid: newAmountPaid,
          paymentStatus: newStatus,
        );
        sales[sIdx] = updatedSale;
        await _saveSalesLocally(businessId, sales);
      }
    }

    // Cloud Firestore commit
    try {
      final batch = _firestore.batch();
      batch.set(_paymentsCol(businessId).doc(payment.id), payment.toJson());

      if (customerId != null && updatedCustomer != null) {
        batch.set(_customersCol(businessId).doc(customerId), {
          'outstandingAmount': FieldValue.increment(-amount),
        }, SetOptions(merge: true));
      }

      if (saleId != null && updatedSale != null) {
        batch.set(_salesCol(businessId).doc(saleId), {
          'amountPaid': updatedSale.amountPaid,
          'paymentStatus': updatedSale.paymentStatus,
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('[RetailRepository] Committed payment to Firestore: ${payment.id}');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore recordPayment error: $e');
    }

    return payment;
  }

  // --- SEED DEMO DATA ---
  Future<void> _seedDemoCollections(String businessId) async {
    await _saveProductsLocally(businessId, DemoData.products);
    await _saveCustomersLocally(businessId, DemoData.customers);
    await _saveSalesLocally(businessId, DemoData.sales);
    await _saveStockMovementsLocally(businessId, DemoData.initialMovements);

    // Also mirror demo dataset to Cloud Firestore
    try {
      final batch = _firestore.batch();
      for (final p in DemoData.products) {
        batch.set(_productsCol(businessId).doc(p.id), p.toJson(), SetOptions(merge: true));
      }
      for (final c in DemoData.customers) {
        batch.set(_customersCol(businessId).doc(c.id), c.toJson(), SetOptions(merge: true));
      }
      for (final s in DemoData.sales) {
        batch.set(_salesCol(businessId).doc(s.id), s.toJson(), SetOptions(merge: true));
      }
      for (final m in DemoData.initialMovements) {
        batch.set(_stockMovementsCol(businessId).doc(m.id), m.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[RetailRepository] Seeded demo data to Firestore.');
    } catch (e) {
      debugPrint('[RetailRepository] Firestore demo seed note: $e');
    }
  }

  Future<void> resetToDemoData(String businessId) async {
    await init();
    await saveBusiness(DemoData.business);
    await _seedDemoCollections(businessId);
  }
}
