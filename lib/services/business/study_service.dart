class StudyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveStudyNote(StudyNote note) async {
    // 학습 노트 저장
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    // 북마크 저장
  }

  Stream<List<StudyNote>> studyNotes(String userId) {
    // 학습 노트 실시간 조회
  }

  Stream<List<Bookmark>> bookmarks(String userId) {
    // 북마크 실시간 조회
  }
} 