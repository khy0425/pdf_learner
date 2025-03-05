import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { PayPalClient } from './paypal-client';

export const verifyPayPalPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '인증이 필요합니다.'
    );
  }

  const { paymentId, tier, amount } = data;
  const userId = context.auth.uid;

  try {
    // PayPal API로 결제 검증
    const paypal = new PayPalClient();
    const payment = await paypal.verifyPayment(paymentId);

    if (payment.status !== 'COMPLETED') {
      throw new Error('결제가 완료되지 않았습니다.');
    }

    // 결제 금액 검증
    const paidAmount = Math.round(parseFloat(payment.amount.total) * 100);
    if (paidAmount !== amount) {
      throw new Error('결제 금액이 일치하지 않습니다.');
    }

    // Firestore에 결제 정보 저장
    const db = admin.firestore();
    await db.runTransaction(async (transaction) => {
      // 1. 결제 기록 저장
      const paymentRef = db.collection('payments').doc(paymentId);
      transaction.set(paymentRef, {
        userId,
        amount,
        tier,
        paymentId,
        provider: 'paypal',
        status: 'completed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. 구독 정보 업데이트
      const subscriptionRef = db.collection('subscriptions').doc(userId);
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);  // 30일 구독

      transaction.set(subscriptionRef, {
        tier,
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
        lastPaymentId: paymentId,
        status: 'active',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  } catch (error) {
    console.error('PayPal 결제 검증 오류:', error);
    throw new functions.https.HttpsError(
      'internal',
      '결제 검증 중 오류가 발생했습니다.',
      error
    );
  }
});

export const verifyPayPalSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '인증이 필요합니다.'
    );
  }

  const { subscriptionId, tier } = data;
  const userId = context.auth.uid;

  try {
    // PayPal API로 구독 상태 검증
    const paypal = new PayPalClient();
    const subscription = await paypal.verifySubscription(subscriptionId);

    if (subscription.status !== 'ACTIVE') {
      throw new Error('구독이 활성화되지 않았습니다.');
    }

    // Firestore에 구독 정보 저장
    const db = admin.firestore();
    await db.runTransaction(async (transaction) => {
      const subscriptionRef = db.collection('subscriptions').doc(userId);
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      transaction.set(subscriptionRef, {
        tier,
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
        subscriptionId,
        provider: 'paypal',
        status: 'active',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  } catch (error) {
    console.error('PayPal 구독 검증 오류:', error);
    throw new functions.https.HttpsError(
      'internal',
      '구독 검증 중 오류가 발생했습니다.',
      error
    );
  }
}); 