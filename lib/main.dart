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
                  builder: (_) => RecipeScreen(task: task),
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
              builder: (_) => AddRecipeScreen(
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


class AddRecipeScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const AddRecipeScreen({
    super.key,
    required this.dbHelper,
  });

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final recipeNameController = TextEditingController();
  final ingredientsController = TextEditingController();
  final instructionController = TextEditingController();

  Future<void> _addTask() async {
    if (recipeNameController.text.isEmpty) return;

    await widget.dbHelper.insertTask(
      Task(
        recipeName: recipeNameController.text,
        ingredients: ingredientsController.text,
        instruction: instructionController.text,
        createdAt: DateTime.now(),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('add recipe'),
      ),

      body: Padding(
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

            SizedBox(height: 8),

            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(
                labelText: 'ingredients',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 8),

            TextField(
              controller: instructionController,
              decoration: InputDecoration(
                labelText: 'instruction',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _addTask,
              child: Text('save'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeScreen extends StatelessWidget {
  final Task task;

  const RecipeScreen({
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
                    builder: (_) => EditRecipeScreen(task: task),
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

class EditRecipeScreen extends StatefulWidget {
  final Task task;

  const EditRecipeScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late TextEditingController recipeNameController;
  late TextEditingController ingredientsController;
  late TextEditingController instructionController;

  @override
  void initState() {
    super.initState();

    recipeNameController =
        TextEditingController(text: widget.task.recipeName);

    ingredientsController =
        TextEditingController(text: widget.task.ingredients);

    instructionController =
        TextEditingController(text: widget.task.instruction);
  }

  Future<void> _updateTask() async {
    Task updatedTask = Task(
      id: widget.task.id,
      recipeName: recipeNameController.text,
      ingredients: ingredientsController.text,
      instruction: instructionController.text,
      isCompleted: widget.task.isCompleted,
      createdAt: widget.task.createdAt,
    );

    await DatabaseHelper.instance.updateTask(updatedTask);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit recipe'),
      ),

      body: Padding(
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

            SizedBox(height: 8),

            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(
                labelText: 'ingredients',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 8),

            TextField(
              controller: instructionController,
              decoration: InputDecoration(
                labelText: 'instruction',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _updateTask,
              child: Text('save'),
            ),
          ],
        ),
      ),
    );
  }
}