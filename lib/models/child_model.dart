// class ChildModel {
//   final String id;
//   final String name;
//   final int age;
//   final String parentId;
//   final String teacherId;
//   final String? avatarUrl;

//   ChildModel({
//     required this.id,
//     required this.name,
//     required this.age,
//     required this.parentId,
//     required this.teacherId,
//     this.avatarUrl,
//   });

//   factory ChildModel.fromJson(Map<String, dynamic> json) {
//     return ChildModel(
//       id: json['id'] ?? '',
//       name: json['name'] ?? '',
//       age: json['age'] ?? 0,
//       parentId: json['parentId'] ?? '',
//       teacherId: json['teacherId'] ?? '',
//       avatarUrl: json['avatarUrl'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'age': age,
//       'parentId': parentId,
//       'teacherId': teacherId,
//       'avatarUrl': avatarUrl,
//     };
//   }

//   // Generate DiceBear avatar URL for a child if none is provided
//   String getAvatarUrl() {
//     // Selalu buat URL DiceBear untuk konsistensi dan fallback
//     final seed = Uri.encodeComponent(name);
//     final diceBearUrl = 'https://api.dicebear.com/9.x/thumbs/png?seed=$seed';

//     // Jika avatarUrl tidak tersedia atau kosong, gunakan DiceBear
//     if (avatarUrl == null || avatarUrl!.isEmpty) {
//       return diceBearUrl;
//     }

//     // Jika avatarUrl tersedia, kita tetap gunakan
//     return avatarUrl!;
//   }

//   // Untuk memudahkan fallback ke DiceBear jika avatarUrl gagal
//   String getDiceBearUrl() {
//     final seed = Uri.encodeComponent(name);
//     return 'https://api.dicebear.com/9.x/thumbs/png?seed=$seed';
//   }
// }
