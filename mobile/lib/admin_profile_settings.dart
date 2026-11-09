import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'admin_preferences.dart';

class AdminProfileSettingsPage extends StatefulWidget {
  final String initialName;
  final String email;
  final VoidCallback onLogout;

  const AdminProfileSettingsPage({
    super.key,
    required this.initialName,
    required this.email,
    required this.onLogout,
  });

  @override
  State<AdminProfileSettingsPage> createState() =>
      _AdminProfileSettingsPageState();
}

class _AdminProfileSettingsPageState extends State<AdminProfileSettingsPage> {
  String get _displayName => AdminPreferences.profileName ?? widget.initialName;

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _displayName);
    Uint8List? selectedImage = AdminPreferences.profileImage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: selectedImage == null
                    ? null
                    : MemoryImage(selectedImage!),
                child: selectedImage == null
                    ? const Icon(Icons.person_rounded, size: 36)
                    : null,
              ),
              TextButton.icon(
                onPressed: () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setDialogState(() => selectedImage = bytes);
                  }
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih foto'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama admin',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await AdminPreferences.saveProfile(
                  name: name,
                  image: selectedImage,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (saved == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil lokal berhasil diperbarui.')),
      );
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    try {
      await AdminPreferences.setThemeMode(mode);
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  Future<void> _setNotifications(bool enabled) async {
    try {
      await AdminPreferences.setNotificationsEnabled(enabled);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan lokal gagal disimpan.')),
    );
  }

  void _showPasswordInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: const Text(
          'Penggantian password belum didukung oleh backend. '
          'Tidak ada password yang diubah atau disimpan dari halaman ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = AdminPreferences.profileImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SettingsSection(
                  title: 'Profil Admin',
                  icon: Icons.admin_panel_settings_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: colors.primaryContainer,
                            backgroundImage: image == null
                                ? null
                                : MemoryImage(image),
                            child: image == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 36,
                                    color: colors.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.email,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Administrator ATK Mart',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profil'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nama dan foto profil hanya tersimpan di perangkat ini.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Pengaturan Akun',
                  icon: Icons.manage_accounts_outlined,
                  child: Column(
                    children: [
                      _SettingsAction(
                        icon: Icons.lock_reset_outlined,
                        title: 'Ganti Password',
                        subtitle: 'Belum tersedia melalui backend',
                        onTap: _showPasswordInfo,
                      ),
                      const Divider(height: 20),
                      _SettingsInfoRow(
                        icon: Icons.badge_outlined,
                        title: 'Peran',
                        value: 'Administrator',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Tampilan',
                  icon: Icons.palette_outlined,
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: AdminPreferences.themeMode,
                    builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Terang'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Gelap'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) =>
                          _setTheme(selection.first),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Notifikasi',
                  icon: Icons.notifications_none_rounded,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: AdminPreferences.notificationsEnabled,
                    onChanged: _setNotifications,
                    title: const Text('Notifikasi aplikasi'),
                    subtitle: const Text(
                      'Pilihan ini disimpan di perangkat ini.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Informasi Aplikasi',
                  icon: Icons.info_outline_rounded,
                  child: const _SettingsInfoRow(
                    icon: Icons.storefront_outlined,
                    title: 'ATK Mart',
                    value: 'Versi 1.0.0+1',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(
                        color: colors.error.withValues(alpha: .5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: colors.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingsInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
