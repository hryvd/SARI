import 'package:flutter_test/flutter_test.dart';
import 'package:sare/domain/services/sales_prediction_service.dart';

void main() {
  group('Sar-E On-Device AI: SalesPredictionService Suite', () {
    test('predict handles ordinary weekday correctly', () {
      final DateTime tuesday = DateTime(2025, 6, 3); // Tuesday, no payday, no holiday
      final SalesPredictionResult res =
          SalesPredictionService.instance.predict(tuesday);

      expect(res.isWeekend, isFalse);
      expect(res.isPayday, isFalse);
      expect(res.predictedRevenue, greaterThan(0));
      expect(res.dayType, anyOf(PeakDayType.normal, PeakDayType.slow, PeakDayType.peak));
      expect(res.restockAdvice, isNotEmpty);
    });

    test('predict detects Payday and Weekend peak surge', () {
      // 15th is payday, Sunday is weekend
      final DateTime paydaySunday = DateTime(2025, 6, 15);
      final SalesPredictionResult res =
          SalesPredictionService.instance.predict(paydaySunday);

      expect(res.isWeekend, isTrue);
      expect(res.isPayday, isTrue);
      expect(res.dayType, PeakDayType.peak);
      expect(res.tagLabel, contains('PEAK DAY'));
      expect(res.reason, contains('Payday'));
    });

    test('forecast7Days generates 7 sequential day predictions', () {
      final DateTime start = DateTime(2025, 6, 1);
      final List<SalesPredictionResult> forecast =
          SalesPredictionService.instance.forecast7Days(start);

      expect(forecast.length, 7);
      for (int i = 0; i < 7; i++) {
        expect(forecast[i].date.day, start.day + i);
        expect(forecast[i].predictedRevenue, greaterThan(0));
      }
    });

    test('isPhilippineHoliday flags national holidays', () {
      expect(SalesPredictionService.isPhilippineHoliday(DateTime(2025, 1, 1)), isTrue); // New Year
      expect(SalesPredictionService.isPhilippineHoliday(DateTime(2025, 6, 12)), isTrue); // Independence Day
      expect(SalesPredictionService.isPhilippineHoliday(DateTime(2025, 12, 25)), isTrue); // Christmas Day
      expect(SalesPredictionService.isPhilippineHoliday(DateTime(2025, 3, 10)), isFalse);
    });

    test('On-device inference execution latency is under 15ms', () {
      final Stopwatch sw = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        SalesPredictionService.instance.forecast7Days(DateTime.now());
      }
      sw.stop();
      // 10 7-day forecasts (70 tree ensemble evaluations) completed quickly
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });
}
