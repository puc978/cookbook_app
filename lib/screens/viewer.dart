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

  Future<void> _deleteRecipe(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('delete recipe'),
        content: const Text(
          'are you sure you want to delete this recipe?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await DatabaseHelper.instance.deleteTask(task.id!);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(      
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
                await _deleteRecipe(context);
              }
            },

            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text('edit'),
              ),

              PopupMenuItem(
                value: 'delete',
                child: Text('delete'),
              ),
            ],
          )
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                task.recipeName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

            const SizedBox(height: 16),

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
          const textStyle = TextStyle(fontSize: 16);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: numbered ? 28 : 20,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      numbered ? '${index + 1}.' : '•',
                      textAlign: TextAlign.center,
                      style: textStyle,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    items[index],
                    style: textStyle,
                  ),
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