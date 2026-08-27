import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/profil/data/services/profile_api_service.dart';
import 'package:vendza/features/profil/presantation/widget/avatar_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel>(
      valueListenable: currentUserStore,
      builder: (context, user, _) {
        final fullName = "${user.firstname} ${user.lastname}".trim();

        return Scaffold(
          backgroundColor: AppColors.appBackground(context),
          appBar: AppBar(
            backgroundColor: AppColors.appBackground(context),
            foregroundColor: AppColors.textPrimary(context),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Mon profil",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                ResponsiveContent(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileIdentityCard(
                        name: fullName.isEmpty ? user.name : fullName,
                        email: user.email,
                        imageUrl: user.urlimage,
                        onEdit: () => _showEditProfileSheet(context, user),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: "Informations"),
                      const SizedBox(height: 8),
                      _ProfileInfoTile(
                        icon: Icons.person_outline,
                        title: "Nom",
                        value: user.name,
                      ),
                      const SizedBox(height: 10),
                      _ProfileInfoTile(
                        icon: Icons.badge_outlined,
                        title: "Prénom et postnom",
                        value: fullName.isEmpty ? "Non renseigné" : fullName,
                      ),
                      const SizedBox(height: 10),
                      _ProfileInfoTile(
                        icon: Icons.email_outlined,
                        title: "Email",
                        value: user.email,
                      ),
                      const SizedBox(height: 10),
                      _ProfileInfoTile(
                        icon: Icons.phone_outlined,
                        title: "Numéro de téléphone",
                        value: user.phoneNumber,
                      ),
                      const SizedBox(height: 10),
                      _ProfileInfoTile(
                        icon: Icons.location_on_outlined,
                        title: "Adresse",
                        value: user.address,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showEditProfileSheet(BuildContext context, UserModel user) {
  final nameController = TextEditingController(text: user.name);
  final firstnameController = TextEditingController(text: user.firstname);
  final lastnameController = TextEditingController(text: user.lastname);
  final emailController = TextEditingController(text: user.email);
  final phoneController = TextEditingController(text: user.phoneNumber);
  final addressController = TextEditingController(text: user.address);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Modifier le profil",
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _EditField(label: "Nom", controller: nameController),
              _EditField(label: "Prénom", controller: firstnameController),
              _EditField(label: "Postnom", controller: lastnameController),
              _EditField(label: "Email", controller: emailController),
              _EditField(label: "Téléphone", controller: phoneController),
              _EditField(label: "Adresse", controller: addressController),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (!isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Veuillez entrer une adresse email valide',
                        ),
                      ),
                    );
                    return;
                  }

                  final fullName =
                      '${firstnameController.text.trim()} ${lastnameController.text.trim()}'
                          .trim();
                  final displayName = nameController.text.trim().isEmpty
                      ? fullName
                      : nameController.text.trim();

                  try {
                    final profileApi = ProfileApiService();
                    await profileApi.updateFullName(displayName);
                    await profileApi.updatePhone(phoneController.text.trim());
                    if (addressController.text.trim().isNotEmpty) {
                      await profileApi.updateAddress(
                        city: addressController.text.trim(),
                      );
                    }

                    updateCurrentUser(
                      UserModel(
                        userId: user.userId,
                        name: displayName,
                        firstname: firstnameController.text.trim(),
                        lastname: lastnameController.text.trim(),
                        email: email,
                        phoneNumber: phoneController.text.trim(),
                        address: addressController.text.trim(),
                        urlimage: user.urlimage,
                      ),
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil mis à jour')),
                      );
                    }
                  } on Object catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    nameController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
  });
}

class _EditField extends StatelessWidget {
  const _EditField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.softSurface(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String imageUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          AvatarWidget(
            name: name,
            email: email,
            urlimage: imageUrl,
            editable: true,
            showIdentity: false,
            showEditLabel: false,
            radius: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.accent(context).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.accent(context),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary(context),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.accent(context), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? "Non renseigné" : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
