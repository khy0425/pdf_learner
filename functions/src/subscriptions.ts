import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onSubscriptionCreate = functions.firestore
  .document('subscriptions/{userId}')
  .onCreate((snap, context) => {
    const data = snap.data();
    const userId = context.params.userId;
    
    // 기본값 설정
    return snap.ref.set({
      tier: data.tier || 'basic',
      startDate: data.startDate || admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: data.expiresAt || null,
      lastPaymentId: data.lastPaymentId || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: userId,
      status: 'active',
    }, { merge: true });
  });

export const onSubscriptionUpdate = functions.firestore
  .document('subscriptions/{userId}')
  .onUpdate((change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // 변경된 경우에만 updatedAt 갱신
    if (JSON.stringify(newData) !== JSON.stringify(oldData)) {
      return change.after.ref.update({
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });

// 매일 자정에 실행되는 구독 만료 체크
export const checkSubscriptionExpiry = functions.pubsub
  .schedule('0 0 * * *')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    
    // 만료된 구독 찾기
    const expiredSubs = await admin.firestore()
      .collection('subscriptions')
      .where('status', '==', 'active')
      .where('expiresAt', '<=', now)
      .get();

    // 만료된 구독 처리
    const batch = admin.firestore().batch();
    expiredSubs.docs.forEach(doc => {
      batch.update(doc.ref, {
        tier: 'basic',
        status: 'expired',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return batch.commit();
  }); 