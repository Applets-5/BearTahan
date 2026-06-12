const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

const {defineSecret} = require("firebase-functions/params");
const geminiKey = defineSecret("GEMINI_API_KEY");

admin.initializeApp();
setGlobalOptions({maxInstances: 10, region: "asia-southeast1"});

const db = admin.firestore();
const messaging = admin.messaging();

function getTodayKey(date = new Date()) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kuala_Lumpur",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });

  return formatter.format(date);
}

function timestampToMalaysiaDateKey(value) {
  if (!value) return null;

  if (typeof value.toDate === "function") {
    return getTodayKey(value.toDate());
  }

  if (typeof value === "string") {
    return value.slice(0, 10);
  }

  if (value instanceof Date) {
    return getTodayKey(value);
  }

  return null;
}

async function getParentData(parentId) {
  const parentSnapshot = await db.collection("parents").doc(parentId).get();
  return parentSnapshot.exists ? parentSnapshot.data() : {};
}

async function createParentNotification(parentId, notification) {
  await db
      .collection("parents")
      .doc(parentId)
      .collection("notifications")
      .add({
        ...notification,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
}

async function sendToParent(parentId, payload, notification) {
  const parentData = await getParentData(parentId);
  const token = parentData.fcmToken;

  if (!token) {
    logger.warn("Parent has no FCM token", {parentId, type: payload.type});
    return false;
  }

  await messaging.send({
    token,
    data: payload,
    notification,
    android: {
      priority: "high",
      notification: {
        channelId: "default",
      },
    },
  });

  return true;
}

exports.sendGoalCompleteNotification = onDocumentUpdated(
    "parents/{parentId}/children/{childId}",
    async (event) => {
      const before = event.data.before.data() || {};
      const after = event.data.after.data() || {};
      const parentId = event.params.parentId;
      const childId = event.params.childId;

      const beforeGoal = before.dailyGoal || {};
      const afterGoal = after.dailyGoal || {};
      const beforeNotifiedDate = beforeGoal.lastNotifiedDate;
      const afterNotifiedDate = afterGoal.lastNotifiedDate;
      const today = getTodayKey();

      if (afterNotifiedDate !== today || beforeNotifiedDate === today) {
        return;
      }

      const parentData = await getParentData(parentId);
      if (parentData.dailyGoals === false) {
        logger.info("Goal notification disabled", {parentId, childId});
        return;
      }

      const childName = after.name || "Your child";
      const payload = {
        type: "goal_complete",
        childName,
        childId,
      };

      await sendToParent(
          parentId,
          payload,
          {
            title: "Daily goal complete",
            body: `${childName} completed today's learning goal.`,
          },
      );

      logger.info("Goal completion notification sent", {parentId, childId});
    },
);

exports.sendRewardClaimedNotification = onDocumentCreated(
    "parents/{parentId}/children/{childId}/rewardClaims/{claimId}",
    async (event) => {
      const claim = event.data.data() || {};
      const parentId = event.params.parentId;
      const childId = event.params.childId;

      if (claim.status !== "pending") {
        return;
      }

      const parentData = await getParentData(parentId);
      if (parentData.rewardClaims === false) {
        logger.info("Reward claim notification disabled", {
          parentId,
          childId,
        });
        return;
      }

      const rewardName = claim.rewardName || "a reward";
      const childName = claim.childName || "Your child";
      const starCost = Number(claim.starCost || 0);
      const payload = {
        type: "reward_claimed",
        rewardName,
        starCost: starCost.toString(),
        childName,
        childId,
      };

      await sendToParent(
          parentId,
          payload,
          {
            title: "Reward claimed",
            body: `${childName} wants to claim ${rewardName}.`,
          },
      );

      logger.info("Reward claim notification sent", {
        parentId,
        childId,
        rewardName,
      });
    },
);

exports.sendStreakRiskNotifications = onSchedule(
    {
      schedule: "0 20 * * *",
      timeZone: "Asia/Kuala_Lumpur",
    },
    async () => {
      const today = getTodayKey();
      const parentSnapshots = await db.collection("parents").get();

      let checkedChildren = 0;
      let sentCount = 0;

      for (const parentDoc of parentSnapshots.docs) {
        const parentId = parentDoc.id;
        const parentData = parentDoc.data() || {};

        if (parentData.streakRisk === false) {
          continue;
        }

        const childrenSnapshot = await parentDoc.ref
            .collection("children")
            .get();

        for (const childDoc of childrenSnapshot.docs) {
          checkedChildren++;

          const child = childDoc.data() || {};
          const childId = childDoc.id;
          const currentStreak = Number(child.streakCount || 0);
          const lastActivityKey = timestampToMalaysiaDateKey(
              child.lastActivityDate,
          );
          const lastStreakRiskNotifiedDate =
            child.lastStreakRiskNotifiedDate || null;

          if (
            currentStreak <= 0 ||
          lastActivityKey === today ||
          lastStreakRiskNotifiedDate === today
          ) {
            continue;
          }

          const childName = child.name || "Your child";
          const payload = {
            type: "streak_risk",
            currentStreak: currentStreak.toString(),
            childId,
            childName,
          };

          const sent = await sendToParent(
              parentId,
              payload,
              {
                title: "Streak at risk",
                body:
                `${childName} has a ${currentStreak}-day streak. ` +
                "Practise before midnight to keep it going.",
              },
          );

          if (!sent) continue;

          await createParentNotification(parentId, {
            title:
            `${childName}'s ${currentStreak}-day streak is at risk tonight`,
            type: "streak_risk",
            childId,
            childName,
            payload,
          });

          await childDoc.ref.set(
              {lastStreakRiskNotifiedDate: today},
              {merge: true},
          );

          sentCount++;
        }
      }

      logger.info("Streak risk job completed", {
        checkedChildren,
        sentCount,
      });
    },
);

exports.expireRewardClaims = onSchedule(
    {
      schedule: "0 0 * * *",
      timeZone: "Asia/Kuala_Lumpur",
    },
    async () => {
      const now = admin.firestore.Timestamp.now();
      const claimsSnapshot = await db
          .collectionGroup("rewardClaims")
          .where("status", "==", "pending")
          .where("expiresAt", "<=", now)
          .get();

      if (claimsSnapshot.empty) {
        logger.info("No expired reward claims found");
        return;
      }

      const batch = db.batch();
      claimsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: "expired",
          resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const rewardId = doc.data().rewardId;
        if (rewardId) {
          batch.delete(doc.ref.parent.parent
              .collection("rewardClaimLocks")
              .doc(rewardId));
        }
      });

      await batch.commit();

      logger.info("Expired reward claims", {
        expiredCount: claimsSnapshot.size,
      });
    },
);

// BearAI - AI Parent Consultation
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {GoogleGenerativeAI} = require("@google/generative-ai");

exports.askBearAi = onCall({secrets: [geminiKey]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const {childId, message, history} = request.data;
  if (!childId || !message) {
    throw new HttpsError("invalid-argument", "Missing childId or message.");
  }

  // 1. Input Validation (Issue 7)
  if (message.length > 1000) {
    throw new HttpsError("invalid-argument", "Message too long (max 1000 chars).");
  }

  const parentId = request.auth.uid;

  // 1. Rate Limiting (6s cooldown, 50 daily cap)
  const cooldownMs = 6000;
  const dailyCap = 50;
  const today = getTodayKey();
  const rateRef = db.collection("parents").doc(parentId).collection("rateLimits").doc("bearAiChat");

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(rateRef);
    const now = Date.now();
    const data = snap.exists ? snap.data() : {};

    const nextAllowedAt = data.nextAllowedAt || 0;
    if (now < nextAllowedAt) {
      throw new HttpsError(
          "resource-exhausted",
          "Please wait a few seconds before asking BearAI again.",
      );
    }

    const dailyCount = (data.lastResetDate === today) ? (data.dailyCount || 0) : 0;
    if (dailyCount >= dailyCap) {
      throw new HttpsError(
          "resource-exhausted",
          "Daily limit of 50 BearAI messages reached.",
      );
    }

    tx.set(rateRef, {
      nextAllowedAt: now + cooldownMs,
      dailyCount: dailyCount + 1,
      lastResetDate: today,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  // 2. Assemble context
  const context = await assembleBearAiContext(parentId, childId);

  // 3. Initialize Gemini API (Issue 13: Use stable model)
  const genAI = new GoogleGenerativeAI(geminiKey.value());
  const model = genAI.getGenerativeModel({
    model: "gemini-3.5-flash",
    systemInstruction: buildBearAiSystemPrompt(context),
  });

  try {
    // 4. Start chat with truncated history (Issue 7: max 10 latest messages)
    const truncatedHistory = (history || []).slice(-10).map((m) => ({
      role: m.role === "user" ? "user" : "model",
      parts: [{text: m.content}],
    }));

    const chat = model.startChat({
      history: truncatedHistory,
    });

    const result = await chat.sendMessage(message);
    const response = await result.response;
    return {text: response.text()};
  } catch (error) {
    logger.error("BearAI Chat Error", error);
    if (error.message && error.message.includes("429")) {
      throw new HttpsError("resource-exhausted", "BearAI is currently busy. Please wait a bit.");
    }
    const errorMsg = error.message || "BearAI failed to respond.";
    throw new HttpsError("internal", errorMsg);
  }
});

exports.getBearAiInsight = onCall({secrets: [geminiKey]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const {childId} = request.data;
  if (!childId) {
    throw new HttpsError("invalid-argument", "Missing childId.");
  }

  const parentId = request.auth.uid;
  const childRef = db.collection("parents").doc(parentId).collection("children").doc(childId);
  const childSnap = await childRef.get();
  
  if (!childSnap.exists) {
    throw new HttpsError("not-found", "Child not found.");
  }

  const childData = childSnap.data();
  const lastInsightDate = childData.lastAiInsightDate ? childData.lastAiInsightDate.toDate() : null;
  const now = new Date();

  // If insight exists and is less than 7 days old, return it
  if (childData.lastAiInsight && lastInsightDate) {
    const diffTime = Math.abs(now - lastInsightDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    if (diffDays < 7) {
      return {insight: childData.lastAiInsight};
    }
  }

  // Otherwise generate a new one
  const context = await assembleBearAiContext(parentId, childId, true);

  const genAI = new GoogleGenerativeAI(geminiKey.value());
  const model = genAI.getGenerativeModel({model: "gemini-3.5-flash"});

  const prompt = `In exactly 2-3 sentences, summarise ${context.child.name}'s activity for the past 7 days. ` +
    "Mention their most active subject and one specific area for encouragement. Ground in data below.";

  try {
    const result = await model.generateContent([
      prompt,
      JSON.stringify(context),
    ]);

    const response = await result.response;
    const insightText = response.text();

    // Persist the new insight
    await childRef.update({
      lastAiInsight: insightText,
      lastAiInsightDate: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {insight: insightText};
  } catch (error) {
    logger.error("BearAI Insight Generation Error", error);
    throw new HttpsError("internal", "Failed to generate AI insight.");
  }
});

async function assembleBearAiContext(parentId, childId, last7DaysOnly = false) {
  const childRef = db.collection("parents").doc(parentId).collection("children").doc(childId);
  const childSnap = await childRef.get();
  
  // Issue 6: Consistent child handling
  if (!childSnap.exists) {
    throw new HttpsError("not-found", "Child profile not found.");
  }
  const child = childSnap.data();

  // Issue 3: Include subject IDs
  const subjectsSnap = await childRef.collection("subjectProgress").get();
  const subjects = subjectsSnap.docs.map(doc => ({
    subjectId: doc.id,
    ...doc.data(),
  }));

  // Fetch recent attempts
  let attemptsQuery = childRef.collection("attempts").orderBy("completedAt", "desc");
  if (last7DaysOnly) {
    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000));
    attemptsQuery = attemptsQuery.where("completedAt", ">=", sevenDaysAgo);
  }
  const attemptsSnap = await attemptsQuery.limit(10).get();
  
  // Issue 4: Percentage scores
  const attempts = attemptsSnap.docs.map(doc => {
    const data = doc.data();
    const score = Number(data.score || 0);
    const total = Number(data.totalQuestions || 10);
    const percentage = ((score / total) * 100).toFixed(0);
    return {
      subjectId: data.subjectId,
      score: `${score}/${total} (${percentage}%)`,
      completedAt: timestampToMalaysiaDateKey(data.completedAt),
    };
  });

  // Fetch wrong answer summary
  const wrongSnap = await childRef.collection("wrongAnswerBank").get();
  const wrongAnswers = {};
  wrongSnap.docs.forEach(doc => {
    const data = doc.data();
    wrongAnswers[data.subjectId] = (wrongAnswers[data.subjectId] || 0) + 1;
  });

  // Issue 11: Label lifetime vs 7-day data
  return {
    child: {
      name: child.name,
      streak: child.streakCount,
      stars: child.availableStars,
      lifetimeStars: child.lifetimeStarsEarned,
      dailyGoal: child.dailyGoal,
    },
    lifetimeSubjectProgress: subjects,
    recentAttempts: attempts,
    pendingReviewCountBySubject: wrongAnswers,
    isSevenDayScoped: last7DaysOnly,
  };
}

function buildBearAiSystemPrompt(context) {
  // Issue 5: Comprehensive prompt structure
  const progressStr = context.lifetimeSubjectProgress
      .map(s => `- ${s.subjectId}: ${s.progress}% complete, ${s.lessonsCompleted} lessons done`)
      .join("\n");
  
  const attemptsStr = context.recentAttempts
      .map(a => `- ${a.subjectId}: ${a.score} on ${a.completedAt}`)
      .join("\n");

  const reviewStr = Object.entries(context.pendingReviewCountBySubject)
      .map(([id, count]) => `- ${id}: ${count} questions pending`)
      .join("\n");

  return `You are BearAI, a personal learning consultant inside the BearTahan app.
You help Malaysian parents understand their Standard 1 child's learning progress.
Always be warm, concise, and actionable. Ground every response in the data provided.

CHILD PROFILE:
- Name: ${context.child.name}
- Current Streak: ${context.child.streak} days
- Available Stars: ${context.child.stars}
- Lifetime Stars Earned: ${context.child.lifetimeStars}
- Daily Goal: ${context.child.dailyGoal} lessons/day

LIFETIME PROGRESS:
${progressStr || "No progress recorded yet."}

RECENT ACTIVITY:
${attemptsStr || "No recent attempts."}

PENDING REVIEWS (Wrong Answers):
${reviewStr || "All caught up! No pending reviews."}

GUIDELINES:
- Use Standard 1 context (BM, English, Math, Science, Mandarin).
- Encourage the parent based on streaks and star milestones.
- If a subject has many pending reviews, suggest focusing there.
- Keep responses to 3-5 sentences unless detailed analysis is requested.`;
}

