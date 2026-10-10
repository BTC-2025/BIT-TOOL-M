import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import '../models/weather_model.dart';

/// Dedicated service responsible for third-party Weather & Geocoding APIs (Section 7 of Mobile API Docs).
class WeatherApiService {
  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Retrieves weather forecast data from Open-Meteo according to Section 7 specs.
  ///
  /// Endpoint:
  /// GET https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&daily=weathercode,temperature_2m_max,temperature_2m_min&hourly=temperature_2m&current=temperature_2m,is_day,relative_humidity_2m,wind_speed_10m&timezone=auto
  Future<WeatherDataModel?> fetchForecast({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) async {
    final uri = ApiConfig.weatherForecastUri(
      latitude: latitude,
      longitude: longitude,
    );

    if (kDebugMode) {
      debugPrint('[WeatherAPI] Fetching forecast from: $uri');
    }

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final model = WeatherDataModel.fromOpenMeteoJson(
          json: decoded,
          latitude: latitude,
          longitude: longitude,
          city: city,
          country: country,
        );

        if (kDebugMode) {
          debugPrint(
            '[WeatherAPI] Successfully parsed weather for $city ($country): ${model.current.temperature}°C, ${model.current.condition}',
          );
        }

        return model;
      } else {
        if (kDebugMode) {
          debugPrint('[WeatherAPI] Server returned error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeatherAPI] Error fetching weather: $e');
      }
    }

    return null;
  }

  /// Resolves location name (city, region/country) from coordinates using BigDataCloud reverse geocoding.
  ///
  /// Endpoint:
  /// GET https://api.bigdatacloud.net/data/reverse-geocode-client?latitude={lat}&longitude={lon}&localityLanguage=en
  Future<Map<String, String>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = ApiConfig.reverseGeocodingUri(
      latitude: latitude,
      longitude: longitude,
    );

    if (kDebugMode) {
      debugPrint('[WeatherAPI] Reverse geocoding coordinates ($latitude, $longitude) via BigDataCloud: $uri');
    }

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        
        final cityField = data['city']?.toString().trim() ?? '';
        final localityField = data['locality']?.toString().trim() ?? '';
        final stateRaw = data['principalSubdivision'] ?? '';
        final countryRaw = data['countryName'] ?? '';

        String city = cityField.isNotEmpty ? cityField : localityField;
        String country = stateRaw.toString().trim();

        if (country.isEmpty) {
          country = countryRaw.toString().trim();
        }

        if (city.isEmpty) {
          final localityInfo = data['localityInfo'] as Map<String, dynamic>?;
          if (localityInfo != null) {
            final admin = localityInfo['administrative'] as List?;
            if (admin != null && admin.isNotEmpty) {
              for (final entry in admin.reversed) {
                if (entry is Map && entry['name'] != null) {
                  city = entry['name'].toString().trim();
                  break;
                }
              }
            }
          }
        }

        if (kDebugMode) {
          debugPrint('[WeatherAPI] Resolved location: city="$city", region="$country"');
        }

        return {
          'city': city,
          'country': country,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeatherAPI] Error in reverseGeocode: $e');
      }
    }

    return {
      'city': '',
      'country': '',
    };
  }

  /// Searches for city coordinates and returns latitude, longitude, city, country.
  Future<Map<String, dynamic>?> searchLocation(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cleanQuery)}&count=1&language=en&format=json',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final results = decoded['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final item = results.first as Map<String, dynamic>;
          final lat = (item['latitude'] as num).toDouble();
          final lon = (item['longitude'] as num).toDouble();
          final name = item['name']?.toString() ?? cleanQuery;
          final region = item['admin1']?.toString() ?? item['country']?.toString() ?? '';

          return {
            'latitude': lat,
            'longitude': lon,
            'city': name,
            'country': region,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeatherAPI] Geocoding search error: $e');
      }
    }

    return null;
  }
}
