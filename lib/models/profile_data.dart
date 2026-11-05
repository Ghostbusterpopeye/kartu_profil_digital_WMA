import 'dart:convert';
class ProfileData {
  final String name;
  final String title;
  final String bio;

  const ProfileData({
    required this.name,
    required this.title,
    required this.bio,
  });

  Map<String, dynamic> toMap() => {
      'name': name,
      'title': title,
      'bio': bio,
    };

  factory ProfileData.fromMap(Map<String, dynamic> map) => ProfileData(
        name: map['name'] as String? ?? defaults.name,
        title: map['title'] as String? ?? defaults.title,
        bio: map['bio'] as String? ?? defaults.bio,
      );

  String toJson() => jsonEncode(toMap());

  factory ProfileData.fromJson(String source) =>
      ProfileData.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Data bawaan saat belum ada data tersimpan.
  static const defaults = ProfileData(
    name: 'Sultan Shalahuddin Al Ayubi',
    title: 'Software Engineer & Mahasiswa',
    bio: 'Suka bermain game dan berenang.',
  );
}