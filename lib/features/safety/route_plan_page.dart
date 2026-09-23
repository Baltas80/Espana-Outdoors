import 'package:flutter/material.dart';

import '../../core/safety/route_plan.dart';
import '../../core/safety/route_plan_store.dart';

class RoutePlanPage extends StatefulWidget {
  const RoutePlanPage({super.key});

  @override
  State<RoutePlanPage> createState() => _RoutePlanPageState();
}

class _RoutePlanPageState extends State<RoutePlanPage> {
  final _store = RoutePlanStore();
  final _participants = TextEditingController(text: '1');

  DateTime _departure = DateTime.now().add(const Duration(hours: 1));
  DateTime _returnAt = DateTime.now().add(const Duration(hours: 5));
  RoutePlan? _saved;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _participants.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await _store.load();
    if (!mounted) return;
    setState(() {
      _saved = plan;
      if (plan != null) {
        _departure = plan.departureAt.toLocal();
        _returnAt = plan.expectedReturnAt.toLocal();
        _participants.text = '${plan.participants}';
      }
      _loading = false;
    });
  }

  Future<void> _pickDateTime({required bool departure}) async {
    final current = departure ? _departure : _returnAt;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: current,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (departure) {
        _departure = value;
        if (!_returnAt.isAfter(value)) {
          _returnAt = value.add(const Duration(hours: 4));
        }
      } else {
        _returnAt = value;
      }
    });
  }

  Future<void> _save() async {
    final participants = int.tryParse(_participants.text.trim()) ?? 0;
    final plan = RoutePlan(
      departureAt: _departure.toUtc(),
      expectedReturnAt: _returnAt.toUtc(),
      participants: participants,
    );
    if (!plan.isValid) {
      _show(
        'El plan debe tener al menos una persona y una hora de regreso posterior a la salida.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _store.save(plan);
      if (!mounted) return;
      setState(() {
        _saved = plan;
        _saving = false;
      });
      _show('Plan de ruta guardado.');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _show('No se pudo guardar el plan: $error');
    }
  }

  Future<void> _clear() async {
    await _store.clear();
    if (!mounted) return;
    setState(() => _saved = null);
    _show('Plan eliminado.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _format(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plan de ruta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Configura la salida y la hora prevista de regreso. '
                'España Outdoor puede usar este plan para mejorar la preparación '
                'y las funciones de seguridad.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flight_takeoff_outlined),
                  title: const Text('Salida'),
                  subtitle: Text(_format(_departure)),
                  onTap: () => _pickDateTime(departure: true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Regreso previsto'),
                  subtitle: Text(_format(_returnAt)),
                  onTap: () => _pickDateTime(departure: false),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _participants,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Participantes',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_saved != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Plan activo'),
                subtitle: Text(
                  'Salida ${_format(_saved!.departureAt)} · '
                  'regreso ${_format(_saved!.expectedReturnAt)}',
                ),
                trailing: IconButton(
                  tooltip: 'Eliminar',
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'GUARDANDO...' : 'GUARDAR PLAN'),
            ),
          ),
        ],
      ),
    );
  }
}
