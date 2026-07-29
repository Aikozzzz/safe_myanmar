import 'package:mobile/features/sos/domain/sos_draft.dart';
import 'package:mobile/features/sos/domain/sos_draft_repository.dart';

final class FakeSosDraftRepository implements SosDraftRepository {
  List<SosDraft> drafts = [];
  Object? readError;
  Object? writeError;
  Object? clearError;
  int reads = 0;
  int writes = 0;
  int clears = 0;

  @override
  Future<List<SosDraft>> read() async {
    reads++;
    if (readError case final error?) throw error;
    return List.unmodifiable(drafts);
  }

  @override
  Future<void> write(List<SosDraft> value) async {
    writes++;
    if (writeError case final error?) throw error;
    drafts = List.unmodifiable(value);
  }

  @override
  Future<void> clear() async {
    clears++;
    if (clearError case final error?) throw error;
    drafts = [];
  }
}
