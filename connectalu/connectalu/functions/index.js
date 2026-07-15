const functions = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Callable function used by an admin reviewer to approve or reject a
 * startup's verification request. This is the ONLY place verification
 * state should change in production — Firestore rules reject direct
 * client writes to `verificationStatus` (see firestore.rules), so this
 * function is the single trust boundary for the whole platform.
 *
 * Expected data: { startupId: string, decision: 'verified' | 'rejected', reason?: string }
 */
exports.reviewStartup = functions.onCall(async (request) => {
  const { auth, data } = request;

  if (!auth || auth.token.admin !== true) {
    throw new functions.HttpsError(
      "permission-denied",
      "Only platform admins can review startups."
    );
  }

  const { startupId, decision, reason } = data;
  if (!startupId || !["verified", "rejected"].includes(decision)) {
    throw new functions.HttpsError("invalid-argument", "Missing or invalid parameters.");
  }

  const startupRef = db.collection("startups").doc(startupId);
  const startupSnap = await startupRef.get();
  if (!startupSnap.exists) {
    throw new functions.HttpsError("not-found", "Startup does not exist.");
  }

  await startupRef.update({
    verificationStatus: decision,
    rejectionReason: decision === "rejected" ? (reason || null) : null,
  });

  // Mint/refresh the custom claim for every founder on this startup so
  // Firestore rules (isVerifiedFounderOf) and the client's post-opportunity
  // gating both see the new state on next token refresh.
  const founderIds = startupSnap.data().founderIds || [];
  await Promise.all(
    founderIds.map(async (uid) => {
      const userRecord = await admin.auth().getUser(uid);
      const existingClaims = userRecord.customClaims || {};
      const verifiedStartups = new Set(existingClaims.verifiedStartups || []);

      if (decision === "verified") {
        verifiedStartups.add(startupId);
      } else {
        verifiedStartups.delete(startupId);
      }

      await admin.auth().setCustomUserClaims(uid, {
        ...existingClaims,
        verifiedStartups: Array.from(verifiedStartups),
      });
    })
  );

  return { success: true };
});

/**
 * Keeps opportunities.applicantCount trustworthy even if a client-side
 * transaction is ever bypassed (e.g. future admin tooling writes an
 * application doc directly). Recomputes the count from source of truth
 * whenever an application's status changes, so the founder dashboard
 * funnel counts never drift.
 */
exports.onApplicationWritten = onDocumentUpdated(
  "applications/{applicationId}",
  async (event) => {
    const after = event.data.after.data();
    const before = event.data.before.data();
    const opportunityId = after.opportunityId;

    // Reconcile applicantCount
    const snap = await db
      .collection("applications")
      .where("opportunityId", "==", opportunityId)
      .get();
    await db.collection("opportunities").doc(opportunityId).update({
      applicantCount: snap.size,
    });

    // Send in-app notification to student when status changes
    if (before.status !== after.status) {
      const statusLabels = {
        inReview: "In Review",
        interview: "Interview",
        accepted: "Accepted 🎉",
        rejected: "Not selected",
      };
      const label = statusLabels[after.status];
      if (label) {
        await db.collection("notifications").add({
          userId: after.studentId,
          title: `Application update: ${after.opportunityTitle}`,
          body: `Your application status changed to "${label}"${
            after.interviewScheduledAt
              ? ` — Interview scheduled for ${after.interviewScheduledAt.toDate().toDateString()}`
              : ""
          }.`,
          read: false,
          routePath: "/applications",
          createdAt: new Date(),
        });
      }
    }
  }
);
