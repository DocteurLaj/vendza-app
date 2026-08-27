import 'package:flutter/foundation.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';

UserModel emptyCurrentUser() {
  return UserModel(
    name: '',
    lastname: '',
    firstname: '',
    address: '',
    email: '',
    phoneNumber: '',
    urlimage: '',
  );
}

final currentUserStore = ValueNotifier<UserModel>(emptyCurrentUser());

void updateCurrentUser(UserModel user) {
  currentUserStore.value = user;
}

void clearCurrentUser() {
  currentUserStore.value = emptyCurrentUser();
}

void applyCurrentUserAvatar(String avatarUrl) {
  currentUserStore.value = currentUserStore.value.copyWith(
    urlimage: sanitizeAvatarUrl(avatarUrl),
  );
}

String sanitizeAvatarUrl(String? raw) {
  final value = (raw ?? '').trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return '';
}

bool isValidEmail(String email) {
  final trimmed = email.trim();
  return trimmed.isNotEmpty && trimmed.contains('@');
}
