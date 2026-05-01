// user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart'; // required for Hive type adapter

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password;

  UserModel({required this.name, required this.email, required this.password});
}
