import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../models/employee.dart';
import '../models/absence.dart';

class AbsenceListScreen extends StatelessWidget {
  const AbsenceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة الغيابات'),
          backgroundColor: const Color(0xFF2563eb),
        ),
        body: Consumer<SyncService>(
          builder: (context, syncService, child) {
            final absentEmployees = syncService.employees.where((e) => e.absence != null).toList();

            if (absentEmployees.isEmpty) {
              return const Center(child: Text('✅ لا توجد غيابات مسجلة'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: absentEmployees.length,
              itemBuilder: (context, index) {
                final employee = absentEmployees[index];
                final ab = employee.absence!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(ab.type, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        Text('البدء: ${ab.startDate ?? "--"} · التحاق: ${ab.returnDate ?? "--"}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => syncService.archiveAbsence(employee.reg),
                                icon: const Icon(Icons.archive_outlined, size: 18),
                                label: const Text('أرشفة'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => syncService.removeAbsence(employee.reg),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('حذف'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red, elevation: 0),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأرشيف'),
          backgroundColor: Colors.blueGrey,
        ),
        body: Consumer<SyncService>(
          builder: (context, syncService, child) {
            final allArchived = <Map<String, dynamic>>[];
            for (var e in syncService.employees) {
              for (int i = 0; i < e.archivedAbsences.length; i++) {
                allArchived.add({
                  'employee': e,
                  'absence': e.archivedAbsences[i],
                  'index': i,
                });
              }
            }

            if (allArchived.isEmpty) {
              return const Center(child: Text('🗃️ الأرشيف فارغ'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allArchived.length,
              itemBuilder: (context, index) {
                final item = allArchived[allArchived.length - 1 - index]; // Reverse
                final Employee e = item['employee'];
                final Absence ab = item['absence'];
                final int archIdx = item['index'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${ab.type} · من ${ab.startDate ?? "--"} إلى ${ab.returnDate ?? "--"}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => syncService.deleteFromArchive(e.reg, archIdx),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
