import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch Todos
  Future<List<Todo>> getTodos() async {
    QuerySnapshot snapshot = await _db.collection('todos').get();
    return snapshot.docs.map((doc) => Todo.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  // Add Todo
  Future<void> addTodo(Todo todo) async {
    await _db.collection('todos').doc(todo.id).set(todo.toMap());
  }

  // Update Todo
  Future<void> updateTodo(Todo todo) async {
    await _db.collection('todos').doc(todo.id).update(todo.toMap());
  }

  // Delete Todo
  Future<void> deleteTodo(String id) async {
    await _db.collection('todos').doc(id).delete();
  }
}
