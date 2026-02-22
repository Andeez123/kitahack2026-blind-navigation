import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> initialize() async {
    try {
      // Dispose any existing controller first
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
        _isInitialized = false;
      }

      // Request camera permission first
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied. Please grant camera access in your browser settings.');
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device.');
      }

      // Prefer back camera (environment facing)
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
    } on CameraException catch (e) {
      _isInitialized = false;
      String errorMsg = 'Camera error: ';
      switch (e.code) {
        case 'cameraAccessDenied':
          errorMsg = 'Camera access denied. Please check your browser permissions.';
          break;
        case 'cameraNotReadable':
          errorMsg = 'Camera is not readable. It may be in use by another application. Please close other apps using the camera.';
          break;
        case 'cameraNotFound':
          errorMsg = 'No camera found on this device.';
          break;
        default:
          errorMsg = 'Camera error: ${e.description ?? e.code}';
      }
      throw Exception(errorMsg);
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;

  CameraController? get controller => _controller;

  Future<Uint8List?> captureImage() async {
    if (!isInitialized) {
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      // Resize to 320x240 and compress
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return null;
      
      final resized = img.copyResize(
        decodedImage,
        width: 320,
        height: 240,
      );
      
      final jpeg = img.encodeJpg(resized, quality: 40);
      return Uint8List.fromList(jpeg);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
