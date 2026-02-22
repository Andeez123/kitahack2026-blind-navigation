# Flutter App Setup Guide

## Quick Start

1. **Install Flutter dependencies:**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Configure API Keys:**
   - Open `lib/screens/app_screen.dart`
   - Replace `YOUR_GEMINI_API_KEY` with your Google Gemini API key
   - Replace `YOUR_GOOGLE_MAPS_API_KEY` with your Google Maps API key
   
   Alternatively, you can use environment variables or a config file.

3. **Run the app:**
   ```bash
   flutter run
   ```

## Features Implemented

### ✅ Core Features
- **Initial Activation Screen**: Large yellow button with "Tap to Activate"
- **Standby Screen**: Shows GPS status and listens for "Start" command
- **Active Navigation Screen**: 
  - Map view with user location
  - Camera thumbnail with object detection overlays
  - Hazard alerts with "STOP" overlay
  - Stop button

### ✅ Services
- **CameraService**: Camera access and image capture (320x240, JPEG quality 40%)
- **LocationService**: GPS tracking with high accuracy
- **WebSocketService**: Backend connection for object detection
- **SpeechService**: Speech recognition and text-to-speech
- **GeminiService**: Google Gemini AI integration
- **MapsService**: Google Maps API (Places search, Directions)
- **AudioService**: Alert and activation sounds

### ✅ State Management
- Provider pattern for state management
- Navigation status tracking (IDLE, INITIALIZING, ACTIVE, ERROR)
- Real-time updates for location, detections, and hazards

## Important Notes

### Gemini Live API
The Gemini Live API is not directly available in the Dart SDK. The current implementation uses the standard Generative AI API. For full Live API support with real-time audio streaming, you would need to:
- Implement HTTP WebSocket connections directly
- Handle the Live API protocol manually
- Or use a platform channel to bridge to native code

### Backend Connection
The app expects the backend WebSocket server at:
```
ws://localhost:8000/ws/vision
```

For mobile devices, change `localhost` to your actual backend IP address.

### Permissions
The app requires:
- Camera permission
- Microphone permission
- Location permission (fine and coarse)

These are configured in:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## Architecture

```
lib/
├── main.dart                 # App entry point
├── app_state.dart            # State management with Provider
├── types.dart                # Data models (Location, Detection, NavigationStatus)
├── screens/
│   ├── app_screen.dart       # Main screen router
│   ├── initial_screen.dart   # Initial activation UI
│   ├── standby_screen.dart   # Standby/listening UI
│   └── active_screen.dart    # Active navigation UI
└── services/
    ├── camera_service.dart    # Camera handling
    ├── location_service.dart # GPS tracking
    ├── websocket_service.dart # Backend WebSocket
    ├── speech_service.dart   # Speech recognition & TTS
    ├── gemini_service.dart   # Gemini AI integration
    ├── maps_service.dart     # Google Maps API
    └── audio_service.dart    # Audio playback
```

## Differences from React Version

1. **Gemini Live API**: Uses standard API instead of Live API (requires additional implementation)
2. **Audio Processing**: Simplified audio handling (can be enhanced with flutter_sound)
3. **Maps Display**: Uses static map images instead of interactive map (can be enhanced with google_maps_flutter widget)
4. **State Management**: Uses Provider instead of React hooks

## Next Steps

1. Add environment variable support for API keys
2. Implement full Gemini Live API support via HTTP WebSocket
3. Add interactive Google Maps widget
4. Enhance audio processing for better TTS playback
5. Add error handling and retry logic
6. Implement route path visualization on map
7. Add unit and integration tests
