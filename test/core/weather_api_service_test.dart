import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_tools_backend/core/api/api_config.dart';
import 'package:bit_tools_backend/core/models/weather_model.dart';
import 'package:bit_tools_backend/core/services/weather_api_service.dart';

void main() {
  group('WeatherApiService - Section 7 External Third-Party APIs', () {
    test('ApiConfig constructs exact Section 7 Open-Meteo forecast endpoint', () {
      final uri = ApiConfig.weatherForecastUri(
        latitude: 13.1439,
        longitude: 79.9079,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.open-meteo.com');
      expect(uri.path, '/v1/forecast');
      expect(uri.queryParameters['latitude'], '13.1439');
      expect(uri.queryParameters['longitude'], '79.9079');
      expect(uri.queryParameters['daily'], 'weathercode,temperature_2m_max,temperature_2m_min');
      expect(uri.queryParameters['hourly'], 'temperature_2m');
      expect(uri.queryParameters['current'], 'temperature_2m,is_day,relative_humidity_2m,wind_speed_10m');
      expect(uri.queryParameters['timezone'], 'auto');
    });

    test('ApiConfig constructs exact Section 7 BigDataCloud reverse geocoding endpoint', () {
      final uri = ApiConfig.reverseGeocodingUri(
        latitude: 13.1439,
        longitude: 79.9079,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.bigdatacloud.net');
      expect(uri.path, '/data/reverse-geocode-client');
      expect(uri.queryParameters['latitude'], '13.1439');
      expect(uri.queryParameters['longitude'], '79.9079');
      expect(uri.queryParameters['localityLanguage'], 'en');
    });

    test('fetchForecast parses Section 7 Open-Meteo payload correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.path, '/v1/forecast');
        expect(request.url.queryParameters['latitude'], '13.1439');
        expect(request.url.queryParameters['longitude'], '79.9079');
        expect(request.url.queryParameters['daily'], 'weathercode,temperature_2m_max,temperature_2m_min');
        expect(request.url.queryParameters['hourly'], 'temperature_2m');
        expect(request.url.queryParameters['current'], 'temperature_2m,is_day,relative_humidity_2m,wind_speed_10m');

        final samplePayload = {
          'latitude': 13.1439,
          'longitude': 79.9079,
          'timezone': 'Asia/Kolkata',
          'current': {
            'time': '2026-10-10T14:30',
            'interval': 900,
            'temperature_2m': 31.4,
            'is_day': 1,
            'relative_humidity_2m': 68,
            'wind_speed_10m': 7.6,
          },
          'hourly': {
            'time': [
              '2026-10-10T00:00',
              '2026-10-10T02:00',
              '2026-10-10T04:00',
              '2026-10-10T06:00',
              '2026-10-10T08:00',
              '2026-10-10T10:00',
              '2026-10-10T12:00',
              '2026-10-10T14:00',
            ],
            'temperature_2m': [27.5, 26.8, 26.2, 27.0, 29.3, 31.0, 32.5, 31.4],
          },
          'daily': {
            'time': [
              '2026-10-10',
              '2026-10-11',
              '2026-10-12',
              '2026-10-13',
              '2026-10-14',
              '2026-10-15',
              '2026-10-16',
            ],
            'weathercode': [0, 1, 2, 3, 61, 80, 0],
            'temperature_2m_max': [33.2, 33.8, 34.0, 32.5, 30.0, 31.2, 33.0],
            'temperature_2m_min': [25.8, 25.0, 24.5, 25.1, 24.0, 24.8, 25.0],
          },
        };

        return http.Response(
          jsonEncode(samplePayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WeatherApiService(client: mockClient);
      final weather = await service.fetchForecast(
        latitude: 13.1439,
        longitude: 79.9079,
        city: 'Tiruvallur',
        country: 'Tamil Nadu',
      );

      expect(weather, isNotNull);
      expect(weather!.city, 'Tiruvallur');
      expect(weather.country, 'Tamil Nadu');
      expect(weather.current.temperature, 31.4);
      expect(weather.current.isDay, isTrue);
      expect(weather.current.humidity, 68);
      expect(weather.current.windSpeed, 7.6);
      expect(weather.current.condition, 'Clear Sky');
      expect(weather.minTemp, 25.8);
      expect(weather.maxTemp, 33.2);
      expect(weather.hourly.isNotEmpty, isTrue);
      expect(weather.daily.length, 7);
      expect(weather.daily.first.day, 'TODAY');
      expect(weather.daily.first.condition, 'Clear Sky');
    });

    test('reverseGeocode parses Section 7 BigDataCloud reverse geocoding payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'api.bigdatacloud.net');
        expect(request.url.path, '/data/reverse-geocode-client');
        expect(request.url.queryParameters['latitude'], '13.1439');
        expect(request.url.queryParameters['longitude'], '79.9079');

        final sampleGeo = {
          'city': 'Tiruvallur',
          'locality': 'Tiruvallur',
          'principalSubdivision': 'Tamil Nadu',
          'countryName': 'India',
          'countryCode': 'IN',
        };

        return http.Response(
          jsonEncode(sampleGeo),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WeatherApiService(client: mockClient);
      final geo = await service.reverseGeocode(
        latitude: 13.1439,
        longitude: 79.9079,
      );

      expect(geo['city'], 'Tiruvallur');
      expect(geo['country'], 'Tamil Nadu');
    });

    test('reverseGeocode handles locality fallback if city is empty', () async {
      final mockClient = MockClient((request) async {
        final sampleGeo = {
          'city': '',
          'locality': 'Avadi',
          'principalSubdivision': 'Tamil Nadu',
          'countryName': 'India',
        };

        return http.Response(
          jsonEncode(sampleGeo),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WeatherApiService(client: mockClient);
      final geo = await service.reverseGeocode(
        latitude: 13.1167,
        longitude: 80.1000,
      );

      expect(geo['city'], 'Avadi');
      expect(geo['country'], 'Tamil Nadu');
    });

    test('fetchForecast returns null gracefully on non-200 HTTP response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = WeatherApiService(client: mockClient);
      final weather = await service.fetchForecast(
        latitude: 0.0,
        longitude: 0.0,
        city: 'Unknown',
        country: 'Unknown',
      );

      expect(weather, isNull);
    });

    test('reverseGeocode returns empty strings on HTTP failure without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = WeatherApiService(client: mockClient);
      final geo = await service.reverseGeocode(
        latitude: 0.0,
        longitude: 0.0,
      );

      expect(geo['city'], '');
      expect(geo['country'], '');
    });

    test('searchLocation resolves query via Open-Meteo geocoding search', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'geocoding-api.open-meteo.com');
        expect(request.url.queryParameters['name'], 'Chennai');

        final searchResult = {
          'results': [
            {
              'name': 'Chennai',
              'latitude': 13.0827,
              'longitude': 80.2707,
              'admin1': 'Tamil Nadu',
              'country': 'India',
            }
          ]
        };

        return http.Response(
          jsonEncode(searchResult),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WeatherApiService(client: mockClient);
      final loc = await service.searchLocation('Chennai');

      expect(loc, isNotNull);
      expect(loc!['city'], 'Chennai');
      expect(loc['country'], 'Tamil Nadu');
      expect(loc['latitude'], 13.0827);
      expect(loc['longitude'], 80.2707);
    });

    test('WeatherConditionHelper maps standard WMO codes accurately', () {
      expect(WeatherConditionHelper.getConditionFromCode(0), 'Clear Sky');
      expect(WeatherConditionHelper.getConditionFromCode(1), 'Mostly Sunny');
      expect(WeatherConditionHelper.getConditionFromCode(3), 'Overcast');
      expect(WeatherConditionHelper.getConditionFromCode(45), 'Foggy');
      expect(WeatherConditionHelper.getConditionFromCode(51), 'Drizzle');
      expect(WeatherConditionHelper.getConditionFromCode(61), 'Rain');
      expect(WeatherConditionHelper.getConditionFromCode(71), 'Snow');
      expect(WeatherConditionHelper.getConditionFromCode(80), 'Showers');
      expect(WeatherConditionHelper.getConditionFromCode(95), 'Thunderstorm');
      expect(WeatherConditionHelper.getConditionFromCode(999), 'Sunny');
    });
  });
}
