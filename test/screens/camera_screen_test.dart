import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:camera_app/screens/camera_screen.dart';

void main() {
  group('CameraScreen Tests', () {
    testWidgets('CameraScreen displays error when no cameras', (tester) async {
      const cameras = <CameraDescription>[];

      await tester.pumpWidget(
        const MaterialApp(home: CameraScreen(cameras: cameras)),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('No cameras available on this device'), findsOneWidget);
    });

    testWidgets('CameraScreen has required UI elements', (tester) async {
      const cameras = <CameraDescription>[];

      await tester.pumpWidget(
        const MaterialApp(home: CameraScreen(cameras: cameras)),
      );

      await tester.pumpAndSettle();

      // Check for error view elements
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('CameraScreen structure is correct', (tester) async {
      const cameras = <CameraDescription>[];

      await tester.pumpWidget(
        const MaterialApp(home: CameraScreen(cameras: cameras)),
      );

      await tester.pumpAndSettle();

      // Should have Scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
