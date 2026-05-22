const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyTaskAssigned = functions.firestore
  .document('tasks/{taskId}')
  .onCreate(async (snap) => {
    const task = snap.data();
    const assignedTo = task.assignedTo;
    const householdId = task.householdId;
    const title = task.title;

    if (!assignedTo || !householdId || !title) return null;

    const usersSnap = await admin.firestore()
      .collection('users')
      .where('householdId', '==', householdId)
      .get();

    const assigneeDoc = usersSnap.docs.find((doc) => {
      const data = doc.data();
      const name = data.name || (data.email ? data.email.split('@')[0] : '');
      return name === assignedTo;
    });

    if (!assigneeDoc) return null;

    const fcmToken = assigneeDoc.data().fcmToken;
    if (!fcmToken) return null;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'New task assigned to you',
        body: title,
      },
      android: {
        notification: {
          channelId: 'task_notifications',
          priority: 'high',
          sound: 'default',
        },
      },
    });

    return null;
  });
