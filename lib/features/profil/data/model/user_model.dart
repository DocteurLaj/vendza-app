import 'package:characters/characters.dart';

class UserModel {
  final int? userId;
  final String name;
  final String lastname;
  final String firstname;
  final String address;
  final String email;
  final String phoneNumber;
  final String urlimage;

  UserModel({
    this.userId,
    required this.name,
    required this.lastname,
    required this.firstname,
    required this.address,
    required this.email,
    required this.phoneNumber,
    required this.urlimage,
  });

  bool get hasRemoteAvatar {
    final value = urlimage.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      final emailPrefix = email.split('@').first.trim();
      final initial = _graphemeInitial(emailPrefix);
      return initial.isEmpty ? '?' : initial;
    }
    if (parts.length == 1) {
      final initial = _graphemeInitial(parts.first);
      return initial.isEmpty ? '?' : initial;
    }
    final first = _graphemeInitial(parts.first);
    final last = _graphemeInitial(parts.last);
    if (first.isEmpty && last.isEmpty) return '?';
    return '$first$last';
  }

  UserModel copyWith({
    int? userId,
    String? name,
    String? lastname,
    String? firstname,
    String? address,
    String? email,
    String? phoneNumber,
    String? urlimage,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      lastname: lastname ?? this.lastname,
      firstname: firstname ?? this.firstname,
      address: address ?? this.address,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      urlimage: urlimage ?? this.urlimage,
    );
  }
}

String _graphemeInitial(String value) {
  final chars = value.trim().characters;
  if (chars.isEmpty) return '';
  return chars.first.toUpperCase();
}
