import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../task.dart';

class RecipeEditorScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Task? task;

  const RecipeEditorScreen({
    super.key,
    required this.dbHelper,
    this.task,
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}


class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
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
