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
        title: Text('cookbook'),
      ),

      
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          Task task = tasks[index];

          return ListTile(
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
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),

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