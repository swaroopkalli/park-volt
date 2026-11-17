import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemoUser {
  const DemoUser(this.id, this.name, this.role);
  final String id;
  final String name;
  final String role;
  bool get isAdmin => role == 'ADMIN';
}

const demoUsers = [
  DemoUser('student1', 'Student 1', 'STUDENT'),
  DemoUser('student2', 'Student 2', 'STUDENT'),
  DemoUser('admin', 'Admin', 'ADMIN'),
];

class UserNotifier extends Notifier<DemoUser?> {
  @override
  DemoUser? build() => null;
  void login(DemoUser u) => state = u;
  void logout() => state = null;
}

final userProvider = NotifierProvider<UserNotifier, DemoUser?>(UserNotifier.new);
