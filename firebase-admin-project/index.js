const admin = require('firebase-admin');

const serviceAccount = require('./service-account-file.json'); // تحديث المسار إلى ملف JSON

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://your-project-id.firebaseio.com"
});

console.log("Firebase Admin SDK Initialized");
