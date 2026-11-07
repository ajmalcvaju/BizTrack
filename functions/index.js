const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Daily Scheduled Cron: Runs every morning at 08:00 AM Indian Standard Time (Asia/Kolkata).
 * Scans each user's tasks, future expenses, and leads:
 * - Flags and notifies overdue tasks pending from previous days.
 * - Flags and notifies overdue future expenses pending past their due date.
 * - Notifies leads scheduled for follow-up today.
 */
exports.scheduledDailyBusinessAlerts = functions.pubsub
  .schedule("0 8 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const now = new Date();
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const tomorrowMidnight = new Date(todayMidnight.getTime() + 24 * 60 * 60 * 1000);

    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      // 1. Check Overdue Tasks
      const overdueTasksSnap = await db
        .collection(`users/${userId}/tasks`)
        .where("status", "==", "Pending")
        .where("taskDate", "<", admin.firestore.Timestamp.fromDate(todayMidnight))
        .get();

      if (!overdueTasksSnap.empty && fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "🚨 Overdue Tasks Alert",
            body: `You have ${overdueTasksSnap.size} pending task(s) from earlier days requiring attention!`,
          },
          data: {
            type: "task_overdue",
            count: overdueTasksSnap.size.toString(),
          },
        }).catch((err) => console.log("FCM Task Error:", err));
      }

      // 2. Check Overdue Future Expenses
      const overdueExpensesSnap = await db
        .collection(`users/${userId}/futureExpenses`)
        .where("paymentStatus", "==", "Pending")
        .where("dueDate", "<", admin.firestore.Timestamp.fromDate(todayMidnight))
        .get();

      if (!overdueExpensesSnap.empty && fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "⚠️ Overdue Scheduled Expenses",
            body: `You have ${overdueExpensesSnap.size} unpaid expense(s) that passed their scheduled due date!`,
          },
          data: {
            type: "expense_overdue",
            count: overdueExpensesSnap.size.toString(),
          },
        }).catch((err) => console.log("FCM Expense Error:", err));
      }

      // 3. Check Today's Lead Follow-ups
      const leadsTodaySnap = await db
        .collection(`users/${userId}/leads`)
        .where("isConverted", "==", false)
        .where("nextFollowUpDate", ">=", admin.firestore.Timestamp.fromDate(todayMidnight))
        .where("nextFollowUpDate", "<", admin.firestore.Timestamp.fromDate(tomorrowMidnight))
        .get();

      if (!leadsTodaySnap.empty && fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "📞 Leads Due For Follow-up Today",
            body: `${leadsTodaySnap.size} customer lead(s) are scheduled for conversation today.`,
          },
          data: {
            type: "lead_followup_today",
            count: leadsTodaySnap.size.toString(),
          },
        }).catch((err) => console.log("FCM Lead Error:", err));
      }
    }

    return null;
  });
