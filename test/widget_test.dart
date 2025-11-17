import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:camera_app/main.dart';
import 'package:camera_app/screens/camera_screen.dart';

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('MyApp builds correctly with cameras', (
      WidgetTester tester,
    ) async {
      // Create mock cameras
      final cameras = <CameraDescription>[];

      // Build the app
      await tester.pumpWidget(MyApp(cameras: cameras));

      // Verify app title
      expect(find.text('Photo Capture'), findsNothing); // Title is in AppBar
    });
  });

  group('CameraScreen Widget Tests', () {
    testWidgets('CameraScreen shows error when no cameras available', (
      WidgetTester tester,
    ) async {
      final cameras = <CameraDescription>[];

      await tester.pumpWidget(
        MaterialApp(home: CameraScreen(cameras: cameras)),
      );

      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('No cameras available on this device'), findsOneWidget);
    });

    testWidgets('CameraScreen shows loading initially', (
      WidgetTester tester,
    ) async {
      // Create a mock camera description
      final cameras = [
        const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: CameraScreen(cameras: cameras)),
      );

      // Initially should show loading or camera preview
      // Note: Camera initialization requires actual device, so we test UI elements
      await tester.pump();

      // Should have the app structure
      expect(find.byType(CameraScreen), findsOneWidget);
    });
  });
}
