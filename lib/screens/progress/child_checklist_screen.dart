import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_checklist_student/laravel_api/providers/child_provider.dart';
import 'package:daily_checklist_student/screens/checklist/parent_checklist_screen.dart';
import 'package:daily_checklist_student/widgets/common/loading_indicator.dart';

class ChildChecklistScreen extends StatelessWidget {
  static const routeName = '/child-checklist';

  const ChildChecklistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final childId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      body: FutureBuilder(
        future: _getChildData(context, childId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final child = snapshot.data;
          if (child == null) {
            return const Center(
              child: Text('Data peserta didik tidak ditemukan'),
            );
          }

          return ParentChecklistScreen(child: child);
        },
      ),
    );
  }

  Future<dynamic> _getChildData(BuildContext context, String childId) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    // Pastikan data anak sudah diambil
    if (childProvider.children.isEmpty) {
      await childProvider.fetchChildren();
    }

    return childProvider.getChildById(childId);
  }
}
