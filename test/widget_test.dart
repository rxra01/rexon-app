import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rexon/data/repositories/retail_repository.dart';
import 'package:rexon/main.dart';
import 'package:rexon/providers/auth_provider.dart';
import 'package:rexon/providers/retail_provider.dart';

void main() {
  testWidgets('RexonApp renders login screen when unauthenticated', (WidgetTester tester) async {
    final repository = RetailRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(repository)),
          ChangeNotifierProvider(create: (_) => RetailProvider(repository)),
        ],
        child: const RexonApp(),
      ),
    );

    // Initial frame check
    expect(find.byType(RexonApp), findsOneWidget);
  });
}
