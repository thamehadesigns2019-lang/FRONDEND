import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thameeha/main.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/services/api_service.dart';

void main() {
  testWidgets('Client app smoke test', (WidgetTester tester) async {
    // Set a realistic screen size (e.g. Pixel 4)
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Setup dependency
    final apiService = ApiService();
    final appState = AppState(apiService: apiService);

    // Build our app
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MyPortfolioApp(),
      ),
    );

    // Advance time for SplashScreen
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(); 
    
    expect(find.byType(MaterialApp), findsOneWidget);

    // Teardown
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
