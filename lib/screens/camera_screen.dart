import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/upload_service.dart';

/// Main camera screen with preview, comment input, and capture functionality
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final TextEditingController _commentController = TextEditingController();
  final LocationService _locationService = LocationService();
  final UploadService _uploadService = UploadService();

  bool _isInitialized = false;
  bool _isUploading = false;
  String? _errorMessage;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (mounted && position != null) {
      setState(() {
        _currentLocation = position;
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _errorMessage = 'No cameras available on this device';
      });
      return;
    }

    // Use the first available camera (usually back camera)
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _captureAndUpload() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showSnackBar('Camera is not ready', isError: true);
      return;
    }

    if (_isUploading) return;

    // Hide keyboard if open
    FocusScope.of(context).unfocus();

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get current location
      Position? position = await _locationService.getCurrentLocation();
      if (position == null) {
        _showSnackBar(
          'Failed to get location. Please enable location services.',
          isError: true,
        );
        setState(() => _isUploading = false);
        return;
      }

      // Update displayed location
      setState(() {
        _currentLocation = position;
      });

      // 2. Capture image
      XFile imageFile = await _controller!.takePicture();

      // 3. Get comment
      String comment = _commentController.text.trim();
      if (comment.isEmpty) {
        comment = 'No comment';
      }

      // 4. Upload to server
      bool success = await _uploadService.uploadPhoto(
        imageFile: File(imageFile.path),
        comment: comment,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (success) {
        _showSnackBar(
          'Photo uploaded successfully!\n'
          'Location: ${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}',
          duration: const Duration(seconds: 4),
        );
        _commentController.clear();
      } else {
        _showSnackBar(
          'Failed to upload photo. Please try again.',
          isError: true,
        );
      }

      // Clean up temporary image file
      try {
        await File(imageFile.path).delete();
      } catch (_) {}
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      // Hide keyboard after upload completes
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(
    String message, {
    Duration? duration,
    bool isError = false,
  }) {
    final isSuccess = message.toLowerCase().contains('success');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isError
                  ? Colors.red.withValues(alpha: 0.3)
                  : isSuccess
                  ? const Color(0xFF667eea).withValues(alpha: 0.5)
                  : Colors.orange.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isError
                            ? Colors.red
                            : isSuccess
                            ? const Color(0xFF667eea)
                            : Colors.orange)
                        .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isError
                      ? LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                        )
                      : isSuccess
                      ? const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        )
                      : LinearGradient(
                          colors: [Colors.orange[400]!, Colors.orange[600]!],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: _errorMessage != null
            ? _buildErrorView()
            : !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : _buildCameraView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fullscreen camera preview
        Center(child: CameraPreview(_controller!)),

        // Overlay controls
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                // Top app bar with location
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Photo Capture',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_currentLocation != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF667eea,
                              ).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF667eea),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange[400],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Getting location...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom controls
                SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Comment input field
                        TextField(
                          controller: _commentController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment to your photo...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF667eea),
                                width: 2.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          maxLines: 2,
                          maxLength: 100,
                        ),

                        const SizedBox(height: 20),

                        // Capture button
                        Container(
                          width: double.infinity,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: _isUploading
                                  ? [
                                      const Color(
                                        0xFF667eea,
                                      ).withValues(alpha: 0.5),
                                      const Color(
                                        0xFF764ba2,
                                      ).withValues(alpha: 0.5),
                                    ]
                                  : const [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: _isUploading
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF667eea,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF667eea,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                            border: _isUploading
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isUploading ? null : _captureAndUpload,
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: _isUploading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Uploading...',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 26,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Capture & Upload',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info text
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'GPS coordinates will be attached',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
