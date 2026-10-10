import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/currency_models.dart';
import '../services/currency_rate_service.dart';

enum CurrencySide { left, right }

/// Central state management for the Live Two-Sided Currency Converter.
/// Provides independent currency pair selection, bi-directional conversion,
/// in-memory caching, rate freshness, and decoupling from standard calculator tapes.
class CurrencyConverterProvider extends ChangeNotifier {
  final CurrencyRateService _service;

  List<CurrencyItem> _currencies = [];
  bool _isLoadingCurrencies = false;
  String? _currenciesError;

  CurrencyItem _baseCurrency;
  CurrencyItem _quoteCurrency;

  CurrencyRate? _currentRate;
  bool _isLoadingRate = false;
  String? _rateError;
  DateTime? _lastRefreshedAt;
  bool _isStale = false;

  final TextEditingController baseAmountController = TextEditingController(text: '100');
  final TextEditingController quoteAmountController = TextEditingController();

  CurrencySide _activeSide = CurrencySide.left;
  bool _isUpdatingInternally = false;
  bool _hasInitialized = false;

  CurrencyConverterProvider({CurrencyRateService? service})
      : _service = service ?? CurrencyRateService(),
        _baseCurrency = const CurrencyItem(
          code: 'USD',
          name: 'United States Dollar',
          symbol: '\$',
          countryOrRegion: 'United States',
          flag: '🇺🇸',
        ),
        _quoteCurrency = const CurrencyItem(
          code: 'INR',
          name: 'Indian Rupee',
          symbol: '₹',
          countryOrRegion: 'India',
          flag: '🇮🇳',
        ) {
    _currencies = List.from(CurrencyRateService.defaultFallbackCurrencies);
  }

  // --- Getters ---
  List<CurrencyItem> get currencies => List.unmodifiable(_currencies);
  bool get isLoadingCurrencies => _isLoadingCurrencies;
  String? get currenciesError => _currenciesError;

  CurrencyItem get baseCurrency => _baseCurrency;
  CurrencyItem get quoteCurrency => _quoteCurrency;

  CurrencyRate? get currentRate => _currentRate;
  bool get isLoadingRate => _isLoadingRate;
  String? get rateError => _rateError;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  bool get isStale => _isStale;
  CurrencySide get activeSide => _activeSide;

  /// Ensures initial currencies and rate are loaded once when Compare mode opens.
  Future<void> ensureInitialized() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    await Future.wait([
      fetchCurrencies(),
      fetchRate(),
    ]);
  }

  /// Loads supported currencies from Frankfurter API.
  Future<void> fetchCurrencies({bool forceRefresh = false}) async {
    _isLoadingCurrencies = true;
    _currenciesError = null;
    notifyListeners();

    try {
      final list = await _service.getCurrencies(forceRefresh: forceRefresh);
      _currencies = list;

      // Ensure active currencies match the canonical instances in the list
      final matchedBase = list.where((c) => c.code == _baseCurrency.code).firstOrNull;
      if (matchedBase != null) _baseCurrency = matchedBase;

      final matchedQuote = list.where((c) => c.code == _quoteCurrency.code).firstOrNull;
      if (matchedQuote != null) _quoteCurrency = matchedQuote;
    } catch (e) {
      _currenciesError = 'Failed to load currencies: $e';
    } finally {
      _isLoadingCurrencies = false;
      notifyListeners();
    }
  }

  /// Fetches the live exchange rate for the active [baseCurrency] and [quoteCurrency].
  Future<void> fetchRate({bool forceRefresh = false}) async {
    _isLoadingRate = true;
    _rateError = null;
    notifyListeners();

    try {
      final rate = await _service.getRate(
        _baseCurrency.code,
        _quoteCurrency.code,
        forceRefresh: forceRefresh,
      );
      _currentRate = rate;
      _lastRefreshedAt = rate.fetchedAt;
      _isStale = rate.isStale;
      _rateError = null;

      // Recalculate based on currently active side
      _recalculateConversion();
    } on UnsupportedCurrencyPairException catch (e) {
      _rateError = e.message;
      _currentRate = null;
    } on CurrencyRateException catch (e) {
      _rateError = e.message;
      if (_currentRate != null) {
        _isStale = true;
      }
    } catch (e) {
      _rateError = 'Failed to fetch live rate: $e';
      if (_currentRate != null) {
        _isStale = true;
      }
    } finally {
      _isLoadingRate = false;
      notifyListeners();
    }
  }

  /// Manually requested refresh.
  Future<void> refreshRate() => fetchRate(forceRefresh: true);

  /// Called when the user edits the Left (base) input field.
  void updateBaseAmount(String text) {
    if (_isUpdatingInternally) return;
    _activeSide = CurrencySide.left;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _setControllerTextSilently(quoteAmountController, '');
      notifyListeners();
      return;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      _setControllerTextSilently(quoteAmountController, '');
      notifyListeners();
      return;
    }

    if (_currentRate != null && _currentRate!.rate > 0) {
      final targetVal = parsed * _currentRate!.rate;
      _setControllerTextSilently(
        quoteAmountController,
        _formatRawDecimal(targetVal),
      );
    }
    notifyListeners();
  }

  /// Called when the user edits the Right (quote) input field.
  void updateQuoteAmount(String text) {
    if (_isUpdatingInternally) return;
    _activeSide = CurrencySide.right;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _setControllerTextSilently(baseAmountController, '');
      notifyListeners();
      return;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      _setControllerTextSilently(baseAmountController, '');
      notifyListeners();
      return;
    }

    if (_currentRate != null && _currentRate!.rate > 0) {
      final sourceVal = parsed / _currentRate!.rate;
      _setControllerTextSilently(
        baseAmountController,
        _formatRawDecimal(sourceVal),
      );
    }
    notifyListeners();
  }

  /// Swaps source and target currencies and updates amounts.
  void swapCurrencies() {
    final tempCurrency = _baseCurrency;
    _baseCurrency = _quoteCurrency;
    _quoteCurrency = tempCurrency;

    final leftText = baseAmountController.text;
    final rightText = quoteAmountController.text;

    // Swap text values
    _isUpdatingInternally = true;
    baseAmountController.text = rightText;
    quoteAmountController.text = leftText;
    _isUpdatingInternally = false;

    _activeSide = CurrencySide.left;

    fetchRate();
  }

  /// Changes the base (left) currency.
  void setBaseCurrency(CurrencyItem currency) {
    if (_baseCurrency.code == currency.code && _baseCurrency.countryOrRegion == currency.countryOrRegion) return;

    _baseCurrency = currency;
    notifyListeners();
    fetchRate();
  }

  /// Changes the quote (right) currency.
  void setQuoteCurrency(CurrencyItem currency) {
    if (_quoteCurrency.code == currency.code && _quoteCurrency.countryOrRegion == currency.countryOrRegion) return;

    _quoteCurrency = currency;
    notifyListeners();
    fetchRate();
  }

  /// Recalculates amount on inactive side using current rate.
  void _recalculateConversion() {
    if (_currentRate == null || _currentRate!.rate <= 0) return;

    if (_activeSide == CurrencySide.left) {
      final text = baseAmountController.text.trim();
      final val = double.tryParse(text);
      if (val != null) {
        final target = val * _currentRate!.rate;
        _setControllerTextSilently(quoteAmountController, _formatRawDecimal(target));
      }
    } else {
      final text = quoteAmountController.text.trim();
      final val = double.tryParse(text);
      if (val != null) {
        final source = val / _currentRate!.rate;
        _setControllerTextSilently(baseAmountController, _formatRawDecimal(source));
      }
    }
  }

  void _setControllerTextSilently(TextEditingController controller, String value) {
    _isUpdatingInternally = true;
    final oldCursor = controller.selection.baseOffset;
    controller.text = value;
    if (value.isNotEmpty && oldCursor <= value.length && oldCursor >= 0) {
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
    _isUpdatingInternally = false;
  }

  String _formatRawDecimal(double value) {
    if (value == 0) return '0';
    if (value.abs() >= 1000) {
      return value.toStringAsFixed(2);
    } else if (value.abs() >= 1) {
      // Up to 4 decimals, trim trailing zeros
      return double.parse(value.toStringAsFixed(4)).toString();
    } else {
      // Small values up to 6 decimals
      return double.parse(value.toStringAsFixed(6)).toString();
    }
  }

  /// Formatted equivalent with currency symbol and thousands grouping.
  String formatDisplayValue(String text, CurrencyItem currency) {
    final val = double.tryParse(text.trim());
    if (val == null) return '${currency.symbol}0.00';
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${currency.symbol}${formatter.format(val)}';
  }

  /// Direct exchange rate description string: "1 USD = 96.6400 INR"
  String get rateDescriptionDirect {
    if (_currentRate == null) return 'Rate unavailable';
    final r = _currentRate!.rate;
    final fmt = r >= 100 ? r.toStringAsFixed(2) : (r >= 1 ? r.toStringAsFixed(4) : r.toStringAsFixed(6));
    return '1 ${_baseCurrency.code} = $fmt ${_quoteCurrency.code}';
  }

  /// Inverse exchange rate description string: "1 INR = 0.0103 USD"
  String get rateDescriptionInverse {
    if (_currentRate == null || _currentRate!.rate <= 0) return '';
    final inv = 1.0 / _currentRate!.rate;
    final fmt = inv >= 100 ? inv.toStringAsFixed(2) : (inv >= 1 ? inv.toStringAsFixed(4) : inv.toStringAsFixed(6));
    return '1 ${_quoteCurrency.code} = $fmt ${_baseCurrency.code}';
  }

  @override
  void dispose() {
    baseAmountController.dispose();
    quoteAmountController.dispose();
    super.dispose();
  }
}
