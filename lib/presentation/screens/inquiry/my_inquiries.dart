import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/data/models/inquiry/enums/inquiry_status.dart';
import 'package:zoneer_mobile/presentation/viewmodels/inquiry/inquiry_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/inquiry/inquiry_detail.dart';
import 'package:zoneer_mobile/presentation/screens/inquiry/widgets/inquiry_card.dart';

class MyInquiries extends ConsumerStatefulWidget {
  const MyInquiries({super.key});

  @override
  ConsumerState<MyInquiries> createState() => _MyInquiriesState();
}

class _MyInquiriesState extends ConsumerState<MyInquiries> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        ref
            .read(inquiriesViewModelProvider.notifier)
            .loadUserInquiries(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inquiriesState = ref.watch(inquiriesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Inquiries"),
        centerTitle: true,
      ),
      body: inquiriesState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),

        error: (e, _) =>
            Center(child: Text("Error: ${e.toString()}")),

        data: (inquiries) {
          final pending = inquiries
            .where((i) =>
              i.status == InquiryStatus.newStatus ||
              i.status == InquiryStatus.read)
            .toList();

          if (pending.isEmpty) {
            return const Center(
              child: Text("You have no pending inquiries."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final inquiry = pending[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InquiryDetail(inquiry: inquiry),
                    ),
                  );
                },
                child: InquiryCard(inquiry: inquiry)
              );
            },
          );
        },
      ),
    );
  }
}
