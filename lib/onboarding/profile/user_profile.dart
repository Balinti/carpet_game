import '../ef/ef_models.dart';

/// The signed-up player. [ageGroup] is derived from [age]: under 13 = kid.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final int age;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.createdAt,
  });

  AgeGroup get ageGroup => ageGroupForAge(age);

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'age': age,
        'ageGroup': ageGroup.name, // stored for queries; derived on read
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        uid: j['uid'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        age: (j['age'] as num).toInt(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.uid == uid &&
      other.name == name &&
      other.email == email &&
      other.age == age &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(uid, name, email, age, createdAt);
}
