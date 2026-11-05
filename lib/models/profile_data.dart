class ProfileData {
  final String name;
  final String title;
  final String bio;

  const ProfileData({
    required this.name,
    required this.title,
    required this.bio,
  });

  /// Data bawaan saat belum ada data tersimpan.
  static const defaults = ProfileData(
    name: 'Sultan Shalahuddin Al Ayubi',
    title: 'Software Engineer & Mahasiswa',
    bio: 'Suka memabaca buku dan bermain game.',
  );
}