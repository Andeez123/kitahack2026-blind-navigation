import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'types.dart';
import 'services/camera_service.dart';
import 'services/location_service.dart';
import 'services/websocket_service.dart';
import 'services/speech_service.dart';
import 'services/gemini_service.dart';
import 'services/maps_service.dart';
import 'services/audio_service.dart';

class AppState extends ChangeNotifier {
  NavigationStatus _status = NavigationStatus.idle;
  Location? _location;
  String? _error;
  bool _isLive = false;
  bool _hasInteracted = false;
  String _lastInstruction = "Vision Guide is ready.";
  bool _hazardDetected = false;
  List<Detection> _detectedObstacles = [];
  bool _gpsActive = false;
  String? _routePath;
  List<Detection> _backendDetections = [];

  // Services
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final WebSocketService _websocketService = WebSocketService();
  final SpeechService _speechService = SpeechService();
  final AudioService _audioService = AudioService();
  GeminiService? _geminiService;
  MapsService? _mapsService;
  String _mapsApiKey = '';

  // Streams
  StreamSubscription<Location>? _locationSubscription;
  Timer? _frameTimer;

  // Getters
  NavigationStatus get status => _status;
  Location? get location => _location;
  String? get error => _error;
  bool get isLive => _isLive;
  bool get hasInteracted => _hasInteracted;
  String get lastInstruction => _lastInstruction;
  bool get hazardDetected => _hazardDetected;
  List<Detection> get detectedObstacles => _detectedObstacles;
  bool get gpsActive => _gpsActive;
  String? get routePath => _routePath;
  List<Detection> get backendDetections => _backendDetections;
  CameraController? get cameraController => _cameraService.controller;
  String get mapsApiKey => _mapsApiKey;

  Future<void> initializeServices(String geminiApiKey, String mapsApiKey) async {
    _mapsApiKey = mapsApiKey;
    _geminiService = GeminiService(apiKey: geminiApiKey);
    _mapsService = MapsService(apiKey: mapsApiKey);
    
    // Don't initialize camera here - wait for user gesture (required on web)
    // Camera will be initialized when user starts a session
    
    await _speechService.initialize();
    
    _websocketService.onDetections = (detections) {
      _backendDetections = detections;
      notifyListeners();
    };
    
    _websocketService.onHazard = (isHazard) {
      _hazardDetected = isHazard;
      notifyListeners();
      if (isHazard) {
        _playAlertSound();
        Future.delayed(const Duration(milliseconds: 500), () {
          _hazardDetected = false;
          notifyListeners();
        });
      }
    };
  }

  Future<void> requestLocation() async {
    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      _location = loc;
      _gpsActive = true;
      notifyListeners();
    }
    
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.watchPosition().listen((loc) {
      _location = loc;
      _gpsActive = true;
      notifyListeners();
    });
  }

  void _playAlertSound() {
    _audioService.playAlertSound();
  }

  Future<void> enableVoice() async {
    _error = null;
    _audioService.playActivateSound();
    await requestLocation();
    _hasInteracted = true;
    notifyListeners();
    
    await _speechService.speak("Vision Guide ready. Say Start to begin.");
    
    _speechService.startListening((transcript) {
      if (transcript.contains('start') || 
          transcript.contains('hi') || 
          transcript.contains('hello')) {
        startSession();
      }
    });
  }

  Future<void> startSession() async {
    if (_isLive) return;
    
    _audioService.playActivateSound();
    _status = NavigationStatus.initializing;
    _error = null;
    notifyListeners();
    
    try {
      // Initialize camera when user starts session (user gesture required on web)
      if (!_cameraService.isInitialized) {
        try {
          await _cameraService.initialize();
        } catch (e) {
          _error = '$e';
          _status = NavigationStatus.error;
          notifyListeners();
          // Don't return - allow session to continue without camera
          // User can still use navigation features
        }
      }
      
      await requestLocation();
      
      if (_geminiService != null && _location != null) {
        await _geminiService!.startSession(
          onText: (text) {
            _lastInstruction = text;
            notifyListeners();
          },
          onAudio: (audio) {
            _audioService.playAudioFromBytes(audio);
          },
          location: _location,
        );
      }
      
      // Connect to backend WebSocket
      _websocketService.connect('ws://localhost:8000/ws/vision');
      
      // Start frame capture loop (only if camera is available)
      if (_cameraService.isInitialized) {
        _frameTimer = Timer.periodic(
          const Duration(milliseconds: 500), // 2 FPS
          (timer) async {
            if (!_isLive) return;
            
            final imageBytes = await _cameraService.captureImage();
            if (imageBytes != null) {
              // Send to Gemini
              await _geminiService?.sendImage(imageBytes);
              
              // Send to backend
              _websocketService.sendImage(imageBytes);
            }
          },
        );
      }
      
      _isLive = true;
      _status = NavigationStatus.active;
      notifyListeners();
      
      String message = "Navigation connected.";
      if (!_cameraService.isInitialized) {
        message += " Camera unavailable - navigation will continue without visual detection.";
      } else {
        message += " Where would you like to go today?";
      }
      await _speechService.speak(message);
    } catch (e) {
      _error = e.toString();
      _status = NavigationStatus.error;
      notifyListeners();
      stopSession();
    }
  }

  Future<void> stopSession() async {
    if (!_isLive) return;
    
    _isLive = false;
    _status = NavigationStatus.idle;
    _lastInstruction = "Vision Guide Standby.";
    _detectedObstacles = [];
    _routePath = null;
    notifyListeners();
    
    _frameTimer?.cancel();
    _websocketService.disconnect();
    _geminiService?.stopSession();
    _speechService.stopListening();
    
    await _speechService.speak("Navigation disconnected. I am back on standby.");
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _locationService.dispose();
    _websocketService.disconnect();
    _audioService.dispose();
    _locationSubscription?.cancel();
    _frameTimer?.cancel();
    super.dispose();
  }
}
