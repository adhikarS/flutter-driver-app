class User {
  final String username;

  const User({required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(username: json['username'] as String);
  }

  Map<String, dynamic> toJson() => {'username': username};
}