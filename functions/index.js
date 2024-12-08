const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendBookingNotification = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap, context) => {
      const booking = snap.data();


      try {
      // الحصول على توكن FCM لصاحب الشقة
        const ownerDoc = await admin
            .firestore()
            .collection("users")
            .doc(booking.ownerId)
            .get();

        const ownerToken = ownerDoc.data().fcmToken;

        if (ownerToken) {
        // إرسال إشعار إلى صاحب الشقة
          await admin.messaging().send({
            token: ownerToken,
            notification: {
              title: "طلب حجز جديد",
              body: `لديك طلب جديد للشقة ${booking.apartmentId}`,
            },
          });

          console.log("تم إرسال الإشعار بنجاح");
        } else {
          console.log("لا يوجد توكن FCM لصاحب الشقة");
        }
      } catch (error) {
        console.error("حدث خطأ أثناء إرسال الإشعا:", error);
      }
    });
