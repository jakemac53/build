import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String name;
  final int age;
  final Sex sex;

  User(this.name, this.age, this.sex);

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);

  Map<String, Object?> toJson() => _$UserToJson(this);
}

enum Sex {
  male,
  female,
  nonBinary,
  other,
}
