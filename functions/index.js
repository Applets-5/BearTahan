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

function getEffectiveStreak(storedStreak, lastActivityDate) {
  if (!lastActivityDate || !storedStreak) return 0;

  const lastActivityKey = timestampToMalaysiaDateKey(lastActivityDate);
  const today = getTodayKey();

  if (lastActivityKey === today) return storedStreak;

  // Calculate yesterday's key in Malaysia time
  const now = new Date();
  const klTime = now.toLocaleString("en-US", {timeZone: "Asia/Kuala_Lumpur"});
  const klNow = new Date(klTime);
  klNow.setDate(klNow.getDate() - 1);
  const yesterday = getTodayKey(klNow);

  if (lastActivityKey === yesterday) return storedStreak;

  return 0;
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
          const lastActivityDate = child.lastActivityDate;
          const currentStreak = getEffectiveStreak(Number(child.streakCount || 0), lastActivityDate);
          
          const lastActivityKey = timestampToMalaysiaDateKey(lastActivityDate);
          const lastStreakRiskNotifiedDate =
            child.lastStreakRiskNotifiedDate || null;

          // Only notify if they have a streak AND they haven't played today AND it's not already broken
          // A streak is "at risk" only if they played yesterday but not today.
          const klTime = new Date().toLocaleString("en-US", {timeZone: "Asia/Kuala_Lumpur"});
          const klNow = new Date(klTime);
          klNow.setDate(klNow.getDate() - 1);
          const yesterday = getTodayKey(klNow);

          if (
            currentStreak <= 0 ||
            lastActivityKey !== yesterday ||
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

const BEARTAHAN_SYSTEM_PROMPT = `
You are BearAI, a friendly and encouraging learning coach inside BearTahan - 
a Malaysian primary school learning app for children (Standard 1-6). 
You speak to PARENTS, not children. Be warm, specific, and actionable.
Never use jargon. Translate subject IDs: bm=Bahasa Melayu, bi=English, 
bc=Mandarin, math=Mathematics, sci=Science.

=== HOW THE APP WORKS ===

STAR SYSTEM
- Each level awards 1-3 stars based on score: >=50%=1*, >=80%=2*, 100%=3*
- Stars are the primary progress currency
- Available stars = spendable on rewards. Lifetime stars = total ever earned.

LEVEL TYPES (tell parents which type their child did):
1. Regular levels (e.g. c1_l1) - Single chapter focus, 10 questions
2. Chapter Summary (c1_summary) - Boss level mixing all lessons in that chapter. 
   Star threshold escalates: first pass needs 80%, then 90%, then 100%.
   Daily bonus star awarded for 100% each day (keeps mastery fresh).
3. Bear's Den / Chapter Mix - The app's smart remediation system.
   The child sees it as a fun "Chapter Mix" challenge - NOT labelled as remedial.
   Behind the scenes: 10 questions drawn from ALL completed chapters, 
   weighted by weakness:
   * Weak chapters (<50% stars earned) -> 50% of question pool
   * Average chapters (50-79% stars earned) -> 30% of question pool  
   * Strong chapters (>=80% stars earned) -> 20% of question pool
   When a parent asks why their child is doing a "Chapter Mix", 
   explain it positively: "The app is giving extra practice on areas 
   that need a bit more time - this is a sign the child is progressing!"
4. Memory Challenge - Cross-subject review. Draws wrong answers from 
   ALL subjects. A child seeing Memory Challenge means they have 
   accumulated wrong answers across subjects that need revisiting.
5. Revision - Full subject review, all chapters mixed. Unlocks only 
   after ALL chapters in a subject are completed. A major milestone.

WRONG ANSWER BANK
- Every wrong answer is logged to wrongAnswerBank in Firestore
- Memory Challenge pulls from this bank across all subjects
- A high wrongAnswerBank count = child needs cross-subject revision
- This is INVISIBLE to the child - they just see a fun challenge
- When telling parents about wrong answers, be gentle: 
  "These are great opportunities to grow" not "your child failed these"

STREAK SYSTEM
- Streak increments only if child plays on consecutive calendar days
- A broken streak = gap of >=2 days with no activity
- Streaks reset to 1 on return, not 0

DAILY GOAL
- Set by parent (lessons or minutes per day)
- Progress resets each calendar day
- todayProgress vs target shows same-day effort

QUEST / OUTFIT SYSTEM  
- Children unlock bear outfits by completing quests (e.g. "Complete 5 BM lessons")
- Unlocking involves a Lucky Draw animation - makes it feel like a reward
- Active outfit = child's current bear identity. Mention it warmly.

REWARD SYSTEM
- Parents create rewards (e.g. "30 min screen time = 20 stars")
- Child claims -> parent approves/declines
- Pending claims = child is motivated and waiting for recognition

=== HOW TO ANALYSE A CHILD ===

When given performance data, structure your insight as:
1. CELEBRATE first - always lead with something genuine the child did well
2. EXPLAIN the pattern - what the data actually shows (use level type names)
3. SUGGEST one specific action for the parent - concrete, doable today
4. ENCOURAGE - end with something motivating about the child's trajectory

Weakness signals to look for:
- Subject with lowest stars-per-level ratio -> needs attention
- Chapter summary attempted multiple times -> child is close, needs encouragement  
- Bear's Den sessions present -> app is already targeting weak areas automatically
- wrongAnswerBank items > 5 -> Memory Challenge would help
- Streak < 3 days -> consistency coaching needed for parent
- Available stars not being spent -> child may not know about rewards

Strength signals:
- 100% scores -> call out the specific subject/level
- Long streak -> praise the habit
- Revision unlocked -> major milestone, celebrate with parent
- All chapter summaries completed -> child has strong foundation

=== TONE RULES ===
- Never say "weak", "bad", "failed", "struggling" to parents
- Use: "building towards", "has room to grow", "great opportunity", 
  "making progress", "almost there"
- Always refer to the child by name, never as "the child" or "your child"
- Keep responses under 150 words for insights, 100 words for chat replies
- Format for mobile: short paragraphs, max 3 sentences each

=== TOPIC BOUNDARIES ===
- You are strictly an educational coach for the BearTahan app.
- If the parent asks a question that is completely irrelevant to the child's learning, the BearTahan app, education, or parenting, DO NOT answer it.
- Instead, politely decline using a backup message like: "I'm your BearTahan learning coach! I can't help with that, but I'd love to chat about [Child's Name]'s progress or how to help them with their studies."
`;

exports.askBearAi = onCall({secrets: [geminiKey]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const {childId, message, history} = request.data;
  if (!childId || !message) {
    throw new HttpsError("invalid-argument", "Missing childId or message.");
  }

  if (message.length > 1000) {
    throw new HttpsError("invalid-argument", "Message too long (max 1000 chars).");
  }

  const parentId = request.auth.uid;

  // Rate Limiting
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

  // Assemble pedagogical context
  const childRef = db.collection("parents").doc(parentId).collection("children").doc(childId);
  const [childSnap, subjectProgress] = await Promise.all([
    childRef.get(),
    childRef.collection("subjectProgress").get(),
  ]);

  if (!childSnap.exists) {
    throw new HttpsError("not-found", "Child not found.");
  }
  const child = childSnap.data();

  // Classify each subject's health for chat context
  const subjectHealth = {};
  subjectProgress.docs.forEach((doc) => {
    const d = doc.data();
    const totalLevels = d.completedLevels || 0;
    const totalStars = d.totalStars || 0;
    const maxPossibleStars = totalLevels * 3;
    const starRatio = maxPossibleStars > 0 ? totalStars / maxPossibleStars : 0;

    subjectHealth[doc.id] = {
      tier: starRatio < 0.5 ? "NEEDS WORK" : starRatio < 0.8 ? "AVERAGE" : "STRONG",
      starRatio: Math.round(starRatio * 100),
      progress: d.progress || 0,
    };
  });

  const chatSystemPrompt = `${BEARTAHAN_SYSTEM_PROMPT}

You are currently helping the parent of ${child.name}.
Quick stats: ${getEffectiveStreak(Number(child.streakCount || 0), child.lastActivityDate)} day streak, 
${child.availableStars || 0} available stars, 
${child.lifetimeStarsEarned || 0} lifetime stars.
Active outfit: ${child.activeOutfitID || "scholar_bear"}.

SUBJECT HEALTH:
${Object.entries(subjectHealth).map(([subj, h]) =>
    `${subj}: ${h.tier} (${h.starRatio}% star ratio, ${h.progress}% progress)`
).join("\n") || "No progress recorded yet."}

Keep replies under 100 words.`;

  const genAI = new GoogleGenerativeAI(geminiKey.value());
  const model = genAI.getGenerativeModel({
    model: "gemini-3.5-flash",
  });

  try {
    const truncatedHistory = (history || []).slice(-10).map((m) => ({
      role: m.role === "user" ? "user" : "model",
      parts: [{text: m.content}],
    }));

    // Start chat with system context injected as first turn
    const chat = model.startChat({
      history: [
        { role: 'user', parts: [{ text: chatSystemPrompt }] },
        { role: 'model', parts: [{ text: 'Understood! I know the BearTahan system well and I\'m ready to help with insights about ' + child.name + '.' }] },
        ...truncatedHistory
      ],
    });

    const result = await chat.sendMessage(message);
    const response = await result.response;
    const responseText = response.text();
    
    logger.info("BearAI Chat Response", {
      childId,
      message,
      response: responseText
    });

    return {text: responseText};
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

  // Fetch everything needed
  const [attempts, wrongAnswers, subjectProgress, rewardClaims] = await Promise.all([
    childRef.collection('attempts').orderBy('completedAt', 'desc').limit(20).get(),
    childRef.collection('wrongAnswerBank').get(),
    childRef.collection('subjectProgress').get(),
    childRef.collection('rewardClaims').where('status', '==', 'pending').get(),
  ]);

  // Classify each subject's health
  const subjectHealth = {};
  subjectProgress.docs.forEach(doc => {
    const d = doc.data();
    const totalLevels = d.completedLevels || 0;
    const totalStars = d.totalStars || 0;
    const maxPossibleStars = totalLevels * 3;
    const starRatio = maxPossibleStars > 0 ? totalStars / maxPossibleStars : 0;
    
    subjectHealth[doc.id] = {
      completedLevels: totalLevels,
      totalStars,
      starRatio: Math.round(starRatio * 100),
      // Classify using Bear's Den logic
      tier: starRatio < 0.5 ? 'needs_work' : starRatio < 0.8 ? 'average' : 'strong',
      progress: d.progress || 0,
    };
  });

  // Classify recent attempts by level type
  const recentActivity = attempts.docs.map(doc => {
    const d = doc.data();
    const levelId = d.levelId || '';
    let levelType = 'regular';
    if (levelId.includes('summary')) levelType = 'chapter_summary';
    else if (levelId.includes('revision')) levelType = 'revision';
    else if (d.sessionType === 'bears_den') levelType = 'bears_den';
    else if (d.sessionType === 'memory_challenge') levelType = 'memory_challenge';

    return {
      subject: d.subjectId,
      level: levelId,
      levelType,
      score: d.score,
      total: d.total,
      stars: d.stars,
      percentage: d.total > 0 ? Math.round((d.score / d.total) * 100) : 0,
      completedAt: d.completedAt?.toDate?.()?.toISOString?.() || null,
    };
  });

  // Wrong answer summary by subject
  const wrongBySubject = {};
  wrongAnswers.docs.forEach(doc => {
    const d = doc.data();
    const subj = d.subjectId || 'unknown';
    wrongBySubject[subj] = (wrongBySubject[subj] || 0) + 1;
  });

  // Build the data payload for Gemini
  const childContext = `
CHILD PROFILE
Name: ${childData.name}
Active outfit: ${childData.activeOutfitID || 'scholar_bear'}
Current streak: ${getEffectiveStreak(Number(childData.streakCount || 0), childData.lastActivityDate)} days
Available stars: ${childData.availableStars || 0}
Lifetime stars: ${childData.lifetimeStarsEarned || 0}
Daily goal: ${JSON.stringify(childData.dailyGoal || {})}
Pending reward claims: ${rewardClaims.size}

SUBJECT HEALTH (star ratio = stars earned vs max possible)
${Object.entries(subjectHealth).map(([subj, h]) => 
  `${subj}: ${h.tier.toUpperCase()} - ${h.starRatio}% star ratio, ${h.completedLevels} levels done, ${h.progress}% progress`).join('\n')}

WRONG ANSWER BANK (questions that need revisiting)
${Object.entries(wrongBySubject).map(([subj, count]) => 
  `${subj}: ${count} wrong answers pending`).join('\n') || 'None'}

RECENT ACTIVITY (last 20 sessions)
${recentActivity.map(a => 
  `[${a.levelType}] ${a.subject}/${a.level}: ${a.percentage}% (${a.stars}*) on ${a.completedAt?.split('T')[0] || 'unknown date'}`).join('\n')}`;

  const prompt = `${BEARTAHAN_SYSTEM_PROMPT}

=== TASK ===
Generate a weekly insight for ${childData.name}'s parent. 
Use the data below. Be specific - name actual subjects and scores.
Keep it under 150 words.

${childContext}`;

  const genAI = new GoogleGenerativeAI(geminiKey.value());
  const model = genAI.getGenerativeModel({model: "gemini-3.5-flash"});

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const insightText = response.text();

    logger.info("BearAI Insight Generated", {
      childId,
      insight: insightText
    });

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
