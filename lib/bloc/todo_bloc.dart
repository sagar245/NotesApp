import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/todo.dart';
import '../services/firestore_services.dart';

// Events
abstract class TodoEvent {}

class LoadTodos extends TodoEvent {}

class AddTodo extends TodoEvent {
  final Todo todo;
  AddTodo(this.todo);
}

class UpdateTodo extends TodoEvent {
  final Todo todo;
  UpdateTodo(this.todo);
}

class DeleteTodo extends TodoEvent {
  final String id;
  DeleteTodo(this.id);
}

// States
abstract class TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  TodoLoaded(this.todos);
}

// Bloc
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final FirestoreService _firestoreService = FirestoreService();

  TodoBloc() : super(TodoLoading()) {
    on<LoadTodos>((event, emit) async {
      List<Todo> todos = await _firestoreService.getTodos();
      emit(TodoLoaded(todos));
    });

    on<AddTodo>((event, emit) async {
      await _firestoreService.addTodo(event.todo);
      List<Todo> todos = await _firestoreService.getTodos();
      emit(TodoLoaded(todos));
    });

    on<UpdateTodo>((event, emit) async {
      await _firestoreService.updateTodo(event.todo);
      List<Todo> todos = await _firestoreService.getTodos();
      emit(TodoLoaded(todos));
    });

    on<DeleteTodo>((event, emit) async {
      await _firestoreService.deleteTodo(event.id);
      List<Todo> todos = await _firestoreService.getTodos();
      emit(TodoLoaded(todos));
    });
  }
}
