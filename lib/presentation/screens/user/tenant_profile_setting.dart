import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/screens/inquiry/my_inquiries.dart';
import 'package:zoneer_mobile/presentation/screens/messaging/conversation_list_screen.dart';
import 'package:zoneer_mobile/presentation/screens/property/my_properties_screen.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';
import 'package:zoneer_mobile/presentation/screens/user/widgets/profile_auth_state.dart';
import 'package:zoneer_mobile/presentation/screens/user/tenant/edit_profile_screen.dart';
import 'package:zoneer_mobile/presentation/screens/user/widgets/action_row.dart';
import 'package:zoneer_mobile/presentation/screens/user/widgets/profile_header_card.dart';
import 'package:zoneer_mobile/presentation/screens/user/widgets/section_card.dart';
import 'package:zoneer_mobile/presentation/screens/user/schedule_visits.dart';
import 'package:zoneer_mobile/presentation/screens/wishlist/wishlist_view.dart';
import 'package:zoneer_mobile/shared/widgets/google_nav_bar.dart';

class TenantProfileSetting extends ConsumerWidget {
  const TenantProfileSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final authUser =
        authState.value?.session?.user ??
        Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      return const ProfileAuthState();
    }

    final userAsync = ref.watch(userProfileOrCreateProvider(authUser.id));

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
onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );

                    await ref.refresh(
                    userProfileOrCreateProvider(authUser.id).future,
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

              const SizedBox(height: 10),

              /// My Activity
              SectionCard(
                title: "My Activity",
                children: [
                  ActionRow(
                    icon: Icons.favorite,
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
                    icon: Icons.assessment,
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
                    icon: Icons.chat,
                    label: "Messages",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConversationListScreen(),
                        ),
                      );
                    },
                  ),
                  ActionRow(
                    icon: Icons.event,
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

              const SizedBox(height: 10),

              /// Logout
              SectionCard(
                title: "Account",
                children: [
ActionRow(
                    icon: Icons.logout_rounded,
                    label: "Logout",
                    textColor: AppColors.primary,
                    onTap: () async {
                      // Step 1: Confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Log out?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          content: const Text(
                            'Are you sure you want to sign out of Zoneer?',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text(
                                'Log Out',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true || !context.mounted) return;

                      // Step 2: Loading overlay
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => PopScope(
                          canPop: false,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Signing out...',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );

                      // Step 3: Sign out
                      bool shouldNavigate = false;
                      try {
                        await Supabase.instance.client.auth.signOut();
                        ref.invalidate(userByIdProvider);
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
