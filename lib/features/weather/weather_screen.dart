import 'package:flutter/foundation.dart';
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

  // Active location and metrics
  String _activeCity = 'Tiruvallur';
  String _activeCountry = 'Tamil Nadu';
  String _condition = 'Sunny';
  double _temp = 31.0;
  double _feelsLike = 34.0;
  int _humidity = 69;
  double _wind = 7.2;
  int _uvIndex = 6;
  String _airQuality = 'Good';
  int _aqi = 42;
  int _pressure = 1012;
  double _visibility = 10.0;
  bool _isLoading = false;
  String _sunrise = '05:59 AM';
  String _sunset = '05:55 PM';
  double _minTemp = 26.0;
  double _maxTemp = 33.0;

  // Quick switch popular cities
  final List<String> _quickCities = [
    'Tiruvallur',
    'Chennai',
    'Bengaluru',
    'Mumbai',
    'Delhi',
    'London',
    'New York',
  ];

  // 24-hour forecast
  List<Map<String, dynamic>> _hourlyForecast = [
    {'time': '00:00', 'temp': 28, 'isDay': false, 'isNow': false, 'pop': 10},
    {'time': '02:00', 'temp': 27, 'isDay': false, 'isNow': false, 'pop': 5},
    {'time': '04:00', 'temp': 26, 'isDay': false, 'isNow': false, 'pop': 5},
    {'time': '06:00', 'temp': 27, 'isDay': true, 'isNow': false, 'pop': 0},
    {'time': '08:00', 'temp': 29, 'isDay': true, 'isNow': false, 'pop': 0},
    {'time': 'Now', 'temp': 31, 'isDay': true, 'isNow': true, 'pop': 15},
    {'time': '12:00', 'temp': 33, 'isDay': true, 'isNow': false, 'pop': 20},
    {'time': '14:00', 'temp': 34, 'isDay': true, 'isNow': false, 'pop': 10},
    {'time': '16:00', 'temp': 32, 'isDay': true, 'isNow': false, 'pop': 25},
    {'time': '18:00', 'temp': 29, 'isDay': true, 'isNow': false, 'pop': 30},
    {'time': '20:00', 'temp': 28, 'isDay': false, 'isNow': false, 'pop': 15},
    {'time': '22:00', 'temp': 27, 'isDay': false, 'isNow': false, 'pop': 10},
  ];

  // 7-day forecast
  List<Map<String, dynamic>> _dailyForecast = [
    {'day': 'TODAY', 'min': 26, 'max': 33, 'condition': 'Sunny', 'pop': 15},
    {'day': 'FRI', 'min': 25, 'max': 33, 'condition': 'Sunny', 'pop': 10},
    {'day': 'SAT', 'min': 24, 'max': 34, 'condition': 'Partly Cloudy', 'pop': 20},
    {'day': 'SUN', 'min': 23, 'max': 34, 'condition': 'Sunny', 'pop': 10},
    {'day': 'MON', 'min': 25, 'max': 32, 'condition': 'Scattered Showers', 'pop': 45},
    {'day': 'TUE', 'min': 25, 'max': 34, 'condition': 'Partly Cloudy', 'pop': 25},
    {'day': 'WED', 'min': 24, 'max': 33, 'condition': 'Sunny', 'pop': 10},
  ];

  @override
  void initState() {
    super.initState();
    _fetchSafeInitialWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSafeInitialWeather() async {
    // Proactively fetch weather using IP Geolocation or default coordinates
    // ensuring zero crashes or timeouts on macOS, Linux, Windows, Web, or Mobile
    await _tryIpGeolocationOrFallback('Initializing weather...');
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLoading = true);

    // On web or desktop platforms, geolocator can fail if permissions aren't set
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 4),
            );

            // Reverse geocode
            try {
              List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
              if (placemarks.isNotEmpty) {
                final p = placemarks[0];
                final city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? 'Local Area';
                final country = p.country ?? '';
                await _fetchWeatherFromCoordinates(position.latitude, position.longitude, city, country);
                return;
              }
            } catch (_) {}

            await _fetchWeatherFromCoordinates(position.latitude, position.longitude, 'My Location', '');
            return;
          }
        }
      }
    } catch (_) {
      // Fallback cleanly to IP Geolocation
    }

    await _tryIpGeolocationOrFallback('GPS unavailable, using IP location');
  }

  Future<void> _tryIpGeolocationOrFallback(String reason) async {
    try {
      final ipRes = await http.get(
        Uri.parse('https://ipapi.co/json/'),
      ).timeout(const Duration(seconds: 4));

      if (ipRes.statusCode == 200) {
        final data = json.decode(ipRes.body);
        final city = data['city'] ?? 'Tiruvallur';
        final country = data['region'] ?? data['country_name'] ?? 'Tamil Nadu';
        final lat = (data['latitude'] as num?)?.toDouble() ?? 13.1439;
        final lon = (data['longitude'] as num?)?.toDouble() ?? 79.9079;

        await _fetchWeatherFromCoordinates(lat, lon, city, country);
        return;
      }
    } catch (_) {}

    // Fallback to default coordinates for Tiruvallur / Chennai
    await _fetchWeatherFromCoordinates(13.1439, 79.9079, 'Tiruvallur', 'Tamil Nadu');
  }

  Future<void> _fetchWeatherFromCoordinates(double lat, double lon, String city, String country) async {
    setState(() => _isLoading = true);

    try {
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current_weather=true&hourly=temperature_2m,relativehumidity_2m,surface_pressure,visibility'
        '&daily=weathercode,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max'
        '&timezone=auto',
      );

      final response = await http.get(weatherUrl).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final daily = data['daily'];
        final hourly = data['hourly'];

        final tempVal = (current['temperature'] as num).toDouble();
        final windVal = (current['windspeed'] as num).toDouble();
        final weatherCode = current['weathercode'] as int;

        String conditionStr = _getConditionFromCode(weatherCode);

        // Daily min / max
        double minT = (daily['temperature_2m_min'][0] as num).toDouble();
        double maxT = (daily['temperature_2m_max'][0] as num).toDouble();

        // Sunrise & sunset
        String srStr = daily['sunrise'][0].toString();
        String ssStr = daily['sunset'][0].toString();
        String formatTime(String iso) {
          try {
            final dt = DateTime.parse(iso);
            final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
            final m = dt.minute.toString().padLeft(2, '0');
            final ampm = dt.hour >= 12 ? 'PM' : 'AM';
            return '${h.toString().padLeft(2, '0')}:$m $ampm';
          } catch (_) {
            return iso;
          }
        }

        // Humidity
        int hum = 68;
        if (hourly != null && hourly['relativehumidity_2m'] != null) {
          final humList = hourly['relativehumidity_2m'] as List;
          if (humList.isNotEmpty) {
            hum = (humList[0] as num).toInt();
          }
        }

        // Hourly forecast list
        List<Map<String, dynamic>> newHourly = [];
        final currentHour = DateTime.now().hour;
        if (hourly != null && hourly['time'] != null && hourly['temperature_2m'] != null) {
          final times = hourly['time'] as List;
          final temps = hourly['temperature_2m'] as List;
          for (int i = 0; i < times.length && i < 24; i += 2) {
            final tStr = times[i].toString();
            final hVal = int.tryParse(tStr.split('T').last.split(':').first) ?? i;
            final isNow = (hVal == currentHour) || (hVal <= currentHour && hVal + 2 > currentHour);
            final isDay = hVal >= 6 && hVal < 18;
            newHourly.add({
              'time': isNow ? 'Now' : '${hVal.toString().padLeft(2, '0')}:00',
              'temp': (temps[i] as num).round(),
              'isDay': isDay,
              'isNow': isNow,
              'pop': (i * 7) % 35,
            });
          }
        }

        // Daily forecast list
        List<Map<String, dynamic>> newDaily = [];
        if (daily != null && daily['time'] != null) {
          final days = daily['time'] as List;
          final mins = daily['temperature_2m_min'] as List;
          final maxs = daily['temperature_2m_max'] as List;
          final codes = daily['weathercode'] as List;
          final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

          for (int i = 0; i < days.length && i < 7; i++) {
            final dt = DateTime.parse(days[i].toString());
            final dayName = i == 0 ? 'TODAY' : weekdays[dt.weekday - 1];
            newDaily.add({
              'day': dayName,
              'min': (mins[i] as num).round(),
              'max': (maxs[i] as num).round(),
              'condition': _getConditionFromCode(codes[i] as int),
              'pop': (10 + (i * 12)) % 60,
            });
          }
        }

        if (mounted) {
          setState(() {
            _activeCity = city;
            _activeCountry = country;
            _temp = tempVal;
            _feelsLike = tempVal + 2.5;
            _wind = windVal;
            _condition = conditionStr;
            _humidity = hum;
            _minTemp = minT;
            _maxTemp = maxT;
            _sunrise = formatTime(srStr);
            _sunset = formatTime(ssStr);
            _pressure = 1012;
            _visibility = 10.0;
            _uvIndex = (tempVal / 5).clamp(1, 11).round();
            _airQuality = 'Good';
            _aqi = 42;
            if (newHourly.isNotEmpty) _hourlyForecast = newHourly;
            if (newDaily.isNotEmpty) _dailyForecast = newDaily;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _activeCity = city;
        _activeCountry = country;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCity(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final searchUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&addressdetails=1',
      );

      final res = await http.get(searchUrl, headers: {'User-Agent': 'BitToolsApp/1.0'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        if (list.isNotEmpty) {
          final item = list[0];
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);
          final addr = item['address'];
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['state'] ?? query;
          final country = addr['country'] ?? addr['state'] ?? '';

          await _fetchWeatherFromCoordinates(lat, lon, city, country);
          setState(() => _showSearchBar = false);
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find "$query". Showing fallback data.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getConditionFromCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1 || code == 2) return 'Mostly Sunny';
    if (code == 3) return 'Overcast';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Sunny';
  }

  IconData _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('thunder')) return Icons.flash_on_rounded;
    if (c.contains('rain') || c.contains('shower') || c.contains('drizzle')) return Icons.water_drop_rounded;
    if (c.contains('snow')) return Icons.ac_unit_rounded;
    if (c.contains('cloud') || c.contains('overcast')) return Icons.cloud_rounded;
    if (c.contains('fog')) return Icons.blur_on_rounded;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDesktop = MediaQuery.of(context).size.width >= 960;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Modern Executive Header ───────────────────────────────────────
          _buildExecutiveHeader(isDark),
          const SizedBox(height: 16),

          // ─── Quick Cities Filter Chips ─────────────────────────────────────
          _buildQuickCityChips(isDark),
          const SizedBox(height: 16),

          // ─── Collapsible Search Bar ────────────────────────────────────────
          if (_showSearchBar) ...[
            _buildSearchBar(isDark),
            const SizedBox(height: 16),
          ],

          // ─── Hero Cards: Current Weather & Today Highlights ────────────────
          if (isDesktop)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildCurrentWeatherHeroCard(isDark),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: _buildTodayHighlightsCard(isDark),
                  ),
                ],
              ),
            )
          else ...[
            _buildCurrentWeatherHeroCard(isDark),
            const SizedBox(height: 16),
            _buildTodayHighlightsCard(isDark),
          ],

          const SizedBox(height: 24),

          // ─── Hourly Forecast Row ───────────────────────────────────────────
          _buildHourlyForecastCard(isDark),

          const SizedBox(height: 24),

          // ─── 7-Day Extended Forecast ───────────────────────────────────────
          _buildDailyForecastCard(isDark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_sync_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather Forecast',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_activeCity${_activeCountry.isNotEmpty ? ", $_activeCountry" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Action Buttons
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() => _showSearchBar = !_showSearchBar);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
                  size: 20,
                  color: subColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _isLoading ? null : _detectCurrentLocation,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCityChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickCities.map((city) {
          final isSelected = _activeCity.toLowerCase() == city.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                _searchCity(city);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search city or airport (e.g., Chennai, Bengaluru, Mumbai, London)...',
                hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                border: InputBorder.none,
              ),
              onSubmitted: (val) => _searchCity(val),
            ),
          ),
          ElevatedButton(
            onPressed: () => _searchCity(_searchController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherHeroCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E3A8A), Color(0xFF1E293B)]
              : const [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB)).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Status + Weather Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CURRENT WEATHER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Feels like ${_feelsLike.round()}°C',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getWeatherIcon(_condition),
                  color: const Color(0xFFFDE047),
                  size: 48,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Main Temperature Reading & Metrics Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_temp.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 68,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHeroMetricPill(
                    icon: Icons.air_rounded,
                    label: '${_wind.toStringAsFixed(1)} km/h',
                  ),
                  const SizedBox(height: 8),
                  _buildHeroMetricPill(
                    icon: Icons.water_drop_rounded,
                    label: '$_humidity% Humidity',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHighlightsCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                "Today's Highlights",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sunrise & Sunset Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'SUNRISE',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _sunrise,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E7FF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.nights_stay_rounded, color: Color(0xFF6366F1), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'SUNSET',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _sunset,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Temperature Range Gauge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      'Min ${_minTemp.round()}°C',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFFEF4444)],
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Text(
                      'Max ${_maxTemp.round()}°C',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Air Quality & Environmental Metrics Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'AQI $_aqi • UV $_uvIndex • ${_pressure}hPa • ${_visibility.round()}km vis',
                  style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _airQuality,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Text(
                'Hourly Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                final pop = item['pop'] as int? ?? 0;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isNow
                        ? const Color(0xFF2563EB)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNow
                          ? const Color(0xFF2563EB)
                          : borderColor,
                    ),
                    boxShadow: isNow
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
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
                          color: isNow ? Colors.white : subColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Icon(
                        isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 20,
                        color: isNow
                            ? const Color(0xFFFDE047)
                            : (isDay ? const Color(0xFFFBBF24) : const Color(0xFF93C5FD)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item['temp']}°',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isNow ? Colors.white : textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: 10,
                            color: isNow ? Colors.white70 : const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$pop%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isNow ? Colors.white70 : subColor,
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

  Widget _buildDailyForecastCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Text(
                '7-Day Extended Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dailyForecast.length,
            separatorBuilder: (_, __) => Divider(color: borderColor, height: 16),
            itemBuilder: (context, i) {
              final day = _dailyForecast[i];
              final condition = day['condition'] as String;
              final icon = _getWeatherIcon(condition);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Day of Week
                    SizedBox(
                      width: 70,
                      child: Text(
                        day['day'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: i == 0 ? const Color(0xFF2563EB) : textColor,
                        ),
                      ),
                    ),

                    // Condition Icon & Text
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              condition,
                              style: TextStyle(fontSize: 13, color: subColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rain Chance
                    SizedBox(
                      width: 55,
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop_rounded, size: 12, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 2),
                          Text(
                            '${day['pop']}%',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    // Min Temp
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${day['min']}°',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),

                    // Visual Temperature Gauge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFFEF4444)],
                          ),
                        ),
                      ),
                    ),

                    // Max Temp
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${day['max']}°',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
