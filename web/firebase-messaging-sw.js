importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");
importScripts("vendza-firebase-config.js");

const firebaseConfig = self.VENDZA_FIREBASE_CONFIG || {};
const hasFirebaseConfig =
  firebaseConfig.apiKey &&
  firebaseConfig.projectId &&
  firebaseConfig.messagingSenderId &&
  firebaseConfig.appId;

if (hasFirebaseConfig) {
  firebase.initializeApp(firebaseConfig);

  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((message) => {
    const notification = message.notification || {};
    const data = message.data || {};
    const imageUrl = notification.image || data.image_url || data.product_image || data.store_image || undefined;
    self.registration.showNotification(notification.title || "Vendza", {
      body: notification.body || "",
      icon: data.store_image || imageUrl,
      image: imageUrl,
      data,
    });
  });
}
