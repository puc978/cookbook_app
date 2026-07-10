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
  late List<FocusNode> ingredientFocusNodes;
  late List<FocusNode> instructionFocusNodes;

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

    ingredientFocusNodes = List.generate(
      ingredientsControllers.length,
      (_) => FocusNode(),
    );

    if (instructionControllers.isEmpty) {
      instructionControllers.add(TextEditingController());
    }

    instructionFocusNodes = List.generate(
      instructionControllers.length,
      (_) => FocusNode(),
    );
  }

  void _addIngredientField() {
    if (ingredientsControllers.last.text.trim().isEmpty) {
      return;
    }

    final controller = TextEditingController();
    final focusNode = FocusNode();

    setState(() {
      ingredientsControllers.add(controller);
      ingredientFocusNodes.add(focusNode);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void _addInstructionField() {
    if (instructionControllers.last.text.trim().isEmpty) {
      return;
    }

    final controller = TextEditingController();
    final focusNode = FocusNode();

    setState(() {
      instructionControllers.add(controller);
      instructionFocusNodes.add(focusNode);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
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

  void _reorderIngredients(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }

    setState(() {
      final controller = ingredientsControllers.removeAt(oldIndex);
      ingredientsControllers.insert(newIndex, controller);

      final focusNode = ingredientFocusNodes.removeAt(oldIndex);
      ingredientFocusNodes.insert(newIndex, focusNode);
    });
  }

  void _reorderInstructions(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex--;
    }

    setState(() {
      final controller = instructionControllers.removeAt(oldIndex);
      instructionControllers.insert(newIndex, controller);

      final focusNode = instructionFocusNodes.removeAt(oldIndex);
      instructionFocusNodes.insert(newIndex, focusNode);
    });
  }

  void _removeIngredientField(int index) {
    if (ingredientsControllers.length <= 1) return;

    setState(() {
      ingredientsControllers[index].dispose();
      ingredientFocusNodes[index].dispose();

      ingredientsControllers.removeAt(index);
      ingredientFocusNodes.removeAt(index);
    });
  }

  void _removeInstructionField(int index) {
    if (instructionControllers.length <= 1) return;

    setState(() {
      instructionControllers[index].dispose();
      instructionFocusNodes[index].dispose();

      instructionControllers.removeAt(index);
      instructionFocusNodes.removeAt(index);
    });
  }

  @override
  void dispose() {
    recipeNameController.dispose();

    for (final c in ingredientsControllers) {
      c.dispose();
    }
    for (final c in instructionControllers) {
      c.dispose();
    }

    for (final f in ingredientFocusNodes) {
      f.dispose();
    }
    for (final f in instructionFocusNodes) {
      f.dispose();
    }

    super.dispose();
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
          focusNodes: ingredientFocusNodes,
          onAdd: _addIngredientField,
          onRemove: _removeIngredientField,
          onReorder: _reorderIngredients,
          numbered: false,
        ),

        instructionsWidget: DynamicTextFields(
          label: 'instructions',
          controllers: instructionControllers,
          focusNodes: instructionFocusNodes,
          onAdd: _addInstructionField,
          onRemove: _removeInstructionField,
          onReorder: _reorderInstructions,
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
  final List<FocusNode> focusNodes;
  final VoidCallback onAdd;
  final Function(int index) onRemove;
  final ReorderCallback onReorder;
  final String label;
  final bool numbered;

  const DynamicTextFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    required this.label,
    this.numbered = false,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      itemCount: controllers.length,
      itemBuilder: (context, index) {
        return Padding(
          key: ObjectKey(controllers[index]),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: numbered ? 30 : 20,
                child: Center(
                  child: Text(
                    numbered ? '${index + 1}.' : '•',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            
              Expanded(
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'write text...',
                    border: InputBorder.none,
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
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_indicator),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
