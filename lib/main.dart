import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Notes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> todos = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
    _scrollController.addListener(_scrollListener);
  }

  /// Scroll listener to fetch more items when reaching the last item
  void _scrollListener() {
    if (!isLoading &&
        hasMore &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 &&
        todos.length >= limit) {
      _fetchTodos();
    }
  }

  /// Fetch todos with pagination
  Future<void> _fetchTodos() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    Query query = _firestore
        .collection('todos')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          lastDocument = querySnapshot.docs.last;
          todos.addAll(querySnapshot.docs);
        });
      } else {
        setState(() {
          hasMore = false; // No more data available
        });
      }
    } catch (e) {
      print("Error fetching todos: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _addTodo() async {
    if (_titleController.text.isNotEmpty) {
      await _firestore.collection('todos').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      _descriptionController.clear();
      _refreshList();
    }
  }

  void _deleteTodo(String id) async {
    await _firestore.collection('todos').doc(id).delete();
    _refreshList();
  }

  void _editTodo(String id, String title, String description) {
    _titleController.text = title;
    _descriptionController.text = description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit To-Do"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('todos').doc(id).update({
                'title': _titleController.text,
                'description': _descriptionController.text,
              });
              Navigator.pop(context);
              _refreshList();
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Refresh the list after adding, editing, or deleting a todo
  void _refreshList() {
    setState(() {
      todos.clear();
      lastDocument = null;
      hasMore = true;
    });
    _fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("To-Do List")),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: todos.length + (isLoading && todos.length >= limit ? 1 : 0), // Show loader only if items >= 10
        itemBuilder: (context, index) {
          if (index == todos.length) {
            return hasMore
                ? Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
                : SizedBox();
          }
          var todo = todos[index];
          return ListTile(
            title: Text(todo['title']),
            subtitle: Text(todo['description'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editTodo(todo.id, todo['title'], todo['description']),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTodo(todo.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Add To-Do"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
                  TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    _addTodo();
                    Navigator.pop(context);
                  },
                  child: Text("Add"),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
