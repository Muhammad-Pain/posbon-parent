import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Пайвасти Supabase (проекти "posbon") — калидҳои оммавӣ ──
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
  runApp(const PosbonApp());
}

final supabase = Supabase.instance.client;

class PosbonApp extends StatelessWidget {
  const PosbonApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: brand,
      scaffoldBackgroundColor: bg,
    );
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

// ── Логотипи бренд ──
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
      child: Icon(Icons.shield_rounded,
          color: Colors.white, size: size * 0.52),
    );
  }
}

// Нақшу нигори нуқтагӣ (мисли палангаки барфӣ) дар сарлавҳа
class _SpotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
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
                                      color: Color(0xFFB4281C), fontSize: 13)),
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
                                      borderRadius: BorderRadius.circular(16))),
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
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
      final children = await supabase
          .from('children')
          .select()
          .eq('family_id', familyId)
          .order('created_at');
      setState(() {
        _familyId = familyId;
        _children = List<Map<String, dynamic>>.from(children);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Хатои боргирӣ. Интернетро санҷед.';
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

  Future<void> _pair(String childId, String childName) async {
    try {
      final code = await supabase
          .rpc('app_create_pairing_code', params: {'p_child_id': childId});
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
      _snack('Хато ҳангоми сохтани рамз');
    }
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
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white),
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
    return Container(
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
            child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
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
                Row(
                  children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: Color(0xFF9AA8A2),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Интизори пайвастшавӣ',
                        style:
                            TextStyle(fontSize: 12.5, color: Color(0xFF61726B))),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => _pair(c['id'] as String, name),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEAF4EF),
                foregroundColor: brandDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('Рамз',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
        label: const Text('Кӯдак',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
                                Text(_error!,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: brand),
                                    onPressed: _load,
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
                              itemBuilder: (ctx, i) => _childCard(
                                      _children[i], i)
                                  .animate()
                                  .fadeIn(
                                      duration: 350.ms, delay: (i * 60).ms)
                                  .slideX(begin: 0.08),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
