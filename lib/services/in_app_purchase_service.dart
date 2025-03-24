import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';

class InAppPurchaseService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase;
  bool _isInitialized = false;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  InAppPurchaseService(this._inAppPurchase);

  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('구매 스트림 오류: $error'),
    );

    await _loadProducts();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    const Set<String> _kIds = {
      'pdf_learner_basic',
      'pdf_learner_premium',
      'pdf_learner_enterprise',
    };

    final ProductDetailsResponse productDetailsResponse =
        await _inAppPurchase.queryProductDetails(_kIds);

    if (productDetailsResponse.error != null) {
      debugPrint('제품 정보 로드 실패: ${productDetailsResponse.error}');
      return;
    }

    if (productDetailsResponse.productDetails.isEmpty) {
      debugPrint('제품 정보가 없습니다.');
      return;
    }

    _products = productDetailsResponse.productDetails;
    notifyListeners();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 구매 진행 중
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 구매 오류
        debugPrint('구매 오류: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // 구매 완료 또는 복원
        await _verifyPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    _purchases = purchaseDetailsList;
    notifyListeners();
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // 구매 검증 로직 구현
    // 서버에서 구매 영수증 검증
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      debugPrint('구매 실패: $e');
    }
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
} 