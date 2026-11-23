import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ── Пайвасти Supabase (проекти "posbon") — калидҳои оммавӣ ──
const String supabaseUrl = 'https://dfffubhyobxiknwacvzg.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmZmZ1Ymh5b2J4aWtud2FjdnpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNTE4MDQsImV4cCI6MjExMDkyNzgwNH0.pOf90LC2zprhPF1jpFSscnHkY6pbLnC6gjuInxuh6bs';

const brand = Color(0xFF0E7A5C);
const brandDark = Color(0xFF0A5C45);
const deep = Color(0xFF052019);
const bg = Color(0xFFF2F5F1);
const ink = Color(0xFF12201B);
const danger = Color(0xFFB4281C);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const PosbonApp());
}

final supabase = Supabase.instance.client;

bool deviceOnline(Map? d) {
  if (d == null) return false;
  final ls = d['last_seen'];
  if (ls == null) return false;
  final t = DateTime.tryParse(ls.toString());
  if (t == null) return false;
  return DateTime.now().toUtc().difference(t.toUtc()).inMinutes < 3;
}

String agoText(String? iso) {
  if (iso == null) return '—';
  final t = DateTime.tryParse(iso);
  if (t == null) return '—';
  final diff = DateTime.now().toUtc().difference(t.toUtc());
  if (diff.inMinutes < 1) return 'ҳозир';
  if (diff.inMinutes < 60) return '${diff.inMinutes} дақиқа пеш';
  if (diff.inHours < 24) return '${diff.inHours} соат пеш';
  return '${diff.inDays} рӯз пеш';
}

class PosbonApp extends StatelessWidget {
  const PosbonApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brand,
        scaffoldBackgroundColor: bg);
    return MaterialApp(
      title: 'Посбон',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
            .apply(bodyColor: ink, displayColor: ink),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        return supabase.auth.currentSession == null
            ? const AuthScreen()
            : const HomeScreen();
      },
    );
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

class _SpotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.06);
    final ps = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final spots = <Offset>[
      Offset(size.width * 0.82, 26),
      Offset(size.width * 0.93, 66),
      Offset(size.width * 0.72, 70),
      Offset(size.width * 0.88, 108),
      Offset(size.width * 0.62, 36),
    ];
    for (final s in spots) {
      canvas.drawCircle(s, 13, ps);
      canvas.drawCircle(s, 4.5, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Экрани вуруд ──
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
            email: _email.text.trim(), password: _password.text);
      } else {
        await supabase.auth
            .signUp(email: _email.text.trim(), password: _password.text);
        if (supabase.auth.currentSession == null) {
          setState(() {
            _info = 'Ҳисоб сохта шуд. Акнун ворид шавед.';
            _isLogin = true;
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Хатои пайвастшавӣ. Интернетро санҷед.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: brand),
        filled: true,
        fillColor: const Color(0xFFF4F7F4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: brand, width: 1.6)),
      );

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
                colors: [deep, brandDark, Color(0xFF138A64)],
              ),
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
                        .scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .then()
                        .shimmer(duration: 1400.ms, color: Colors.white24),
                    const SizedBox(height: 18),
                    Text('Посбон',
                        style: GoogleFonts.manrope(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Муҳофизи оромии оилаи шумо',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14)),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 12))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_isLogin ? 'Хуш омадед' : 'Ҳисоби нав',
                              style: GoogleFonts.manrope(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _dec('Email', Icons.mail_outline)),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _password,
                              obscureText: true,
                              decoration: _dec('Рамз', Icons.lock_outline)),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: danger, fontSize: 13)),
                            ),
                          if (_info != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_info!,
                                  style: const TextStyle(
                                      color: brand, fontSize: 13)),
                            ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
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
                                  : Text(_isLogin ? 'Ворид шудан' : 'Сохтан',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                      _isLogin = !_isLogin;
                                      _error = null;
                                      _info = null;
                                    }),
                            child: Text(
                                _isLogin
                                    ? 'Ҳисоб надоред? Созед'
                                    : 'Ҳисоб доред? Ворид шавед',
                                style: const TextStyle(color: brandDark)),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 150.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut),
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

// ── Экрани асосӣ ──
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _familyId;
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  final _palette = const [
    Color(0xFF0E7A5C),
    Color(0xFF2A6CD4),
    Color(0xFFB4541F),
    Color(0xFF7A3FA0),
    Color(0xFF1F7A6E),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final uid = supabase.auth.currentUser!.id;
      var family = await supabase
          .from('families')
          .select('id')
          .eq('owner_id', uid)
          .maybeSingle();
      family ??= await supabase
          .from('families')
          .insert({'owner_id': uid, 'name': 'Оилаи ман'})
          .select('id')
          .single();
      final familyId = family['id'] as String;
      final children = List<Map<String, dynamic>>.from(await supabase
          .from('children')
          .select()
          .eq('family_id', familyId)
          .order('created_at'));
      final ids = children.map((c) => c['id'] as String).toList();
      final Map<String, dynamic> devByChild = {};
      if (ids.isNotEmpty) {
        final devices = await supabase
            .from('devices')
            .select()
            .inFilter('child_id', ids)
            .order('created_at', ascending: false);
        for (final d in devices) {
          final cid = d['child_id'] as String;
          devByChild.putIfAbsent(cid, () => d);
        }
      }
      for (final c in children) {
        c['_device'] = devByChild[c['id']];
      }
      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _children = children;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) _error = 'Хатои боргирӣ. Интернетро санҷед.';
        _loading = false;
      });
    }
  }

  Future<void> _addChild() async {
    final name = await _askName();
    if (name == null || name.trim().isEmpty) return;
    try {
      await supabase
          .from('children')
          .insert({'family_id': _familyId, 'name': name.trim()});
      _load();
    } catch (e) {
      _snack('Хато ҳангоми илова');
    }
  }

  Future<String?> _askName() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Кӯдаки нав'),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration: InputDecoration(
                hintText: 'Номи кӯдак',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: brand),
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Илова')),
        ],
      ),
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: ink));

  Widget _header() {
    final email = supabase.auth.currentUser?.email ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deep, brandDark]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SpotsPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandLogo(size: 40, glow: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Посбон',
                            style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => supabase.auth.signOut(),
                    icon:
                        const Icon(Icons.logout_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Кӯдакони шумо',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _childCard(Map<String, dynamic> c, int i) {
    final name = c['name'] as String;
    final color = _palette[i % _palette.length];
    final device = c['_device'] as Map<String, dynamic>?;
    final online = deviceOnline(device);

    Widget statusLine;
    if (device == null) {
      statusLine = Row(children: [
        Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
                color: Color(0xFF9AA8A2), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        const Text('Интизори пайвастшавӣ',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF61726B))),
      ]);
    } else {
      statusLine = Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: online ? const Color(0xFF1F9D55) : const Color(0xFF9AA8A2),
                shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
            online
                ? 'Онлайн · ${device['battery'] ?? '—'}%'
                : 'Офлайн · ${agoText(device['last_seen'] as String?)}',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF61726B))),
      ]);
    }

    return GestureDetector(
      onTap: device == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ChildDetailScreen(child: c, color: color))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.85), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.manrope(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  statusLine,
                ],
              ),
            ),
            if (device == null)
              FilledButton.tonal(
                onPressed: () => createAndShowCode(
                    context, c['id'] as String, name),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF4EF),
                    foregroundColor: brandDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Рамз',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF9AA8A2)),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
                color: const Color(0xFFEAF4EF),
                borderRadius: BorderRadius.circular(30)),
            child: const Icon(Icons.family_restroom_rounded,
                size: 46, color: brand),
          ),
          const SizedBox(height: 18),
          Text('Ҳоло кӯдаке нест',
              style: GoogleFonts.manrope(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                'Тугмаи «Кӯдак»-ро пахш кунед, то аввалин кӯдакро илова кунед.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF61726B), height: 1.4)),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChild,
        backgroundColor: brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label:
            const Text('Кӯдак', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: brand))
                : _error != null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: brand),
                                    onPressed: () => _load(),
                                    child: const Text('Аз нав')),
                              ],
                            )))
                    : _children.isEmpty
                        ? _empty()
                        : RefreshIndicator(
                            color: brand,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 90),
                              itemCount: _children.length,
                              itemBuilder: (ctx, i) =>
                                  _childCard(_children[i], i)
                                      .animate()
                                      .fadeIn(
                                          duration: 350.ms,
                                          delay: (i * 60).ms)
                                      .slideX(begin: 0.08),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// Сохтани рамз ва нишон додани он (аз ҳар ҷо)
Future<void> createAndShowCode(
    BuildContext context, String childId, String childName) async {
  try {
    final code = await supabase
        .rpc('app_create_pairing_code', params: {'p_child_id': childId});
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 58, glow: false),
              const SizedBox(height: 14),
              Text('Рамз барои $childName',
                  style: GoogleFonts.manrope(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EF),
                    borderRadius: BorderRadius.circular(16)),
                child: Text('$code',
                    style: GoogleFonts.robotoMono(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                        color: brandDark)),
              ),
              const SizedBox(height: 14),
              const Text(
                  'Дар телефони кӯдак, дар барномаи «Посбон Кӯдак» ин рамзро ворид кунед. Эътибор то 10 дақиқа.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Хуб'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Хато ҳангоми сохтани рамз')));
    }
  }
}

// ── Экрани тафсилоти кӯдак (харита + ҳолат + огоҳиҳо) ──
class ChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  final Color color;
  const ChildDetailScreen(
      {super.key, required this.child, required this.color});
  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  Map<String, dynamic>? _device;
  Map<String, dynamic>? _location;
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  Timer? _timer;
  final _map = MapController();

  String get childId => widget.child['id'] as String;
  String get childName => widget.child['name'] as String;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dev = await supabase
          .from('devices')
          .select()
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      Map<String, dynamic>? loc;
      if (dev != null) {
        loc = await supabase
            .from('locations')
            .select()
            .eq('device_id', dev['id'])
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();
      }
      final events = List<Map<String, dynamic>>.from(await supabase
          .from('events')
          .select()
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(10));
      if (!mounted) return;
      setState(() {
        _device = dev;
        _location = loc;
        _events = events;
        _loading = false;
      });
      if (loc != null) {
        final ll = LatLng(
            (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        try {
          _map.move(ll, 15);
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'sos':
        return Icons.warning_amber_rounded;
      case 'zone':
        return Icons.my_location_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = deviceOnline(_device);
    final hasLoc = _location != null;
    final ll = hasLoc
        ? LatLng((_location!['lat'] as num).toDouble(),
            (_location!['lng'] as num).toDouble())
        : const LatLng(38.5598, 68.7870); // Душанбе — пешфарз

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded)),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          widget.color.withOpacity(0.85),
                          widget.color
                        ]),
                        borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: Text(childName.characters.first.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(childName,
                            style: GoogleFonts.manrope(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: online
                                      ? const Color(0xFF1F9D55)
                                      : const Color(0xFF9AA8A2),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                              online
                                  ? 'Онлайн · ${_device?['battery'] ?? '—'}%'
                                  : (_device == null
                                      ? 'Пайваст нашуда'
                                      : 'Офлайн · ${agoText(_device?['last_seen'] as String?)}'),
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFF61726B))),
                        ]),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () =>
                          createAndShowCode(context, childId, childName),
                      icon: const Icon(Icons.qr_code_rounded, color: brand)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: brand))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: SizedBox(
                            height: 300,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _map,
                                  options: MapOptions(
                                      initialCenter: ll, initialZoom: 15),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.posbon.parent',
                                    ),
                                    if (hasLoc)
                                      MarkerLayer(markers: [
                                        Marker(
                                          point: ll,
                                          width: 46,
                                          height: 46,
                                          child: const Icon(
                                              Icons.location_on,
                                              color: brand,
                                              size: 46),
                                        )
                                      ]),
                                  ],
                                ),
                                if (!hasLoc)
                                  Container(
                                    color: Colors.black.withOpacity(0.35),
                                    alignment: Alignment.center,
                                    child: const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                          'Ҷой ҳоло дастрас нест.\nДар телефони кӯдак иҷозати ҷойро санҷед.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (hasLoc)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                                'Навсозии ҷой: ${agoText(_location?['recorded_at'] as String?)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF61726B))),
                          ),
                        const SizedBox(height: 20),
                        Text('Огоҳиҳо',
                            style: GoogleFonts.manrope(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        if (_events.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18)),
                            child: const Text('Ҳоло огоҳӣ нест',
                                style: TextStyle(color: Color(0xFF61726B))),
                          )
                        else
                          ..._events.map((e) {
                            final high = e['severity'] == 'high';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: high
                                      ? Border.all(
                                          color: const Color(0xFFF3C9C2))
                                      : null),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: high
                                            ? const Color(0xFFFBE6E3)
                                            : const Color(0xFFEAF4EF),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(
                                        _eventIcon(e['type'] as String),
                                        color: high ? danger : brand,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            (e['title'] ?? e['type']) as String,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        if (e['detail'] != null)
                                          Text(e['detail'] as String,
                                              style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: Color(0xFF61726B))),
                                      ],
                                    ),
                                  ),
                                  Text(
                                      agoText(e['created_at'] as String?),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF8495A0))),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
