import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/live_data/gateway_config.dart';
import '../../core/live_data/live_data_gateway_client.dart';
import '../../core/weather/gateway_weather_service.dart';
import '../../core/weather/weather_models.dart';
import '../weather/weather_icon.dart';

class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});

  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends ConsumerState<WeatherPage> {
  final _municipality = TextEditingController();
  WeatherForecast? _forecast;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _municipality.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final code = _municipality.text.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      setState(() => _error = 'Introduce un código de municipio de 5 cifras.');
      return;
    }

    final baseUri = GatewayConfig.baseUri;
    if (baseUri == null) {
      setState(() {
        _error =
            'Gateway no configurado. Usa ESPANA_OUTDOOR_GATEWAY_URL al compilar.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final gateway = HttpLiveDataGateway(baseUri: baseUri);
      final service = GatewayWeatherService(gateway);
      final forecast = await service.dailyMunicipalityForecast(code);
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  String _conditionLabel(WeatherCondition condition) => switch (condition) {
        WeatherCondition.clear => 'Despejado',
        WeatherCondition.partlyCloudy => 'Intervalos nubosos',
        WeatherCondition.cloudy => 'Nuboso',
        WeatherCondition.rain => 'Lluvia',
        WeatherCondition.storm => 'Tormenta',
        WeatherCondition.snow => 'Nieve',
        WeatherCondition.fog => 'Niebla',
        WeatherCondition.unknown => 'Sin descripción',
      };

  String _dateLabel(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _temperature(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(0)} °C';

  @override
  Widget build(BuildContext context) {
    final forecast = _forecast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meteorología'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previsión municipal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La previsión procede del gateway configurado. '
                    'La app conserva la fuente y la hora de recuperación.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _municipality,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: const InputDecoration(
                      labelText: 'Código de municipio',
                      hintText: '5 cifras',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_outlined),
                    label: Text(
                      _loading ? 'CONSULTANDO...' : 'CONSULTAR PREVISIÓN',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          ],
          if (forecast != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.verified_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${forecast.source} · Recuperado ${forecast.fetchedAt.toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (forecast.days.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'La fuente no devolvió días utilizables para este municipio.',
                  ),
                ),
              )
            else
              for (final day in forecast.days) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WeatherIcon(
                          condition: day.condition,
                          size: 46,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateLabel(day.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_conditionLabel(day.condition)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    'Máx ${_temperature(day.maxTemperatureC)}',
                                  ),
                                  Text(
                                    'Mín ${_temperature(day.minTemperatureC)}',
                                  ),
                                  if (day.precipitationProbabilityPercent !=
                                      null)
                                    Text(
                                      'Lluvia ${day.precipitationProbabilityPercent} %',
                                    ),
                                  if (day.windSpeedKmh != null)
                                    Text(
                                      'Viento '
                                      '${day.windSpeedKmh!.toStringAsFixed(0)} km/h'
                                      '${day.windDirection == null ? '' : ' ${day.windDirection}'}',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}
