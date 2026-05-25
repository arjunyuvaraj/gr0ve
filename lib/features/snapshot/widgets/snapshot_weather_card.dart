import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gr0ve/features/snapshot/widgets/snapshot_shared.dart';

sealed class WX {}

class WXLoading extends WX {}

class WXError extends WX {}

class WXData extends WX {
  final int temp, feels, humidity, wind, code;
  WXData({
    required this.temp,
    required this.feels,
    required this.humidity,
    required this.wind,
    required this.code,
  });
}

final wxNotifier = ValueNotifier<WX>(WXLoading());

Future<void> fetchWeather() async {
  wxNotifier.value = WXLoading();
  try {
    final r = await http.get(
      Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=40.8859&longitude=-74.0435'
        '&current=temperature_2m,apparent_temperature,weather_code,'
        'relative_humidity_2m,wind_speed_10m'
        '&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America%2FNew_York',
      ),
    );
    final c = (jsonDecode(r.body)['current'] as Map);
    wxNotifier.value = WXData(
      temp: (c['temperature_2m'] as num).round(),
      feels: (c['apparent_temperature'] as num).round(),
      humidity: c['relative_humidity_2m'] as int,
      wind: (c['wind_speed_10m'] as num).round(),
      code: c['weather_code'] as int,
    );
  } catch (_) {
    wxNotifier.value = WXError();
  }
}

String _wLabel(int c) {
  if (c == 0) return 'Clear';
  if (c <= 2) return 'Partly Cloudy';
  if (c <= 3) return 'Overcast';
  if (c <= 48) return 'Foggy';
  if (c <= 55) return 'Drizzle';
  if (c <= 65) return 'Rain';
  if (c <= 77) return 'Snow';
  if (c <= 82) return 'Showers';
  return 'Thunderstorm';
}

IconData _wIcon(int c) {
  if (c == 0) return Icons.wb_sunny_rounded;
  if (c <= 3) return Icons.cloud_rounded;
  if (c <= 48) return Icons.foggy;
  if (c <= 67) return Icons.water_drop_rounded;
  if (c <= 82) return Icons.grain_rounded;
  return Icons.thunderstorm_rounded;
}

class SnapshotWeatherCard extends StatefulWidget {
  final bool compact;

  const SnapshotWeatherCard({super.key, this.compact = false});

  @override
  State<SnapshotWeatherCard> createState() => _SnapshotWeatherCardState();
}

class _SnapshotWeatherCardState extends State<SnapshotWeatherCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (wxNotifier.value is WXLoading || wxNotifier.value is WXError) {
      fetchWeather();
    }
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      fetchWeather();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;
    return ValueListenableBuilder<WX>(
      valueListenable: wxNotifier,
      builder: (_, wx, __) {
        if (wx is WXLoading) {
          return SnapshotTile(
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.primary,
                ),
              ),
            ),
          );
        }
        if (wx is WXError) {
          return SnapshotTile(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Weather unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: fetchWeather,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '↺',
                    style: TextStyle(color: c.primary, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }
        final d = wx as WXData;
        return Column(
          children: [
            SnapshotTile(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.temp}°F',
                          style: TextStyle(
                            fontSize: widget.compact ? 26.0 : 32.0,
                            fontWeight: FontWeight.w900,
                            color: c.onSurface,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_wLabel(d.code)} · Feels ${d.feels}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.onSurface.withOpacity(0.45),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _wIcon(d.code),
                    size: widget.compact ? 28.0 : 36.0,
                    color: c.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: SnapshotTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 16,
                          color: c.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d.humidity}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Humidity',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.onSurface.withOpacity(0.35),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: SnapshotTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.air_rounded, size: 16, color: c.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d.wind} mph',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Wind',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.onSurface.withOpacity(0.35),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
