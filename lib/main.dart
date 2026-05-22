import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'task.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Task> tasks = [];
  final recipeNameController = TextEditingController();
  final ingredientsController = TextEditingController();
  final instructionController = TextEditingController();

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

  _addTask() async {
    if (recipeNameController.text.isEmpty) return;

    await dbHelper.insertTask(Task(
      recipeName: recipeNameController.text,
      ingredients: ingredientsController.text,
      instruction: instructionController.text,
      createdAt: DateTime.now(),
    ));

    recipeNameController.clear();
    ingredientsController.clear();
    instructionController.clear();
    _refreshTaskList();
  }

  _toggleTaskStatus(Task task) async {
    Task updatedTask = Task(
      id: task.id,
      recipeName: task.recipeName,
      ingredients: task.ingredients,
      instruction: task.instruction,
      isCompleted: !task.isCompleted,
      createdAt: task.createdAt,
    );

    await dbHelper.updateTask(updatedTask);
    _refreshTaskList();
  }

  _deleteTask(int id) async {
    await dbHelper.deleteTask(id);
    _refreshTaskList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('cookbook'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: recipeNameController,
                  decoration: InputDecoration(
                    labelText: 'name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: ingredientsController,
                  decoration: InputDecoration(
                    labelText: 'ingredients',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: instructionController,
                  decoration: InputDecoration(
                    labelText: 'instruction',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: _addTask,
                  child: Text('add recipe'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                Task task = tasks[index];
                return ListTile(
                  title: Text(
                    task.recipeName,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: task.ingredients != null
                      ? Text(task.ingredients!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          task.isCompleted
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        onPressed: () => _toggleTaskStatus(task),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTask(task.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}