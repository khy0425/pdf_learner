import 'package:flutter/material.dart';

/// 구독 배지 정보 클래스
class SubscriptionBadgeInfo {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const SubscriptionBadgeInfo({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.icon,
  });
}

/// 구독 배지 유틸리티
class SubscriptionBadge {
  /// 구독 등급에 따른 배지 정보 반환
  static SubscriptionBadgeInfo getBadgeForTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const SubscriptionBadgeInfo(
          label: '프리미엄',
          color: Color(0xFFFFD700), // 골드
          textColor: Colors.black87,
          icon: Icons.workspace_premium,
        );
      case 'pro':
        return const SubscriptionBadgeInfo(
          label: '프로',
          color: Color(0xFF9C27B0), // 퍼플
          textColor: Colors.white,
          icon: Icons.diamond,
        );
      case 'standard':
        return const SubscriptionBadgeInfo(
          label: '스탠다드',
          color: Color(0xFF2196F3), // 블루
          textColor: Colors.white,
          icon: Icons.star,
        );
      case 'free':
      default:
        return const SubscriptionBadgeInfo(
          label: '무료',
          color: Color(0xFF757575), // 그레이
          textColor: Colors.white,
          icon: Icons.person,
        );
    }
  }

  /// 구독 등급명 반환
  static String getTierName(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return '프리미엄';
      case 'pro':
        return '프로';
      case 'standard':
        return '스탠다드';
      case 'free':
      default:
        return '무료';
    }
  }

  /// 구독 등급별 혜택 목록 반환
  static List<String> getBenefitsForTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return [
          '일 200회 PDF 요약 생성',
          '광고 없는 사용',
          '우선 고객 지원',
          '모든 요약 스타일 및 길이 지원',
          '최대 50페이지 요약',
          '요약 내역 무제한 저장',
        ];
      case 'pro':
        return [
          '일 500회 PDF 요약 생성',
          '광고 없는 사용',
          '24/7 우선 고객 지원',
          '모든 요약 스타일 및 길이 지원',
          '전체 PDF 요약 (페이지 제한 없음)',
          '요약 내역 무제한 저장',
          '세부 분석 및 키워드 추출',
          'API 연동 지원',
        ];
      case 'standard':
        return [
          '일 50회 PDF 요약 생성',
          '광고 최소화',
          '이메일 고객 지원',
          '모든 요약 스타일 및 길이 지원',
          '최대 20페이지 요약',
          '50개 요약 내역 저장',
        ];
      case 'free':
      default:
        return [
          '일 10회 PDF 요약 생성',
          '최대 10페이지 요약',
          '기본 요약 스타일',
          '10개 요약 내역 저장',
        ];
    }
  }
  
  /// 구독 등급별 월 비용
  static double getPriceForTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return 9.99;
      case 'pro':
        return 19.99;
      case 'standard':
        return 4.99;
      case 'free':
      default:
        return 0.0;
    }
  }
  
  /// 구독 배지 위젯 생성
  static Widget buildBadge(String tier, {double? fontSize, bool includeIcon = true}) {
    final badgeInfo = getBadgeForTier(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeInfo.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (includeIcon && badgeInfo.icon != null) ...[
            Icon(
              badgeInfo.icon,
              color: badgeInfo.textColor,
              size: (fontSize ?? 14) + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            badgeInfo.label,
            style: TextStyle(
              color: badgeInfo.textColor,
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 