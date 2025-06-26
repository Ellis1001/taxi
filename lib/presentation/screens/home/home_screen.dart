import 'package:flutter/material.dart';
import 'package:taxibooking/presentation/screens/excursion/excursion_tab.dart';
import 'package:taxibooking/presentation/screens/reservas/reservas_tab.dart';
import 'package:taxibooking/presentation/screens/taxi/taxi_tab.dart';
import '../../../core/constants/app_colors.dart';
import 'package:taxibooking/presentation/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuba Taxi & Tours'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TaxiTab(), // <--- Aquí va la pestaña de Taxi
          ExcursionTab(),
          ReservasTab(),
          ProfileScreen(), // <--- Aquí va la pantalla de Perfil real
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_taxi), label: 'Taxi'),
          BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Excursiones'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}