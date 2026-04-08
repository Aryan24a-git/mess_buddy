const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const crypto = require("crypto");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

// Helpers
function generateReferralCode() {
  return crypto.randomBytes(3).toString("hex").toUpperCase();
}

/**
 * 1. grantAdCredits
 * Called by client after ad watched successfully.
 * Checks max 5 ads/day or max 10 credits/day using adWatches subcollection.
 * Rewards 3 credits.
 */
exports.grantAdCredits = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }
  const uid = request.auth.uid;
  
  // Set today 00:00 UTC
  const now = new Date();
  const startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
  const startOfDayTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);

  const userRef = db.collection("users").doc(uid);
  const adWatchesRef = userRef.collection("adWatches");

  return await db.runTransaction(async (t) => {
    // We must read in the transaction to prevent race conditions.
    // However, querying inside a transaction requires all reads before writes.
    const todayQuery = adWatchesRef.where("watchedAt", ">=", startOfDayTimestamp);
    const todaySnapshot = await t.get(todayQuery);
    
    let count = 0;
    let totalCredits = 0;
    
    todaySnapshot.forEach((doc) => {
      count++;
      totalCredits += (doc.data().creditsEarned || 0);
    });

    if (count >= 5) {
      throw new HttpsError("failed-precondition", "daily_ad_limit_reached");
    }

    if (totalCredits >= 10) {
      throw new HttpsError("failed-precondition", "daily_credit_limit_reached");
    }

    // Add new watch record
    const newWatchRef = adWatchesRef.doc();
    t.set(newWatchRef, {
      watchedAt: admin.firestore.Timestamp.now(),
      creditsEarned: 3
    });

    // Increment overall credits
    t.update(userRef, {
      credits: admin.firestore.FieldValue.increment(3)
    });

    // Return current stats (optional extended object)
    return { success: true, newBalance: totalCredits + 3, newCount: count + 1 };
  });
});

/**
 * 2. redeemPremium
 * Uses credits to buy Premium duration.
 */
exports.redeemPremium = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }
  
  const { plan } = request.data;
  const pricing = {
    3: 50,
    14: 150,
    30: 300
  };
  
  if (!pricing[plan]) {
    throw new HttpsError("invalid-argument", "Invalid duration.");
  }
  
  const cost = pricing[plan];
  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);

  return await db.runTransaction(async (t) => {
    const doc = await t.get(userRef);
    if (!doc.exists) {
      throw new HttpsError("not-found", "User document not found.");
    }
    
    const data = doc.data();
    const credits = data.credits || 0;
    
    if (credits < cost) {
      throw new HttpsError("failed-precondition", "Insufficient credits.");
    }
    
    let newExpiryMillis = admin.firestore.Timestamp.now().toMillis();
    if (data.premiumExpiresAt && data.premiumExpiresAt.toMillis() > newExpiryMillis) {
      newExpiryMillis = data.premiumExpiresAt.toMillis();
    }
    
    newExpiryMillis += (plan * 24 * 60 * 60 * 1000);
    const newExpiry = admin.firestore.Timestamp.fromMillis(newExpiryMillis);
    
    t.update(userRef, {
      credits: admin.firestore.FieldValue.increment(-cost),
      isPremium: true,
      premiumExpiresAt: newExpiry
    });
    
    return { success: true, newExpiry: newExpiryMillis, newBalance: credits - cost };
  });
});

/**
 * 3. grantReferralBonus
 * Validates code, assigns referrer, gives new user 1 day Pro.
 * Also creates a tracking document in the referrer's 'referrals' subcollection.
 */
exports.grantReferralBonus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }
  const code = request.data.code?.toUpperCase();
  if (!code) throw new HttpsError("invalid-argument", "Missing referral code.");
  
  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);
  
  // 1. Find referrer by their unique code
  const query = await db.collection("users").where("referralCode", "==", code).limit(1).get();
  if (query.empty) {
    throw new HttpsError("not-found", "Invalid referral code.");
  }
  const referrerDoc = query.docs[0];
  const referrerId = referrerDoc.id;
  const referrerRef = db.collection("users").doc(referrerId);
  
  if (referrerId === uid) {
    throw new HttpsError("failed-precondition", "Cannot use your own code.");
  }

  return await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    if (!userDoc.exists) throw new HttpsError("not-found", "User not found.");
    
    const userData = userDoc.data();
    if (userData.referredBy) {
      throw new HttpsError("already-exists", "Already used a referral code.");
    }
    
    const now = admin.firestore.Timestamp.now();
    let newExpiryMillis = now.toMillis();
    
    // Extend existing expiry if present
    if (userData.premiumExpiresAt && userData.premiumExpiresAt.toMillis() > newExpiryMillis) {
      newExpiryMillis = userData.premiumExpiresAt.toMillis();
    }
    
    newExpiryMillis += (1 * 24 * 60 * 60 * 1000); // Give 1 day pro
    const newExpiry = admin.firestore.Timestamp.fromMillis(newExpiryMillis);
    
    // Log the referral in the referrer's subcollection for streak tracking
    const referralTrackingRef = referrerRef.collection("referrals").doc(uid);
    t.set(referralTrackingRef, {
      referredUid: uid,
      streakDays: 0,
      streakStartedAt: now,
      rewardGranted: false,
      createdAt: now
    });

    // Update the new user's profile
    t.update(userRef, {
      referredBy: referrerId,
      premiumExpiresAt: newExpiry,
      isPremium: true // Explicitly set premium flag
    });
    
    return { 
      success: true, 
      message: "Referral applied! 1 day of Pro granted.",
      newExpiry: newExpiryMillis 
    };
  });
});

/**
 * 4. checkReferralCompletion
 * Called by client or scheduled hook when streak updates.
 */
exports.checkReferralCompletion = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }
  
  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);

  return await db.runTransaction(async (t) => {
    const doc = await t.get(userRef);
    if (!doc.exists) throw new HttpsError("not-found", "User not found.");
    const data = doc.data();
    
    if (data.referralStatus !== "pending" || !data.referredBy) {
      return { success: false, reason: "No pending referral." };
    }
    
    // Check if 7 day usage active 
    // Wait, the client updates 'activeStreak' locally in Firestore?
    // No, client shouldn't update activeStreak directly if we strictly secure it, 
    // but without a backend activity hook, we can let client update activeStreak or process it here.
    // Assuming activeStreak >= 7
    if ((data.activeStreak || 0) < 7) {
       return { success: false, reason: "Streak not reached yet." };
    }
    
    // Grant referrer 50-100 credits
    const reward = Math.floor(Math.random() * (100 - 50 + 1)) + 50;
    const referrerRef = db.collection("users").doc(data.referredBy);
    
    const referrerDoc = await t.get(referrerRef);
    if (referrerDoc.exists) {
        t.update(referrerRef, {
            credits: (referrerDoc.data().credits || 0) + reward
        });
    }
    
    t.update(userRef, {
      referralStatus: "completed"
    });
    
    return { success: true, message: "Referral completed." };
  });
});

/**
 * 5. On User Create Trigger
 * Create empty profile with referral code.
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
exports.onUserCreated = admin.auth ? require("firebase-functions/v1/auth").user().onCreate((user) => {
  const referralCode = generateReferralCode();
  return db.collection("users").doc(user.uid).set({
    credits: 0,
    referralCode,
    activeStreak: 1,
    lastActive: admin.firestore.Timestamp.now()
  });
}) : null;
/**
 * 6. checkReferralStreaks
 * Scheduled daily task at midnight UTC.
 * Checks referred user activity for the previous day.
 */
exports.checkReferralStreaks = onSchedule("0 0 * * *", async (event) => {
  const referralsSnapshot = await db.collectionGroup("referrals").where("rewardGranted", "==", false).get();

  // Get yesterday's date string in YYYY-MM-DD
  const yesterday = new Date();
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const dateString = yesterday.toISOString().split("T")[0];

  const promises = referralsSnapshot.docs.map(async (doc) => {
    const data = doc.data();
    const referredUid = data.referredUid;
    const parentUid = doc.ref.parent.parent.id;

    // Check if the referred user has a session log for yesterday
    const sessionDoc = await db.collection("users").doc(referredUid).collection("appSessions").doc(dateString).get();

    if (sessionDoc.exists) {
      const newStreak = (data.streakDays || 0) + 1;
      const updateData = {streakDays: newStreak};

      if (newStreak >= 7) {
        updateData.rewardGranted = true;
        const reward = Math.floor(Math.random() * 51) + 50;

        await db.collection("users").doc(parentUid).update({
          credits: admin.firestore.FieldValue.increment(reward),
        });

        console.log(`[STREAK] User ${referredUid} reached 7 days. Granting ${reward} credits to ${parentUid}.`);

        const referrerDoc = await db.collection("users").doc(parentUid).get();
        const fcmToken = referrerDoc.data()?.fcmToken;
        if (fcmToken) {
          try {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: "Friend Reward!",
                body: `Your friend completed 7 days! You earned ${reward} credits!`,
              },
            });
          } catch (err) {
            console.error("FCM Send failed:", err);
          }
        }
      }

      await doc.ref.update(updateData);
    } else {
      if ((data.streakDays || 0) > 0) {
        await doc.ref.update({
          streakDays: 0,
          streakStartedAt: admin.firestore.Timestamp.now(),
        });
      }
    }
  });

  await Promise.all(promises);
  console.log(`[STREAK] Daily check complete. Items: ${referralsSnapshot.size}`);
});

/**
 * 7. createCashfreeOrder
 * Hits Cashfree API to create a new session
 */
exports.createCashfreeOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { amount, customer_id, email } = request.data;
  const orderId = `order_${Date.now()}_${request.auth.uid.substring(0, 5)}`;

  // Use environment variables for production keys
  const app_id = process.env.CASHFREE_APP_ID || ""; 
  const secret_key = process.env.CASHFREE_SECRET_KEY || "";
  const api_version = "2023-08-01";
  
  const endpoint = "https://api.cashfree.com/pg/orders"; // Production Endpoint

  try {
    const response = await axios.post(endpoint, {
      order_id: orderId,
      order_amount: amount,
      order_currency: "INR",
      customer_details: {
        customer_id: customer_id,
        customer_email: email,
        customer_phone: "9999999999"
      }
    }, {
      headers: {
        "x-client-id": app_id,
        "x-client-secret": secret_key,
        "x-api-version": api_version,
        "Content-Type": "application/json"
      }
    });

    return {
      success: true,
      order_id: response.data.order_id,
      payment_session_id: response.data.payment_session_id
    };
  } catch (error) {
    console.error("Cashfree Order Creation Error:", error.response?.data || error.message);
    throw new HttpsError("internal", "Failed to create Cashfree order.");
  }
});

/**
 * 8. redeemPremiumWithCash
 * Upgrades user to premium after real money purchase.
 */
exports.redeemPremiumWithCash = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { planDays, orderId } = request.data;
  
  if (!planDays || typeof planDays !== 'number') {
    throw new HttpsError("invalid-argument", "Invalid plan duration.");
  }
  
  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);

  return await db.runTransaction(async (t) => {
    const doc = await t.get(userRef);
    if (!doc.exists) {
      throw new HttpsError("not-found", "User document not found.");
    }
    
    const data = doc.data();
    
    let newExpiryMillis = admin.firestore.Timestamp.now().toMillis();
    if (data.premiumExpiresAt && data.premiumExpiresAt.toMillis() > newExpiryMillis) {
      newExpiryMillis = data.premiumExpiresAt.toMillis();
    }
    
    newExpiryMillis += (planDays * 24 * 60 * 60 * 1000);
    const newExpiry = admin.firestore.Timestamp.fromMillis(newExpiryMillis);
    
    t.update(userRef, {
      isPremium: true,
      premiumExpiresAt: newExpiry
    });
    
    // Store payment record
    const paymentRecordRef = db.collection("payments").doc();
    t.set(paymentRecordRef, {
      uid: uid,
      orderId: orderId || "mock_order",
      planDays: planDays,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true, newExpiry: newExpiryMillis };
  });
});
