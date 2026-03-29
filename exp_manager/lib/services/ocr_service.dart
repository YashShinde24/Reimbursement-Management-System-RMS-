class OcrResult {
  final double? amount;
  final String? date;
  final String? description;
  final String? vendorName;
  final String? category;
  final List<String> rawLines;

  OcrResult({
    this.amount,
    this.date,
    this.description,
    this.vendorName,
    this.category,
    this.rawLines = const [],
  });
}

class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  OcrResult parseReceiptText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    double? amount;
    String? date;
    String? vendorName;
    String? description;
    String? category;

    // Try to extract amount (look for total/amount patterns)
    final amountRegex = RegExp(
        r'(?:total|amount|sum|grand\s*total|net|subtotal)[:\s]*[\$€£₹]?\s*([\d,]+\.?\d*)',
        caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    }

    // Fallback: find largest number
    if (amount == null) {
      final allNumbers = RegExp(r'[\$€£₹]?\s*([\d,]+\.\d{2})')
          .allMatches(text)
          .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')))
          .whereType<double>()
          .toList();
      if (allNumbers.isNotEmpty) {
        allNumbers.sort();
        amount = allNumbers.last;
      }
    }

    // Try to extract date
    final dateRegex = RegExp(
        r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}|\d{4}[/\-\.]\d{1,2}[/\-\.]\d{1,2})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      date = dateMatch.group(1);
    }

    // Vendor name: usually the first non-empty line
    if (lines.isNotEmpty) {
      vendorName = lines.first.trim();
      if (vendorName!.length > 50) {
        vendorName = vendorName.substring(0, 50);
      }
    }

    // Guess category from keywords
    final lowerText = text.toLowerCase();
    if (lowerText.contains('restaurant') ||
        lowerText.contains('cafe') ||
        lowerText.contains('food') ||
        lowerText.contains('lunch') ||
        lowerText.contains('dinner')) {
      category = 'Food & Dining';
    } else if (lowerText.contains('hotel') ||
        lowerText.contains('lodge') ||
        lowerText.contains('stay')) {
      category = 'Accommodation';
    } else if (lowerText.contains('taxi') ||
        lowerText.contains('uber') ||
        lowerText.contains('fuel') ||
        lowerText.contains('gas')) {
      category = 'Transportation';
    } else if (lowerText.contains('flight') ||
        lowerText.contains('airline') ||
        lowerText.contains('train')) {
      category = 'Travel';
    }

    description = lines.take(3).join(' | ');

    return OcrResult(
      amount: amount,
      date: date,
      description: description,
      vendorName: vendorName,
      category: category,
      rawLines: lines,
    );
  }
}
