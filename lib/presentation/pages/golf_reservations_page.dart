// lib/presentation/pages/golf_reservations_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
// import '../widgets/booking/animated_compact_stats.dart';
// import '../widgets/booking/enhanced_court_tabs.dart';
import '../widgets/booking/reservation_form_modal.dart';
// import '../widgets/booking/reservation_webview.dart';
// import '../widgets/booking/time_slot_block.dart';
// import '../widgets/common/date_navigation_header.dart';
// import '../../core/constants/golf_constants.dart';
import '../../core/services/user_service.dart';
// import '../../core/theme/golf_theme.dart';
import '../../domain/entities/booking.dart';
import '../../../core/constants/app_constants.dart';

class GolfReservationsPage extends StatefulWidget {
  const GolfReservationsPage({Key? key}) : super(key: key);

  @override
  State<GolfReservationsPage> createState() => _GolfReservationsPageState();
}

class _GolfReservationsPageState extends State<GolfReservationsPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: context.read<BookingProvider>().currentDateIndex,
    );
    
    // Inicialización para Golf
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      print('⛳ GOLF INIT: provider.selectedCourtId = ${provider.selectedCourtId}');
      // Forzar selección inicial de Golf - Tee 1 por defecto
      provider.selectCourt('golf_tee_1');
      print('⛳ GOLF INIT: Forzado a golf_tee_1');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Golf Reservas'),
            backgroundColor: Color(0xFF7CB342),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.golf_course, size: 80, color: Color(0xFF7CB342)),
                SizedBox(height: 20),
                Text(
                  'Golf Reservations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7CB342),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Página en desarrollo',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}