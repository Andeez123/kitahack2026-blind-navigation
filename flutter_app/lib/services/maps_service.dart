import 'dart:convert';
import 'package:http/http.dart' as http;
import '../types.dart';

class MapsService {
  final String apiKey;

  MapsService({required this.apiKey});

  Future<List<Map<String, dynamic>>> searchPlace(String query, Location? location) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(query)}'
        '${location != null ? '&location=${location.latitude},${location.longitude}' : ''}'
        '&radius=5000'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          return (data['results'] as List)
              .take(3)
              .map((r) => {
                    'name': r['name'],
                    'address': r['formatted_address'],
                    'place_id': r['place_id'],
                  })
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDirections(
    Location origin,
    String destination,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${Uri.encodeComponent(destination)}'
        '&mode=walking'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          return {
            'steps': (leg['steps'] as List)
                .map((s) => (s['html_instructions'] as String)
                    .replaceAll(RegExp(r'<[^>]*>'), ''))
                .toList(),
            'total_distance': leg['distance']?['text'],
            'total_duration': leg['duration']?['text'],
            'overview_polyline': route['overview_polyline']?['points'],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String getStaticMapUrl(Location location, {String? routePath}) {
    var url = 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${location.latitude},${location.longitude}'
        '&zoom=19'
        '&size=640x640'
        '&scale=2'
        '&maptype=roadmap'
        '&key=$apiKey';
    
    if (routePath != null) {
      url += '&path=weight:5|color:0xFAFF00|enc:$routePath';
    }
    
    return url;
  }
}
