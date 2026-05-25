import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/models/reward.dart';

void main() {
  group('Reward Model', () {
    test('fromFirestore should create a Reward object correctly', () {
      final data = {
        'title': 'Test Reward',
        'description': 'Test Description',
        'cost': 100,
        'status': 'available',
      };
      final reward = Reward.fromFirestore('id123', data);

      expect(reward.id, 'id123');
      expect(reward.title, 'Test Reward');
      expect(reward.description, 'Test Description');
      expect(reward.cost, 100);
      expect(reward.status, 'available');
    });

    test('toFirestore should return a correct map', () {
      final reward = Reward(
        id: 'id123',
        title: 'Test Reward',
        description: 'Test Description',
        cost: 100,
        status: 'pending',
      );
      final data = reward.toFirestore();

      expect(data['title'], 'Test Reward');
      expect(data['description'], 'Test Description');
      expect(data['cost'], 100);
      expect(data['status'], 'pending');
    });

    test('copyWith should create a modified copy', () {
      final reward = Reward(
        id: 'id123',
        title: 'Test Reward',
        description: 'Test Description',
        cost: 100,
      );
      final updated = reward.copyWith(status: 'redeemed', cost: 150);

      expect(updated.id, 'id123');
      expect(updated.status, 'redeemed');
      expect(updated.cost, 150);
      expect(updated.title, 'Test Reward');
    });
  });
}
