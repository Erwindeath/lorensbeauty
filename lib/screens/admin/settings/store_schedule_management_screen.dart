import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStoreScheduleScreen extends StatefulWidget {
  const AdminStoreScheduleScreen({Key? key}) : super(key: key);

  @override
  State<AdminStoreScheduleScreen> createState() => _AdminStoreScheduleScreenState();
}

class _AdminStoreScheduleScreenState extends State<AdminStoreScheduleScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  final List<_WeekDay> _days = const [
    _WeekDay(1, 'Lunes', 'LUN'),
    _WeekDay(2, 'Martes', 'MAR'),
    _WeekDay(3, 'Miercoles', 'MIE'),
    _WeekDay(4, 'Jueves', 'JUE'),
    _WeekDay(5, 'Viernes', 'VIE'),
    _WeekDay(6, 'Sabado', 'SAB'),
    _WeekDay(7, 'Domingo', 'DOM'),
  ];

  late final List<String> _baseSlots;
  final Map<int, Set<String>> _slotsByDay = {for (var i = 1; i <= 7; i++) i: <String>{}};

  int _selectedDay = 1;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _tableMissing = false;

  @override
  void initState() {
    super.initState();
    _baseSlots = _generateHalfHourSlots();
    _loadSchedule();
  }

  List<String> _generateHalfHourSlots() {
    final slots = <String>[];
    for (int h = 8; h <= 18; h++) {
      for (int m = 0; m <= 30; m += 30) {
        if (h == 18 && m == 30) continue;
        slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
      _tableMissing = false;
    });

    try {
      final response = await _client
          .from('store_booking_slots')
          .select('weekday, slot_time')
          .order('weekday')
          .order('slot_time');

      for (var i = 1; i <= 7; i++) {
        _slotsByDay[i] = <String>{};
      }

      for (final row in (response as List)) {
        final day = row['weekday'] as int?;
        final slot = _normalizeSlot(row['slot_time']?.toString());
        if (day == null || slot == null || !_slotsByDay.containsKey(day)) continue;
        _slotsByDay[day]!.add(slot);
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final missing = msg.contains('store_booking_slots') || msg.contains('relation') || msg.contains('does not exist');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _tableMissing = missing;
        _error = missing
            ? 'No existe la tabla store_booking_slots en Supabase.'
            : 'No se pudo cargar el horario. $e';
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _client.from('store_booking_slots').delete().gte('weekday', 1);

      final rows = <Map<String, dynamic>>[];
      _slotsByDay.forEach((day, slots) {
        for (final slot in slots) {
          rows.add({'weekday': day, 'slot_time': slot});
        }
      });

      if (rows.isNotEmpty) {
        await _client.from('store_booking_slots').insert(rows);
      }

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario guardado correctamente.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Error al guardar: $e';
      });
    }
  }

  void _setMorningOnly() {
    final morning = _baseSlots.where((s) => s.compareTo('12:00') <= 0).toSet();
    setState(() => _slotsByDay[_selectedDay] = morning);
  }

  void _setFullDay() {
    setState(() => _slotsByDay[_selectedDay] = _baseSlots.toSet());
  }

  void _setClosed() {
    setState(() => _slotsByDay[_selectedDay] = <String>{});
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xff721c80)),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final minute = picked.minute < 15
        ? 0
        : picked.minute < 45
            ? 30
            : 0;
    final hour = picked.minute >= 45 ? (picked.hour + 1) : picked.hour;
    if (hour > 23) return;

    final slot = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    setState(() => _slotsByDay[_selectedDay]!.add(slot));
  }

  int get _weekTotal => _slotsByDay.values.fold(0, (sum, s) => sum + s.length);

  String? _normalizeSlot(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  int _slotToMinutes(String slot) {
    final parts = slot.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  List<String> _sortedSlots(Iterable<String> slots) {
    final list = slots.toSet().toList();
    list.sort((a, b) => _slotToMinutes(a).compareTo(_slotToMinutes(b)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSlots = _slotsByDay[_selectedDay] ?? <String>{};
    final visibleSlots = _sortedSlots({..._baseSlots, ...selectedSlots});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario de Atencion'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff721c80)))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff721c80), Color(0xffC46FA9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Configura los horarios que veran tus clientes al reservar. Total semanal: $_weekTotal bloques.',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _tableMissing ? Colors.orange.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _tableMissing ? Colors.orange.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: _tableMissing ? Colors.orange.shade900 : Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final selected = _selectedDay == day.value;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(day.short),
                        onSelected: (_) => setState(() => _selectedDay = day.value),
                        selectedColor: const Color(0xff721c80),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      _quickBtn('Todo el dia', _setFullDay),
                      const SizedBox(width: 8),
                      _quickBtn('Solo manana', _setMorningOnly),
                      const SizedBox(width: 8),
                      _quickBtn('Cerrar dia', _setClosed, color: Colors.red.shade700),
                      const Spacer(),
                      IconButton(
                        onPressed: _addCustomTime,
                        icon: const Icon(Icons.add_circle, color: Color(0xff721c80)),
                        tooltip: 'Agregar hora',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: visibleSlots.map((slot) {
                            final selected = selectedSlots.contains(slot);
                            return FilterChip(
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    selectedSlots.add(slot);
                                  } else {
                                    selectedSlots.remove(slot);
                                  }
                                });
                              },
                              label: Text(slot),
                              selectedColor: const Color(0xff721c80).withOpacity(0.16),
                              checkmarkColor: const Color(0xff721c80),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveSchedule,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Guardando...' : 'Guardar horario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff721c80),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickBtn(String text, VoidCallback onTap, {Color? color}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color ?? const Color(0xff721c80)),
        foregroundColor: color ?? const Color(0xff721c80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _WeekDay {
  final int value;
  final String label;
  final String short;

  const _WeekDay(this.value, this.label, this.short);
}
