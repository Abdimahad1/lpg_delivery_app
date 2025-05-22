import 'package:get/get.dart';

class FavoriteItem {
  final String title;
  final String location;
  final double price;
  final String imagePath;

  FavoriteItem({
    required this.title,
    required this.location,
    required this.price,
    required this.imagePath,
  });
}

class FavoritesController extends GetxController {
  var favorites = <FavoriteItem>[].obs;

  void addToFavorites(FavoriteItem item) {
    if (!favorites.any((element) => element.title == item.title)) {
      favorites.add(item);
    }
  }

  void removeFromFavorites(FavoriteItem item) {
    favorites.removeWhere((element) => element.title == item.title);
  }

  bool isFavorite(FavoriteItem item) {
    return favorites.any((element) => element.title == item.title);
  }
}
