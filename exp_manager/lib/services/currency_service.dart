import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class CountryInfo {
  final String name;
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;

  CountryInfo({
    required this.name,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
  });

  @override
  String toString() => '$name ($currencyCode)';
}

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._();
  factory CurrencyService() => _instance;
  CurrencyService._();

  List<CountryInfo>? _cachedCountries;
  Map<String, Map<String, double>>? _ratesCache;

  Future<List<CountryInfo>> getCountries() async {
    if (_cachedCountries != null) return _cachedCountries!;

    try {
      final response = await http.get(Uri.parse(AppConstants.countriesApi));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final countries = <CountryInfo>[];

        for (final country in data) {
          final name = country['name']['common'] as String;
          final currencies = country['currencies'] as Map<String, dynamic>?;

          if (currencies != null && currencies.isNotEmpty) {
            final firstCurrency = currencies.entries.first;
            countries.add(CountryInfo(
              name: name,
              currencyCode: firstCurrency.key,
              currencyName: firstCurrency.value['name'] ?? '',
              currencySymbol: firstCurrency.value['symbol'] ?? '',
            ));
          }
        }

        countries.sort((a, b) => a.name.compareTo(b.name));
        _cachedCountries = countries;
        return countries;
      }
    } catch (e) {
      // Return fallback list on error
    }

    return _getFallbackCountries();
  }

  Future<double?> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;

    _ratesCache ??= {};

    if (_ratesCache!.containsKey(from) &&
        _ratesCache![from]!.containsKey(to)) {
      return _ratesCache![from]![to];
    }

    try {
      final response = await http
          .get(Uri.parse(AppConstants.exchangeRateApi(from)));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, dynamic>.from(data['rates']);
        _ratesCache![from] = rates.map(
            (key, value) => MapEntry(key, (value as num).toDouble()));
        return _ratesCache![from]?[to];
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  Future<double?> convertAmount(
      double amount, String from, String to) async {
    final rate = await getExchangeRate(from, to);
    if (rate == null) return null;
    return amount * rate;
  }

  List<String> getCurrencyCodes() {
    if (_cachedCountries == null) return _fallbackCurrencyCodes;
    final codes = _cachedCountries!
        .map((c) => c.currencyCode)
        .toSet()
        .toList();
    codes.sort();
    return codes;
  }

  List<CountryInfo> _getFallbackCountries() {
    return [
      CountryInfo(name: 'India', currencyCode: 'INR', currencyName: 'Indian rupee', currencySymbol: '₹'),
      CountryInfo(name: 'United States', currencyCode: 'USD', currencyName: 'US Dollar', currencySymbol: '\$'),
      CountryInfo(name: 'United Kingdom', currencyCode: 'GBP', currencyName: 'British pound', currencySymbol: '£'),
      CountryInfo(name: 'Germany', currencyCode: 'EUR', currencyName: 'Euro', currencySymbol: '€'),
      CountryInfo(name: 'Japan', currencyCode: 'JPY', currencyName: 'Japanese yen', currencySymbol: '¥'),
      CountryInfo(name: 'Australia', currencyCode: 'AUD', currencyName: 'Australian dollar', currencySymbol: '\$'),
      CountryInfo(name: 'Canada', currencyCode: 'CAD', currencyName: 'Canadian dollar', currencySymbol: '\$'),
    ];
  }

  static const List<String> _fallbackCurrencyCodes = [
    'AED', 'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'EUR', 'GBP',
    'HKD', 'INR', 'JPY', 'KRW', 'MXN', 'MYR', 'NOK', 'NZD',
    'PHP', 'PLN', 'RUB', 'SAR', 'SEK', 'SGD', 'THB', 'TRY',
    'TWD', 'USD', 'ZAR',
  ];
}
