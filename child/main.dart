import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:permission_handler/permission_handler.dart';

const String supabaseUrl = 'https://dfffubhyobxiknwacvzg.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmZmZ1Ymh5b2J4aWtud2FjdnpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNTE4MDQsImV4cCI6MjExMDkyNzgwNH0.pOf90LC2zprhPF1jpFSscnHkY6pbLnC6gjuInxuh6bs';

const brand = Color(0xFF0E7A5C);
const brandDark = Color(0xFF0A5C45);
const deep = Color(0xFF052019);
const bg = Color(0xFFF2F5F1);
const ink = Color(0xFF12201B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ChildApp());
}

final supabase = Supabase.instance.client;

class ChildApp extends StatelessWidget {
  const ChildApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brand,
        scaffoldBackgroundColor: bg);
    return MaterialApp(
      title: 'Посбон Кӯдак',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
            .apply(bodyColor: ink, displayColor: ink),
      ),
      home: const ChildGate(),
    );
  }
}

class ChildGate extends StatefulWidget {
  const ChildGate({super.key});
  @override
  State<ChildGate> createState() => _ChildGateState();
}

class _ChildGateState extends State<ChildGate> {
  bool _loading = true;
  String? _token;
  String? _childName;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _token = p.getString('device_token');
      _childName = p.getString('child_name');
      _loading = false;
    });
  }

  void _onPaired(String token, String name) {
    setState(() {
      _token = token;
      _childName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: brand)));
    }
    if (_token == null) return PairScreen(onPaired: _onPaired);
    return ProtectedScreen(token: _token!, childName: _childName ?? 'Кӯдак');
  }
}

class BrandLogo extends StatelessWidget {
  final double size;
  final bool glow;
  const BrandLogo({super.key, this.size = 76, this.glow = true});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF17A277), brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: glow
            ? [
                BoxShadow(
                    color: brand.withOpacity(0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 10))
              ]
            : null,
      ),
      child:
          Icon(Icons.shield_rounded, color: Colors.white, size: size * 0.52),
    );
  }
}

// ── Экрани пайвастшавӣ ──
class PairScreen extends StatefulWidget {
  final void Function(String token, String name) onPaired;
  const PairScreen({super.key, required this.onPaired});
  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _connect() async {
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Рамзи 6-рақамаро пурра ворид кунед');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String model = 'Android';
      try {
        final a = await DeviceInfoPlugin().androidInfo;
        model = '${a.manufacturer} ${a.model}';
      } catch (_) {}
      final res = await supabase.rpc('redeem_pairing_code',
          params: {'p_code': _code.text.trim(), 'p_model': model});
      final map = Map<String, dynamic>.from(res as Map);
      final token = map['device_token'] as String;
      final name = (map['child_name'] ?? 'Кӯдак') as String;
      final p = await SharedPreferences.getInstance();
      await p.setString('device_token', token);
      await p.setString('child_name', name);
      widget.onPaired(token, name);
    } on PostgrestException catch (_) {
      setState(() => _error = 'Рамз нодуруст ё кӯҳна аст');
    } catch (e) {
      setState(() => _error = 'Хатои пайвастшавӣ. Интернетро санҷед.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [deep, brandDark, Color(0xFF138A64)]),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 84)
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 18),
                    Text('Посбон Кӯдак',
                        style: GoogleFonts.manrope(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Рамзро аз телефони волидайн ворид кунед',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14)),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: GoogleFonts.robotoMono(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 12,
                                color: brandDark),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '––––––',
                              hintStyle: GoogleFonts.robotoMono(
                                  fontSize: 36,
                                  letterSpacing: 12,
                                  color: const Color(0xFFBFCCC6)),
                              filled: true,
                              fillColor: const Color(0xFFF4F7F4),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Color(0xFFB4281C), fontSize: 13)),
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _connect,
                              style: FilledButton.styleFrom(
                                  backgroundColor: brand,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16))),
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white))
                                  : const Text('Пайваст кардан',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(
                        begin: 0.15, curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Экрани муҳофизатшуда (ошкоро, назорати фонӣ) ──
class ProtectedScreen extends StatefulWidget {
  final String token;
  final String childName;
  const ProtectedScreen(
      {super.key, required this.token, required this.childName});
  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> {
  final _battery = Battery();
  Timer? _timer;
  StreamSubscription<Position>? _posSub;
  int? _level;
  bool _locationOn = false;
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Permission.notification.request();
    } catch (_) {}
    await _ensureLocationPermission();
    await _tick();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    _startTracking();
  }

  Future<void> _ensureLocationPermission() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final ok = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (mounted) setState(() => _locationOn = ok);
    } catch (_) {}
  }

  // Назорати фонӣ: хидмати фаъол бо огоҳии доимӣ
  void _startTracking() {
    if (_tracking || !_locationOn) return;
    try {
      final settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Посбон фаъол аст',
          notificationText: 'Ҷой ва бехатарӣ назорат мешавад',
          enableWakeLock: true,
        ),
      );
      _posSub = Geolocator.getPositionStream(locationSettings: settings)
          .listen((pos) => _report(pos));
      _tracking = true;
    } catch (_) {}
  }

  Future<void> _report(Position pos) async {
    try {
      await supabase.rpc('device_report_location', params: {
        'p_token': widget.token,
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
        'p_accuracy': pos.accuracy,
      });
    } catch (_) {}
  }

  Future<void> _tick() async {
    try {
      final lvl = await _battery.batteryLevel;
      if (mounted) setState(() => _level = lvl);
      await supabase.rpc('device_heartbeat', params: {
        'p_token': widget.token,
        'p_battery': lvl,
        'p_status': 'online'
      });
    } catch (_) {}
    if (_locationOn) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        await _report(pos);
      } catch (_) {}
    } else {
      await _ensureLocationPermission();
      if (_locationOn) _startTracking();
    }
  }

  Future<void> _sos() async {
    try {
      await supabase.rpc('device_log_event', params: {
        'p_token': widget.token,
        'p_type': 'sos',
        'p_title': 'SOS аз ${widget.childName}',
        'p_detail': 'Кӯдак тугмаи SOS-ро пахш кард',
        'p_severity': 'high',
      });
      if (_locationOn) {
        try {
          final pos = await Geolocator.getCurrentPosition();
          await _report(pos);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ба волидайн хабар фиристода шуд'),
            backgroundColor: brand));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  Widget _row(IconData ic, String title, String sub, bool ok) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(ic, color: brand, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14.5)),
                  Text(sub,
                      style: const TextStyle(
                          color: Color(0xFF61726B), fontSize: 12.5)),
                ],
              ),
            ),
            Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: ok ? brand : const Color(0xFFC9972A), size: 20),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                  child: const BrandLogo(size: 76)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1,
                          end: 1.05,
                          duration: 1800.ms,
                          curve: Curves.easeInOut)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [deep, brandDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF53E39B),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 7),
                          const Text('Назорат фаъол',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Ин телефон зери назорати\nволидайн аст',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1.3,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('${widget.childName} · батарея ${_level ?? '—'}%',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text('Волидайн чиро мебинанд',
                        style: GoogleFonts.manrope(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _row(Icons.location_on_outlined, 'Ҷойгиршавӣ',
                        _locationOn ? 'Фаъол · ҳатто вақти баста' : 'Иҷозати ҷой лозим аст', _locationOn),
                    const Divider(height: 1),
                    _row(Icons.battery_charging_full_rounded, 'Батарея ва ҳолат',
                        'Онлайн ва заряд', true),
                    const Divider(height: 1),
                    _row(Icons.notifications_none_rounded,
                        'Ҳушдорҳои бехатарӣ', 'SOS ва ҳолатҳои хатарнок', true),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF2DCA8))),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFF9A6A12), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Барои кори доимӣ, дар танзимоти телефон ба «Посбон» иҷозати худкор оғозёбӣ (Autostart) диҳед ва маҳдудияти батареяро хомӯш кунед.',
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Color(0xFF7A5A12))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 62,
                child: FilledButton.icon(
                  onPressed: _sos,
                  icon: const Icon(Icons.warning_amber_rounded, size: 26),
                  label: const Text('SOS — ба волидайн хабар диҳед',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB4281C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text('Посбон фаъол аст',
                    style: TextStyle(color: Color(0xFF8495A0), fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
