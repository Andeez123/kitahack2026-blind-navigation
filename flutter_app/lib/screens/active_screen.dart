import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../types.dart';

class ActiveScreen extends StatelessWidget {
  final Location? location;
  final String? routePath;
  final String mapsApiKey;
  final bool hazardDetected;
  final List<Detection> backendDetections;
  final CameraController? cameraController;
  final VoidCallback onStop;

  const ActiveScreen({
    super.key,
    this.location,
    this.routePath,
    this.mapsApiKey = '',
    required this.hazardDetected,
    required this.backendDetections,
    this.cameraController,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map View
        Positioned.fill(
          child: location != null
              ? Image.network(
                  _getMapUrl(),
                  fit: BoxFit.cover,
                  color: const Color.fromRGBO(255, 255, 255, 0.9),
                  colorBlendMode: BlendMode.difference,
                )
              : const Center(
                  child: Text(
                    'Searching GPS...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF404040),
                    ),
                  ),
                ),
        ),

        // User Location Pointer
        if (location != null)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow.shade400,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.shade400.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Hazard Alert Overlay
        if (hazardDetected)
          Positioned.fill(
            child: Container(
              color: Colors.red.shade600.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'STOP',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Camera Thumbnail
        if (cameraController != null && cameraController!.value.isInitialized)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 96,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF27272A),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: CameraPreview(cameraController!),
                    ),
                  ),
                  // Detection Overlays
                  ...backendDetections.map((det) {
                    final box = det.box;
                    if (box.length < 4) return const SizedBox.shrink();
                    
                    // Map from 320x240 to thumbnail dimensions (96x128)
                    final left = (box[0] / 320) * 96;
                    final top = (box[1] / 240) * 128;
                    final width = ((box[2] - box[0]) / 320) * 96;
                    final height = ((box[3] - box[1]) / 240) * 128;
                    
                    return Positioned(
                      left: left,
                      top: top,
                      width: width,
                      height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.shade500, width: 1),
                          color: Colors.green.shade500.withOpacity(0.2),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                            ),
                            child: Text(
                              det.label,
                              style: const TextStyle(
                                fontSize: 6,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Stop Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF18181B),
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: onStop,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade900.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'STOP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getMapUrl() {
    if (location == null) return '';
    
    // Note: In production, pass MapsService instance or API key through constructor
    var url = 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${location!.latitude},${location!.longitude}'
        '&zoom=19'
        '&size=640x640'
        '&scale=2'
        '&maptype=roadmap'
        '&key=$mapsApiKey';
    
    if (routePath != null) {
      url += '&path=weight:5|color:0xFAFF00|enc:$routePath';
    }
    
    return url;
  }
}
