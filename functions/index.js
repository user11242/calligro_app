// Import Firebase Admin SDK and Functions SDK (v2)
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

// Initialize Admin SDK
admin.initializeApp();

// Set global options (cost control, concurrency, etc.)
setGlobalOptions({ maxInstances: 10 });

// Firestore trigger when a new user document is created
exports.notifyAdminOnTeacherRegistration = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const newUser = event.data.data(); // New document data

    // Only trigger for teachers with status = pending
    if (newUser.role !== "teacher" || newUser.status !== "pending") {
      return null;
    }

    // Get all admins with fcmToken
    const adminsSnap = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const tokens = adminsSnap.docs
      .map((doc) => doc.data().fcmToken)
      .filter((token) => !!token);

    if (tokens.length === 0) {
      console.log("No admin tokens found");
      return null;
    }

    try {
      // ✅ Correct placement of tokens for sendEachForMulticast
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "New Teacher Registration",
          body: `${
            newUser.name || "A new teacher"
          } is waiting for approval.`,
        },
        data: {
          userId: event.params.userId,
          type: "new_teacher",
        },
      });

      console.log(
        "Notifications sent:",
        response.successCount,
        "success,",
        response.failureCount,
        "failed"
      );

      if (response.failureCount > 0) {
        response.responses.forEach((res, idx) => {
          if (!res.success) {
            console.error("Failed token:", tokens[idx], res.error);
          }
        });
      }
    } catch (error) {
      console.error("Error sending notifications:", error);
    }

    return null;
  }
);
