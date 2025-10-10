class Progress {
  final int? id;
  final int studentId;
  final int sessionId;
  final double? score;
  final String? remarks;
  final String? createdAt;

  Progress({
    this.id,
    required this.studentId,
    required this.sessionId,
    this.score,
    this.remarks,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'sessionId': sessionId,
    'score': score,
    'remarks': remarks,
    'createdAt': createdAt,
  };

  factory Progress.fromMap(Map<String, dynamic> m) => Progress(
    id: m['id'],
    studentId: m['studentId'],
    sessionId: m['sessionId'],
    score: (m['score'] is int) ? (m['score'] as int).toDouble() : (m['score'] as double?),
    remarks: m['remarks'],
    createdAt: m['createdAt'],
  );
}