import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/property/media_model.dart';
import 'package:zoneer_mobile/data/repositories/property/media_repository.dart';

final mediaViewmodelProvider = FutureProvider.family<List<MediaModel>, String>((ref, propertyId) async {
  final repository = ref.read(mediaRepositoryProvider);

  final media = await repository.getMediaByPropertyId(propertyId);

  return media;
});
