import 'package:bear_tahan/utils/data_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes legacy subject and level identifiers', () {
    expect(DataContracts.normalizeSubjectId('en'), 'bi');
    expect(DataContracts.normalizeSubjectId('science'), 'sci');
    expect(DataContracts.normalizeLevelId('l2'), 'c1_l2');
    expect(DataContracts.normalizeLevelId('c2_l2'), 'c2_l2');
  });

  test('builds an exact question prefix without forcing chapter one', () {
    expect(DataContracts.levelPrefix('bi', 'c2_l3'), 'bi_c2_l3_');
    expect(DataContracts.levelPrefix('science', 'l1'), 'sci_c1_l1_');
  });
}
