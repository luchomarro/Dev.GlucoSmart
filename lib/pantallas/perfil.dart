import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '/estado_global.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();

  DateTime? _fechaNac;
  List<String> _condicionesSeleccionadas = [];
  String? _rutaFoto;

  final Color _colorPrincipal = const Color(0xFF5AB1E6);
  final Color _colorTextoGris = const Color(0xFF757575);

  final List<String> _opcionesCondiciones = [
    'Obesidad', 'Familiares con diabetes', 'Hipertensión',
    'Colesterol alto', 'Sedentarismo', 'SOP'
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl.text = appState.perfil.nombre;
    _telefonoCtrl.text = appState.perfil.telefono;
    _pesoCtrl.text = appState.perfil.peso?.toString() ?? '';
    _alturaCtrl.text = appState.perfil.altura?.toString() ?? '';
    _fechaNac = appState.perfil.fechaNacimiento;
    _condicionesSeleccionadas = List.from(appState.perfil.condicionesMedicas);
    _rutaFoto = appState.perfil.fotoPerfilPath;
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final XFile? imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagenSeleccionada != null) {
      setState(() {
        _rutaFoto = imagenSeleccionada.path;
      });
      _guardarCambios();
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _colorPrincipal)),
        child: child!,
      ),
    );
    if (fechaElegida != null) setState(() => _fechaNac = fechaElegida);
  }

  Future<void> _abrirTecladoEspecial(String titulo, String sufijo, TextEditingController ctrl) async {
    String valor = ctrl.text;

    final resultado = await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {

                Widget tecla(String texto) {
                  return InkWell(
                    onTap: () {
                      setStateDialog(() {
                        if (texto == '⌫') {
                          if (valor.isNotEmpty) valor = valor.substring(0, valor.length - 1);
                        } else if (texto == '.') {
                          if (!valor.contains('.')) valor += '.';
                        } else {
                          if (valor.length < 5) valor += texto;
                        }
                      });
                    },
                    child: Center(
                      child: texto == '⌫'
                          ? const Icon(Icons.backspace_outlined, size: 28, color: Colors.black54)
                          : Text(texto, style: const TextStyle(fontSize: 32, color: Colors.black54)),
                    ),
                  );
                }

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Container(
                    padding: const EdgeInsets.only(top: 24),
                    width: 300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(valor.isEmpty ? "0" : valor, style: const TextStyle(fontSize: 32, color: Colors.black87)),
                                  const Spacer(),
                                  Text(sufijo, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                ],
                              ),
                              Divider(color: _colorPrincipal, thickness: 2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 1.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            tecla('1'), tecla('2'), tecla('3'),
                            tecla('4'), tecla('5'), tecla('6'),
                            tecla('7'), tecla('8'), tecla('9'),
                            tecla('⌫'), tecla('0'), tecla('.'),
                          ],
                        ),
                        const Divider(height: 0),
                        Row(
                          children: [
                            Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontSize: 16)))),
                            Container(width: 1, height: 48, color: Colors.grey.shade300),
                            Expanded(child: TextButton(onPressed: () => Navigator.pop(context, valor), child: Text("ACEPTAR", style: TextStyle(color: _colorPrincipal, fontSize: 16)))),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );

    if (resultado != null) {
      setState(() {
        ctrl.text = resultado;
      });
    }
  }

  void _guardarCambios() {
    final nuevoPerfil = PerfilUsuario(
      nombre: _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : "Usuario",
      fechaNacimiento: _fechaNac,
      telefono: _telefonoCtrl.text,
      peso: double.tryParse(_pesoCtrl.text),
      altura: double.tryParse(_alturaCtrl.text),
      condicionesMedicas: _condicionesSeleccionadas,
      fotoPerfilPath: _rutaFoto,
    );

    appState.actualizarPerfil(nuevoPerfil);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Perfil médico guardado"), backgroundColor: _colorPrincipal)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Perfil", style: TextStyle(color: _colorPrincipal, fontSize: 20, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _colorPrincipal), // Da color celeste a la flecha de regreso
        actions: [IconButton(icon: Icon(Icons.settings_outlined, color: _colorPrincipal), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- FOTO DE PERFIL CON GALERÍA ---
            Center(
              child: GestureDetector(
                onTap: _cambiarFoto,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: _colorPrincipal.withOpacity(0.8),
                      backgroundImage: _rutaFoto != null ? FileImage(File(_rutaFoto!)) : null,
                      child: _rutaFoto == null ? const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 8),
                    Text("Editar", style: TextStyle(color: _colorPrincipal, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- LISTA DE CAMPOS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilaTexto("Nombre*", ctrl: _nombreCtrl),
                  _buildFilaTexto("Teléfono", ctrl: _telefonoCtrl, isNumber: true),

                  _buildFilaBoton("Fecha de nacimiento*", _fechaNac != null ? DateFormat('dd/MM/yyyy').format(_fechaNac!) : "", () => _seleccionarFecha(context)),
                  _buildFilaBoton("Peso", _pesoCtrl.text.isNotEmpty ? "${_pesoCtrl.text} Kg" : "", () => _abrirTecladoEspecial("Kg", "Kg", _pesoCtrl)),
                  _buildFilaBoton("Altura", _alturaCtrl.text.isNotEmpty ? "${_alturaCtrl.text} m" : "", () => _abrirTecladoEspecial("Metros", "m", _alturaCtrl)),

                  const SizedBox(height: 24),

                  // --- CONDICIONES MÉDICAS ---
                  Text("Condiciones Médicas*", style: TextStyle(fontSize: 16, color: _colorTextoGris, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _opcionesCondiciones.map((condicion) {
                      final isSelected = _condicionesSeleccionadas.contains(condicion);
                      return FilterChip(
                        label: Text(condicion),
                        selected: isSelected,
                        selectedColor: _colorPrincipal.withOpacity(0.2),
                        checkmarkColor: _colorPrincipal,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(color: isSelected ? _colorPrincipal : _colorTextoGris),
                        side: BorderSide(color: isSelected ? _colorPrincipal : Colors.transparent),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) _condicionesSeleccionadas.add(condicion);
                            else _condicionesSeleccionadas.remove(condicion);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // --- BOTONES INFERIORES ---
                  Center(
                    child: SizedBox(
                      width: 200, height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _colorPrincipal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0
                        ),
                        onPressed: _guardarCambios,
                        child: const Text("Guardar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _botonDelineado("Cerrar sesión", _colorPrincipal, () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }),
                      _botonDelineado("Cambiar contraseña", const Color(0xFFE53935), () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enlace enviado al correo")));
                      }),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGETS REUTILIZABLES DE FILA
  Widget _buildFilaTexto(String titulo, {required TextEditingController ctrl, bool isNumber = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text(titulo, style: TextStyle(fontSize: 16, color: _colorTextoGris, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: ctrl, textAlign: TextAlign.right,
                  keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
      ],
    );
  }

  Widget _buildFilaBoton(String titulo, String valor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: TextStyle(fontSize: 16, color: _colorTextoGris, fontWeight: FontWeight.bold)),
                Text(valor, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
        ],
      ),
    );
  }

  Widget _botonDelineado(String texto, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
          foregroundColor: color, side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
      ),
      onPressed: onPressed,
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
