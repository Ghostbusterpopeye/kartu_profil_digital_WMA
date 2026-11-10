class Project {
  const Project({
    this.id,
    required this.title,
    required this.description,
    required this.techStack,
    required this.createdAt,
  });

  final int? id; // null = belum disimpan; diisi otomatis oleh database
  final String title;
  final String description;
  final String techStack;
  final DateTime createdAt;

  /// Object → Map (untuk ditulis ke database)
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'tech_stack': techStack,
        'created_at': createdAt.toIso8601String(),
      };

  /// Map (hasil baca database) → Object
  factory Project.fromMap(Map<String, Object?> map) => Project(
        id: map['id'] as int?,
        title: map['title'] as String,
        description: map['description'] as String,
        techStack: map['tech_stack'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}