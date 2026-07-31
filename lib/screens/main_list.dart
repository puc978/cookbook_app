import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../task.dart';
import 'viewer.dart';
import 'editor.dart';

class RecipeListScreen extends StatefulWidget {
  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  _refreshTaskList() async {
    List<Task> taskList = await dbHelper.getAllTasks();
    setState(() {
      tasks = taskList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('cookbook'),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export') {
                await dbHelper.exportDatabase();
              }

              if (value == 'import') {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('import database'),
                    content: const Text(
                      'replace old recipes or merge data?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, 'replace'),
                        child: const Text('replace'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'merge'),
                        child: const Text('merge'),
                      ),
                    ],
                  ),
                );

                if (result == 'merge') {
                  await dbHelper.importDatabase(merge: true);
                  _refreshTaskList();
                }

                if (result == 'replace') {
                  await dbHelper.importDatabase(merge: false);
                  _refreshTaskList();
                }
              }
            },

            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'import',
                child: Text('import database'),
              ),

              PopupMenuItem(
                value: 'export',
                child: Text('export database'),
              ),
            ],
          ),
        ],
      ),

      
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          Task task = tasks[index];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.0,
              ),
            ),
            elevation: 0,
            child: ListTile(
              title: Text(task.recipeName),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeViewScreen(task: task),
                  ),
                );
              
                if (result == true) {
                  _refreshTaskList();
                }
              },
            )
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        
        child: Icon(
          Icons.add,
          color: Theme.of(context).scaffoldBackgroundColor
        ),

        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeEditorScreen(
                dbHelper: dbHelper,
              ),
            ),
          );

          _refreshTaskList();
        },
      ),
      );
  }
}