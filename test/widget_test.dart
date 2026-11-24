import 'package:projet_tp/api_client.dart';
import 'package:projet_tp/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves photo URLs against the API base URL', () {
    final baseUri = Uri.parse(apiBaseUrl);
    final photoUri = resolvePhotoUri('/uploads/photo.jpg');
    final basePath = baseUri.path.replaceFirst(RegExp(r'/+$'), '');

    expect(photoUri.scheme, baseUri.scheme);
    expect(photoUri.authority, baseUri.authority);
    expect(photoUri.path, '$basePath/uploads/photo.jpg');
    expect(
      resolvePhotoUri('https://cdn.example.com/photo.jpg').toString(),
      'https://cdn.example.com/photo.jpg',
    );
  });

  testWidgets('shows the sign-in screen and opens registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MonCvApp());

    expect(find.text('Mon CV & Famille'), findsNothing);
    expect(
      find.text(
        'Votre profil, vos proches et vos étudiants,\nréunis au même endroit.',
      ),
      findsNothing,
    );
    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsWidgets);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
  });
}
