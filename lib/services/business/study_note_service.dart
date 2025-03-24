class StudyNote {
  final String id;
  final String pdfPath;
  final int pageNumber;
  final String content;
  final DateTime createdAt;
  final List<String> tags;
  final String? aiSuggestion;

  StudyNote({
    required this.id,
    required this.pdfPath,
    required this.pageNumber,
    required this.content,
    required this.createdAt,
    this.tags = const [],
    this.aiSuggestion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfPath': pdfPath,
      'pageNumber': pageNumber,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'aiSuggestion': aiSuggestion,
    };
  }

  factory StudyNote.fromMap(Map<String, dynamic> map) {
    return StudyNote(
      id: map['id'],
      pdfPath: map['pdfPath'],
      pageNumber: map['pageNumber'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      tags: List<String>.from(map['tags']),
      aiSuggestion: map['aiSuggestion'],
    );
  }
}

class StudyNoteService {
  final DatabaseHelper _db;
  final AIService _aiService;

  StudyNoteService(this._db, this._aiService);

  Future<void> addNote(StudyNote note) async {
    await _db.insert('study_notes', note.toMap());
  }

  Future<List<StudyNote>> getNotesForPage(String pdfPath, int pageNumber) async {
    final maps = await _db.query(
      'study_notes',
      where: 'pdfPath = ? AND pageNumber = ?',
      whereArgs: [pdfPath, pageNumber],
    );
    return maps.map((map) => StudyNote.fromMap(map)).toList();
  }

  Future<String> getAISuggestion(String content) async {
    return _aiService.generateStudySuggestion(content);
  }
} 