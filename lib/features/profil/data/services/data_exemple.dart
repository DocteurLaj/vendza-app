import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';

UserModel get user => currentUserStore.value;
