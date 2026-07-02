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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),

      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'recipe name:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          TextField(
            controller: recipeNameController,
            decoration: InputDecoration(
              hintText: 'write text...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: 14),
            ),
          ),

          SizedBox(height: 8),

          const SizedBox(height: 24),
          
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ingredients:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          ingredientsWidget,

          const SizedBox(height: 24),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

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
  final Task? task;

  const AddRecipeScreen({
    super.key,
    required this.dbHelper,
    this.task,
  });

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class DynamicTextFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final Function(int index) onRemove;
  final String label;
  final bool numbered;

  const DynamicTextFields({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.label,
    this.numbered = false,
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
              hintText: 'write text...',
              border: InputBorder.none,
              prefixText: numbered ? '${index + 1}. ': '• ',

              suffixIcon: index == controllers.length - 1
                  ? IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                    )
                  : IconButton(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.delete),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  late TextEditingController recipeNameController;
  late List<TextEditingController> ingredientsControllers;
  late List<TextEditingController> instructionControllers;

  @override
  void initState() {
    super.initState();

    recipeNameController = TextEditingController(
      text: widget.task?.recipeName ?? '',
    );

    ingredientsControllers =
        (widget.task?.ingredients ?? '')
            .split('\n')
            .where((e) => e.isNotEmpty)
            .map((e) => TextEditingController(text: e))
            .toList();

    instructionControllers =
        (widget.task?.instruction ?? '')
            .split('\n')
            .where((e) => e.isNotEmpty)
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
    if (ingredientsControllers.last.text.trim().isEmpty) {
      return;
    }

    setState(() {
      ingredientsControllers.add(TextEditingController());
    });
  }

  void _addInstructionField() {
    if (instructionControllers.last.text.trim().isEmpty) {
      return;
    }

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

    Navigator.pop(context, true);
  }

  Future<void> _updateTask() async {
    Task updatedTask = Task(
      id: widget.task!.id,
      recipeName: recipeNameController.text,
      ingredients: ingredientsControllers
          .map((e) => e.text)
          .where((e) => e.isNotEmpty)
          .join('\n'),
      instruction: instructionControllers
          .map((e) => e.text)
          .where((e) => e.isNotEmpty)
          .join('\n'),
      isCompleted: widget.task!.isCompleted,
      createdAt: widget.task!.createdAt,
    );

    await widget.dbHelper.updateTask(updatedTask);

    Navigator.pop(context, true);
  }

  void _removeIngredientField(int index) {
    if (ingredientsControllers.length <= 1) return;

    setState(() {
      ingredientsControllers[index].dispose();
      ingredientsControllers.removeAt(index);
    });
  }

  void _removeInstructionField(int index) {
    if (instructionControllers.length <= 1) return;

    setState(() {
      instructionControllers[index].dispose();
      instructionControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.task == null
              ? "add recipe"
              : "edit recipe",
        ),
      ),
      
      body: RecipeForm(
        recipeNameController: recipeNameController,
        ingredientsWidget: DynamicTextFields(
        label: 'ingredients',
          controllers: ingredientsControllers,
          onAdd: _addIngredientField,
          onRemove: _removeIngredientField,
          numbered: false,
        ),

        instructionsWidget: DynamicTextFields(
          label: 'instructions',
          controllers: instructionControllers,
          onAdd: _addInstructionField,
          onRemove: _removeInstructionField,
          numbered: true,
        ),
        onSave: widget.task == null
              ? _addTask
              : _updateTask)
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
                    builder: (_) => AddRecipeScreen(
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