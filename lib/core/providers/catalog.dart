import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_category.dart';
import 'supabase.dart';

final publicCategoriesProvider = FutureProvider<List<ProductCategory>>((
  ref,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('categories')
      .select()
      .eq('is_active', true)
      .order('sort_order')
      .order('name');

  return rows
      .map<ProductCategory>(
        (row) => ProductCategory.fromMap(Map<String, dynamic>.from(row)),
      )
      .toList();
});
