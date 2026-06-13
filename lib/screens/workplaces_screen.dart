import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:get/instance_manager.dart';
import '../models/workplace.dart';
import '../services/sync_service.dart';
import '../utils/translations.dart';

class WorkplacesScreen extends StatefulWidget {
  const WorkplacesScreen({super.key});

  @override
  State<WorkplacesScreen> createState() => _WorkplacesScreenState();
}

class _WorkplacesScreenState extends State<WorkplacesScreen> {
  final _nameCtrl = TextEditingController();

  Future<void> _addWorkplace() async {
    final val = _nameCtrl.text.trim();
    if (val.isNotEmpty) {
      final syncService = Get.find<SyncService>();
      final wp = Workplace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: val,
        updatedAt: DateTime.now().toIso8601String(),
        version: 1,
      );
      await syncService.addWorkplace(wp);
      _nameCtrl.clear();
    }
  }

  Future<void> _removeWorkplace(String id) async {
    final syncService = Get.find<SyncService>();
    await syncService.deleteWorkplace(id);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('workplaces_menu'.tr(context)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'workplace_name_hint'.tr(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addWorkplace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: GetBuilder<SyncService>(
              builder: (syncService) {
                final list = syncService.workplaces;
                return list.isEmpty
                    ? Center(
                        child: Text(
                          'empty_workplaces'.tr(context),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final wp = list[i];
                          return ListTile(
                            leading: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                            title: Text(wp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeWorkplace(wp.id),
                            ),
                          );
                        },
                      );
              }
            ),
          )
        ],
      ),
    );
  }
}
