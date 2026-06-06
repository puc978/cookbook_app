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

class RecipeForm extends StatelessWidget {
  final TextEditingController recipeNameController;
  final Widget ingredientsWidget;
  final Widget instructionsWidget;
  final VoidCallback onSave;

  const RecipeForm({
    super.key,
    required this.recipeNameController,
    required this.ingredientsWidget,
    required this.instructionsWidget,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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

          ingredientsWidget,

          SizedBox(height: 8),

          instructionsWidget,

          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: onSave,
            child: Text('save'),
          ),
        ],
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

class DynamicTextFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final String label;

  const DynamicTextFields({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        controllers.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: controllers[index],
            decoration: InputDecoration(
              labelText: index == 0 ? label : null,
              border: const OutlineInputBorder(),

              suffixIcon: index == controllers.length - 1
                  ? IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final recipeNameController = TextEditingController();

  List<TextEditingController> ingredientsControllers = [
    TextEditingController(),
  ];

  List<TextEditingController> instructionControllers = [
    TextEditingController(),
  ];

  void _addIngredientField() {
    setState(() {
      ingredientsControllers.add(TextEditingController());
    });
  }

  void _addInstructionField() {
    setState(() {
      instructionControllers.add(TextEditingController());
    });
  }

  Future<void> _addTask() async {
    if (recipeNameController.text.isEmpty) return;

    await widget.dbHelper.insertTask(
      Task(
        recipeName: recipeNameController.text,
        ingredients: ingredientsControllers
            .map((e) => e.text)
            .where((e) => e.isNotEmpty)
            .join('\n'),
        instruction: instructionControllers
            .map((e) => e.text)
            .where((e) => e.isNotEmpty)
            .join('\n'),
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
      
      body: RecipeForm(
        recipeNameController: recipeNameController,

        ingredientsWidget: DynamicTextFields(
          label: 'ingredients',
          controllers: ingredientsControllers,
          onAdd: _addIngredientField,
        ),

        instructionsWidget: DynamicTextFields(
          label: 'instructions',
          controllers: instructionControllers,
          onAdd: _addInstructionField,
        ),

        onSave: _addTask,
      )
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
  late List<TextEditingController> ingredientsControllers;
  late List<TextEditingController> instructionControllers;

  @override
  void initState() {
    super.initState();

    recipeNameController =
        TextEditingController(text: widget.task.recipeName);

    ingredientsControllers =
        (widget.task.ingredients ?? '')
            .split('\n')
            .map((e) => TextEditingController(text: e))
            .toList();

    instructionControllers =
        (widget.task.instruction ?? '')
            .split('\n')
            .map((e) => TextEditingController(text: e))
            .toList();

    if (ingredientsControllers.isEmpty) {
      ingredientsControllers.add(TextEditingController());
    }

    if (instructionControllers.isEmpty) {
      instructionControllers.add(TextEditingController());
    }
  }

  void _addIngredientField() {
    setState(() {
      ingredientsControllers.add(TextEditingController());
    });
  }

  void _addInstructionField() {
    setState(() {
      instructionControllers.add(TextEditingController());
    });
  }

  Future<void> _updateTask() async {
    Task updatedTask = Task(
      id: widget.task.id,
      recipeName: recipeNameController.text,
      ingredients: ingredientsControllers
        .map((e) => e.text)
        .where((e) => e.isNotEmpty)
        .join('\n'),

      instruction: instructionControllers
        .map((e) => e.text)
        .where((e) => e.isNotEmpty)
        .join('\n'),
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

      body: RecipeForm(
        recipeNameController: recipeNameController, 
        ingredientsWidget: DynamicTextFields(
        label: 'ingredients',
          controllers: ingredientsControllers,
          onAdd: _addIngredientField,
        ),

        instructionsWidget: DynamicTextFields(
          label: 'instructions',
          controllers: instructionControllers,
          onAdd: _addInstructionField,
        ),
        onSave: _updateTask)
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