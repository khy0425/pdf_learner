exports.aiProxy = functions.https.onCall(async (data, context) => {
  // 사용자 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }

  // 사용량 제한 확인
  const usageCount = await checkUserUsage(context.auth.uid);
  if (!await isUserPremium(context.auth.uid) && usageCount >= 50) {
    throw new functions.https.HttpsError('resource-exhausted', '일일 사용량을 초과했습니다.');
  }

  // API 호출 및 응답
  const response = await callGeminiAPI(data.text);
  
  // 사용량 기록
  await incrementUserUsage(context.auth.uid);
  
  return response;
}); 