import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_tools_backend/core/services/weather_api_service.dart';
import 'package:bit_tools_backend/features/weather/weather_screen.dart';

void main() {
  group('WeatherScreen Integration & Widget Tests', () {
    late WeatherApiService mockWeatherService;

    setUp(() {
      final mockClient = MockClient((request) async {
        final host = request.url.host;
        final path = request.url.path;

        // Open-Meteo forecast endpoint
        if (host == 'api.open-meteo.com' && path == '/v1/forecast') {
          final lat = double.tryParse(request.url.queryParameters['latitude'] ?? '0') ?? 0.0;
          final isChennai = (lat - 13.0827).abs() < 0.01;

          return http.Response(
            jsonEncode({
              'latitude': lat,
              'longitude': 80.0,
              'timezone': 'Asia/Kolkata',
              'current': {
                'time': '2026-10-10T14:00',
                'temperature_2m': isChennai ? 34.5 : 31.0,
                'is_day': 1,
                'relative_humidity_2m': isChennai ? 72 : 68,
                'wind_speed_10m': isChennai ? 12.0 : 7.2,
              },
              'hourly': {
                'time': ['2026-10-10T00:00', '2026-10-10T06:00', '2026-10-10T12:00', '2026-10-10T18:00'],
                'temperature_2m': [27.0, 26.5, 33.0, 30.0],
              },
              'daily': {
                'time': ['2026-10-10', '2026-10-11', '2026-10-12'],
                'weathercode': [isChennai ? 1 : 0, 0, 2],
                'temperature_2m_max': [34.0, 33.5, 34.0],
                'temperature_2m_min': [26.0, 25.5, 25.0],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        // BigDataCloud reverse geocoding endpoint
        if (host == 'api.bigdatacloud.net' && path == '/data/reverse-geocode-client') {
          return http.Response(
            jsonEncode({
              'city': 'Tiruvallur',
              'principalSubdivision': 'Tamil Nadu',
              'countryName': 'India',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        // Open-Meteo geocoding search
        if (host == 'geocoding-api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'Chennai',
                  'latitude': 13.0827,
                  'longitude': 80.2707,
                  'admin1': 'Tamil Nadu',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 200);
      });

      mockWeatherService = WeatherApiService(client: mockClient);
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: WeatherScreen(weatherApiService: mockWeatherService),
        ),
      );
    }

    testWidgets('Renders WeatherScreen header, chips, and initial location cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Weather Forecast'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.textContaining('Tiruvallur'), findsAtLeastNWidgets(1));

      // Verify Quick City Chips
      expect(find.text('Tiruvallur'), findsAtLeastNWidgets(1));
      expect(find.text('Chennai'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);
      expect(find.text('Mumbai'), findsOneWidget);

      // Verify Metrics Highlights
      expect(find.textContaining('Humidity'), findsOneWidget);
      expect(find.text("Today's Highlights"), findsOneWidget);
      expect(find.text('SUNRISE'), findsOneWidget);
      expect(find.text('SUNSET'), findsOneWidget);
    });

    testWidgets('Tapping search icon toggles search input field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Search bar initially closed
      expect(find.byType(TextField), findsNothing);

      // Tap search toggle icon
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Search bar is now visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close toggle icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Search bar is hidden again
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Tapping quick city chip switches location and updates forecast', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 'Chennai' quick chip
      final chennaiChip = find.text('Chennai');
      expect(chennaiChip, findsOneWidget);
      await tester.tap(chennaiChip);
      await tester.pumpAndSettle();

      // Should now show Chennai in header location
      expect(find.textContaining('Chennai'), findsAtLeastNWidgets(1));
      expect(find.text('35°'), findsOneWidget); // 34.5 rounded
    });
  });
}
