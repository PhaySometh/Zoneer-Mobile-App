import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/features/inquiry/views/my_inquiries.dart';
import 'package:zoneer_mobile/features/property/views/my_properties_screen.dart';
import 'package:zoneer_mobile/features/user/viewmodels/user_provider.dart';
import 'package:zoneer_mobile/features/user/views/auth/auth_required_screen.dart';
import 'package:zoneer_mobile/features/user/views/tenant/edit_profile_screen.dart';
import 'package:zoneer_mobile/features/user/widgets/action_row.dart';
import 'package:zoneer_mobile/features/user/widgets/profile_header_card.dart';
import 'package:zoneer_mobile/features/user/widgets/section_card.dart';
import 'package:zoneer_mobile/features/user/views/schedule_visits.dart';
import 'package:zoneer_mobile/features/wishlist/views/wishlist_view.dart';
import 'package:zoneer_mobile/shared/widgets/google_nav_bar.dart';

class TenantProfileSetting extends ConsumerWidget {
  const TenantProfileSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      return const AuthRequiredScreen();
    }

    final userAsync = ref.watch(userByIdProvider(authUser.id));

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (user) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ProfileHeaderCard(
                user: user,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                onMyProperties: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyPropertiesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// My Activity
              SectionCard(
                title: "My Activity",
                children: [
                  ActionRow(
                    icon: Icons.favorite_border,
                    label: "Saved Properties",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishlistView(),
                        ),
                      );
                    },
                  ),
                  ActionRow(
                    icon: Icons.assignment_outlined,
                    label: "My Applications",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyInquiries(),
                        ),
                      );
                    },
                  ),
                  ActionRow(
                    icon: Icons.chat_bubble_outline,
                    label: "Messages",
                    onTap: () {},
                  ),
                  ActionRow(
                    icon: Icons.event_outlined,
                    label: "Scheduled Visits",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleVisits(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Logout
              SectionCard(
                title: "Account",
                children: [
                  ActionRow(
                    icon: Icons.logout,
                    label: "Logout",
                    textColor: Colors.red,
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      bool shouldNavigate = false;
                      try {
                        await Supabase.instance.client.auth.signOut();
                        shouldNavigate = true;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logout failed. Please try again.'),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          if (shouldNavigate) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GoogleNavBar(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
