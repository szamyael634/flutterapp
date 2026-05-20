import 'package:flutter_test/flutter_test.dart';

import 'package:flutterapp/core/config/app_env.dart';

void main() {
  test('default app scheme is stable', () {
    expect(AppEnv.appScheme, isNotEmpty);
  });
}
