/* Firestore -> Supabase daily backup
 *
 * Env vars required:
 * FIREBASE_PROJECT_ID
 * FIREBASE_CLIENT_EMAIL
 * FIREBASE_PRIVATE_KEY         (use \\n in secrets; code replaces with real newlines)
 * SUPABASE_URL
 * SUPABASE_SERVICE_ROLE_KEY
 * SUPABASE_BUCKET              (default: backups)
 * BACKUP_PREFIX                (default: firestore)
 */

const { Firestore } = require('@google-cloud/firestore');
const { createClient } = require('@supabase/supabase-js');

function required(name) {
  const v = process.env[name];
  if (!v || v.trim() === '') {
    console.error(`[backup] Missing required env var: ${name}`);
    process.exit(1);
  }
  return v;
}

const PROJECT_ID = required('FIREBASE_PROJECT_ID');
const CLIENT_EMAIL = required('FIREBASE_CLIENT_EMAIL');
const PRIVATE_KEY = required('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n');

const SUPABASE_URL = required('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = required('SUPABASE_SERVICE_ROLE_KEY');
const SUPABASE_BUCKET = process.env.SUPABASE_BUCKET || 'backups';
const BACKUP_PREFIX = process.env.BACKUP_PREFIX || 'firestore';

const firestore = new Firestore({
  projectId: PROJECT_ID,
  credentials: { client_email: CLIENT_EMAIL, private_key: PRIVATE_KEY },
});

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  global: { headers: { 'X-Client-Info': 'firestore-backup-script' } },
});

function todayStr() {
  const d = new Date();
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(d.getUTCDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

async function exportDocWithSubs(docRef) {
  const snap = await docRef.get();
  const data = snap.data() || {};

  // Remove potentially huge binary fields or transient fields if needed
  // e.g., delete data.largeBlob

  const subcollections = await docRef.listCollections();
  const subMap = {};
  for (const sub of subcollections) {
    const subSnap = await sub.get();
    const items = [];
    for (const d of subSnap.docs) {
      items.push(await exportDocWithSubs(d.ref));
    }
    subMap[sub.id] = items;
  }
  return {
    id: docRef.id,
    path: docRef.path,
    data,
    subcollections: subMap,
  };
}

async function exportCollection(collRef) {
  const snap = await collRef.get();
  const items = [];
  for (const d of snap.docs) {
    items.push(await exportDocWithSubs(d.ref));
  }
  return items;
}

async function uploadJson(path, obj) {
  const body = Buffer.from(JSON.stringify(obj, null, 2), 'utf-8');
  const { error } = await supabase.storage
    .from(SUPABASE_BUCKET)
    .upload(path, body, {
      contentType: 'application/json',
      upsert: true,
    });
  if (error) throw error;
}

async function backupAll() {
  const date = todayStr();
  const start = Date.now();
  console.log(`[backup] Starting backup for ${date}`);

  // Top-level: users collection and each user's subcollections
  const usersRef = firestore.collection('users');
  const userDocRefs = await usersRef.listDocuments();
  console.log(`[backup] Found ${userDocRefs.length} user(s)`);

  // Also backup any top-level collections other than 'users' if needed
  // const topLevelCollections = await firestore.listCollections();
  // ...

  let collCount = 0;
  let objectCount = 0;

  for (const userRef of userDocRefs) {
    const userId = userRef.id;
    // Backup the user document itself
    const userSnap = await userRef.get();
    const userDocPath = `${BACKUP_PREFIX}/${date}/users/${userId}/__user_doc.json`;
    await uploadJson(userDocPath, {
      id: userId,
      path: userRef.path,
      data: userSnap.data() || {},
    });
    objectCount += 1;

    // Backup each subcollection of this user
    const subCollections = await userRef.listCollections();
    for (const sub of subCollections) {
      collCount += 1;
      console.log(`[backup] Exporting ${userId}/${sub.id} ...`);
      const data = await exportCollection(sub);
      const path = `${BACKUP_PREFIX}/${date}/users/${userId}/${sub.id}.json`;
      await uploadJson(path, { collection: sub.id, items: data });
      objectCount += data.length;
    }
  }

  // Backup all other top-level collections
  const topLevelCollections = await firestore.listCollections();
  for (const coll of topLevelCollections) {
    if (coll.id === 'users') continue;
    collCount += 1;
    console.log(`[backup] Exporting top-level ${coll.id} ...`);
    const data = await exportCollection(coll);
    const path = `${BACKUP_PREFIX}/${date}/collections/${coll.id}.json`;
    await uploadJson(path, { collection: coll.id, items: data });
    objectCount += data.length;
  }

  const ms = Date.now() - start;
  console.log(
    `[backup] Completed. Collections: ${collCount}, Objects: ${objectCount}, Time: ${ms}ms`
  );
}

backupAll().catch((err) => {
  console.error('[backup] Failed:', err);
  process.exit(1);
});
