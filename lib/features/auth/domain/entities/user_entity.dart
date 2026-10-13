import 'package:equatable/equatable.dart';

/// Pure domain entity representing a signed-in user.
/// No JSON, no framework dependencies.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.avatar,
  });

  final int id;
  final String email;
  final String name;
  final String avatar;

  @override
  List<Object?> get props => [id, email, name, avatar];
}
