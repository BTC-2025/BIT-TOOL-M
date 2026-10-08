import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  // Weather state variables initialized with reference values
  String _activeCity = 'Tiruvallur';
  String _activeCountry = 'Tamil Nadu';
  String _condition = 'Sunny';
  double _temp = 31.0;
  int _humidity = 69;
  double _wind = 7.2;
  int _uvIndex = 6;
  String _airQuality = 'Good';
  bool _isLoading = false;
  String _sunrise = '05:59';
  String _sunset = '17:55';
  double _minTemp = 26.0;
  double _maxTemp = 33.0;

  // Hourly forecast state
  List<Map<String, dynamic>> _hourlyForecast = [
    {'time': '00:00', 'temp': 28, 'isDay': false, 'isNow': false},
    {'time': '01:00', 'temp': 27, 'isDay': false, 'isNow': false},
    {'time': '02:00', 'temp': 27, 'isDay': false, 'isNow': false},
    {'time': '03:00', 'temp': 26, 'isDay': false, 'isNow': false},
    {'time': '04:00', 'temp': 27, 'isDay': false, 'isNow': false},
    {'time': '05:00', 'temp': 27, 'isDay': false, 'isNow': false},
    {'time': '06:00', 'temp': 27, 'isDay': true, 'isNow': false},
    {'time': '07:00', 'temp': 28, 'isDay': true, 'isNow': false},
    {'time': '08:00', 'temp': 30, 'isDay': true, 'isNow': false},
    {'time': 'Now', 'temp': 31, 'isDay': true, 'isNow': true},
  ];

  // 7-day forecast state
  List<Map<String, dynamic>> _dailyForecast = [
    {'day': 'TODAY', 'min': 26, 'max': 33, 'condition': 'Sunny'},
    {'day': 'FRI', 'min': 25, 'max': 33, 'condition': 'Sunny'},
    {'day': 'SAT', 'min': 24, 'max': 34, 'condition': 'Sunny'},
    {'day': 'SUN', 'min': 23, 'max': 34, 'condition': 'Sunny'},
    {'day': 'MON', 'min': 25, 'max': 32, 'condition': 'Sunny'},
    {'day': 'TUE', 'min': 25, 'max': 34, 'condition': 'Sunny'},
    {'day': 'WED', 'min': 24, 'max': 33, 'condition': 'Sunny'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Request and fetch location coordinates
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _tryIpGeolocationOrFallback('Location services disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _tryIpGeolocationOrFallback('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _tryIpGeolocationOrFallback(
          'Location permission permanently denied.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      // 2. Reverse geocode coordinates using package:geocoding with OSM fallback
      String cityName = 'Tiruvallur';
      String countryName = 'Tamil Nadu';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String? city =
              place.locality ??
              place.subLocality ??
              place.subAdministrativeArea ??
              place.administrativeArea;
          if (city != null && city.isNotEmpty) {
            cityName = city;
          }
          countryName = place.administrativeArea ?? place.country ?? '';
        }
      } catch (e) {
        final geoUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
        );
        final geoResponse = await http.get(
          geoUrl,
          headers: {'User-Agent': 'BitToolsApp/1.0'},
        );
        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          final address = geoData['address'];
          if (address != null) {
            cityName =
                address['city'] ??
                address['town'] ??
                address['village'] ??
                address['suburb'] ??
                'Tiruvallur';
            countryName =
                address['state'] ?? address['country'] ?? 'Tamil Nadu';
          }
        }
      }

      // 3. Fetch Weather from Open-Meteo
      await _fetchWeatherFromCoordinates(
        position.latitude,
        position.longitude,
        cityName,
        countryName,
      );
    } catch (e) {
      await _tryIpGeolocationOrFallback('Failed to retrieve location weather.');
    }
  }

  Future<void> _tryIpGeolocationOrFallback(String snackBarMsg) async {
    try {
      final ipGeoUrl = Uri.parse('http://ip-api.com/json');
      final ipResponse = await http
          .get(ipGeoUrl)
          .timeout(const Duration(seconds: 4));
      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        if (ipData['status'] == 'success') {
          final lat = (ipData['lat'] as num).toDouble();
          final lon = (ipData['lon'] as num).toDouble();
          final city = ipData['city'] as String? ?? 'Tiruvallur';
          final region = ipData['regionName'] as String? ?? 'Tamil Nadu';
          await _fetchWeatherFromCoordinates(lat, lon, city, region);
          return;
        }
      }
    } catch (_) {}

    _loadFallbackCity(snackBarMsg);
  }

  void _loadFallbackCity(String snackBarMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$snackBarMsg Showing regional forecast.')),
      );
    }
    // Fallback coordinates for Tiruvallur, Tamil Nadu
    _fetchWeatherFromCoordinates(13.1432, 79.9079, 'Tiruvallur', 'Tamil Nadu');
  }

  Future<void> _fetchWeatherFromCoordinates(
    double lat,
    double lon,
    String city,
    String country,
  ) async {
    try {
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,uv_index&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset&timezone=auto',
      );

      final response = await http.get(weatherUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final hourly = data['hourly'];
        final daily = data['daily'];

        // Map Open-Meteo Weather Codes to condition names
        int code = current['weathercode'] ?? 0;
        String cond = 'Sunny';
        if (code <= 1) {
          cond = 'Sunny';
        } else if (code == 2 || code == 3) {
          cond = 'Cloudy';
        } else if (code >= 51 && code <= 67) {
          cond = 'Rainy';
        } else if (code >= 95) {
          cond = 'Stormy';
        }

        // Current hour data
        final currentHour = DateTime.now().hour;
        int hum = 69;
        int uv = 6;
        if (hourly != null) {
          final humList = hourly['relative_humidity_2m'];
          final uvList = hourly['uv_index'];
          if (humList != null && humList.length > currentHour) {
            hum = (humList[currentHour] as num).toInt();
          }
          if (uvList != null && uvList.length > currentHour) {
            uv = (uvList[currentHour] as num).toInt();
          }
        }

        // Sunrise & Sunset from daily
        String sunriseStr = '05:59';
        String sunsetStr = '17:55';
        double minT = 26.0;
        double maxT = 33.0;

        if (daily != null) {
          final sunrises = daily['sunrise'] as List?;
          final sunsets = daily['sunset'] as List?;
          final maxTemps = daily['temperature_2m_max'] as List?;
          final minTemps = daily['temperature_2m_min'] as List?;

          if (sunrises != null && sunrises.isNotEmpty) {
            final s = sunrises[0].toString();
            if (s.contains('T')) sunriseStr = s.split('T')[1];
          }
          if (sunsets != null && sunsets.isNotEmpty) {
            final s = sunsets[0].toString();
            if (s.contains('T')) sunsetStr = s.split('T')[1];
          }
          if (minTemps != null && minTemps.isNotEmpty) {
            minT = (minTemps[0] as num).toDouble();
          }
          if (maxTemps != null && maxTemps.isNotEmpty) {
            maxT = (maxTemps[0] as num).toDouble();
          }
        }

        // Build 10-point Hourly Forecast matching UI
        List<Map<String, dynamic>> tempHourly = [];
        if (hourly != null) {
          final temps = hourly['temperature_2m'] as List?;
          if (temps != null) {
            for (int h = 0; h < 9; h++) {
              final val = h < temps.length ? (temps[h] as num).round() : 27;
              tempHourly.add({
                'time': '${h.toString().padLeft(2, '0')}:00',
                'temp': val,
                'isDay': h >= 6 && h <= 18,
                'isNow': false,
              });
            }
            final currentT = (current['temperature'] as num).round();
            tempHourly.add({
              'time': 'Now',
              'temp': currentT,
              'isDay': currentHour >= 6 && currentHour <= 18,
              'isNow': true,
            });
          }
        }

        // Build 7-Day Forecast
        List<Map<String, dynamic>> tempDaily = [];
        if (daily != null) {
          final maxTemps = daily['temperature_2m_max'] as List?;
          final minTemps = daily['temperature_2m_min'] as List?;
          final daysOfWeek = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
          final todayWeekday = DateTime.now().weekday - 1;

          for (int i = 0; i < 7; i++) {
            final dayLabel = i == 0
                ? 'TODAY'
                : daysOfWeek[(todayWeekday + i) % 7];
            final dMin = (minTemps != null && minTemps.length > i)
                ? (minTemps[i] as num).round()
                : (24 + (i % 3));
            final dMax = (maxTemps != null && maxTemps.length > i)
                ? (maxTemps[i] as num).round()
                : (32 + (i % 3));

            tempDaily.add({
              'day': dayLabel,
              'min': dMin,
              'max': dMax,
              'condition': 'Sunny',
            });
          }
        }

        setState(() {
          _activeCity = city;
          _activeCountry = country;
          _condition = cond;
          _temp = (current['temperature'] as num).toDouble();
          _wind = (current['windspeed'] as num).toDouble();
          _humidity = hum;
          _uvIndex = uv;
          _airQuality = uv > 6 ? 'Fair' : 'Good';
          _sunrise = sunriseStr;
          _sunset = sunsetStr;
          _minTemp = minT;
          _maxTemp = maxT;
          if (tempHourly.isNotEmpty) _hourlyForecast = tempHourly;
          if (tempDaily.isNotEmpty) _dailyForecast = tempDaily;
          _isLoading = false;
        });
      } else {
        throw Exception('Open-Meteo status error');
      }
    } catch (_) {
      setState(() {
        _activeCity = city.isNotEmpty ? city : 'Tiruvallur';
        _activeCountry = country.isNotEmpty ? country : 'Tamil Nadu';
        _condition = 'Sunny';
        _temp = 31.0;
        _wind = 7.2;
        _humidity = 69;
        _uvIndex = 6;
        _airQuality = 'Good';
        _sunrise = '05:59';
        _sunset = '17:55';
        _minTemp = 26.0;
        _maxTemp = 33.0;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCityWeather() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&addressdetails=1',
      );

      final response = await http.get(
        searchUrl,
        headers: {'User-Agent': 'BitToolsApp/1.0'},
      );
      if (response.statusCode == 200) {
        final results = json.decode(response.body);
        if (results.isNotEmpty) {
          final res = results[0];
          double lat = double.parse(res['lat']);
          double lon = double.parse(res['lon']);

          final address = res['address'];
          String city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state'] ??
              query;
          String country = address['state'] ?? address['country'] ?? '';

          await _fetchWeatherFromCoordinates(lat, lon, city, country);
          setState(() {
            _showSearchBar = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('City not found. Please try another name.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search request failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: Weather Forecast & Location ──────────────────────────
          _buildHeader(),
          const SizedBox(height: 20),

          // ─── Search Bar (Collapsible) ─────────────────────────────────────
          if (_showSearchBar) ...[
            _buildSearchRow(),
            const SizedBox(height: 20),
          ],

          // ─── Top Cards (Current Weather + Today's Summary) ────────────────
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildCurrentWeatherCard(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: _buildTodaySummaryCard(),
                ),
              ],
            )
          else ...[
            _buildCurrentWeatherCard(),
            const SizedBox(height: 16),
            _buildTodaySummaryCard(),
          ],

          const SizedBox(height: 20),

          // ─── Hourly Forecast Card ─────────────────────────────────────────
          _buildHourlyForecastCard(),

          const SizedBox(height: 20),

          // ─── 7-Day Forecast Card ──────────────────────────────────────────
          _buildDailyForecastCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Forecast',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_activeCity${_activeCountry.isNotEmpty ? ', $_activeCountry' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFF64748B),
              ),
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                });
              },
              tooltip: 'Search City',
            ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF2563EB),
                    ),
              onPressed: _isLoading ? null : _fetchCurrentLocationWeather,
              tooltip: 'Detect Location',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search any city (e.g., Chennai, Bengaluru, Mumbai)...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              onSubmitted: (_) => _searchCityWeather(),
            ),
          ),
          ElevatedButton(
            onPressed: _searchCityWeather,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Weather',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(_condition),
                color: const Color(0xFFFDE047),
                size: 56,
              ),
            ],
          ),
          const SizedBox(height: 38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_temp.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.air_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 8),
                        Text(
                          '${_wind.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_outlined, color: Colors.white, size: 15),
                        const SizedBox(width: 8),
                        Text(
                          '$_humidity%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.device_thermostat_rounded,
                color: Color(0xFFF97316),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Today's Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Sunrise Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        color: Color(0xFFEA580C),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SUNRISE',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sunrise,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Sunset Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.wb_twilight_rounded,
                        color: Color(0xFF6366F1),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SUNSET',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sunset,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // MIN / MAX temperatures container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'MIN',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_minTemp.round()}°',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'MAX',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_maxTemp.round()}°',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UV Index: $_uvIndex',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Air Quality: $_airQuality',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String cond) {
    switch (cond) {
      case 'Sunny':
        return Icons.wb_sunny_rounded;
      case 'Rainy':
        return Icons.umbrella_rounded;
      case 'Cloudy':
        return Icons.wb_cloudy_rounded;
      case 'Stormy':
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  Widget _buildHourlyForecastCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_rounded, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text(
                'Hourly Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _hourlyForecast.map((item) {
                final isNow = item['isNow'] == true;
                final isDay = item['isDay'] == true;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isNow ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNow ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                    ),
                    boxShadow: isNow
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isNow ? FontWeight.bold : FontWeight.w600,
                          color: isNow ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Icon(
                        isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 20,
                        color: isNow
                            ? const Color(0xFFFDE047)
                            : (isDay
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF93C5FD)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${item['temp']}°',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isNow ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecastCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text(
                '7-Day Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _dailyForecast.map((day) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day['day'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${day['min']}°',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            '  •  ',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${day['max']}°',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
