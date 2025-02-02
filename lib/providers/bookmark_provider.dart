import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkProvider with ChangeNotifier {
  final Map<String, List<BookmarkItem>> _bookmarks = {};
  SharedPreferences? _prefs;
  static const String _bookmarksKey = 'pdf_bookmarks';

  Map<String, List<BookmarkItem>> get bookmarks => _bookmarks;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    _prefs = await SharedPreferences.getInstance();
    final savedBookmarks = _prefs?.getString(_bookmarksKey);
    if (savedBookmarks != null) {
      final Map<String, dynamic> decoded = json.decode(savedBookmarks);
      decoded.forEach((key, value) {
        _bookmarks[key] = (value as List)
            .map((item) => BookmarkItem.fromJson(item))
            .toList();
      });
      notifyListeners();
    }
  }

  Future<void> _saveBookmarks() async {
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    final encodedBookmarks = json.encode(_bookmarks.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    ));
    await _prefs?.setString(_bookmarksKey, encodedBookmarks);
  }

  List<BookmarkItem> getBookmarksForFile(String filePath) {
    return _bookmarks[filePath] ?? [];
  }

  Future<void> addBookmark(String filePath, BookmarkItem bookmark) async {
    if (!_bookmarks.containsKey(filePath)) {
      _bookmarks[filePath] = [];
    }
    _bookmarks[filePath]!.add(bookmark);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(String filePath, BookmarkItem bookmark) async {
    _bookmarks[filePath]?.removeWhere(
      (item) => item.pageNumber == bookmark.pageNumber,
    );
    await _saveBookmarks();
    notifyListeners();
  }

  bool isPageBookmarked(String filePath, int pageNumber) {
    return _bookmarks[filePath]?.any(
          (bookmark) => bookmark.pageNumber == pageNumber,
        ) ??
        false;
  }
}

class BookmarkItem {
  final int pageNumber;
  final String title;
  final String? note;
  final DateTime createdAt;

  BookmarkItem({
    required this.pageNumber,
    required this.title,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'title': title,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      pageNumber: json['pageNumber'],
      title: json['title'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 