import 'package:intl/intl.dart';

/// 날짜 포맷을 위한 유틸리티 클래스
class DateFormatter {
  /// 날짜를 '2023년 4월 1일' 형식으로 변환
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일', 'ko_KR').format(date);
  }
  
  /// 날짜를 '2023.04.01' 형식으로 변환
  static String formatDateCompact(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }
  
  /// 날짜를 '2023년 4월 1일 오후 3:45' 형식으로 변환
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR').format(date);
  }
  
  /// 현재 시간과 비교하여 상대적 시간 표시
  /// 오늘: '오늘 오후 3:45', 어제: '어제 오전 11:30', 그 외: '2023년 4월 1일'
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return '오늘 ${DateFormat('a h:mm', 'ko_KR').format(date)}';
    } else if (targetDate == yesterday) {
      return '어제 ${DateFormat('a h:mm', 'ko_KR').format(date)}';
    } else {
      return formatDate(date);
    }
  }
  
  /// 파일 크기를 포맷팅
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
} 