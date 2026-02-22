import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../types.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(List<Detection>)? onDetections;
  Function(bool)? onHazard;

  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['status'] == 'success') {
              if (data['detections'] != null) {
                final detections = (data['detections'] as List)
                    .map((d) => Detection.fromJson(d))
                    .toList();
                onDetections?.call(detections);
              }
              if (data['hazard'] == true) {
                onHazard?.call(true);
              }
            }
          } catch (e) {
            // Handle error
          }
        },
        onError: (error) {
          // Handle error
        },
      );
    } catch (e) {
      // Handle error
    }
  }

  void sendImage(Uint8List imageBytes) {
    if (_channel != null) {
      final base64 = base64Encode(imageBytes);
      _channel!.sink.add(jsonEncode({'image': base64}));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
