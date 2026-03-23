const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const db = admin.firestore();

exports.sendChatNotification = functions.firestore
    .document('notification_queue/{notificationId}')
    .onCreate(async (snapshot, context) => {
      const notification = snapshot.data();
      
      if (!notification || notification.processed) {
        return null;
      }

      const { receiverId, title, body, data } = notification;

      try {
        const userDoc = await db.collection('users').doc(receiverId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (!fcmToken) {
          console.log('No FCM token found for user:', receiverId);
          await snapshot.ref.update({ processed: true, error: 'No FCM token' });
          return null;
        }

        const message = {
          notification: {
            title: title,
            body: body,
          },
          data: data || {},
          token: fcmToken,
          android: {
            priority: 'high',
            notification: {
              channelId: 'chat_messages',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: 'default',
              },
            },
          },
        };

        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response);
        
        await snapshot.ref.update({ 
          processed: true, 
          sentAt: admin.firestore.FieldValue.serverTimestamp() 
        });
        
        return response;
      } catch (error) {
        console.error('Error sending message:', error);
        await snapshot.ref.update({ 
          processed: true, 
          error: error.message 
        });
        return null;
      }
    });

exports.sendNotificationOnNewMessage = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
      const message = snapshot.data();
      const { chatId } = context.params;
      const { senderId, senderName, text, imageUrl, fileUrl, fileName } = message;

      if (!senderId) return null;

      try {
        const chatDoc = await db.collection('chats').doc(chatId).get();
        const chatData = chatDoc.data();
        
        if (!chatData) return null;

        const participants = chatData.participants || [];
        const isSupportChat = chatData.isSupportChat || false;

        const displayText = imageUrl 
            ? 'Sent an image' 
            : fileUrl 
                ? `Sent a file: ${fileName || 'file'}`
                : (text && text.length > 50 ? `${text.substring(0, 50)}...` : text);

        const notificationTitle = isSupportChat ? 'Drivemate Support' : senderName;

        const promises = participants
            .filter(participantId => participantId !== senderId)
            .map(async (participantId) => {
              const userDoc = await db.collection('users').doc(participantId).get();
              const fcmToken = userDoc.data()?.fcmToken;

              if (!fcmToken) {
                console.log('No FCM token for user:', participantId);
                return null;
              }

              const notificationMessage = {
                notification: {
                  title: notificationTitle,
                  body: displayText || 'New message',
                },
                data: {
                  type: 'chat_message',
                  chatId: chatId,
                  senderId: senderId,
                  senderName: senderName,
                },
                token: fcmToken,
                android: {
                  priority: 'high',
                  notification: {
                    channelId: 'chat_messages',
                    priority: 'high',
                    defaultSound: true,
                  },
                },
                apns: {
                  payload: {
                    aps: {
                      badge: 1,
                      sound: 'default',
                    },
                  },
                },
              };

              return admin.messaging().send(notificationMessage);
            });

        const results = await Promise.allSettled(promises);
        results.forEach((result, index) => {
          if (result.status === 'fulfilled') {
            console.log('Notification sent successfully to participant:', participants[index]);
          } else {
            console.error('Failed to send notification:', result.reason);
          }
        });

        return null;
      } catch (error) {
        console.error('Error in sendNotificationOnNewMessage:', error);
        return null;
      }
    });

// ==========================================
// GMAIL NODEMAILER EMAIL TRIGGERS
// ==========================================

// Load Gmail credentials from environment variables (.env)
const gmailEmail = process.env.GMAIL_EMAIL || 'drivemate.mds@gmail.com';
const gmailPassword = process.env.GMAIL_APP_PASSWORD || 'YOUR_APP_PASSWORD';

// Create a Nodemailer transporter using Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// Configure the default sender
const defaultSender = `"Drivemate" <${gmailEmail}>`;

// Helper function to send email via nodemailer
async function sendEmail(to, subject, htmlContent) {
  try {
    const info = await transporter.sendMail({
      from: defaultSender,
      to: to,
      subject: subject,
      html: htmlContent,
    });
    console.log('Email sent successfully:', info.messageId);
    return info;
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
}

// 1. Welcome Email (New User Account)
exports.sendWelcomeEmailOnAuth = functions.auth.user().onCreate(async (user) => {
  if (!user.email) return null;

  try {
    await sendEmail(
      user.email,
      'Welcome to Drivemate!',
      `<h2>Welcome to Drivemate!</h2>
       <p>Hi ${user.displayName || 'there'},</p>
       <p>Your account has been successfully created. We are excited to have you on board.</p>
       <p>Best regards,<br>The Drivemate Team</p>`
    );
  } catch (error) {}
  return null;
});

// 2. Student Registration Welcome Email
exports.sendStudentWelcomeEmail = functions.firestore
  .document('users/{schoolId}/students/{studentId}')
  .onCreate(async (snapshot, context) => {
    const student = snapshot.data();
    if (!student || !student.email) return null;

    try {
      await sendEmail(
        student.email,
        'Welcome to our Driving School!',
        `<h2>Welcome, ${student.fullName || 'Student'}!</h2>
         <p>Your registration is complete.</p>
         <p><strong>Your Student ID:</strong> ${student.studentId || context.params.studentId}</p>
         <p>We look forward to helping you learn how to drive safely.</p>
         <p>Best regards,<br>The Driving School Team</p>`
      );
    } catch (error) {}
    return null;
  });

// 3. Payment Receipt Email
exports.sendPaymentReceiptEmail = functions.firestore
  .document('users/{schoolId}/students/{studentId}/payments/{paymentId}')
  .onCreate(async (snapshot, context) => {
    const payment = snapshot.data();
    if (!payment) return null;

    try {
      const studentDoc = await db.collection('users').doc(context.params.schoolId)
        .collection('students').doc(context.params.studentId).get();
      const student = studentDoc.data();
      
      if (!student || !student.email) {
        console.log('Skipping payment email: No student email address found.');
        return null;
      }

      const amount = payment.amount || 0;
      const dateStr = payment.date && payment.date.toDate 
        ? payment.date.toDate().toLocaleDateString() 
        : new Date().toLocaleDateString();

      await sendEmail(
        student.email,
        'Payment Receipt - Driving School',
        `<h2>Payment Receipt</h2>
         <p>Hi ${student.fullName || 'Student'},</p>
         <p>We have successfully received your payment.</p>
         <table style="border-collapse: collapse; width: 100%; max-width: 400px; margin-top: 10px;">
           <tr>
             <td style="padding: 8px; border: 1px solid #ddd;"><strong>Amount:</strong></td>
             <td style="padding: 8px; border: 1px solid #ddd;">₹${amount}</td>
           </tr>
           <tr>
             <td style="padding: 8px; border: 1px solid #ddd;"><strong>Date:</strong></td>
             <td style="padding: 8px; border: 1px solid #ddd;">${dateStr}</td>
           </tr>
         </table>
         <p>Thank you for your payment!</p>`
      );
    } catch (error) {}
    return null;
  });

// 4 & 5. Test Updates and Results Email
exports.sendTestUpdateEmail = functions.firestore
  .document('users/{schoolId}/students/{studentId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (!after || !after.email) return null;

    try {
      // Logic for Test Dates
      const beforeDate = before.testDate || before.scheduledTestDate;
      const afterDate = after.testDate || after.scheduledTestDate;
      
      // Logic for Test Results
      const beforeResult = before.testResult || before.result;
      const afterResult = after.testResult || after.result;

      let subject = '';
      let message = '';

      if (afterDate && beforeDate !== afterDate) {
        // Date was scheduled or updated
        const dateStr = afterDate.toDate ? afterDate.toDate().toLocaleDateString() : String(afterDate);
        subject = 'Your Driving Test has been Scheduled';
        message = `<p>Your upcoming driving test is scheduled for: <strong>${dateStr}</strong>.</p>
                   <p>Please remember to bring all necessary documents and arrive on time.</p>`;
      } else if (afterResult && beforeResult !== afterResult) {
        // Result was updated
        const resultString = String(afterResult).toLowerCase();
        const isPass = resultString.includes('pass') || resultString === 'p';
        
        subject = isPass ? 'Congratulations! You Passed Your Driving Test' : 'Your Driving Test Result Update';
        message = `<p>Your driving test result has just been updated in our system.</p>
                   <p>Result: <strong>${afterResult}</strong></p>
                   ${isPass 
                     ? '<p>Congratulations on passing! We wish you safe travels on the road.</p>' 
                     : '<p>Don\'t be discouraged! You can review your mistakes and schedule another test when you\'re ready.</p>'}`;
      }

      if (subject && message) {
        await sendEmail(
          after.email,
          subject,
          `<h2>Hi ${after.fullName || 'Student'},</h2>${message}<p>Best regards,<br>The Driving School Team</p>`
        );
      }
    } catch (error) {}
    return null;
  });
