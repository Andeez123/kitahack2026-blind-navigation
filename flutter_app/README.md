# VisionGuide AI - Flutter App

Flutter implementation of the VisionGuide AI navigation assistant for the blind.

## Features

- Real-time object detection and depth estimation
- Text-to-speech navigation instructions
- Google Maps integration for navigation
- Hazard detection and alerts
- Voice-activated controls
- GPS location tracking
- Camera feed with detection overlays

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Google Gemini API key
- Google Maps API key

### Installation

1. Install dependencies:
```bash
cd flutter_app
flutter pub get
```

2. Configure API keys:
   - Create a `.env` file or update `lib/screens/app_screen.dart` with your API keys
   - Replace `YOUR_GEMINI_API_KEY` and `YOUR_GOOGLE_MAPS_API_KEY` with your actual keys

3. For Android:
   - Update `android/app/src/main/AndroidManifest.xml` if needed
   - Ensure minimum SDK version is 21 or higher

4. For iOS:
   - Update `ios/Runner/Info.plist` if needed
   - Run `pod install` in the `ios` directory

### Running the App

```bash
flutter run
```

## Architecture

- **State Management**: Provider pattern
- **Services**: 
  - `CameraService`: Handles camera access and image capture
  - `LocationService`: GPS location tracking
  - `WebSocketService`: Backend communication for object detection
  - `SpeechService`: Speech recognition and TTS
  - `GeminiService`: Google Gemini AI integration
  - `MapsService`: Google Maps API integration

## Notes

- The Gemini Live API is not directly available in the Dart SDK. The current implementation uses the standard API. For full Live API support, you may need to implement HTTP requests directly.
- Ensure the backend WebSocket server is running on `ws://localhost:8000/ws/vision`
- Camera permissions are required for the app to function

## Platform-Specific Notes

### Android
- Minimum SDK: 21
- Requires camera, microphone, and location permissions

### iOS
- Requires camera, microphone, and location permissions in Info.plist
- May need additional configuration for WebSocket connections
