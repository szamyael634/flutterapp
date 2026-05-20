import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/product_category.dart';
import '../../../core/providers/supabase.dart';
import '../models/admin_dashboard_data.dart';
import '../models/admin_dispute_record.dart';
import '../models/admin_operations_data.dart';
import '../models/admin_user_record.dart';
import '../models/seller_verification_review.dart';

class AdminRepository {
  const AdminRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<AdminDashboardData> fetchDashboard() async {
    final response = await _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'dashboard'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return AdminDashboardData.fromMap(data);
  }

  Future<List<AdminUserRecord>> fetchUsers() async {
    final response = await _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'list_users'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final rows = List<Map<String, dynamic>>.from(
      (data['users'] as List<dynamic>? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    return rows.map(AdminUserRecord.fromMap).toList();
  }

  Future<void> updateUserStatus({
    required String userId,
    required String approvalStatus,
    String reviewNotes = '',
  }) {
    return _supabase.functions.invoke(
      'admin-console',
      body: {
        'action': 'update_user_status',
        'user_id': userId,
        'approval_status': approvalStatus,
        'review_notes': reviewNotes,
      },
    );
  }

  Future<List<SellerVerificationReview>> fetchVerifications() async {
    final response = await _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'list_verifications'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final rows = List<Map<String, dynamic>>.from(
      (data['verifications'] as List<dynamic>? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    return rows.map(SellerVerificationReview.fromMap).toList();
  }

  Future<void> reviewVerification({
    required String documentId,
    required String verificationStatus,
    String reviewNotes = '',
  }) {
    return _supabase.functions.invoke(
      'admin-console',
      body: {
        'action': 'review_verification',
        'document_id': documentId,
        'verification_status': verificationStatus,
        'review_notes': reviewNotes,
      },
    );
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'list_categories'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final rows = List<Map<String, dynamic>>.from(
      (data['categories'] as List<dynamic>? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    return rows.map(ProductCategory.fromMap).toList();
  }

  Future<AdminOperationsData> fetchOperations() async {
    final response = await _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'operations'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return AdminOperationsData.fromMap(data);
  }

  Future<List<AdminDisputeRecord>> fetchDisputes() async {
    final response = await _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'list_disputes'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final rows = List<Map<String, dynamic>>.from(
      (data['disputes'] as List<dynamic>? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    return rows.map(AdminDisputeRecord.fromMap).toList();
  }

  Future<void> updateDisputeStatus({
    required String disputeId,
    required String status,
    required String resolutionNotes,
  }) {
    return _supabase.functions.invoke(
      'admin-console',
      body: {
        'action': 'update_dispute_status',
        'dispute_id': disputeId,
        'status': status,
        'resolution_notes': resolutionNotes,
      },
    );
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required String description,
    required bool isActive,
    required int sortOrder,
  }) {
    return _supabase.functions.invoke(
      'admin-console',
      body: {
        'action': 'save_category',
        'id': id,
        'name': name,
        'description': description,
        'is_active': isActive,
        'sort_order': sortOrder,
      },
    );
  }

  Future<void> toggleCategory({required String id, required bool isActive}) {
    return _supabase.functions.invoke(
      'admin-console',
      body: {'action': 'toggle_category', 'id': id, 'is_active': isActive},
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchDashboard();
});

final adminUsersProvider = FutureProvider<List<AdminUserRecord>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchUsers();
});

final adminVerificationsProvider =
    FutureProvider<List<SellerVerificationReview>>((ref) async {
      return ref.watch(adminRepositoryProvider).fetchVerifications();
    });

final adminCategoriesProvider = FutureProvider<List<ProductCategory>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).fetchCategories();
});

final adminOperationsProvider = FutureProvider<AdminOperationsData>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).fetchOperations();
});

final adminDisputesProvider = FutureProvider<List<AdminDisputeRecord>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).fetchDisputes();
});
