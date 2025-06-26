import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:taxibooking/providers/reservation_provider.dart'; // Import for date formatting

class ReservasTab extends StatefulWidget {
  const ReservasTab({super.key});

  @override
  State<ReservasTab> createState() => _ReservasTabState();
}

class _ReservasTabState extends State<ReservasTab> {
  // Remove local state variables, data comes from provider
  // List<Map<String, dynamic>> _provinciales = [];
  // List<Map<String, dynamic>> _excursiones = [];
  // bool _loading = true; // Loading state comes from provider
  String _selectedTab = 'provinciales'; // Keep state to track selected tab

  @override
  void initState() {
    super.initState();
    // Remove _fetchReservas call, provider handles initial fetch via auth listener
    // _fetchReservas();
  }

  // Remove _fetchReservas method entirely, provider handles data fetching and streaming
  // Future<void> _fetchReservas() async { ... }

  Future<void> _deleteReservation(int id) async {
    try {
      final bool confirmDelete =
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirmar Eliminación'),
                content: const Text(
                  '¿Está seguro de que desea eliminar esta reserva?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Eliminar'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (confirmDelete) {
        // Access the provider to call its delete method
        final reservationProvider = context.read<ReservationProvider>(); // Use read here as we are not listening for changes in this async method
        await reservationProvider.deleteReservation(
          id,
          _selectedTab == 'excursiones' ? 'reservas_excursiones' : 'reservas',
        );

        // _fetchReservas(); // This is no longer needed, provider's stream will update the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva eliminada con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting reservation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function to format DateTime
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime =
          DateTime.parse(dateTimeString).toLocal(); // Convert to local time
      // Format as 'dd/MM/yyyy HH:mm'
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      print('Error parsing date: $e');
      return 'Fecha inválida';
    }
  }

  // Helper function to determine icon based on location name (copied from taxi_tab logic)
  


  // Helper function to build a single excursion list item UI
  Widget _buildExcursionItem(Map<String, dynamic> reserva) {
    // Use a ValueKey based on the reservation ID
    return Card(
      key: ValueKey(reserva['id']), // Added Key for unique identification
      color: const Color.fromARGB(220, 250, 250, 202),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Stack(
        children: [
          ListTile(
            isThreeLine: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              reserva['titulo'].toString() ?? 'Excursión sin título',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                if (reserva['ubicacion'] != null &&
                    reserva['ubicacion'].toString().isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      // Use Expanded only if Row is inside a widget with bounded width (which is true here)
                      Expanded(
                        child: Text(
                          'Ubicación: ${reserva['ubicacion']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Personas: ${reserva['cantidad_personas']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Fecha: ${_formatDateTime(reserva['fecha_hora'])}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Guía: ${reserva['incluir_guia'] == true ? 'Sí' : 'No'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 15,
            right: 20,
            child: Text(
              '\$${reserva['precio']}',
              style: TextStyle(
                color: Colors.green,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ),
          // Position the status chip and delete button
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    reserva['estado'] ?? 'Confirmado',
                    style: TextStyle(
                      color:  Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  color: Colors.grey[600],
                  onPressed: () => _deleteReservation(reserva['id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build a single provincial list item UI
  Widget _buildProvincialItem(Map<String, dynamic> reserva) {
    // Get origin and destino strings, handle potential nulls
    final origen = reserva['origen']?.toString() ?? 'Origen desconocido';
    final destino = reserva['destino']?.toString() ?? 'Destino desconocido';

    return Card(
      key: ValueKey(reserva['id']), // Added Key for unique identification
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Stack(
        children: [
          ListTile(
            // Removed title property
            // title: Text(
            //   '${reserva['origen']} → ${reserva['destino']}',
            //   style: TextStyle(
            //     fontWeight: FontWeight.bold,
            //     fontSize: 18,
            //     color: Theme.of(context).primaryColor, // Main app color
            //   ),
            // ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Row for Origen with Icon
                Row(
                  children: [
                    Icon(
                      Icons.location_on, // Get icon based on name
                      size: 18,
                      color: Colors.green, // Green color for Origin
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ' $origen',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                           fontWeight: FontWeight.bold, // Make Origin bold
                           color: Theme.of(context).primaryColor, // Use primary color for text
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                 // Row for Destino with Icon
                Row(
                  children: [
                    Icon(
                       Icons.location_on, // Get icon based on name
                      size: 18,
                      color: Colors.red, // Red color for Destino
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ' $destino',
                        overflow: TextOverflow.ellipsis,
                         style: TextStyle(
                           fontWeight: FontWeight.bold, // Make Destino bold
                           color: Theme.of(context).primaryColor, // Use primary color for text
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Add some space before other details
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ' ${reserva['personas']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ' ${_formatDateTime(reserva['fecha_hora'])}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Precio en esquina inferior derecha
          Positioned(
            bottom: 15,
            right: 20,
            child: Text(
              '\$${reserva['precio']}',
              style: TextStyle(
                color: Colors.green,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ),
          // Position the status chip
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Text(
                    reserva['estado'] ?? 'Confirmado',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  color: Colors.grey[600],
                  onPressed: () => _deleteReservation(reserva['id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usa context.watch para escuchar los cambios en el provider
    final reservationProvider = context.watch<ReservationProvider>();

    // Obtén los datos y el estado de carga del provider
    final provinciales = reservationProvider.provinciales;
    final excursiones = reservationProvider.excursiones;
    final loading = reservationProvider.isLoading;
    final errorMessage = reservationProvider.errorMessage;

    // Use loading state from the provider
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Optionally show error message from provider
    if (errorMessage.isNotEmpty) {
       return Center(child: Text('Error: $errorMessage'));
    }

    // Use Column to arrange buttons and list vertically
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            // Row for the tab buttons
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                // Make buttons take equal width
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTab = 'provinciales';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedTab == 'provinciales'
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                    foregroundColor:
                        _selectedTab == 'provinciales'
                            ? Colors.white
                            : Colors.black87,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.local_taxi),
                      const Text('Viajes Provinciales'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTab = 'excursiones';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedTab == 'excursiones'
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                    foregroundColor:
                        _selectedTab == 'excursiones'
                            ? Colors.white
                            : Colors.black87,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.travel_explore),
                      const Text('Excursiones'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          // Use Expanded to make the list take available space
          child:
              (_selectedTab == 'provinciales' && provinciales.isEmpty) || // Use provider list
                      (_selectedTab == 'excursiones' &&
                          excursiones.isEmpty) // Use provider list
                  ? Center(
                    child: Text(
                      'No hay reservas ${_selectedTab == 'provinciales' ? 'provinciales' : 'de excursiones'} confirmadas.',
                    ),
                  )
                  : _selectedTab == 'provinciales'
                  ? RefreshIndicator( // Wrap Provincial list with RefreshIndicator
                      onRefresh: () async {
                        // Call the provider's fetch method on pull-to-refresh
                        await context.read<ReservationProvider>().fetchReservations();
                      },
                      child: ListView.builder(
                        // Direct ListView.builder for provinciales
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provinciales.length, // Use provider list count
                        itemBuilder: (context, index) {
                          final reserva =
                              provinciales[index]; // Use provider list item
                          return _buildProvincialItem(
                            reserva,
                          ); // Use item builder helper
                        },
                      ),
                    )
                  : RefreshIndicator( // Wrap Excursion list with RefreshIndicator
                      onRefresh: () async {
                        // Call the provider's fetch method on pull-to-refresh
                        await context.read<ReservationProvider>().fetchReservations();
                      },
                      child: ListView.builder(
                        // Direct ListView.builder for provinciales
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: excursiones.length, // Use provider list count
                        itemBuilder: (context, index) {
                          final reserva =
                              excursiones[index]; // Use provider list item
                          return _buildExcursionItem(
                            reserva,
                          ); // Use item builder helper
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
