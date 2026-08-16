import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../task.dart';
import 'viewer.dart';
import 'editor.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  Future<void> _refreshTaskList() async {
    final taskList = await dbHelper.getAllTasks();

    taskList.sort(
      (a, b) => a.recipeName.toLowerCase().compareTo(
        b.recipeName.toLowerCase(),
      ),
    );

    if (!mounted) return;

    setState(() {
      tasks = taskList;
    });
  }

  Future<void> _importDatabase() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('import database'),
        content: const Text(
                      'new recipes will be added to your cookbook. existing recipes will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'import'),
            child: const Text('import'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'import') {
      await dbHelper.importDatabase();

      if (!mounted) return;

      _refreshTaskList();
    }
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
                dbHelper.exportDatabase();
              }

              if (value == 'import') {
                _importDatabase();
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