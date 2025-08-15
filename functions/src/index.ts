/**
 * Firebase Cloud Functions for Smart Mess Application
 * Handles user deletion including Firebase Auth cleanup with PMC protection
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Cloud Function to delete a user by email (callable function)
export const deleteUserByEmail = onCall(async (request) => {
  try {
    const { email } = request.data;
    
    if (!email) {
      throw new HttpsError('invalid-argument', 'Email is required');
    }

    // Only allow authenticated users to call this function
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    // Check if the caller is an admin
    const callerDoc = await admin.firestore()
      .collection('staff_state')
      .where('email', '==', request.auth.token.email)
      .where('role', 'in', ['PMC', 'G2 (Mess)', 'Mess Secretary'])
      .get();

    if (callerDoc.empty) {
      throw new HttpsError('permission-denied', 'Insufficient permissions. Only authorized administrators can delete users.');
    }

    // Safety check: Prevent deletion of PMC accounts
    const targetUserDoc = await admin.firestore()
      .collection('staff_state')
      .where('email', '==', email)
      .get();

    if (!targetUserDoc.empty) {
      const targetRole = targetUserDoc.docs[0].data().role;
      if (targetRole === 'PMC') {
        throw new HttpsError('permission-denied', 'PMC accounts cannot be deleted. They serve as super admin to maintain system access.');
      }
    }

    // Find the user by email
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        console.log(`User with email ${email} not found in Firebase Auth`);
        return { 
          success: true, 
          message: "User not found in Firebase Auth (may have been already deleted)" 
        };
      }
      throw new HttpsError('internal', `Failed to find user: ${error.message}`);
    }

    // Delete the user from Firebase Auth
    await admin.auth().deleteUser(userRecord.uid);
    
    console.log(`Successfully deleted user ${email} (UID: ${userRecord.uid})`);
    
    return { 
      success: true, 
      message: `User ${email} deleted successfully from Firebase Auth` 
    };

  } catch (error: any) {
    console.error("Error deleting user:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Failed to delete user: ${error.message}`);
  }
});

// Firestore trigger: automatically cleanup when staff document is deleted
export const onStaffDeleted = onDocumentDeleted('staff_state/{staffId}', async (event) => {
  try {
    const deletedStaff = event.data?.data();
    const email = deletedStaff?.email;
    const role = deletedStaff?.role;
    const staffId = event.params?.staffId;
    
    // Safety check: Log if PMC was somehow deleted (shouldn't happen)
    if (role === 'PMC') {
      console.error(`🚨 CRITICAL: PMC account was deleted! Email: ${email}, ID: ${staffId}`);
      console.error('This should never happen as PMC serves as super admin');
      // Still proceed with cleanup but log the critical issue
    }
    
    if (!email) {
      console.warn(`No email found for deleted staff document ${staffId}`);
      return;
    }

    console.log(`Auto-cleanup triggered for deleted staff: ${email} (Role: ${role})`);

    // Try to delete the corresponding Firebase Auth user
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      await admin.auth().deleteUser(userRecord.uid);
      console.log(`✅ Automatically deleted Firebase Auth user for ${email} (UID: ${userRecord.uid})`);
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        console.log(`ℹ️ Firebase Auth user for ${email} was already deleted or never existed`);
      } else {
        console.error(`❌ Failed to auto-delete Firebase Auth user for ${email}:`, error);
      }
    }

    // Also delete from users collection if exists
    try {
      const userQuery = await admin.firestore()
        .collection('users')
        .where('email', '==', email)
        .get();
      
      if (!userQuery.empty) {
        const batch = admin.firestore().batch();
        userQuery.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`✅ Deleted ${userQuery.docs.length} user documents for ${email}`);
      } else {
        console.log(`ℹ️ No user documents found for ${email}`);
      }
    } catch (error) {
      console.error(`❌ Failed to delete user documents for ${email}:`, error);
    }

  } catch (error) {
    console.error("❌ Error in onStaffDeleted trigger:", error);
  }
});

/**
 * Auto Loop Function - Runs daily at 21:00 (9:00 PM) Bangladesh Time
 * Automatically creates meal states for users with enabled auto loop
 */
export const dailyAutoLoop = onSchedule({
  schedule: "0 21 * * *", // Every day at 21:00 (9:00 PM)
  timeZone: "Asia/Dhaka", // Bangladesh timezone
}, async (event) => {
  console.log("🔄 Starting daily auto loop process...");
  
  try {
    // Get all users with enabled auto loop
    const autoLoopSnapshot = await admin.firestore()
      .collection('user_auto_loop')
      .where('enabled', '==', true)
      .get();

    if (autoLoopSnapshot.empty) {
      console.log("No users with auto loop enabled");
      return;
    }

    // Calculate tomorrow's date
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = `${tomorrow.getFullYear()}-${String(tomorrow.getMonth() + 1).padStart(2, '0')}-${String(tomorrow.getDate()).padStart(2, '0')}`;

    console.log(`📅 Processing auto loop for date: ${tomorrowStr}`);

    const batch = admin.firestore().batch();
    let processedCount = 0;

    for (const doc of autoLoopSnapshot.docs) {
      const loopData = doc.data();
      const baNo = loopData.ba_no;
      const mealPattern = loopData.meal_pattern;

      // Check if meal state already exists for this user on this date
      const existingMealStateRef = admin.firestore()
        .collection('user_meal_state')
        .doc(tomorrowStr);
      
      const existingDoc = await existingMealStateRef.get();
      
      // Skip if user already has meal state for tomorrow (manual submission takes priority)
      if (existingDoc.exists && existingDoc.data()?.[baNo]) {
        console.log(`⏭️ Skipping ${baNo} - manual submission already exists for ${tomorrowStr}`);
        continue;
      }

      // Create meal state data
      const mealStateData = {
        name: loopData.name,
        rank: loopData.rank,
        breakfast: mealPattern.breakfast || false,
        lunch: mealPattern.lunch || false,
        dinner: mealPattern.dinner || false,
        remarks: '',
        disposal: false,
        disposal_type: '',
        disposal_from: '',
        disposal_to: '',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        admin_generated: loopData.admin_created || false, // Set based on who created the Auto Loop
        auto_loop_generated: true, // Mark as auto loop generated
      };

      // Add to batch
      batch.set(existingMealStateRef, {
        [baNo]: mealStateData
      }, { merge: true });

      processedCount++;
      console.log(`✅ Queued auto loop meal state for ${baNo} (${loopData.name})`);
    }

    // Commit batch
    if (processedCount > 0) {
      await batch.commit();
      console.log(`🎉 Successfully processed ${processedCount} auto loop meal states for ${tomorrowStr}`);
    } else {
      console.log("No new auto loop meal states to process");
    }

  } catch (error) {
    console.error("❌ Error in daily auto loop process:", error);
    throw error;
  }
});
