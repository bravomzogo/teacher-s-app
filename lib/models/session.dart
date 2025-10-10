class Session {
  final int? id;
  final String title;
  final String? date;
  final String? notes;
  final String? createdAt;

  Session({
    this.id,
    required this.title,
    this.date,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'date': date,
    'notes': notes,
    'createdAt': createdAt,
  };

  factory Session.fromMap(Map<String, dynamic> m) => Session(
    id: m['id'],
    title: m['title'],
    date: m['date'],
    notes: m['notes'],
    createdAt: m['createdAt'],
  );

  @override
  String toString() => title;
}