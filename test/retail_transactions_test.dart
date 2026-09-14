import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rexon/data/models/sale.dart';
import 'package:rexon/data/repositories/demo_data.dart';
import 'package:rexon/data/repositories/retail_repository.dart';
import 'package:rexon/providers/retail_provider.dart';

void main() {
  group('Rexon Retail Atomic Transactions Test Suite', () {
    late RetailRepository repo;
    late RetailProvider provider;
    const businessId = DemoData.demoBusinessId;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = RetailRepository();
      await repo.init();
      await repo.resetToDemoData(businessId);
      provider = RetailProvider(repo);
      await provider.loadAll(businessId);
    });

    test('Initial sample data is correctly seeded for business', () async {
      expect(provider.products.length, greaterThanOrEqualTo(10));
      expect(provider.customers.length, greaterThanOrEqualTo(4));
      expect(provider.sales.isNotEmpty, isTrue);
      expect(provider.todaySalesTotal, greaterThan(0));
      expect(provider.totalOutstandingReceivables, greaterThan(0));
    });

    test('Sale transaction decrements stock and updates customer Khata balance', () async {
      final product = provider.products.firstWhere((p) => p.currentStock > 10);
      final customer = provider.customers.firstWhere((c) => c.name.contains('Sharma'));

      final initialStock = product.currentStock;
      final initialDue = customer.outstandingAmount;
      const soldQty = 2;
      final total = product.sellingPrice * soldQty;

      final sale = await provider.createSale(
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        items: [
          SaleItem(
            productId: product.id,
            productName: product.name,
            sku: product.sku,
            unitPrice: product.sellingPrice,
            quantity: soldQty,
            lineTotal: total,
          ),
        ],
        discount: 0.0,
        tax: 0.0,
        grandTotal: total,
        paymentStatus: 'unpaid',
        amountPaid: 0.0,
        paymentMethod: 'khata',
        createdBy: 'owner',
      );

      expect(sale.id.isNotEmpty, isTrue);
      expect(sale.invoiceNumber.startsWith('INV-'), isTrue);

      // Verify stock decreased
      final updatedProduct = provider.products.firstWhere((p) => p.id == product.id);
      expect(updatedProduct.currentStock, equals(initialStock - soldQty));

      // Verify Khata due increased
      final updatedCustomer = provider.customers.firstWhere((c) => c.id == customer.id);
      expect(updatedCustomer.outstandingAmount, closeTo(initialDue + total, 0.01));

      // Verify stock movement was recorded
      final movement = provider.movements.firstWhere((m) => m.referenceId == sale.id);
      expect(movement.quantityChange, equals(-soldQty));
      expect(movement.type, equals('sale'));
    });

    test('Voiding sale restores inventory and reverses customer Khata dues', () async {
      final product = provider.products.first;
      final customer = provider.customers.first;
      final initialStock = product.currentStock;
      final initialDue = customer.outstandingAmount;

      const qty = 3;
      final total = product.sellingPrice * qty;

      final sale = await provider.createSale(
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        items: [
          SaleItem(
            productId: product.id,
            productName: product.name,
            sku: product.sku,
            unitPrice: product.sellingPrice,
            quantity: qty,
            lineTotal: total,
          ),
        ],
        discount: 0.0,
        tax: 0.0,
        grandTotal: total,
        paymentStatus: 'unpaid',
        amountPaid: 0.0,
        paymentMethod: 'khata',
        createdBy: 'owner',
      );

      expect(provider.products.firstWhere((p) => p.id == product.id).currentStock, equals(initialStock - qty));

      // Void the sale
      await provider.voidSale(
        saleId: sale.id,
        voidReason: 'Customer returned damaged item',
        createdBy: 'owner',
      );

      // Verify stock is restored
      final restoredProduct = provider.products.firstWhere((p) => p.id == product.id);
      expect(restoredProduct.currentStock, equals(initialStock));

      // Verify customer Khata is restored
      final restoredCustomer = provider.customers.firstWhere((c) => c.id == customer.id);
      expect(restoredCustomer.outstandingAmount, closeTo(initialDue, 0.01));

      // Verify sale is marked void
      final voidedSale = provider.sales.firstWhere((s) => s.id == sale.id);
      expect(voidedSale.voided, isTrue);
      expect(voidedSale.voidReason, equals('Customer returned damaged item'));
    });

    test('Recording customer payment settles dues', () async {
      final customer = provider.customers.firstWhere((c) => c.outstandingAmount > 200);
      final initialDue = customer.outstandingAmount;
      const paymentAmt = 200.0;

      final payment = await provider.recordPayment(
        customerId: customer.id,
        customerName: customer.name,
        amount: paymentAmt,
        method: 'upi',
        note: 'GPay payment',
      );

      expect(payment.amount, equals(paymentAmt));
      expect(payment.method, equals('upi'));

      final updatedCustomer = provider.customers.firstWhere((c) => c.id == customer.id);
      expect(updatedCustomer.outstandingAmount, closeTo(initialDue - paymentAmt, 0.01));
    });

    test('Adjust stock modifies inventory with audit reason', () async {
      final product = provider.products.first;
      final initialStock = product.currentStock;
      const delta = -2;

      await provider.adjustStock(
        productId: product.id,
        quantityDelta: delta,
        reason: 'Expired Goods',
        createdBy: 'owner',
      );

      final updatedProduct = provider.products.firstWhere((p) => p.id == product.id);
      expect(updatedProduct.currentStock, equals(initialStock + delta));

      final movement = provider.movements.firstWhere(
        (m) => m.productId == product.id && m.reason == 'Expired Goods',
      );
      expect(movement.quantityChange, equals(delta));
      expect(movement.type, equals('adjustment'));
    });
  });
}
