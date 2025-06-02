# Dummy Data untuk Aplikasi Daily Checklist

Folder ini berisi data dummy untuk aplikasi Daily Checklist. Data ini dapat digunakan untuk pengujian dan pengembangan aplikasi.

## Daftar File

- `dummy_teachers.json`: Berisi data 4 guru
- `dummy_parents.json`: Berisi data 12 orang tua
- `dummy_children.json`: Berisi data 18 anak
- `dummy_activities.json`: Berisi data 20 aktivitas
- `dummy_checklist_items.json`: Berisi data 20 item checklist
- `dummy_plans.json`: Berisi data 10 rencana aktivitas (8 mingguan, 2 harian)
- `dummy_follow_up_suggestions.json`: Berisi data 10 saran follow-up aktivitas
- `dummy_data_import.js`: Script untuk mengimpor data ke Firebase Firestore

## Struktur Data

### Teachers (Guru)
- `id`: ID unik guru
- `name`: Nama guru
- `email`: Email guru
- `password`: Password guru (enkripsi disarankan untuk implementasi sebenarnya)
- `role`: Peran (selalu "teacher")
- `phone`: Nomor telepon guru
- `address`: Alamat guru
- `avatarUrl`: URL avatar guru
- `createdAt`: Waktu pembuatan akun

### Parents (Orang Tua)
- `id`: ID unik orang tua
- `name`: Nama orang tua
- `email`: Email orang tua
- `password`: Password orang tua (enkripsi disarankan untuk implementasi sebenarnya)
- `role`: Peran (selalu "parent")
- `phone`: Nomor telepon orang tua
- `address`: Alamat orang tua
- `avatarUrl`: URL avatar orang tua
- `createdBy`: ID guru yang membuat akun orang tua
- `createdAt`: Waktu pembuatan akun

### Children (Anak)
- `id`: ID unik anak
- `name`: Nama anak
- `age`: Usia anak (3-6 tahun)
- `parentId`: ID orang tua
- `teacherId`: ID guru
- `avatarUrl`: URL avatar anak
- `createdAt`: Waktu pembuatan data anak

### Activities (Aktivitas)
- `id`: ID unik aktivitas
- `title`: Judul aktivitas
- `description`: Deskripsi aktivitas
- `environment`: Lingkungan aktivitas ("Home", "School", "Both")
- `difficulty`: Tingkat kesulitan ("Easy", "Medium", "Hard")
- `ageRange`: Rentang usia yang sesuai (`min` dan `max`)
- `customSteps`: Langkah-langkah kustom dari guru
- `createdAt`: Waktu pembuatan aktivitas
- `createdBy`: ID guru yang membuat aktivitas

### Checklist Items (Item Checklist)
- `id`: ID unik item checklist
- `childId`: ID anak
- `activityId`: ID aktivitas
- `assignedDate`: Tanggal penugasan
- `dueDate`: Tanggal jatuh tempo
- `status`: Status ("pending", "in-progress", "completed")
- `homeObservation`: Observasi di rumah
- `schoolObservation`: Observasi di sekolah
- `customStepsUsed`: ID guru yang langkah-langkah kustomnya digunakan

### Plans (Rencana Aktivitas)
- `id`: ID unik rencana
- `teacherId`: ID guru
- `type`: Tipe rencana ("weekly", "daily")
- `title`: Judul rencana
- `description`: Deskripsi rencana
- `startDate`: Tanggal mulai
- `endDate`: Tanggal selesai
- `childId`: ID anak
- `activities`: Daftar aktivitas dalam rencana
- `createdAt`: Waktu pembuatan rencana

### Follow-up Suggestions (Saran Follow-up)
- `id`: ID unik saran
- `childId`: ID anak
- `completedActivityId`: ID aktivitas yang telah diselesaikan
- `suggestedActivityId`: ID aktivitas yang disarankan
- `autoAssigned`: Apakah otomatis ditugaskan
- `assignedDate`: Tanggal penugasan (null jika belum ditugaskan)
- `status`: Status saran ("suggested", "assigned", "pending")
- `createdAt`: Waktu pembuatan saran

## Cara Mengimpor Data

1. Pastikan Anda telah menginstal Node.js
2. Instal dependensi yang diperlukan:
   ```
   npm install firebase
   ```
3. Edit file `dummy_data_import.js` dan tambahkan konfigurasi Firebase Anda
4. Jalankan script:
   ```
   node dummy_data_import.js
   ```

## Catatan Penting

- Data dummy ini hanya untuk tujuan pengembangan dan pengujian
- Untuk lingkungan produksi, pastikan untuk menggunakan data nyata dan menerapkan aturan keamanan yang sesuai
- Password dalam data dummy tidak dienkripsi, pastikan untuk mengimplementasikan enkripsi password di aplikasi sebenarnya 