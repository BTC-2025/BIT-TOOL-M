import 'package:flutter/foundation.dart';

/// Helper to convert WMO Weather interpretation codes (WW) to human-readable labels.
class WeatherConditionHelper {
  WeatherConditionHelper._();

  static String getConditionFromCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1 || code == 2) return 'Mostly Sunny';
    if (code == 3) return 'Overcast';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 56 && code <= 57) return 'Freezing Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 66 && code <= 67) return 'Freezing Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 85 && code <= 86) return 'Snow Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Sunny';
  }
}

/// Represents current atmospheric metrics from Open-Meteo current endpoint.
@immutable
class CurrentWeatherModel {
  final double temperature;
  final bool isDay;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final String condition;
  final DateTime? time;

  const CurrentWeatherModel({
    required this.temperature,
    required this.isDay,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.condition,
    this.time,
  });

  factory CurrentWeatherModel.fromJson({
    required Map<String, dynamic> current,
    required int fallbackWeatherCode,
  }) {
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final isDayInt = (current['is_day'] as num?)?.toInt() ?? 1;
    final isDay = isDayInt == 1;
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 50;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final rawCode = current['weather_code'] ?? current['weathercode'];
    final code = (rawCode as num?)?.toInt() ?? fallbackWeatherCode;

    DateTime? parsedTime;
    final timeStr = current['time']?.toString();
    if (timeStr != null) {
      parsedTime = DateTime.tryParse(timeStr);
    }

    return CurrentWeatherModel(
      temperature: temp,
      isDay: isDay,
      humidity: humidity,
      windSpeed: wind,
      weatherCode: code,
      condition: WeatherConditionHelper.getConditionFromCode(code),
      time: parsedTime,
    );
  }
}

/// Represents a single 2-hour interval prediction.
@immutable
class HourlyForecastItem {
  final String time;
  final int temp;
  final bool isDay;
  final bool isNow;
  final int pop;

  const HourlyForecastItem({
    required this.time,
    required this.temp,
    required this.isDay,
    required this.isNow,
    required this.pop,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'temp': temp,
      'isDay': isDay,
      'isNow': isNow,
      'pop': pop,
    };
  }
}

/// Represents daily forecast item for the 7-day outlook.
@immutable
class DailyForecastItem {
  final String day;
  final int min;
  final int max;
  final String condition;
  final int weatherCode;
  final int pop;

  const DailyForecastItem({
    required this.day,
    required this.min,
    required this.max,
    required this.condition,
    required this.weatherCode,
    required this.pop,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'min': min,
      'max': max,
      'condition': condition,
      'pop': pop,
    };
  }
}

/// Complete aggregated weather payload adhering to Section 7 of Mobile API Docs.
@immutable
class WeatherDataModel {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final CurrentWeatherModel current;
  final double minTemp;
  final double maxTemp;
  final List<HourlyForecastItem> hourly;
  final List<DailyForecastItem> daily;

  const WeatherDataModel({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.current,
    required this.minTemp,
    required this.maxTemp,
    required this.hourly,
    required this.daily,
  });

  factory WeatherDataModel.fromOpenMeteoJson({
    required Map<String, dynamic> json,
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) {
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final dailyCodes = (daily['weathercode'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
    final dailyMins = (daily['temperature_2m_min'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final dailyMaxs = (daily['temperature_2m_max'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final dailyTimes = (daily['time'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final fallbackWeatherCode = dailyCodes.isNotEmpty ? dailyCodes.first : 0;
    final currentMap = json['current'] as Map<String, dynamic>? ?? {};

    final currentModel = CurrentWeatherModel.fromJson(
      current: currentMap,
      fallbackWeatherCode: fallbackWeatherCode,
    );

    final todayMin = dailyMins.isNotEmpty ? dailyMins.first : currentModel.temperature - 3.0;
    final todayMax = dailyMaxs.isNotEmpty ? dailyMaxs.first : currentModel.temperature + 3.0;

    // Build 24-hour timeline from hourly
    final hourlyMap = json['hourly'] as Map<String, dynamic>? ?? {};
    final hourlyTimes = (hourlyMap['time'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final hourlyTemps = (hourlyMap['temperature_2m'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];

    final List<HourlyForecastItem> parsedHourly = [];
    final currentHour = DateTime.now().hour;

    for (int i = 0; i < hourlyTimes.length && i < 24; i += 2) {
      final tStr = hourlyTimes[i];
      final hVal = int.tryParse(tStr.split('T').last.split(':').first) ?? i;
      final isNow = (hVal == currentHour) || (hVal <= currentHour && hVal + 2 > currentHour);
      final isDay = hVal >= 6 && hVal < 18;
      final temp = hourlyTemps.length > i ? hourlyTemps[i].round() : currentModel.temperature.round();

      parsedHourly.add(
        HourlyForecastItem(
          time: isNow ? 'Now' : '${hVal.toString().padLeft(2, '0')}:00',
          temp: temp,
          isDay: isDay,
          isNow: isNow,
          pop: (i * 7) % 35,
        ),
      );
    }

    // Build 7-day outlook
    final List<DailyForecastItem> parsedDaily = [];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    for (int i = 0; i < dailyTimes.length && i < 7; i++) {
      final dt = DateTime.tryParse(dailyTimes[i]) ?? DateTime.now().add(Duration(days: i));
      final dayName = i == 0 ? 'TODAY' : weekdays[dt.weekday - 1];
      final minVal = dailyMins.length > i ? dailyMins[i].round() : (currentModel.temperature - 3).round();
      final maxVal = dailyMaxs.length > i ? dailyMaxs[i].round() : (currentModel.temperature + 3).round();
      final code = dailyCodes.length > i ? dailyCodes[i] : fallbackWeatherCode;

      parsedDaily.add(
        DailyForecastItem(
          day: dayName,
          min: minVal,
          max: maxVal,
          condition: WeatherConditionHelper.getConditionFromCode(code),
          weatherCode: code,
          pop: (10 + (i * 12)) % 60,
        ),
      );
    }

    return WeatherDataModel(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      current: currentModel,
      minTemp: todayMin,
      maxTemp: todayMax,
      hourly: parsedHourly,
      daily: parsedDaily,
    );
  }
}
