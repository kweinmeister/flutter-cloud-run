import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';
import 'todo_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cloud Run Todo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          secondary: const Color(0xFF14B8A6),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
        ),
      ),
      home: const TodoListPage(),
    );
  }
}

sealed class TodoState {}

class TodoLoading extends TodoState {}

class TodoData extends TodoState {
  final List<TodoItem> todos;
  final String? nextPageToken;
  TodoData(this.todos, {this.nextPageToken});
}

class TodoError extends TodoState {
  final String message;
  TodoError(this.message);
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});
  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _client = TodoClient();
  TodoState _state = TodoLoading();
  final TextEditingController _controller = TextEditingController();
  bool _isLoadingMore = false;
  bool _isProcessing = false;

  List<TodoItem> get _todos => switch (_state) {
    TodoData(todos: final todos) => todos,
    _ => [],
  };

  String? get _nextPageToken => switch (_state) {
    TodoData(nextPageToken: final token) => token,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  Future<void> _fetchTodos({bool loadMore = false}) async {
    try {
      if (loadMore) {
        setState(() => _isLoadingMore = true);
      }

      final response = await _client.fetchTodos(
        pageToken: loadMore ? _nextPageToken : null,
      );

      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _state = TodoData([
            ..._todos,
            ...response.items,
          ], nextPageToken: response.nextPageToken);
          _isLoadingMore = false;
        } else {
          _state = TodoData(
            response.items,
            nextPageToken: response.nextPageToken,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = TodoError('Failed to fetch tasks');
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _runOptimistic({
    required VoidCallback action,
    required VoidCallback rollback,
    required Future<void> Function() apiCall,
    required String errorMessage,
  }) async {
    if (!mounted) return;

    // 1. Optimistic Update
    setState(action);

    try {
      // 2. Network Request
      await apiCall();
    } catch (e) {
      if (!mounted) return;
      // 3. Rollback on failure
      setState(rollback);
      context.showError(errorMessage);
    }
  }

  void _addTodo() async {
    if (_controller.text.isEmpty || _isProcessing) return;
    final text = _controller.text;
    _controller.clear();
    setState(() => _isProcessing = true);

    final newItem = TodoItem(
      id: const Uuid().v4(),
      title: text,
      createdAt: DateTime.now(),
    );

    await _runOptimistic(
      action: () => _todos.add(newItem),
      rollback: () {
        _todos.remove(newItem);
        _isProcessing = false;
      },
      apiCall: () async {
        final created = await _client.createTodo(newItem);
        if (!mounted) return;
        setState(() {
          final index = _todos.indexWhere((t) => t.id == newItem.id);
          if (index != -1) _todos[index] = created;
          _isProcessing = false;
        });
      },
      errorMessage: 'Could not add task',
    );
  }

  void _updateTodo(TodoItem item, {String? title, bool? isDone}) async {
    final updated = item.copyWith(title: title, isDone: isDone);

    await _runOptimistic(
      action: () {
        final index = _todos.indexWhere((t) => t.id == item.id);
        if (index != -1) _todos[index] = updated;
      },
      rollback: () {
        final index = _todos.indexWhere((t) => t.id == item.id);
        if (index != -1) _todos[index] = item;
      },
      apiCall: () => _client.updateTodo(updated),
      errorMessage: 'Failed to update task',
    );
  }

  void _deleteTodo(String id) async {
    final original = _todos.firstWhere((t) => t.id == id);
    final index = _todos.indexOf(original);

    await _runOptimistic(
      action: () => _todos.removeAt(index),
      rollback: () => _todos.insert(index, original),
      apiCall: () => _client.deleteTodo(id),
      errorMessage: 'Failed to delete task',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: UiConstants.maxContentWidth,
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'My Tasks',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  key: const Key('newTodoInput'),
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    prefixIcon: Icon(
                      Icons.add_task_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton.filled(
                        onPressed: _addTodo,
                        icon: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _addTodo(),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: switch (_state) {
                  TodoLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  TodoError(message: final msg) => Center(child: Text(msg)),
                  TodoData(todos: final todos) =>
                    todos.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  itemCount: todos.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final todo = todos[index];
                                    return TodoTile(
                                      key: ValueKey(todo.id),
                                      item: todo,
                                      onToggle: () => _updateTodo(
                                        todo,
                                        isDone: !todo.isDone,
                                      ),
                                      onSave: (newTitle) =>
                                          _updateTodo(todo, title: newTitle),
                                      onDelete: () => _deleteTodo(todo.id),
                                    );
                                  },
                                ),
                              ),
                              if (_nextPageToken != null)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton.icon(
                                          onPressed: () =>
                                              _fetchTodos(loadMore: true),
                                          icon: const Icon(Icons.expand_more),
                                          label: const Text('Load More'),
                                        ),
                                ),
                            ],
                          ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 64,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          'All caught up!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

extension BuildContextX on BuildContext {
  void showError(String message) => ScaffoldMessenger.of(this).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class TodoTile extends StatefulWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final void Function(String) onSave;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  bool _isHovered = false;
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.item.title);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _submitEdit() {
    if (_editController.text.isNotEmpty &&
        _editController.text != widget.item.title) {
      widget.onSave(_editController.text);
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: UiConstants.hoverAnimationDuration,
        curve: Curves.easeInOut,
        transform: _isHovered
            ? Matrix4.translationValues(4, 0, 0)
            : Matrix4.identity(),
        child: Dismissible(
          key: ValueKey(widget.item.id),
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            widget.onDelete();
          },
          background: _buildDismissBackground(Alignment.centerLeft),
          secondaryBackground: _buildDismissBackground(Alignment.centerRight),
          child: Card(
            elevation: _isHovered ? 4 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _isHovered
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2)
                    : Colors.grey[100]!,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  shape: const CircleBorder(),
                  value: widget.item.isDone,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (_) {
                    if (!widget.item.isDone) HapticFeedback.lightImpact();
                    widget.onToggle();
                  },
                ),
              ),
              title: _isEditing
                  ? TextField(
                      controller: _editController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                      onSubmitted: (_) => _submitEdit(),
                      onTapOutside: (_) => _submitEdit(),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: GoogleFonts.inter().fontFamily,
                          decoration: widget.item.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: widget.item.isDone
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontWeight: widget.item.isDone
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                        child: Text(widget.item.title),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}
