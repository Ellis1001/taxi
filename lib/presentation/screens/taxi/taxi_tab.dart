import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class TaxiTab extends StatefulWidget {
  const TaxiTab({super.key});

  @override
  State<TaxiTab> createState() => _TaxiTabState();
}

class _TaxiTabState extends State<TaxiTab> {
  final _formKey = GlobalKey<FormState>();
  String _taxiType = 'Colectivo'; // <-- Set initial value to 'Colectivo'
  String _origen = '';
  String _destino = '';
  int _personas = 1;
  DateTime? _fechaHora;

  double? _precio;
  bool _precioCalculado = false;
  bool _camposEditados = false;

  void _calcularPrecio() {
    // Simulación de cálculo de precio (puedes reemplazarlo con tu lógica real)
    setState(() {
      _precio =
          (_taxiType == 'Privado' ? 30 : 15) +
          (_personas * 2) +
          ((_origen.length + _destino.length) % 10); // Solo para demo
      _precioCalculado = true;
      _camposEditados = false;
    });
  }

  void _resetPrecio() {
    setState(() {
      _precio = null;
      _precioCalculado = false;
      _camposEditados = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Taxi type selection as two buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _taxiType == 'Colectivo'
                              ? const Color(0xFF002A8F) // Blue
                              : Colors.grey[200],
                      foregroundColor:
                          _taxiType == 'Colectivo'
                              ? Colors.white
                              : Colors.black,
                      elevation: _taxiType == 'Colectivo' ? 4 : 0,
                    ),
                    onPressed: () {
                      setState(() {
                        _taxiType = 'Colectivo';
                        _resetPrecio();
                      });
                    },
                    child: const Text('Colectivo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _taxiType == 'Privado'
                              ? const Color(0xFFFFD700) // Yellow
                              : Colors.grey[200],
                      foregroundColor:
                          _taxiType == 'Privado' ? Colors.white : Colors.black,
                      elevation: _taxiType == 'Privado' ? 4 : 0,
                    ),
                    onPressed: () {
                      setState(() {
                        _taxiType = 'Privado';
                        _resetPrecio();
                      });
                    },
                    child: const Text('Privado'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Origen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onChanged: (value) {
                _origen = value;
                if (_precioCalculado) _resetPrecio();
              },
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Ingrese el origen'
                          : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Destino',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onChanged: (value) {
                _destino = value;
                if (_precioCalculado) _resetPrecio();
              },
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Ingrese el destino'
                          : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _personas,
                    decoration: const InputDecoration(
                      labelText: 'Personas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _personas = value!;
                        _resetPrecio();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _fechaHora = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            _resetPrecio();
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha y hora',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fechaHora == null
                                  ? 'Seleccionar'
                                  : '${_fechaHora!.day}/${_fechaHora!.month}/${_fechaHora!.year} ${_fechaHora!.hour}:${_fechaHora!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color:
                                    _fechaHora == null
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Mostrar el precio si ya fue calculado
            if (_precioCalculado && _precio != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Precio estimado: \$${_precio!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !_precioCalculado ? Colors.deepPurple : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _fechaHora != null) {
                    if (!_precioCalculado) {
                      _calcularPrecio();
                    } else {
                      final contactFormKey = GlobalKey<FormState>();
                      String direccion = '';
                      String nombreAlojamiento = '';
                      final direccionController = TextEditingController();
                      direccionController.text = '';
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Datos de Recogida'),
                            content: Form(
                              key: contactFormKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Como último paso para confirmar su reserva introduzca la dirección física y el nombre de la casa particular o hotel donde será recogido',
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: direccionController,
                                      decoration: InputDecoration(
                                        labelText: 'Dirección física',
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) => direccion = value,
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Ingrese su dirección'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Nombre de la casa particular o hotel',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (value) => nombreAlojamiento = value,
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Ingrese el nombre del alojamiento'
                                                  : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (contactFormKey.currentState!.validate()) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Reserva confirmada en $nombreAlojamiento, dirección: ${direccionController.text}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Enviar'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } else if (_fechaHora == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione fecha y hora')),
                    );
                  }
                },
                child: Text(
                  !_precioCalculado
                      ? 'Calcular Precio'
                      : (_camposEditados ? 'Recalcular' : 'Confirmar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// Add this widget at the end of your file
class _TaxiFormModal extends StatefulWidget {
  final String taxiType;
  final ValueChanged<String> onTaxiTypeChanged;
  final String origen;
  final ValueChanged<String> onOrigenChanged;
  final String destino;
  final ValueChanged<String> onDestinoChanged;
  final int personas;
  final ValueChanged<int> onPersonasChanged;
  final DateTime? fechaHora;
  final ValueChanged<DateTime?> onFechaHoraChanged;
  final double? precio;
  final bool precioCalculado;
  final bool camposEditados;
  final VoidCallback onCalcularPrecio;
  final VoidCallback onResetPrecio;
  final GlobalKey<FormState> formKey;

  const _TaxiFormModal({
    required this.taxiType,
    required this.onTaxiTypeChanged,
    required this.origen,
    required this.onOrigenChanged,
    required this.destino,
    required this.onDestinoChanged,
    required this.personas,
    required this.onPersonasChanged,
    required this.fechaHora,
    required this.onFechaHoraChanged,
    required this.precio,
    required this.precioCalculado,
    required this.camposEditados,
    required this.onCalcularPrecio,
    required this.onResetPrecio,
    required this.formKey,
    Key? key,
  }) : super(key: key);

  @override
  State<_TaxiFormModal> createState() => _TaxiFormModalState();
}

class _TaxiFormModalState extends State<_TaxiFormModal> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Taxi type selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.taxiType == 'Colectivo'
                              ? const Color(0xFF002A8F)
                              : Colors.grey[200],
                      foregroundColor:
                          widget.taxiType == 'Colectivo'
                              ? Colors.white
                              : Colors.black,
                      elevation: widget.taxiType == 'Colectivo' ? 4 : 0,
                    ),
                    onPressed: () {
                      widget.onTaxiTypeChanged('Colectivo');
                    },
                    child: const Text('Colectivo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.taxiType == 'Privado'
                              ? const Color(0xFFFFD700)
                              : Colors.grey[200],
                      foregroundColor:
                          widget.taxiType == 'Privado'
                              ? Colors.white
                              : Colors.black,
                      elevation: widget.taxiType == 'Privado' ? 4 : 0,
                    ),
                    onPressed: () {
                      widget.onTaxiTypeChanged('Privado');
                    },
                    child: const Text('Privado'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Origen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              initialValue: widget.origen,
              onChanged: widget.onOrigenChanged,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Ingrese el origen'
                          : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Destino',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              initialValue: widget.destino,
              onChanged: widget.onDestinoChanged,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Ingrese el destino'
                          : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: widget.personas,
                    decoration: const InputDecoration(
                      labelText: 'Personas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) widget.onPersonasChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          widget.onFechaHoraChanged(
                            DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha y hora',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.fechaHora == null
                                  ? 'Seleccionar'
                                  : '${widget.fechaHora!.day}/${widget.fechaHora!.month}/${widget.fechaHora!.year} ${widget.fechaHora!.hour}:${widget.fechaHora!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color:
                                    widget.fechaHora == null
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.precioCalculado && widget.precio != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Precio estimado: \$${widget.precio!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !widget.precioCalculado
                          ? Colors.deepPurple
                          : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (widget.formKey.currentState!.validate() &&
                      widget.fechaHora != null) {
                    if (!widget.precioCalculado) {
                      widget.onCalcularPrecio();
                    } else {
                      Navigator.of(context).pop();
                      // You can trigger the next step here (e.g., show contact info dialog)
                    }
                  } else if (widget.fechaHora == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione fecha y hora')),
                    );
                  }
                },
                child: Text(
                  !widget.precioCalculado
                      ? 'Calcular Precio'
                      : (widget.camposEditados ? 'Recalcular' : 'Confirmar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
