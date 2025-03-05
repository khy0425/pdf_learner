import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// 새 사용자 생성 시 자동으로 실행
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const batch = admin.firestore().batch();
  const db = admin.firestore();

  // 1. 기본 구독 정보 생성
  const subscriptionRef = db.collection('subscriptions').doc(user.uid);
  batch.set(subscriptionRef, {
    tier: 'basic',
    startDate: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: null,
    lastPaymentId: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    userId: user.uid,
    status: 'active'
  });

  // 2. 초기 사용량 문서 생성
  const today = new Date().toISOString().split('T')[0];
  const usageRef = db
    .collection('usage')
    .doc(user.uid)
    .collection('statistics')
    .doc('daily')
    .collection(today);

  batch.set(usageRef, {
    userId: user.uid,
    aiSummary: 0,
    aiQuiz: 0,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    date: today
  });

  // 3. 일괄 처리 실행
  return batch.commit();
}); 