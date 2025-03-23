import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 리워드 광고를 시청하고 포인트를 얻는 버튼 위젯
class RewardAdButton extends StatefulWidget {
  /// 버튼 텍스트
  final String text;
  
  /// 광고 시청 후 얻을 포인트 (기본값: 5)
  final int rewardPoints;
  
  /// 광고를 표시할 수 없을 때 표시할 텍스트
  final String unavailableText;
  
  /// 로그인이 필요할 때 표시할 텍스트
  final String loginRequiredText;
  
  /// 버튼 스타일
  final ButtonStyle? buttonStyle;
  
  /// 버튼 아이콘
  final IconData? icon;
  
  /// 광고 보상 후 실행할 콜백
  final Function()? onRewarded;

  const RewardAdButton({
    Key? key,
    this.text = '광고 보고 5 포인트 받기',
    this.rewardPoints = 5,
    this.unavailableText = '광고 준비 중...',
    this.loginRequiredText = '포인트 획득을 위해 로그인하세요',
    this.buttonStyle,
    this.icon = Icons.card_giftcard,
    this.onRewarded,
  }) : super(key: key);

  @override
  State<RewardAdButton> createState() => _RewardAdButtonState();
}

class _RewardAdButtonState extends State<RewardAdButton> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context);
    final authService = Provider.of<AuthService>(context);
    
    // 로그인하지 않은 경우
    if (!authService.isLoggedIn) {
      return ElevatedButton.icon(
        icon: Icon(Icons.login),
        label: Text(widget.loginRequiredText),
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        style: widget.buttonStyle,
      );
    }
    
    // 광고가 로드되지 않은 경우
    if (!adService.isRewardedAdLoaded) {
      return ElevatedButton.icon(
        icon: Icon(Icons.hourglass_empty),
        label: Text(widget.unavailableText),
        onPressed: null,
        style: widget.buttonStyle ?? ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
        ),
      );
    }
    
    // 로딩 중인 경우
    if (_isLoading) {
      return ElevatedButton.icon(
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        label: Text('처리 중...'),
        onPressed: null,
        style: widget.buttonStyle,
      );
    }
    
    // 오류가 발생한 경우
    if (_errorMessage != null) {
      return ElevatedButton.icon(
        icon: Icon(Icons.error_outline),
        label: Text(_errorMessage!),
        onPressed: () {
          setState(() {
            _errorMessage = null;
          });
        },
        style: widget.buttonStyle ?? ElevatedButton.styleFrom(
          backgroundColor: Colors.red[100],
          foregroundColor: Colors.red[800],
        ),
      );
    }
    
    // 정상 상태
    return ElevatedButton.icon(
      icon: Icon(widget.icon),
      label: Text(widget.text),
      onPressed: () => _showRewardAd(context),
      style: widget.buttonStyle,
    );
  }
  
  Future<void> _showRewardAd(BuildContext context) async {
    final adService = Provider.of<AdService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final success = await adService.showRewardedAd((RewardItem reward) async {
        // 실제 리워드 아이템 사용 안 함, 우리는 고정된 rewardPoints 사용
        debugPrint('광고 보상: ${reward.amount} ${reward.type}');
        
        // 사용자에게 포인트 추가
        final result = await authService.addPoints(widget.rewardPoints);
        
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('축하합니다! ${widget.rewardPoints} 포인트를 획득했습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // 콜백 호출
          if (widget.onRewarded != null) {
            widget.onRewarded!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('포인트 획득 중 오류가 발생했습니다: ${authService.error}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _errorMessage = '포인트 획득 실패';
          });
        }
      });
      
      if (!success) {
        setState(() {
          _errorMessage = '광고를 표시할 수 없습니다';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 