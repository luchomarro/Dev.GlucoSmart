import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/estado_global.dart';
import '/servicios/api_service.dart';

class RegistroMedicionScreen extends StatefulWidget {
  final RegistroSalud? registroAEditar;
  const RegistroMedicionScreen({super.key, this.registroAEditar});

  @override
  State<RegistroMedicionScreen> createState() => _RegistroMedicionScreenState();
}

class _RegistroMedicionScreenState extends State<RegistroMedicionScreen> {
  final _glucosaCtrl = TextEditingController();
  final _sisCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String _tipoSeleccionado = 'ambos';
  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;

  // ── NUEVO: controla el estado de carga mientras se llama a la API ──
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();
    _horaSeleccionada = TimeOfDay.now();

    if (widget.registroAEditar != null) {
      final reg = widget.registroAEditar!;
      if (reg.tieneGlucosa && reg.tienePresion) {
        _tipoSeleccionado = 'ambos';
      } else if (reg.tieneGlucosa) {
        _tipoSeleccionado = 'glucosa';
      } else if (reg.tienePresion) {
        _tipoSeleccionado = 'presion';
      }

      _glucosaCtrl.text = reg.glucosa?.toString() ?? '';
      _sisCtrl.text = reg.presionSis?.toString() ?? '';
      _diaCtrl.text = reg.presionDia?.toString() ?? '';
      _notasCtrl.text = reg.notas;
      _fechaSeleccionada = reg.fecha;
      _horaSeleccionada = TimeOfDay(hour: reg.fecha.hour, minute: reg.fecha.minute);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2F80ED),
              onPrimary: Colors.white,
              onSurface: Color(0xFF12305B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaElegida != null && fechaElegida != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = DateTime(
          fechaElegida.year,
          fechaElegida.month,
          fechaElegida.day,
          _horaSeleccionada.hour,
          _horaSeleccionada.minute,
        );
      });
    }
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? horaElegida = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2F80ED),
              onPrimary: Colors.white,
              onSurface: Color(0xFF12305B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (horaElegida != null) {
      setState(() {
        _horaSeleccionada = horaElegida;
        _fechaSeleccionada = DateTime(
          _fechaSeleccionada.year,
          _fechaSeleccionada.month,
          _fechaSeleccionada.day,
          horaElegida.hour,
          horaElegida.minute,
        );
      });
    }
  }

  // ── CORRECCIÓN PRINCIPAL: _guardar() ahora llama a la API ──
  Future<void> _guardar() async {
    final glucosa = (_tipoSeleccionado == 'ambos' || _tipoSeleccionado == 'glucosa')
        ? double.tryParse(_glucosaCtrl.text)
        : null;
    final presionSis = (_tipoSeleccionado == 'ambos' || _tipoSeleccionado == 'presion')
        ? int.tryParse(_sisCtrl.text)
        : null;
    final presionDia = (_tipoSeleccionado == 'ambos' || _tipoSeleccionado == 'presion')
        ? int.tryParse(_diaCtrl.text)
        : null;

    // Validación básica
    if (glucosa == null && presionSis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un valor de glucosa o presión'),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      if (widget.registroAEditar != null) {
        // Edición: el backend no tiene endpoint PUT/PATCH para readings,
        // así que solo actualizamos el estado local.
        // TODO: implementar PUT /api/readings/{id} en el backend.
        final reg = RegistroSalud(
          id: widget.registroAEditar!.id,
          glucosa: glucosa,
          presionSis: presionSis,
          presionDia: presionDia,
          fecha: _fechaSeleccionada,
          notas: _notasCtrl.text,
        );
        appState.actualizarRegistro(reg);
      } else {
        // ── NUEVA lectura: llamamos al backend ──
        final response = await ApiService.registrarMedicion(
          glucosa: glucosa,
          presionSis: presionSis,
          presionDia: presionDia,
          notas: _notasCtrl.text,
          fecha: _fechaSeleccionada,
        );

        // Construimos el RegistroSalud con el ID real que devuelve el backend
        final nuevoReg = RegistroSalud(
          id: response['id'].toString(),
          glucosa: response['glucosa'] != null
              ? (response['glucosa'] as num).toDouble()
              : null,
          presionSis: response['presion_sis'] as int?,
          presionDia: response['presion_dia'] as int?,
          fecha: DateTime.parse(response['fecha'] as String),
          notas: (response['notas'] as String?) ?? '',
        );

        appState.agregarRegistro(nuevoReg);
      }

      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.message}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Text(
          widget.registroAEditar != null ? "Editar Medición" : "Nueva Medición",
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF12305B)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF12305B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'glucosa', label: Text('Glucosa')),
                ButtonSegment(value: 'ambos', label: Text('Ambos')),
                ButtonSegment(value: 'presion', label: Text('Presión')),
              ],
              selected: {_tipoSeleccionado},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() { _tipoSeleccionado = newSelection.first; });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return const Color(0xFF2F80ED);
                  return Colors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return const Color(0xFF12305B);
                }),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fecha de la medición",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF12305B))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _seleccionarFecha(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF2F80ED)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_fechaSeleccionada),
                              style: const TextStyle(fontSize: 16, color: Color(0xFF12305B)),
                            ),
                          ),
                          const Icon(Icons.edit, size: 16, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SELECTOR DE HORA
                  const Text("Hora de la medición",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF12305B))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _seleccionarHora(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF2F80ED)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _horaSeleccionada.format(context),
                              style: const TextStyle(fontSize: 16, color: Color(0xFF12305B)),
                            ),
                          ),
                          const Icon(Icons.edit, size: 16, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_tipoSeleccionado == 'ambos' || _tipoSeleccionado == 'glucosa')
                    _buildInput("Glucosa (mg/dL)", _glucosaCtrl,
                        Icons.water_drop_outlined, const Color(0xFF00C7BE)),

                  if (_tipoSeleccionado == 'ambos' || _tipoSeleccionado == 'presion')
                    Row(
                      children: [
                        Expanded(child: _buildInput("Sistólica", _sisCtrl,
                            Icons.favorite_border, const Color(0xFFFF3B30))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInput("Diastólica", _diaCtrl,
                            Icons.favorite_border, const Color(0xFFFF3B30))),
                      ],
                    ),

                  const SizedBox(height: 16),
                  const Text("Notas (Opcional)",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF12305B))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notasCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FBFF),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Botón con estado de carga ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Guardar Registro",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController ctrl, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF12305B))),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: color),
              filled: true,
              fillColor: const Color(0xFFF8FBFF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
