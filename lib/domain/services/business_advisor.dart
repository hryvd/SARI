import '../entities/sales_summary.dart';
import '../entities/transaction.dart';

class BusinessAdvisor {
  const BusinessAdvisor._();

  static List<String> generateAdvice({
    required double revenue,
    required double grossProfit,
    required double profitMargin,
    required double dailyTarget,
    required List<TopProduct> topProducts,
    required List<Transaction> recentTransactions,
    bool isFilipino = true,
  }) {
    final List<String> insights = <String>[];

    // 1. Target achievement advice
    if (dailyTarget > 0) {
      if (revenue >= dailyTarget) {
        insights.add(isFilipino
            ? 'Binabati kita! Naabot mo na ang arawang target na benta (₱${revenue.toStringAsFixed(2)}).'
            : 'Congratulations! You reached your daily sales target (₱${revenue.toStringAsFixed(2)}).');
      } else {
        final double gap = dailyTarget - revenue;
        insights.add(isFilipino
            ? 'Kulang na lang ng ₱${gap.toStringAsFixed(2)} para maabot ang arawang target na ₱${dailyTarget.toStringAsFixed(2)}.'
            : 'Only ₱${gap.toStringAsFixed(2)} left to hit your daily goal of ₱${dailyTarget.toStringAsFixed(2)}.');
      }
    }

    // 2. Profit margin insight
    if (revenue > 0) {
      if (profitMargin >= 25.0) {
        insights.add(isFilipino
            ? 'Maganda ang kita: ${profitMargin.toStringAsFixed(1)}% profit margin. Panatilihin ang maayos na presyo.'
            : 'Healthy margins: ${profitMargin.toStringAsFixed(1)}% profit margin. Maintain your current pricing.');
      } else {
        insights.add(isFilipino
            ? 'Nasa ${profitMargin.toStringAsFixed(1)}% ang tubo. Maaaring suriin ang mga puhunan at supplier discounts.'
            : 'Current profit margin is ${profitMargin.toStringAsFixed(1)}%. Review product costs with suppliers.');
      }
    }

    // 3. Peak hours advice
    if (recentTransactions.isNotEmpty) {
      final Map<int, int> hourCounts = <int, int>{};
      for (final Transaction t in recentTransactions) {
        final int h = t.timestamp.hour;
        hourCounts[h] = (hourCounts[h] ?? 0) + 1;
      }
      int peakHour = 8;
      int maxCount = 0;
      hourCounts.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          peakHour = hour;
        }
      });

      if (maxCount > 0) {
        final String amPm = peakHour < 12 ? 'ng umaga' : (peakHour < 18 ? 'ng hapon' : 'ng gabi');
        final String amPmEn = peakHour < 12 ? 'AM' : 'PM';
        final int displayHour = peakHour > 12 ? peakHour - 12 : (peakHour == 0 ? 12 : peakHour);
        insights.add(isFilipino
            ? 'Mabenta ang tindahan bandang alas-$displayHour $amPm. Mag-handa ng dagdag na paninda bago mag-alas $displayHour.'
            : 'Rush hour peaks around $displayHour:00 $amPmEn. Prepare inventory before this window.');
      }
    }

    // 4. Top product insight
    if (topProducts.isNotEmpty) {
      final TopProduct top = topProducts.first;
      insights.add(isFilipino
          ? 'Pinakamalakas ang "${top.name}" (${top.totalQty} na piraso/kilo naibenta). Siguraduhing hindi maubusan ng stock.'
          : 'Top seller is "${top.name}" with ${top.totalQty} units sold. Ensure stock does not deplete.');
    }

    if (insights.isEmpty) {
      insights.add(isFilipino
          ? 'Magtala ng mga benta araw-araw upang makita ang takbo at payo para sa iyong tindahan.'
          : 'Record daily sales to receive automated tips and business patterns.');
    }

    return insights;
  }
}
