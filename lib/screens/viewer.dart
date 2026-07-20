import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../task.dart';
import 'editor.dart';

class RecipeViewScreen extends StatelessWidget {
  final Task task;

  const RecipeViewScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.recipeName),
        
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeEditorScreen(
                      dbHelper: DatabaseHelper.instance,
                      task: task
                    ),
                  ),
                );

                if (result == true) {
                  Navigator.pop(context, true);
                }
              }

              if (value == 'delete') {
                await DatabaseHelper.instance.deleteTask(task.id!);

                Navigator.pop(context, true);
              }
            },

            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),

              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          )
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            sectionCard(
              context: context,
              title: 'ingredients',
              items: (task.ingredients ?? '')
                  .split('\n')
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),

            const SizedBox(height: 16),

            sectionCard(
              context: context,
              title: 'instructions',
              numbered: true,
              items: (task.instruction ?? '')
                  .split('\n')
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
          ],
        ),
      )
    );
  }
}

Widget sectionCard({
  required BuildContext context,
  required String title,
  required List<String> items,
  bool numbered = false,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          ...List.generate(items.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: numbered ? 30 : 20,
                    child: Center(
                      child: Text(
                        numbered ? '${index + 1}.' : '•',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(items[index]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}