/// 파일 크기 포맷팅을 위한 유틸리티 클래스
class FileSizeFormatter {
  /// 바이트를 사람이 읽기 쉬운 형식으로 변환 (B, KB, MB, GB)
  static String formatSize(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 주어진 B, KB, MB, GB 문자열을 바이트로 변환
  static int parseSize(String sizeStr) {
    sizeStr = sizeStr.trim().toUpperCase();
    if (sizeStr.isEmpty) return 0;
    
    final RegExp regex = RegExp(r'^(\d+\.?\d*)\s*([BKMG]B?)?$');
    final match = regex.firstMatch(sizeStr);
    
    if (match == null) return 0;
    
    final double value = double.parse(match.group(1) ?? '0');
    final String? unit = match.group(2);
    
    switch (unit) {
      case 'KB':
      case 'K':
        return (value * 1024).round();
      case 'MB':
      case 'M':
        return (value * 1024 * 1024).round();
      case 'GB':
      case 'G':
        return (value * 1024 * 1024 * 1024).round();
      default:
        return value.round();
    }
  }
} 