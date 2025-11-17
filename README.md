# 📸 Photo Capture App

A modern Flutter mobile application for capturing photos with automatic geolocation tagging and server upload functionality.

## ✨ Features

- 📷 **Fullscreen Camera Preview** - Capture moments in high quality
- 📍 **Automatic Geolocation** - GPS coordinates are automatically attached to each photo
- 💬 **Photo Comments** - Add text notes to your photos
- ☁️ **Server Upload** - Instant upload of photos with metadata
- 🎨 **Modern UI** - Beautiful interface with gradients and smooth animations
- 📱 **Responsive Design** - Works on all screen sizes
- ⚡ **Error Handling** - Graceful handling when camera or GPS is unavailable

## 🛠 Technologies

- **Flutter** - Cross-platform development framework
- **Camera** - Device camera integration
- **Geolocator** - GPS coordinates retrieval
- **HTTP** - Server data upload
- **Permission Handler** - Permission management

## 📋 Requirements

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- iOS 12.0+ or Android API 21+
- Device with camera
- Camera and location permissions

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ankazuzu/camera_app.git
   cd camera_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## 📖 Usage

1. **Open the app** - Camera automatically initializes
2. **Wait for GPS coordinates** - Coordinates will appear at the top of the screen
3. **Enter a comment** (optional) - Add text to your photo
4. **Press "Capture & Upload"** - Photo will be captured and sent to the server
5. **Get confirmation** - Notification about successful upload

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── screens/
│   └── camera_screen.dart   # Main camera screen
└── services/
    ├── location_service.dart  # Geolocation service
    └── upload_service.dart    # Photo upload service

test/
├── widget_test.dart         # Widget tests
├── screens/
│   └── camera_screen_test.dart
├── services/
│   ├── location_service_test.dart
│   └── upload_service_test.dart
└── integration_test.dart    # Integration tests
```

## 🧪 Testing

Run all tests:
```bash
flutter test
```

Run a specific test:
```bash
flutter test test/services/location_service_test.dart
```

Test coverage:
- ✅ All services (LocationService, UploadService)
- ✅ Main widgets (MyApp, CameraScreen)
- ✅ Error handling
- ✅ Component integration

## 🔧 Configuration

### Server URL Setup

Change the URL in `lib/services/upload_service.dart`:
```dart
static const String uploadUrl = 'YOUR_SERVER_URL';
```

### Request Format

The app sends a POST request with multipart/form-data:
- `comment` - Text comment
- `latitude` - Latitude (double)
- `longitude` - Longitude (double)
- `photo` - Image file

## 📱 Supported Platforms

- ✅ iOS
- ✅ Android

## 👤 Author

**Your Name**
- GitHub: [@ankazuzu](https://github.com/ankazuzu)
