import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'api_client.dart';

const _blue = Color(0xFF276749);
const _navy = Color(0xFF17352A);
const _page = Color(0xFFF7F3E8);
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() => runApp(const MonCvApp());

class MonCvApp extends StatelessWidget {
  const MonCvApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Projet TP',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: _messengerKey,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _blue),
      scaffoldBackgroundColor: _page,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCF4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD7C5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD7C5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    ),
    home: const _AuthPage(),
  );
}

class _AuthPage extends StatefulWidget {
  const _AuthPage();

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await _api.authenticate(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        register: _register,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => _AppShell(api: _api, user: user),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Connexion impossible : $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [_blue, Color(0xFF123E2C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFFE8EDF5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _register ? 'Créer un compte' : 'Bon retour !',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _register
                                ? 'Inscrivez-vous pour commencer.'
                                : 'Connectez-vous à votre espace personnel.',
                            style: const TextStyle(color: Color(0xFF77849A)),
                          ),
                          const SizedBox(height: 22),
                          if (_register) ...[
                            _AuthField(
                              controller: _name,
                              label: 'Nom complet',
                              icon: Icons.person_outline,
                              validator: (value) =>
                                  value == null || value.trim().length < 2
                                  ? 'Entrez votre nom.'
                                  : null,
                            ),
                            const SizedBox(height: 13),
                          ],
                          _AuthField(
                            controller: _email,
                            label: 'Adresse e-mail',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null ||
                                    !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                        .hasMatch(value.trim())
                                ? 'Entrez une adresse e-mail valide.'
                                : null,
                          ),
                          const SizedBox(height: 13),
                          _AuthField(
                            controller: _password,
                            label: 'Mot de passe',
                            icon: Icons.lock_outline,
                            obscure: true,
                            validator: (value) =>
                                value == null || value.length < 8
                                ? '8 caractères minimum.'
                                : null,
                          ),
                          if (_register) ...[
                            const SizedBox(height: 13),
                            _AuthField(
                              controller: _passwordAgain,
                              label: 'Confirmer le mot de passe',
                              icon: Icons.verified_user_outlined,
                              obscure: true,
                              validator: (value) => value != _password.text
                                  ? 'Les mots de passe ne correspondent pas.'
                                  : null,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _blue,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _register ? 'S’inscrire' : 'Se connecter',
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _register = !_register;
                                    _error = null;
                                  }),
                            child: Text(
                              _register
                                  ? 'Déjà un compte ? Se connecter'
                                  : 'Créer un compte',
                              style: const TextStyle(
                                color: _blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Connexion sécurisée · Vos données restent privées',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8793A7), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    ),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.api, required this.user});

  final ApiClient api;
  final UserProfile user;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _tab = 0;
  List<PersonRecord> _family = const [];
  List<PersonRecord> _students = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.api.loadPeople(DirectoryKind.family),
        widget.api.loadPeople(DirectoryKind.students),
      ]);
      if (!mounted) return;
      setState(() {
        _family = results[0];
        _students = results[1];
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Chargement impossible : $error';
        });
      }
    }
  }

  Future<void> _signOut() async {
    String? errorMessage;
    try {
      await widget.api.signOut();
    } catch (error) {
      errorMessage = 'Déconnexion du serveur impossible : $error';
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const _AuthPage()),
      (_) => false,
    );
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Accueil', 'Famille', 'Étudiants', 'Mon profil'];
    final pages = [
      _HomePage(
        user: widget.user,
        family: _family,
        students: _students,
        loading: _loading,
        error: _loadError,
        onRefresh: _reload,
        onNavigate: (tab) => setState(() => _tab = tab),
      ),
      _PeoplePage(
        api: widget.api,
        kind: DirectoryKind.family,
        records: _family,
        loading: _loading,
        error: _loadError,
        onChanged: _reload,
      ),
      _PeoplePage(
        api: widget.api,
        kind: DirectoryKind.students,
        records: _students,
        loading: _loading,
        error: _loadError,
        onChanged: _reload,
      ),
      _ProfilePage(user: widget.user, onSignOut: _signOut),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EDD8),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.badge_outlined, color: _blue, size: 21),
            ),
            const SizedBox(width: 10),
            Text(
              titles[_tab],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE6EDD8),
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Famille',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Étudiants',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.user,
    required this.family,
    required this.students,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onNavigate,
  });

  final UserProfile user;
  final List<PersonRecord> family;
  final List<PersonRecord> students;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.trim().split(' ').first;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        children: [
          Text(
            'Bonjour, $firstName 👋',
            style: const TextStyle(
              color: _navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Votre espace personnel en un coup d’œil.',
            style: TextStyle(color: Color(0xFF7B879A)),
          ),
          const SizedBox(height: 21),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, Color(0xFF123E2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 29,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: _blue, size: 34),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mon espace',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user_outlined, color: Colors.white70),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 15),
            _ErrorBanner(message: error!),
          ],
          const SizedBox(height: 23),
          const _SectionHeading(title: 'Vue d’ensemble'),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _CountCard(
                  title: 'Famille',
                  count: loading ? '—' : '${family.length}',
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF28A66A),
                  onTap: () => onNavigate(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountCard(
                  title: 'Étudiants',
                  count: loading ? '—' : '${students.length}',
                  icon: Icons.school_rounded,
                  color: const Color(0xFFFF9F39),
                  onTap: () => onNavigate(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeading(title: 'Accès rapide'),
          const SizedBox(height: 13),
          _QuickLink(
            icon: Icons.badge_outlined,
            color: _blue,
            title: 'Mon CV',
            subtitle: 'Consulter mon profil professionnel',
            onTap: () => onNavigate(3),
          ),
          const SizedBox(height: 10),
          _QuickLink(
            icon: Icons.groups_outlined,
            color: const Color(0xFF28A66A),
            title: 'Ma famille',
            subtitle: 'Ajouter ou modifier un membre',
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 10),
          _QuickLink(
            icon: Icons.school_outlined,
            color: const Color(0xFFFF9F39),
            title: 'Mes étudiants',
            subtitle: 'Gérer les dossiers des étudiants',
            onTap: () => onNavigate(2),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              color: _navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(title, style: const TextStyle(color: Color(0xFF77849A))),
        ],
      ),
    ),
  );
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    tileColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE9EEF5)),
    ),
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .1),
      child: Icon(icon, color: color, size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, color: _navy),
    ),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.chevron_right, color: Color(0xFF8A97A9)),
  );
}

class _PeoplePage extends StatefulWidget {
  const _PeoplePage({
    required this.api,
    required this.kind,
    required this.records,
    required this.loading,
    required this.error,
    required this.onChanged,
  });

  final ApiClient api;
  final DirectoryKind kind;
  final List<PersonRecord> records;
  final bool loading;
  final String? error;
  final VoidCallback onChanged;

  @override
  State<_PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<_PeoplePage> {
  bool _busy = false;

  Future<void> _edit([PersonRecord? record]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            _PersonFormPage(api: widget.api, kind: widget.kind, record: record),
      ),
    );
    if (saved == true) widget.onChanged();
  }

  Future<void> _delete(PersonRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce dossier ?'),
        content: Text('Le dossier de ${record.fullName} sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await widget.api.deletePerson(widget.kind, record.id);
      widget.onChanged();
    } catch (error) {
      if (mounted) _showMessage(context, 'Suppression impossible : $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      RefreshIndicator(
        onRefresh: () async => widget.onChanged(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.kind == DirectoryKind.family
                        ? 'Les personnes qui comptent pour vous.'
                        : 'Les dossiers de vos étudiants.',
                    style: const TextStyle(color: Color(0xFF77849A)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _edit(),
                  icon: const Icon(Icons.add, size: 19),
                  label: Text('Ajouter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (widget.error != null) ...[
              _ErrorBanner(message: widget.error!),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: widget.onChanged,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ] else if (widget.loading && widget.records.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (widget.records.isEmpty)
              _EmptyState(
                icon: widget.kind == DirectoryKind.family
                    ? Icons.groups_outlined
                    : Icons.school_outlined,
                title: 'Aucun dossier pour le moment',
                message:
                    'Ajoutez un ${widget.kind.singular} pour le retrouver ici.',
                onAdd: () => _edit(),
              )
            else
              ...widget.records.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PersonCard(
                    record: record,
                    kind: widget.kind,
                    onEdit: () => _edit(record),
                    onDelete: () => _delete(record),
                  ),
                ),
              ),
          ],
        ),
      ),
      if (_busy)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(minHeight: 2),
        ),
    ],
  );
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.record,
    required this.kind,
    required this.onEdit,
    required this.onDelete,
  });

  final PersonRecord record;
  final DirectoryKind kind;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final detail = kind == DirectoryKind.family
        ? record.relation
        : record.schoolClass;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: [
          _PersonAvatar(record: record, radius: 27),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.fullName,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFF7B879A),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (record.phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    record.phone,
                    style: const TextStyle(
                      color: Color(0xFF7B879A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Modifier',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: _blue, size: 20),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.shade500,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonFormPage extends StatefulWidget {
  const _PersonFormPage({required this.api, required this.kind, this.record});

  final ApiClient api;
  final DirectoryKind kind;
  final PersonRecord? record;

  @override
  State<_PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<_PersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _relation;
  late final TextEditingController _className;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _birthday;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _saving = false;
  String? _error;

  bool get _isFamily => widget.kind == DirectoryKind.family;
  bool get _editing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _firstName = TextEditingController(text: record?.firstName ?? '');
    _lastName = TextEditingController(text: record?.lastName ?? '');
    _relation = TextEditingController(text: record?.relation ?? '');
    _className = TextEditingController(text: record?.schoolClass ?? '');
    _address = TextEditingController(text: record?.address ?? '');
    _phone = TextEditingController(text: record?.phone ?? '');
    _birthday = TextEditingController(text: record?.birthday ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _relation.dispose();
    _className.dispose();
    _address.dispose();
    _phone.dispose();
    _birthday.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _photoBytes = bytes;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Ouverture de la galerie : $error');
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('fr'),
    );
    if (date != null) {
      _birthday.text =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.savePerson(
        kind: widget.kind,
        id: widget.record?.id,
        photo: _photo,
        fields: {
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          if (_isFamily) 'relationship': _relation.text.trim(),
          if (!_isFamily) ...{
            'school_class': _className.text.trim(),
            'address': _address.text.trim(),
          },
          'phone': _phone.text.trim(),
          'birthday': _birthday.text.trim(),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Enregistrement impossible : $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${_editing ? 'Modifier' : 'Ajouter'} ${widget.kind.singular}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _choosePhoto,
                    child: Stack(
                      children: [
                        _photoBytes != null
                            ? CircleAvatar(
                                radius: 48,
                                backgroundImage: MemoryImage(_photoBytes!),
                              )
                            : _PersonAvatar(record: widget.record, radius: 48),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: _blue,
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _choosePhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Choisir une photo dans la galerie'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FormInput(
              controller: _lastName,
              label: 'Nom',
              icon: Icons.person_outline,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _FormInput(
              controller: _firstName,
              label: 'Prénom',
              icon: Icons.person_outline,
              validator: _required,
            ),
            const SizedBox(height: 12),
            if (_isFamily)
              _FormInput(
                controller: _relation,
                label: 'Lien de parenté',
                icon: Icons.family_restroom_outlined,
                hint: 'Ex. : Mère, frère, conjoint…',
              )
            else ...[
              _FormInput(
                controller: _className,
                label: 'Classe / formation',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),
              _FormInput(
                controller: _address,
                label: 'Adresse',
                icon: Icons.location_on_outlined,
              ),
            ],
            const SizedBox(height: 12),
            _FormInput(
              controller: _birthday,
              label: 'Date de naissance',
              icon: Icons.calendar_month_outlined,
              readOnly: true,
              onTap: _pickBirthday,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _FormInput(
              controller: _phone,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _editing
                          ? 'Enregistrer les modifications'
                          : 'Enregistrer',
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Ce champ est obligatoire.'
      : null;
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    readOnly: readOnly,
    onTap: onTap,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
    ),
  );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.user, required this.onSignOut});

  final UserProfile user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE9EEF5)),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 43,
              backgroundColor: Color(0xFFE6EDD8),
              child: Icon(Icons.person, color: _blue, size: 47),
            ),
            const SizedBox(height: 13),
            Text(
              user.name,
              style: const TextStyle(
                color: _navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: Color(0xFF77849A))),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const _SectionHeading(title: 'Mon CV'),
      const SizedBox(height: 10),
      const _ProfileInfoRow(
        icon: Icons.work_outline,
        title: 'Profession',
        subtitle: 'Etudiant en Informatique à ISIG/GOMA',
      ),
      const _ProfileInfoRow(
        icon: Icons.school_outlined,
        title: 'Formation',
        subtitle: 'Informatique Appliqué à la Gestion des Entreprises',
      ),
      const _ProfileInfoRow(
        icon: Icons.location_on_outlined,
        title: 'Localisation',
        subtitle: 'Goma, RDC',
      ),
      const SizedBox(height: 18),
      const _SectionHeading(title: 'Application'),
      const SizedBox(height: 10),
      const _ProfileInfoRow(
        icon: Icons.info_outline,
        title: 'À propos de Projet TP',
        subtitle: 'Flutter · API PHP · MySQL',
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: onSignOut,
        icon: const Icon(Icons.logout, color: Color(0xFFDA4A4A)),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(color: Color(0xFFDA4A4A)),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: Color(0xFFF2D7D7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  );
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFE6EDD8),
      child: Icon(icon, color: _blue, size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    subtitle: Text(subtitle),
  );
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({this.record, required this.radius});

  final PersonRecord? record;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = record?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE6EDD8),
        child: ClipOval(
          child: Image.network(
            resolvePhotoUri(photoUrl).toString(),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person,
              size: radius * .9,
              color: _blue,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE6EDD8),
      child: Icon(Icons.person, size: radius * .9, color: _blue),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onAdd,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 32),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE9EEF5)),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 29,
          backgroundColor: const Color(0xFFE6EDD8),
          child: Icon(icon, color: _blue, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF77849A)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter'),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: _navy,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF7D0CD)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFB63D36), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF9D312B), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
