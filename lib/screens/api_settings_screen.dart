import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APISettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 설정')),
      body: Column(
        children: [
          // 현재 구독 상태 표시
          SubscriptionStatusCard(),
          
          // 사용량 통계
          UsageStatisticsWidget(),
          
          // 구독 플랜 선택
          SubscriptionPlansWidget(),
          
          // 결제 정보 관리
          PaymentMethodsWidget(),
        ],
      ),
    );
  }
} 