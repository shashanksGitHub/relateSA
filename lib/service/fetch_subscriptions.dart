import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class Featch {
  Future<List<Offering>> getProducts(context) async {
    try {
      final offering = await Purchases.getOfferings();
      final current = offering.current;

      return current == null ? [] : [current];
    } on PlatformException {
      return [];
    }
  }
}
