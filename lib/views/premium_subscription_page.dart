import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PremiumSubscriptionPage extends StatefulWidget {
  const PremiumSubscriptionPage({Key? key}) : super(key: key);

  @override
  _PremiumSubscriptionPageState createState() => _PremiumSubscriptionPageState();
}

class _PremiumSubscriptionPageState extends State<PremiumSubscriptionPage> {
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedPlan = 1; // 0: 베이직, 1: 프리미엄
  
  final List<Map<String, dynamic>> _plans = [
    {
      'title': '베이직 플랜',
      'price': '$1/월',
      'priceKRW': '₩1,300/월',
      'description': '매월 자동 결제',
      'features': [
        '매월 30회 AI 요약 기능',
        '매월 20회 퀴즈 생성',
        '최대 50개 PDF 문서 저장',
        '기본 북마크 및 하이라이트',
        '광고 제거',
        '간단한 학습 통계',
        '텍스트 검색 기능 강화',
      ],
      'bestValue': false,
      'color': Colors.blue,
    },
    {
      'title': '프리미엄 플랜',
      'price': '$3/월',
      'priceKRW': '₩3,900/월',
      'description': '매월 자동 결제 (최고의 가치)',
      'features': [
        '무제한 PDF 저장',
        '무제한 AI 요약 및 퀴즈 생성',
        '다중 기기 동기화 (클라우드)',
        'AI 기반 학습 패턴 분석',
        '맞춤형 학습 계획 생성',
        '고급 플래시카드 기능',
        '오프라인 모드 지원',
        'OCR 텍스트 인식',
        '고급 퀴즈 형식 지원',
        'PDF 협업 및 공유 기능',
        '우선 기술 지원',
      ],
      'bestValue': true,
      'color': Colors.amber,
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄 구독'),
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                
                // 무료 플랜 정보
                _buildFreePlanCard(),
                const SizedBox(height: 24),
                
                // 구독 플랜 선택
                isMobile 
                    ? Column(
                        children: [
                          _buildPlanCard(0, fullWidth: true),
                          const SizedBox(height: 16),
                          _buildPlanCard(1, fullWidth: true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPlanCard(0)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPlanCard(1)),
                        ],
                      ),
                
                const SizedBox(height: 32),
                
                // 프리미엄 혜택 비교표
                _buildComparisonTable(),
                
                const SizedBox(height: 32),
                
                // 프리미엄 혜택 설명
                _buildPremiumBenefits(),
                
                const SizedBox(height: 32),
                
                // 결제 버튼
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSubscription(authService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _plans[_selectedPlan]['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('${_plans[_selectedPlan]['title']} 시작하기'),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  '구독은 언제든지 취소할 수 있습니다. 결제 후 취소하지 않으면 자동으로 갱신됩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.workspace_premium,
          size: 64,
          color: Colors.amber,
        ),
        const SizedBox(height: 16),
        const Text(
          '프리미엄 회원이 되어 더 많은 기능을 이용하세요',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'PDF 학습기의 모든 기능을 활용하여 학습 효율을 높이세요',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildFreePlanCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.loyalty, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  '무료 플랜',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: const Text('현재 이용 중'),
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('무료 플랜에 포함된 기능:'),
            const SizedBox(height: 8),
            _buildFeatureRow('기본 PDF 뷰어 기능'),
            _buildFeatureRow('일일 3회 AI 요약 기능'),
            _buildFeatureRow('매월 5회 퀴즈 생성'),
            _buildFeatureRow('최대 5개 PDF 문서 저장'),
            _buildFeatureRow('기본 검색 기능'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard(int index, {bool fullWidth = false}) {
    final plan = _plans[index];
    final isSelected = _selectedPlan == index;
    final color = plan['color'] as Color;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = index;
        });
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan['bestValue'])
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '최고의 가치',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(
                    index == 0 ? Icons.star : Icons.workspace_premium,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plan['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan['price'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      plan['priceKRW'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                plan['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              for (final feature in plan['features'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.black87 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: Radio(
                    value: index,
                    groupValue: _selectedPlan,
                    onChanged: (value) {
                      setState(() {
                        _selectedPlan = value as int;
                      });
                    },
                    activeColor: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildComparisonTable() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '플랜 비교',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('기능')),
                  DataColumn(label: Text('무료')),
                  DataColumn(label: Text('베이직')),
                  DataColumn(label: Text('프리미엄')),
                ],
                rows: [
                  _buildDataRow('PDF 저장', '5개', '50개', '무제한'),
                  _buildDataRow('AI 요약', '일일 3회', '월 30회', '무제한'),
                  _buildDataRow('퀴즈 생성', '월 5회', '월 20회', '무제한'),
                  _buildDataRow('다중 기기 동기화', '✖', '✓', '✓'),
                  _buildDataRow('북마크/하이라이트', '기본', '✓', '✓'),
                  _buildDataRow('오프라인 모드', '✖', '✖', '✓'),
                  _buildDataRow('OCR 검색', '✖', '✖', '✓'),
                  _buildDataRow('PDF 협업', '✖', '✖', '✓'),
                  _buildDataRow('고급 플래시카드', '✖', '✖', '✓'),
                  _buildDataRow('우선 기술 지원', '✖', '✖', '✓'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  DataRow _buildDataRow(String feature, String free, String basic, String premium) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(free)),
        DataCell(Text(basic)),
        DataCell(Text(premium)),
      ],
    );
  }
  
  Widget _buildPremiumBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '프리미엄 플랜 혜택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          Icons.cloud_done,
          '다중 기기 동기화',
          '모든 기기에서 동일한 PDF와 학습 데이터를 이용할 수 있습니다.',
        ),
        _buildBenefitItem(
          Icons.psychology,
          'AI 학습 분석',
          '학습 패턴을 분석하여 효율적인 학습 방법을 제안합니다.',
        ),
        _buildBenefitItem(
          Icons.quiz,
          '고급 퀴즈 기능',
          '다양한 퀴즈 형식과 난이도로 학습 효과를 높이세요.',
        ),
        _buildBenefitItem(
          Icons.text_format,
          'OCR 텍스트 인식',
          '스캔된 PDF도 검색 가능한 텍스트로 변환됩니다.',
        ),
      ],
    );
  }
  
  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.amber.shade800,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleSubscription(AuthService authService) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 로그인 확인
      if (!authService.isLoggedIn) {
        // 로그인 페이지로 이동
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      
      // 결제 처리
      final planType = _selectedPlan == 0 ? 'basic' : 'premium';
      final success = await authService.upgradeToPayment(planType: planType);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_plans[_selectedPlan]['title']} 구독이 시작되었습니다!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = '구독 처리 중 오류가 발생했습니다. 다시 시도해 주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 