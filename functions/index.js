const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

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
      });

      await batch.commit();

      logger.info("Expired reward claims", {
        expiredCount: claimsSnapshot.size,
      });
    },
);
