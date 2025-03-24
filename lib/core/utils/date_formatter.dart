import 'package:intl/intl.dart';

/// 날짜 포맷팅을 위한 유틸리티 클래스
class DateFormatter {
  /// 일반 날짜 형식 (yyyy-MM-dd)
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  
  /// 시간 포함 날짜 형식 (yyyy-MM-dd HH:mm)
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  
  /// 상대적 시간 표시를 위한 기준 시간 (현재)
  static DateTime get _now => DateTime.now();
  
  /// 날짜를 문자열로 포맷팅
  static String formatDate(DateTime date) {
    // 오늘인 경우
    if (_isToday(date)) {
      return '오늘';
    }
    
    // 어제인 경우
    if (_isYesterday(date)) {
      return '어제';
    }
    
    // 일주일 이내인 경우
    if (_isWithinDays(date, 7)) {
      return '${_now.difference(date).inDays}일 전';
    }
    
    // 그 외의 경우 날짜 포맷팅
    return _dateFormat.format(date);
  }
  
  /// 날짜와 시간을 문자열로 포맷팅
  static String formatDateTime(DateTime date) {
    // 오늘인 경우 시간만 표시
    if (_isToday(date)) {
      return '오늘 ${DateFormat('HH:mm').format(date)}';
    }
    
    // 어제인 경우 
    if (_isYesterday(date)) {
      return '어제 ${DateFormat('HH:mm').format(date)}';
    }
    
    // 그 외의 경우 날짜와 시간 포맷팅
    return _dateTimeFormat.format(date);
  }
  
  /// 오늘인지 확인
  static bool _isToday(DateTime date) {
    return date.year == _now.year && date.month == _now.month && date.day == _now.day;
  }
  
  /// 어제인지 확인
  static bool _isYesterday(DateTime date) {
    final yesterday = _now.subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }
  
  /// 특정 일수 이내인지 확인
  static bool _isWithinDays(DateTime date, int days) {
    final difference = _now.difference(date).inDays;
    return difference < days && difference > 0;
  }
  
  /// 두 날짜 간의 차이를 서술적으로 표현
  static String getTimeDifference(DateTime date) {
    final difference = _now.difference(date);
    
    // 1분 이내
    if (difference.inMinutes < 1) {
      return '방금 전';
    }
    
    // 1시간 이내
    if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    }
    
    // 1일 이내
    if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    }
    
    // 30일 이내
    if (difference.inDays < 30) {
      return '${difference.inDays}일 전';
    }
    
    // 1년 이내
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    }
    
    // 1년 이상
    return '${(difference.inDays / 365).floor()}년 전';
  }

  /// 날짜를 yyyy-MM-dd 형식의 문자열로 변환
  static String formatToYMD(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }
  
  /// 날짜를 yyyy-MM-dd HH:mm 형식의 문자열로 변환
  static String formatToYMDHM(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }
  
  /// 날짜를 '오늘', '어제', 또는 yyyy-MM-dd 형식의 상대적 문자열로 변환
  static String formatToRelative(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (targetDate == today) {
      return '오늘';
    } else if (targetDate == yesterday) {
      return '어제';
    } else if (now.difference(dateTime).inDays < 7) {
      // 1주일 이내
      return '${now.difference(dateTime).inDays}일 전';
    } else if (dateTime.year == now.year) {
      // 같은 해 내에는 월-일만 표시
      return DateFormat('M월 d일').format(dateTime);
    } else {
      // 다른 해의 경우 연-월-일 표시
      return DateFormat('yyyy년 M월 d일').format(dateTime);
    }
  }
  
  /// 파일 크기를 사람이 읽기 쉬운 형식으로 변환 (KB, MB, GB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
  
  /// 시간을 분:초 형식으로 변환 (비디오 또는 오디오 길이에 적합)
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
} 