import 'package:flutter/material.dart';
import '../models/profile_data.dart';
import '../services/pref_service.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.prefs,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.themeColor,
    required this.onThemeColorChanged,
  });

  final PrefService prefs;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Color themeColor;
  final ValueChanged<Color> onThemeColorChanged;

  static const _themeColors = <(String, Color)>[
    ('Indigo', Color(0xFF3F51B5)),
    ('Teal', Color(0xFF009688)),
    ('Oranye', Color(0xFFFF9800)),
    ('Ungu', Color(0xFF9C27B0)),
    ('Biru', Color(0xFF2196F3)),
  ];

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileData _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.prefs.profile; // baca data tersimpan
  }

  Future<void> _edit() async {
    final result = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(initial: _profile)),
    );
    if (result == null) return; // pengguna menekan back

    await widget.prefs.saveProfile(result);
    if (!mounted) return;
    setState(() => _profile = result);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil tersimpan')));
  }

  Future<void> _reset() async {
    await widget.prefs.clearProfile();
    if (!mounted) return;
    setState(() => _profile = widget.prefs.profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil dikembalikan ke bawaan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = _profile.name.isNotEmpty
        ? _profile.name[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartu Profil Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit profil',
            onPressed: _edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.primaryContainer,
                    child: Text(initial, style: const TextStyle(fontSize: 32)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset Profil'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_profile.title),
                  const SizedBox(height: 12),
                  Text(_profile.bio, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Terakhir diedit: ${widget.prefs.lastEdited ?? 'Belum pernah'}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Mode tampilan'),
            trailing: DropdownButton<ThemeMode>(
              value: widget.themeMode,
              onChanged: (mode) {
                if (mode != null) widget.onThemeModeChanged(mode);
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistem'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Terang')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warna tema',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (name, color) in ProfilePage._themeColors)
                      ChoiceChip(
                        label: Text(name),
                        selected:
                            widget.themeColor.toARGB32() == color.toARGB32(),
                        onSelected: (_) => widget.onThemeColorChanged(color),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Lab 11 akan menambahkan menu "Proyek Saya" di sini.
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Kartu ini sudah dibuka ${widget.prefs.openCount} kali',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
