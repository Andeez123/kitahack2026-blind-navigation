import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'initial_screen.dart';
import 'standby_screen.dart';
import 'active_screen.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      final geminiKey = dotenv.env['VITE_GEMINI_API_KEY'] ?? '';
      final mapsKey = dotenv.env['VITE_GOOGLE_MAPS_API_KEY'] ?? '';
      state.initializeServices(geminiKey, mapsKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (!state.hasInteracted) {
          return InitialScreen(
            onEnableVoice: () => state.enableVoice(),
          );
        } else if (!state.isLive) {
          return StandbyScreen(
            gpsActive: state.gpsActive,
            error: state.error,
            onStart: () => state.startSession(),
          );
        } else {
          return ActiveScreen(
            location: state.location,
            routePath: state.routePath,
            mapsApiKey: state.mapsApiKey,
            hazardDetected: state.hazardDetected,
            backendDetections: state.backendDetections,
            cameraController: state.cameraController,
            onStop: () => state.stopSession(),
          );
        }
      },
    );
  }
}
