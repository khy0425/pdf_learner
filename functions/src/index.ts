import * as admin from 'firebase-admin';
import { onUserCreated } from './auth';
import { onSubscriptionCreate, onSubscriptionUpdate, checkSubscriptionExpiry } from './subscriptions';

admin.initializeApp();

export {
  onUserCreated,
  onSubscriptionCreate,
  onSubscriptionUpdate,
  checkSubscriptionExpiry
}; 