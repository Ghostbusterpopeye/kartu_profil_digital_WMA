import 'package:flutter/material.dart';
import '../models/profile_data.dart';
import '../services/pref_service.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.prefs,
    required this.isDark,
    required this.onThemeChanged,
  });

  final PrefService prefs;
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil tersimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial =
        _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : '?';

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
                  const SizedBox(height: 16),
                  Text(_profile.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(_profile.title),
                  const SizedBox(height: 12),
                  Text(_profile.bio, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Mode Gelap'),
            value: widget.isDark,
            onChanged: widget.onThemeChanged,
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