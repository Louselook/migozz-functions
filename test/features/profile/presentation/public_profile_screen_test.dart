import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/profile/presentation/public_profile_screen.dart';

void main() {
  testWidgets('PublicProfileScreen renders correctly', (
    WidgetTester tester,
  ) async {
    // Create a mock UserDTO
    final user = UserDTO(
      email: 'test@example.com',
      lang: 'en',
      displayName: 'Test User',
      username: 'testuser',
      location: LocationDTO(
        country: 'US',
        state: 'CA',
        city: 'San Francisco',
        lat: 37.7749,
        lng: -122.4194,
      ),
      bio: 'This is a test bio',
      socialEcosystem: [
        {
          'instagram': {'url': 'https://instagram.com/test', 'followers': 1000},
        },
        {
          'twitter': {'url': 'https://twitter.com/test', 'followers': 500},
        },
      ],
    );

    // Pump the widget
    await tester.pumpWidget(MaterialApp(home: PublicProfileScreen(user: user)));

    // Verify critical elements are present
    expect(find.text('@testuser'), findsOneWidget); // Display name
    expect(find.text('Test User'), findsOneWidget); // Name
    expect(find.text('Download Migos App'), findsOneWidget); // CTA Button

    // Verify social rail exists (by finding icons or structure)
    // Detailed checks might require more setup for SVGs depending on implementation
  });
}
