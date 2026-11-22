import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Пайвасти Supabase (проекти "posbon") ──
// Ин калидҳо ОММАВӢ (public/anon) ҳастанд ва бехатаранд.
const String supabaseUrl = 'https://dfffubhyobxiknwacvzg.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmZmZ1Ymh5b2J4aWtud2FjdnpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNTE4MDQsImV4cCI6MjExMDkyNzgwNH0.pOf90LC2zprhPF1jpFSscnHkY6pbLnC6gjuInxuh6bs';

const brand = Color(0xFF0E7A5C);

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
    return MaterialApp(
      title: 'Посбон',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brand,
        scaffoldBackgroundColor: const Color(0xFFF4F6F3),
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
        final session = supabase.auth.currentSession;
        if (session == null) return const AuthScreen();
        return const HomeScreen();
      },
    );
  }
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
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (supabase.auth.currentSession == null) {
          setState(() {
            _info =
                'Ҳисоб сохта шуд. Агар тасдиқи email фаъол бошад, почтаатонро тафтиш кунед, баъд ворид шавед.';
            _isLogin = true;
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_outlined, size: 56, color: brand),
                const SizedBox(height: 12),
                const Text('Посбон',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_isLogin ? 'Ворид шавед' : 'Ҳисоби нав созед',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Рамз', border: OutlineInputBorder()),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child:
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_info != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_info!, style: const TextStyle(color: brand)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: brand),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isLogin ? 'Ворид шудан' : 'Сохтан'),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                            _info = null;
                          }),
                  child: Text(_isLogin
                      ? 'Ҳисоб надоред? Созед'
                      : 'Ҳисоб доред? Ворид шавед'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Экрани асосӣ: кӯдакон ва рамзи пайваст ──
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
        _error = e.toString();
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
      _snack(e.toString());
    }
  }

  Future<String?> _askName() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Кӯдаки нав'),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Номи кӯдак')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
          FilledButton(
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
        builder: (ctx) => AlertDialog(
          title: Text('Рамз барои $childName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$code',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: brand)),
              const SizedBox(height: 8),
              const Text(
                  'Дар телефони кӯдак, дар барномаи «Посбон Кӯдак» ин рамзро ворид кунед. Эътибор то 10 дақиқа.',
                  textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Хуб')),
          ],
        ),
      );
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Посбон'),
        actions: [
          IconButton(
              onPressed: () => supabase.auth.signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChild,
        icon: const Icon(Icons.add),
        label: const Text('Кӯдак'),
        backgroundColor: brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _children.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Ҳоло кӯдаке нест.\nТугмаи «Кӯдак»-ро пахш кунед.',
                            textAlign: TextAlign.center),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _children.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final c = _children[i];
                          final name = c['name'] as String;
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE2EFE9),
                                child: Text(
                                    name.isEmpty ? '?' : name.characters.first,
                                    style: const TextStyle(color: brand)),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              trailing: FilledButton.tonal(
                                onPressed: () => _pair(c['id'] as String, name),
                                child: const Text('Рамз'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
