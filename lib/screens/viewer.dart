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
        title: Text("recipe"),
        
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
      
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.recipeName,
              style: TextStyle(fontSize: 24),
            ),

            SizedBox(height: 16),

            Text("Ingredients:"),
            Text(task.ingredients ?? ""),

            SizedBox(height: 16),

            Text("Instructions:"),
            Text(task.instruction ?? ""),
          ],
        ),
      ),
    );
  }
}