import 'package:flutter_test/flutter_test.dart';
import 'package:postern/presentation/files/files_model.dart';

void main() {
  test('fmtSize', () {
    expect(fmtSize(0), '0 B');
    expect(fmtSize(1023), '1023 B');
    expect(fmtSize(1536), '1.5 KB');
    expect(fmtSize(50 * 1024 * 1024), '50 MB');
  });
}
