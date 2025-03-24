/// 정렬 옵션 타입
enum SortOption {
  /// 최신 날짜순 (가장 최근에 열어본 것 먼저)
  dateNewest,
  
  /// 오래된 날짜순 (가장 오래전에 열어본 것 먼저)
  dateOldest,
  
  /// 이름 오름차순 (A-Z)
  nameAZ,
  
  /// 이름 내림차순 (Z-A)
  nameZA,
  
  /// 페이지 수 오름차순 (적은 것부터)
  pageCountAsc,
  
  /// 페이지 수 내림차순 (많은 것부터)
  pageCountDesc,
  
  /// 추가일 최신순
  addedNewest,
  
  /// 추가일 오래된순
  addedOldest,
} 