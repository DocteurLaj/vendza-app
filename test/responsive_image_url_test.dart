import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/shared/widgets/media/responsive_image_url.dart';

void main() {
  test('keeps non-variant urls unchanged', () {
    expect(
      responsiveImageUrl(
        'https://cdn.example.com/users/a/product/photo.jpg',
        width: 80,
      ),
      'https://cdn.example.com/users/a/product/photo.jpg',
    );
  });

  test('chooses thumb variant for small image slots', () {
    expect(
      responsiveImageUrl(
        'https://cdn.example.com/users/a/product/image/card.webp',
        width: 56,
        devicePixelRatio: 2,
      ),
      'https://cdn.example.com/users/a/product/image/thumb.webp',
    );
  });

  test(
    'preserves original logo variant when large slot lacks generated sizes',
    () {
      const logo = 'https://media.example.com/users/a/logo/b/medium.webp';
      expect(responsiveImageUrl(logo, width: 420, devicePixelRatio: 2), logo);
    },
  );

  test('chooses detail variant for large image slots', () {
    expect(
      responsiveImageUrl(
        'https://cdn.example.com/users/a/product/image/card.webp',
        width: 520,
        devicePixelRatio: 2,
      ),
      'https://cdn.example.com/users/a/product/image/detail.webp',
    );
  });
}
