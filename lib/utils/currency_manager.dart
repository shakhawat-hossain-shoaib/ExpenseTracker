import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyManager {
  static final CurrencyManager _instance = CurrencyManager._internal();
  
  factory CurrencyManager() {
    return _instance;
  }

  CurrencyManager._internal();

  final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('USD');

  String get currency => currencyNotifier.value;

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('selected_currency') ?? 'USD';
    currencyNotifier.value = savedCurrency;
  }

  Future<void> setCurrency(String newCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', newCurrency);
    currencyNotifier.value = newCurrency;
  }

  String getCurrencySymbol() {
    return getSymbolForCurrency(currencyNotifier.value);
  }

  static String getSymbolForCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'BDT':
        return '৳';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CAD':
      case 'AUD':
        return '\$';
      default:
        return currencyCode;
    }
  }
}
