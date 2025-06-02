// Script untuk mengimpor data dummy ke Firebase Firestore
// Simpan file ini di root proyek dan jalankan dengan:
// node dummy_data_import.js

const fs = require('fs');
const path = require('path');
const { initializeApp } = require('firebase/app');
const { 
  getFirestore, 
  collection, 
  doc, 
  setDoc, 
  Timestamp 
} = require('firebase/firestore');

// Impor konfigurasi Firebase dari file firebase_options.dart
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// Inisialisasi Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Fungsi untuk mengonversi objek dengan format seconds/nanoseconds ke Timestamp Firestore
function convertTimestamps(obj) {
  if (obj === null || typeof obj !== 'object') {
    return obj;
  }
  
  // Buat salinan objek untuk menghindari mutasi objek asli
  const result = Array.isArray(obj) ? [...obj] : {...obj};
  
  for (const key in result) {
    if (result[key] && typeof result[key] === 'object') {
      if (result[key].seconds !== undefined && result[key].nanoseconds !== undefined) {
        // Konversi ke Timestamp Firestore
        result[key] = Timestamp.fromMillis(result[key].seconds * 1000);
      } else {
        // Rekursif untuk objek bersarang
        result[key] = convertTimestamps(result[key]);
      }
    }
  }
  
  return result;
}

// Fungsi untuk mengimpor data dari file JSON ke Firestore
async function importData(filePath, collectionName) {
  try {
    console.log(`Mengimpor data dari ${filePath} ke koleksi ${collectionName}...`);
    
    // Baca file JSON
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const items = data[collectionName];
    
    // Periksa apakah ada data untuk diimpor
    if (!items || !Array.isArray(items) || items.length === 0) {
      console.log(`Tidak ada data untuk diimpor di koleksi ${collectionName}`);
      return;
    }
    
    // Impor setiap item ke Firestore
    for (const item of items) {
      const itemWithTimestamps = convertTimestamps(item);
      const docRef = doc(collection(db, collectionName), item.id);
      await setDoc(docRef, itemWithTimestamps);
      console.log(`Berhasil mengimpor ${collectionName} dengan ID: ${item.id}`);
    }
    
    console.log(`Selesai mengimpor ${items.length} item ke koleksi ${collectionName}`);
  } catch (error) {
    console.error(`Error saat mengimpor data ke ${collectionName}:`, error);
  }
}

// Fungsi utama untuk mengimpor semua data dummy
async function importAllData() {
  try {
    console.log('Mulai mengimpor data dummy ke Firestore...');
    
    // Impor data guru
    await importData('dummy_teachers.json', 'teachers');
    
    // Impor data orang tua
    await importData('dummy_parents.json', 'parents');
    
    // Impor data anak
    await importData('dummy_children.json', 'children');
    
    // Impor data aktivitas
    await importData('dummy_activities.json', 'activities');
    
    // Impor data checklist items
    await importData('dummy_checklist_items.json', 'checklist_items');
    
    // Impor data rencana aktivitas
    await importData('dummy_plans.json', 'plans');
    
    // Impor data saran follow-up
    await importData('dummy_follow_up_suggestions.json', 'follow_up_suggestions');
    
    console.log('Semua data berhasil diimpor!');
  } catch (error) {
    console.error('Error saat mengimpor data:', error);
  }
}

// Jalankan fungsi impor
importAllData(); 