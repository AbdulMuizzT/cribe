import '../models/models.dart';

/// Generates the Heritage Passport's "making process", "artisan story" and
/// authenticity ID from existing product/artisan data — no API call needed,
/// so this always works offline and never fails.
class HeritageTemplates {
  static String makingProcess(Product product) {
    return 'Skilled hands transform raw ${product.material.toLowerCase()} into this '
        '${product.name.toLowerCase()} using the time-honoured ${product.craft.toLowerCase()} '
        'technique, practiced for generations in ${product.origin}. Every piece is finished '
        'entirely by hand — no two are ever quite the same.';
  }

  static String artisanStory(Artisan artisan, Product product) {
    return '${artisan.name} has practiced ${artisan.craft.toLowerCase()} in ${artisan.location} for '
        'years, carrying forward a craft rooted in local tradition. Every ${product.name.toLowerCase()} '
        'that leaves their hands carries a piece of that heritage — made not in a factory, but by a '
        'real person with real skill.';
  }

  /// A believable, deterministic "authenticity ID" — same product always
  /// gets the same ID, without needing a backend or database.
  static String authenticityId(Product product) {
    final seed = (product.id.hashCode.abs() + product.name.hashCode.abs()) % 900000 + 100000;
    return 'CRIBEIT-IN-$seed';
  }

  /// What the QR code encodes — a plausible verification link. There's no
  /// real server behind this in the prototype; it's shown as a concept.
  static String verificationUrl(Product product) {
    return 'https://cribeit.app/verify/${authenticityId(product)}';
  }
}
