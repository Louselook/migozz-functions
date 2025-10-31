import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import QRCode from "qrcode";

initializeApp();
const db = getFirestore();
const storage = getStorage();


// 1. onUserCreate → sincroniza con profiles_public
export const onUserCreate = onDocumentCreated("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const snap = event.data;
  if (!snap) return;

  const userData = snap.data();

  await db.collection("profiles_public").doc(uid).set({
    username: userData.username || "",
    displayName: userData.displayName || "",
    avatarUrl: userData.avatarUrl || "",
    category: userData.category || "",
    city: userData.location?.city || "",
    country: userData.location?.country || "",
    totalFollowers: userData.totalFollowers || 0,
    linksCount: userData.linksCount || 0,
  t: FieldValue.serverTimestamp(),
  });
});


// 2. verifyHandle → reserva usernames
export const verifyHandle = onCall(async (request) => {
  const {handle, uid} = request.data;

  const ref = db.collection("shareHandles").doc(handle);
  const snap = await ref.get();

  if (snap.exists) {
    throw new Error("Handle already taken");
  }

  await ref.set({
    uid,
  createdAt: FieldValue.serverTimestamp(),
  });

  return {success: true};
});


// 3. profilesPublicSync → actualiza perfiles públicos
export const profilesPublicSync = onDocumentUpdated("users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after;
    if (!after) return;

    const data = after.data();

    await db.collection("profiles_public").doc(uid).set({
      username: data.username,
      displayName: data.displayName,
      avatarUrl: data.avatarUrl,
      category: data.category,
      city: data.location?.city,
      country: data.location?.country,
      totalFollowers: data.totalFollowers,
      linksCount: data.linksCount,
  t: FieldValue.serverTimestamp(),
    }, {merge: true});
  });


// 4. fetchSocialMetrics (ejemplo básico, sin APIs reales)
export const fetchSocialMetrics = onCall(async (request) => {
  const {uid, linkId} = request.data;

  const followers = Math.floor(Math.random() * 10000);
  const postsCount = Math.floor(Math.random() * 500);

  await db.collection("userSocials")
    .doc(uid)
    .collection("links")
    .doc(linkId).update({
      followers,
      postsCount,
  lastFetchedAt: FieldValue.serverTimestamp(),
    });

  // recalcular totalFollowers
  const linksSnap = await db
    .collection("userSocials")
    .doc(uid)
    .collection("links")
    .get();
  const totalFollowers = linksSnap
    .docs.reduce((sum, doc) => sum + (doc.data().followers || 0), 0);

  await db.collection("users").doc(uid).update({totalFollowers});

  return {success: true, followers, postsCount};
});


// 5. generateProfileQR → genera QR y lo guarda en Storage
export const generateProfileQR = onCall(async (request) => {
  const {uid, publicUrl} = request.data;

  const qrDataUrl = await QRCode.toDataURL(publicUrl);
  const buffer = Buffer.from(qrDataUrl.split(",")[1], "base64");

  const file = storage.bucket().file(`qr/${uid}/profile.png`);
  await file.save(buffer, {contentType: "image/png"});

  const qrUrl = `https://storage.googleapis.com/${file.bucket.name}/${file.name}`;

  await db.collection("users").doc(uid).update({
    "share.qrUrl": qrUrl,
  });

  return {success: true, qrUrl};
});
