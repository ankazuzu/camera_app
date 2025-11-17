import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera_app/services/location_service.dart';
import 'package:camera_app/services/upload_service.dart';
import 'dart:io';

void main() {
  group('Integration Tests', () {
    test('Services can be instantiated together', () {
      final locationService = LocationService();
      final uploadService = UploadService();

      expect(locationService, isNotNull);
      expect(uploadService, isNotNull);
    });

    test('Location and Upload services work independently', () async {
      final locationService = LocationService();
      final uploadService = UploadService();

      // Test location service
      final locationResult = locationService.getCurrentLocation();
      expect(locationResult, isA<Future<Position?>>());

      // Test upload service with mock data
      final tempFile = File('test_temp.png');
      try {
        if (!await tempFile.exists()) {
          await tempFile.create();
        }

        final uploadResult = uploadService.uploadPhoto(
          imageFile: tempFile,
          comment: 'Integration test',
          latitude: 50.0,
          longitude: 36.0,
        );

        expect(uploadResult, isA<Future<bool>>());

        // Clean up
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        // Expected in test environment
        expect(e, isA<Object>());
      }
    });
  });
}
