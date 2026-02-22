enum NavigationStatus {
  idle,
  initializing,
  active,
  error,
}

class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});
}

class Detection {
  final List<double> box; // [x1, y1, x2, y2]
  final String label;
  final double confidence;

  Detection({
    required this.box,
    required this.label,
    required this.confidence,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      box: List<double>.from(json['box'] ?? []),
      label: json['label'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
    );
  }
}
