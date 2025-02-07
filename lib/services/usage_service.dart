class UsageService {
  // 일일 사용량 추적
  Future<void> trackUsage({
    required String feature,
    required int amount,
  });
  
  // 사용량 통계
  Future<Map<String, int>> getDailyUsage();
  Future<Map<String, int>> getMonthlyUsage();
} 