import '../models/customer_cuisine.dart';

/// Bundled cuisine illustrations — always shown on home even when API is offline.
abstract final class BundledCuisines {
  static const _assetDir = 'assets/images/cuisines';

  static const list = [
    CustomerCuisine(id: 0, name: 'North Indian', assetPath: '$_assetDir/north_indian.png'),
    CustomerCuisine(id: 0, name: 'Bengali', assetPath: '$_assetDir/bengali.png'),
    CustomerCuisine(id: 0, name: 'South Indian', assetPath: '$_assetDir/south_indian.png'),
    CustomerCuisine(id: 0, name: 'Rajasthani', assetPath: '$_assetDir/rajasthani.png'),
    CustomerCuisine(id: 0, name: 'Chinese', assetPath: '$_assetDir/chinese.png'),
    CustomerCuisine(id: 0, name: 'Bihari', assetPath: '$_assetDir/bihari.png'),
    CustomerCuisine(id: 0, name: 'Gujarati', assetPath: '$_assetDir/gujarati.png'),
    CustomerCuisine(id: 0, name: 'Mughlai', assetPath: '$_assetDir/mughlai.png'),
    CustomerCuisine(id: 0, name: 'Odisha', assetPath: '$_assetDir/odisha.png'),
    CustomerCuisine(id: 0, name: 'Kerala', assetPath: '$_assetDir/kerala.png'),
    CustomerCuisine(id: 0, name: 'Tamil', assetPath: '$_assetDir/tamil.png'),
    CustomerCuisine(id: 0, name: 'Punjabi', assetPath: '$_assetDir/punjabi.png'),
    CustomerCuisine(id: 0, name: 'Maharashtrian', assetPath: '$_assetDir/maharashtrian.png'),
  ];

  /// Prefer bundled order + local assets; enrich with API ids and image URLs.
  static List<CustomerCuisine> displayList(List<CustomerCuisine> fromApi) {
    if (fromApi.isEmpty) return list;

    final byName = {
      for (final c in fromApi) c.name.trim().toLowerCase(): c,
    };
    final bundledNames = <String>{};

    final merged = [
      for (final bundled in list)
        () {
          final key = bundled.name.toLowerCase();
          bundledNames.add(key);
          final api = byName[key];
          if (api == null) return bundled;
          return CustomerCuisine(
            id: api.id,
            name: api.name,
            imageUrl: api.imageUrl,
            assetPath: bundled.assetPath,
          );
        }(),
    ];

    final extras = fromApi
        .where((c) => !bundledNames.contains(c.name.trim().toLowerCase()))
        .toList();

    return [...merged, ...extras];
  }
}
