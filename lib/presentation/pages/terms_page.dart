import 'package:flutter/material.dart';

/// 이용약관 및 개인정보처리방침 페이지
class TermsPage extends StatefulWidget {
  final bool isPrivacyPolicy;
  
  const TermsPage({Key? key, this.isPrivacyPolicy = false}) : super(key: key);

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPrivacyPolicy ? '개인정보처리방침' : '이용약관'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isPrivacyPolicy)
                  _buildPrivacyPolicy()
                else
                  _buildTermsOfService(),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF5D5FEF),
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsOfService() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이용약관',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D5FEF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '최종 수정일: ${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
          '1. 서비스 이용 약관',
          '본 약관은 PDF 학습기 서비스(이하 "서비스")의 이용에 관한 조건 및 절차, 회사와 회원 간의 권리와 의무 등을 규정합니다. 회원은 본 약관을 숙지하고 서비스를 이용해야 합니다.',
        ),
        _buildSection(
          '2. 서비스 이용',
          '회원은 본 서비스를 이용하여 PDF 파일을 업로드하고, 읽고, 학습할 수 있습니다. 단, 회원이 업로드한 콘텐츠에 대한 저작권 및 기타 권리는 회원 본인에게 있으며, 불법적인 콘텐츠의 업로드는 금지됩니다.',
        ),
        _buildSection(
          '3. 회원 가입 및 계정',
          '서비스 이용을 위해서는 회원 가입이 필요합니다. 회원은 정확한 정보를 제공해야 하며, 계정 정보의 보안을 유지해야 합니다. 회사는 회원의 계정 정보 유출로 인한 피해에 대해 책임을 지지 않습니다.',
        ),
        _buildSection(
          '4. 서비스 변경 및 중단',
          '회사는 언제든지 서비스 내용을 변경하거나 중단할 수 있습니다. 중요한 변경사항이 있을 경우, 회사는 회원에게 사전 통지할 것입니다.',
        ),
        _buildSection(
          '5. 책임 제한',
          '회사는 서비스를 통해 업로드된 콘텐츠의 정확성, 신뢰성, 적법성에 대해 책임을 지지 않습니다. 서비스 이용 중 발생하는 데이터 손실이나 기타 손해에 대해 회사는 책임을 지지 않습니다.',
        ),
        _buildSection(
          '6. 약관 변경',
          '회사는 필요에 따라 본 약관을 변경할 수 있으며, 변경된 약관은 서비스 내 공지사항을 통해 알릴 것입니다. 변경된 약관에 동의하지 않는 회원은 서비스 이용을 중단할 수 있습니다.',
        ),
        _buildSection(
          '7. 준거법 및 관할',
          '본 약관은 대한민국 법률에 따라 해석되며, 서비스 이용으로 인한 분쟁은 대한민국 법원을 관할 법원으로 합니다.',
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '개인정보처리방침',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D5FEF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '최종 수정일: ${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
          '1. 수집하는 개인정보',
          '회사는 서비스 제공을 위해 다음과 같은 개인정보를 수집합니다:\n- 이메일 주소\n- 이름\n- 프로필 정보\n- 서비스 이용 기록\n- 기기 정보',
        ),
        _buildSection(
          '2. 개인정보 수집 목적',
          '회사는 다음과 같은 목적으로 개인정보를 수집합니다:\n- 회원 식별 및 관리\n- 서비스 제공 및 개선\n- 안내 및 고지사항 전달\n- 서비스 보안 유지',
        ),
        _buildSection(
          '3. 개인정보 보유 기간',
          '회사는 회원이 서비스를 이용하는 동안 개인정보를 보유하며, 회원 탈퇴 시 즉시 삭제합니다. 단, 관련 법령에 따라 보존이 필요한 정보는 법정 기간 동안 보관됩니다.',
        ),
        _buildSection(
          '4. 개인정보 제3자 제공',
          '회사는 원칙적으로 회원의 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의 경우에는 예외적으로 제공할 수 있습니다:\n- 회원의 동의가 있는 경우\n- 법령에 의거하거나 수사기관의 요청이 있는 경우',
        ),
        _buildSection(
          '5. 회원의 권리',
          '회원은 언제든지 자신의 개인정보를 조회, 수정, 삭제할 수 있으며, 개인정보 처리를 거부할 권리가 있습니다. 이러한 권리 행사는 서비스 내 설정을 통해 가능합니다.',
        ),
        _buildSection(
          '6. 개인정보 보호 조치',
          '회사는 회원의 개인정보를 안전하게 보호하기 위해 보안 시스템을 갖추고 있으며, 개인정보 처리 직원을 최소화하고 정기적인 교육을 실시합니다.',
        ),
        _buildSection(
          '7. 개인정보 관리 책임자',
          '개인정보 관리에 관한 문의사항은 다음의 개인정보 관리 책임자에게 연락하시기 바랍니다:\n- 이메일: privacy@pdflearner.com\n- 전화: 02-123-4567',
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
} 