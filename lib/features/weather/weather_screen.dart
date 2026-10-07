import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/widgets/neumorphic_widgets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Weather state variables
  String _activeCity = 'Detecting Location...';
  String _activeCountry = '';
  String _condition = 'Cloudy'; // Sunny, Rainy, Cloudy, Stormy
  double _temp = 0.0;
  int _humidity = 0;
  double _wind = 0.0;
  int _uvIndex = 0;
  String _airQuality = 'Good';
  bool _isLoading = true;

  // Hourly and 7-day forecast state arrays
  List<Map<String, dynamic>> _hourlyForecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationWeather();
  }

  Future<void> _fetchCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _activeCity = 'Detecting Location...';
      _activeCountry = '';
    });

    try {
      // 1. Request and fetch location coordinates
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _loadFallbackCity('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _loadFallbackCity('Location permission permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // 2. Reverse geocode coordinates using package:geocoding with OSM fallback
      String cityName = 'Current Location';
      String countryName = '';

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
          String? postcode = place.postalCode;
          if (city != null && city.isNotEmpty) {
            cityName = (postcode != null && postcode.isNotEmpty)
                ? "$city, $postcode"
                : city;
          } else {
            cityName = (postcode != null && postcode.isNotEmpty)
                ? postcode
                : 'My Location';
          }
          countryName = place.country ?? '';
        } else {
          throw Exception('No placemarks found');
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
            final city =
                address['city'] ??
                address['town'] ??
                address['village'] ??
                address['suburb'];
            final postcode = address['postcode'];
            if (city != null && postcode != null) {
              cityName = "$city, $postcode";
            } else if (city != null) {
              cityName = city;
            } else if (postcode != null) {
              cityName = postcode;
            } else {
              cityName = 'My Location';
            }
            countryName = address['country'] ?? '';
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
      _loadFallbackCity('Failed to retrieve location weather.');
    }
  }

  void _loadFallbackCity(String snackBarMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$snackBarMsg Loading Bengaluru fallback.')),
      );
    }
    // Fallback coordinates for Bengaluru, India
    _fetchWeatherFromCoordinates(12.9716, 77.5946, 'Bengaluru', 'India');
  }

  Future<void> _fetchWeatherFromCoordinates(
    double lat,
    double lon,
    String city,
    String country,
  ) async {
    try {
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,uv_index&daily=temperature_2m_max,weather_code&timezone=auto',
      );

      final response = await http.get(weatherUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final hourly = data['hourly'];
        final daily = data['daily'];

        // Map Open-Meteo Weather Codes to condition names
        // WMO Weather interpretation codes (https://open-meteo.com/en/docs)
        int code = current['weathercode'];
        String cond = 'Cloudy';
        if (code <= 1) {
          cond = 'Sunny';
        } else if (code == 2 || code == 3) {
          cond = 'Cloudy';
        } else if (code >= 51 && code <= 67) {
          cond = 'Rainy';
        } else if (code >= 71 && code <= 86) {
          cond = 'Cloudy'; // Snow/showers
        } else if (code >= 95) {
          cond = 'Stormy';
        }

        // Retrieve current hour index
        int currentHourIdx = DateTime.now().hour;
        int hum = 60;
        int uv = 5;
        if (hourly != null) {
          final humList = hourly['relative_humidity_2m'];
          final uvList = hourly['uv_index'];
          if (humList != null && humList.length > currentHourIdx) {
            hum = (humList[currentHourIdx] as num).toInt();
          }
          if (uvList != null && uvList.length > currentHourIdx) {
            uv = (uvList[currentHourIdx] as num).toInt();
          }
        }

        // Build Hourly Forecast array
        List<Map<String, dynamic>> tempHourly = [];
        if (hourly != null) {
          final temps = hourly['temperature_2m'];
          for (int i = 0; i < 6; i++) {
            int futureIdx = (currentHourIdx + i * 2) % 24;
            if (temps != null && temps.length > futureIdx) {
              tempHourly.add({
                'hour': '${(DateTime.now().hour + i * 2) % 24}:00',
                'temp': temps[futureIdx],
              });
            }
          }
        }

        // Build Daily Forecast array
        List<Map<String, dynamic>> tempDaily = [];
        if (daily != null) {
          final maxTemps = daily['temperature_2m_max'];
          final weatherCodes = daily['weather_code'];
          final weekdays = [
            'Today',
            'Tomorrow',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
            'Monday',
          ];
          for (int i = 0; i < 5; i++) {
            if (maxTemps != null && maxTemps.length > i) {
              int dailyCode = weatherCodes != null ? weatherCodes[i] : 0;
              String dailyCond = 'Cloudy';
              if (dailyCode <= 1) {
                dailyCond = 'Sunny';
              } else if (dailyCode == 2 || dailyCode == 3) {
                dailyCond = 'Cloudy';
              } else if (dailyCode >= 51 && dailyCode <= 67) {
                dailyCond = 'Rainy';
              } else if (dailyCode >= 95) {
                dailyCond = 'Stormy';
              }

              tempDaily.add({
                'day': weekdays[i],
                'temp': maxTemps[i],
                'condition': dailyCond,
              });
            }
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
          _hourlyForecast = tempHourly;
          _dailyForecast = tempDaily;
          _isLoading = false;
        });
      } else {
        throw Exception('Open-Meteo status error');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _activeCity = 'Error loading weather';
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
      // Nominatim OSM Search API
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
          String city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state'] ??
              query;
          String country = address['country'] ?? '';

          await _fetchWeatherFromCoordinates(lat, lon, city, country);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Search request failed.')));
      }
    }
  }

  Color _getWeatherThemeColor() {
    switch (_condition) {
      case 'Sunny':
        return Colors.orangeAccent.withValues(alpha: 0.08);
      case 'Rainy':
        return Colors.blueAccent.withValues(alpha: 0.08);
      case 'Cloudy':
        return Colors.blueGrey.withValues(alpha: 0.08);
      case 'Stormy':
        return Colors.purpleAccent.withValues(alpha: 0.08);
      default:
        return Colors.transparent;
    }
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
        return Icons.wb_cloudy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Search input bar
          NeumorphicCard(
            inset: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search city weather...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) => _searchCityWeather(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location, size: 18),
                  onPressed: _fetchCurrentLocationWeather,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary weather stats card
          _isLoading
              ? const NeumorphicCard(
                  borderRadius: 24,
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Fetching live meteorological reports...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : NeumorphicCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  color: _getWeatherThemeColor(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeCity,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_activeCountry.isNotEmpty)
                                  Text(
                                    _activeCountry,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            _getWeatherIcon(_condition),
                            color: Colors.orange,
                            size: 40,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_temp.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _condition,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 20),

          // Advanced weather stats cards grid
          if (!_isLoading) ...[
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _buildMetricCard(Icons.opacity, 'Humidity', '$_humidity%'),
                _buildMetricCard(
                  Icons.air,
                  'Wind',
                  '${_wind.toStringAsFixed(1)} km/h',
                ),
                _buildMetricCard(
                  Icons.wb_sunny_outlined,
                  'UV Index',
                  '$_uvIndex',
                ),
                _buildMetricCard(
                  Icons.eco_outlined,
                  'Air Quality',
                  _airQuality,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hourly Forecast list
            if (_hourlyForecast.isNotEmpty) ...[
              const Text(
                'Hourly Forecast',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _hourlyForecast.map((fc) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: NeumorphicCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        borderRadius: 14,
                        child: Column(
                          children: [
                            Text(
                              fc['hour'],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              _getWeatherIcon(_condition),
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(fc['temp'] as num).toStringAsFixed(1)}°',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 7-day forecast
            if (_dailyForecast.isNotEmpty) ...[
              const Text(
                'Daily Forecast',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dailyForecast.length,
                itemBuilder: (context, idx) {
                  final fc = _dailyForecast[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: NeumorphicCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderRadius: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fc['day'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                _getWeatherIcon(fc['condition']),
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${(fc['temp'] as num).toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String val) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
