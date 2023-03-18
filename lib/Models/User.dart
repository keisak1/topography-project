import 'Project.dart';

class User {
  final String name;
  final List<Project> projects;

  const User({
    required this.name,
    required this.projects
  });

  factory User.fromJson(Map<String, dynamic> json){
    final List<dynamic> projectsJson = json['projects'] ?? [];
    final List<Project> projects = projectsJson.map((e) => Project.fromJson(e)).toList();

    return User(
        name: json['name'],
        projects: projects
    );
  }
}