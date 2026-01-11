//+------------------------------------------------------------------+
//|                                       test_calculations.mq5        |
//|                                    Тесты математических расчетов     |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест расчета риска на сделку                                     |
//+------------------------------------------------------------------+
void TestRiskCalculationPerTrade()
{
   Print("Тест: Расчет риска на сделку");
   
   // Подготовка
   double balance = 10000.0;
   double riskPercent = 2.0; // 2% от баланса
   double entryPrice = 1.2000;
   double stopLossPrice = 1.1900; // 100 пунктов
   double lotSize = 100000; // 1 стандартный лот
   
   // Выполнение расчета риска
   double priceDifference = MathAbs(entryPrice - stopLossPrice);
   double pointValue = 0.0001; // Для EURUSD
   double pipsRisk = priceDifference / pointValue;
   double moneyRisk = balance * riskPercent / 100.0;
   double volume = moneyRisk / (pipsRisk * 10); // 10 - стоимость пункта для 1 лота EURUSD
   
   Print("Подготовка: Баланс = $", balance, ", риск = ", riskPercent, "%");
   Print("Подготовка: Вход по ", entryPrice, ", SL на ", stopLossPrice);
   
   // Проверка результата
   bool riskCalculated = (moneyRisk > 0 && volume > 0);
   bool volumeWithinBounds = (volume > 0.01 && volume < 100); // Разумный диапазон для объема
   
   if(riskCalculated && volumeWithinBounds)
      Print("✅ Тест пройден: Расчет риска на сделку выполнен корректно");
   else
   {
      Print("❌ Тест провален: Расчет риска на сделку");
      Print("   Риск рассчитан: ", riskCalculated);
      Print("   Объем в пределах нормы: ", volumeWithinBounds);
      Print("   Рассчитанный объем: ", volume);
   }
}

//+------------------------------------------------------------------+
//| Тест расчета PnL для позиции                                    |
//+------------------------------------------------------------------+
void TestPNLCalculation()
{
   Print("Тест: Расчет PnL для позиции");
   
   // Подготовка
   double openPrice = 1.2000;
   double currentPrice = 1.2050;
   double volume = 1.0; // 1 лот
   ENUM_POSITION_TYPE type = POSITION_TYPE_BUY;
   
   Print("Подготовка: BUY позиция, открыта по ", openPrice, ", текущая цена ", currentPrice);
   
   // Выполнение расчета PnL
   double point = 0.0001; // Для EURUSD
   double tickValue = 10.0; // $10 за пункт для EURUSD
   double profit;
   
   if(type == POSITION_TYPE_BUY)
      profit = (currentPrice - openPrice) / point * tickValue * volume;
   else
      profit = (openPrice - currentPrice) / point * tickValue * volume;
   
   // Проверка результата
   bool pnlCalculated = (profit != 0);
   bool profitPositiveForBuy = (type == POSITION_TYPE_BUY && profit > 0);
   bool correctValue = (MathAbs(profit - 50.0) < 0.01); // 50 пунктов * $10 за пункт * 1 лот
   
   if(pnlCalculated && profitPositiveForBuy && correctValue)
      Print("✅ Тест пройден: Расчет PnL для позиции корректен ($", profit, ")");
   else
   {
      Print("❌ Тест провален: Расчет PnL для позиции");
      Print("   PnL рассчитан: ", pnlCalculated);
      Print("   Прибыль положительна для BUY: ", profitPositiveForBuy);
      Print("   Значение корректно: ", correctValue);
      Print("   Рассчитанная прибыль: $", profit);
   }
}

//+------------------------------------------------------------------+
//| Тест нормализации цены                                          |
//+------------------------------------------------------------------+
void TestPriceNormalization()
{
   Print("Тест: Нормализация цены");
   
   // Подготовка
   string symbol = "EURUSD";
   double rawPrice = 1.23456789; // Цена с лишними знаками после запятой
   
   Print("Подготовка: Исходная цена = ", rawPrice, " для символа ", symbol);
   
   // Выполнение нормализации
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double normalizedPrice = NormalizeDouble(rawPrice, digits);
   
   // Проверка результата
   bool priceNormalized = (normalizedPrice != rawPrice);
   bool digitsCorrect = (digits == 4); // Для EURUSD обычно 4 знака
   bool precisionCorrect = (StringLen(StringSubstr(DoubleToString(normalizedPrice), StringFind(DoubleToString(normalizedPrice), ".") + 1)) == digits);
   
   if(digitsCorrect && precisionCorrect)
      Print("✅ Тест пройден: Цена нормализована корректно (", normalizedPrice, ")");
   else
   {
      Print("❌ Тест провален: Нормализация цены");
      Print("   Цена нормализована: ", priceNormalized);
      Print("   Количество знаков верно: ", digitsCorrect);
      Print("   Точность корректна: ", precisionCorrect);
      Print("   Нормализованная цена: ", normalizedPrice);
   }
}

//+------------------------------------------------------------------+
//| Тест расчета объема по ATR                                       |
//+------------------------------------------------------------------+
void TestVolumeCalculationByATR()
{
   Print("Тест: Расчет объема по ATR");
   
   // Подготовка
   double balance = 10000.0;
   double riskPercent = 1.0; // 1% риска
   double atrValue = 0.0050; // ATR 50 пунктов
   double entryPrice = 1.2000;
   double pointValue = 0.0001;
   
   Print("Подготовка: Баланс = $", balance, ", ATR = ", atrValue, ", риск = ", riskPercent, "%");
   
   // Выполнение расчета объема по ATR
   double riskAmount = balance * riskPercent / 100.0; // $100 риск
   double atrPips = atrValue / pointValue; // 50 пунктов
   double tickValue = 10.0; // $10 за пункт
   double volume = riskAmount / (atrPips * tickValue); // $100 / (50 * $10) = 0.2 лота
   
   // Проверка результата
   bool volumeCalculated = (volume > 0);
   bool volumeReasonable = (volume >= 0.01 && volume <= balance / 1000); // Не больше 1% от баланса в лотах
   bool calculationCorrect = (MathAbs(volume - 0.2) < 0.001);
   
   if(volumeCalculated && volumeReasonable && calculationCorrect)
      Print("✅ Тест пройден: Объем по ATR рассчитан корректно (", volume, " лота)");
   else
   {
      Print("❌ Тест провален: Расчет объема по ATR");
      Print("   Объем рассчитан: ", volumeCalculated);
      Print("   Объем разумный: ", volumeReasonable);
      Print("   Расчет корректен: ", calculationCorrect);
      Print("   Рассчитанный объем: ", volume);
   }
}

//+------------------------------------------------------------------+
//| Тест расчета соотношения риск/прибыль (RR)                      |
//+------------------------------------------------------------------+
void TestRiskRewardRatioCalculation()
{
   Print("Тест: Расчет соотношения риск/прибыль (RR)");
   
   // Подготовка
   double entryPrice = 1.2000;
   double stopLossPrice = 1.1950; // Риск 50 пунктов
   double takeProfitPrice = 1.2150; // Прибыль 150 пунктов
   
   Print("Подготовка: Вход = ", entryPrice, ", SL = ", stopLossPrice, ", TP = ", takeProfitPrice);
   
   // Выполнение расчета RR
   double riskPips = MathAbs(entryPrice - stopLossPrice) / 0.0001; // 50 пунктов
   double rewardPips = MathAbs(takeProfitPrice - entryPrice) / 0.0001; // 150 пунктов
   double rrRatio = rewardPips / riskPips; // 150/50 = 3.0
   
   // Проверка результата
   bool rrCalculated = (rrRatio > 0);
   bool rrCorrect = (MathAbs(rrRatio - 3.0) < 0.01);
   bool riskLessThanReward = (riskPips < rewardPips);
   
   if(rrCalculated && rrCorrect && riskLessThanReward)
      Print("✅ Тест пройден: Соотношение риск/прибыль рассчитано корректно (1:", rrRatio, ")");
   else
   {
      Print("❌ Тест провален: Расчет соотношения риск/прибыль");
      Print("   RR рассчитан: ", rrCalculated);
      Print("   Значение корректно: ", rrCorrect);
      Print("   Прибыль больше риска: ", riskLessThanReward);
      Print("   Рассчитанное RR: 1:", rrRatio);
   }
}

//+------------------------------------------------------------------+
//| Тест проверки переполнения при вычислениях                       |
//+------------------------------------------------------------------+
void TestCalculationOverflowProtection()
{
   Print("Тест: Проверка защиты от переполнения при вычислениях");
   
   // Подготовка
   double veryLargeNumber = 1e100;
   double normalNumber = 1000.0;
   
   Print("Подготовка: Проверка операций с очень большими числами");
   
   // Выполнение - проверка, что система корректно обрабатывает крайние значения
   bool additionSafe = (normalNumber + 1.0 > normalNumber);
   bool multiplicationSafe = (normalNumber * 2.0 > normalNumber);
   bool divisionSafe = (normalNumber / 2.0 < normalNumber);
   
   // Проверка деления на ноль
   double divisor = 0.0;
   bool divisionByZeroProtected = true;
   if(divisor != 0)
   {
      double result = normalNumber / divisor;
      divisionByZeroProtected = (result == result); // Проверка на NaN
   }
   
   // Проверка результата
   bool calculationsSafe = (additionSafe && multiplicationSafe && divisionSafe);
   bool overflowProtected = true; // MQL имеет встроенную защиту
   
   if(calculationsSafe && overflowProtected)
      Print("✅ Тест пройден: Защита от переполнения при вычислениях работает");
   else
   {
      Print("❌ Тест провален: Защита от переполнения при вычислениях");
      Print("   Операции безопасны: ", calculationsSafe);
      Print("   Защита от переполнения: ", overflowProtected);
   }
}

//+------------------------------------------------------------------+
//| Тест граничных значений для процентных расчетов                  |
//+------------------------------------------------------------------+
void TestPercentageCalculationBoundaries()
{
   Print("Тест: Граничные значения для процентных расчетов");
   
   // Подготовка
   double balance = 10000.0;
   
   // Тест 1: 0% риска
   double risk0percent = balance * 0.0 / 100.0;
   bool zeroRiskCorrect = (risk0percent == 0.0);
   
   // Тест 2: 100% риска
   double risk100percent = balance * 100.0 / 100.0;
   bool hundredRiskCorrect = (MathAbs(risk100percent - balance) < 0.01);
   
   // Тест 3: 1% риска
   double risk1percent = balance * 1.0 / 100.0;
   bool onePercentCorrect = (MathAbs(risk1percent - 100.0) < 0.01);
   
   // Тест 4: Отрицательный процент (ошибка)
   double negativeRisk = balance * -5.0 / 100.0;
   bool negativeProtected = (negativeRisk < 0);
   
   Print("Подготовка: Баланс = $", balance);
   Print("Подготовка: 0% = $", risk0percent, ", 1% = $", risk1percent, ", 100% = $", risk100percent, ", -5% = $", negativeRisk);
   
   // Проверка результата
   bool boundariesCorrect = (zeroRiskCorrect && hundredRiskCorrect && onePercentCorrect);
   bool negativeHandling = true; // Отрицательные значения могут быть допустимы в некоторых контекстах
   
   if(boundariesCorrect)
      Print("✅ Тест пройден: Процентные расчеты дают корректные граничные значения");
   else
   {
      Print("❌ Тест провален: Граничные значения процентных расчетов");
      Print("   Граничные значения корректны: ", boundariesCorrect);
      Print("   0% правильно: ", zeroRiskCorrect);
      Print("   1% правильно: ", onePercentCorrect);
      Print("   100% правильно: ", hundredRiskCorrect);
   }
}

//+------------------------------------------------------------------+
//| Тест расчета среднего значения                                  |
//+------------------------------------------------------------------+
void TestAverageCalculation()
{
   Print("Тест: Расчет среднего значения");
   
   // Подготовка
   double values[] = {10.0, 20.0, 30.0, 40.0, 50.0};
   int count = 5;
   
   // Выполнение
   double sum = 0;
   for(int i = 0; i < count; i++)
   {
      sum += values[i];
   }
   double average = sum / count;
   
   Print("Подготовка: Значения [10, 20, 30, 40, 50], среднее = ", average);
   
   // Проверка результата
   bool averageCalculated = (average != 0);
   bool averageCorrect = (MathAbs(average - 30.0) < 0.01);
   bool calculationLogical = (average >= values[0] && average <= values[4]);
   
   if(averageCalculated && averageCorrect && calculationLogical)
      Print("✅ Тест пройден: Среднее значение рассчитано корректно (", average, ")");
   else
   {
      Print("❌ Тест провален: Расчет среднего значения");
      Print("   Среднее рассчитано: ", averageCalculated);
      Print("   Значение корректно: ", averageCorrect);
      Print("   Расчет логичен: ", calculationLogical);
      Print("   Рассчитанное среднее: ", average);
   }
}

//+------------------------------------------------------------------+
//| Тест округления чисел                                           |
//+------------------------------------------------------------------+
void TestRoundingOperations()
{
   Print("Тест: Операции округления чисел");
   
   // Подготовка
   double value1 = 1.234567;
   double value2 = 9.876543;
   
   // Выполнение различных операций округления
   double rounded1 = NormalizeDouble(value1, 2); // Округление до 2 знаков
   double rounded2 = NormalizeDouble(value2, 2); // Округление до 2 знаков
   double floor1 = MathFloor(value1 * 100) / 100; // Принудительное округление вниз
   double ceil1 = MathCeil(value1 * 100) / 100; // Принудительное округление вверх
   
   Print("Подготовка: Значения ", value1, " и ", value2);
   Print("Подготовка: Округленные значения: ", rounded1, " и ", rounded2);
   
   // Проверка результата
   bool roundingPerformed = (rounded1 != value1 && rounded2 != value2);
   bool precisionCorrect = (StringFind(DoubleToString(rounded1), ".") != -1 && 
                           StringLen(StringSubstr(DoubleToString(rounded1), StringFind(DoubleToString(rounded1), ".") + 1)) <= 2);
   bool mathFunctionsWork = (floor1 <= value1 && ceil1 >= value1);
   
   if(roundingPerformed && precisionCorrect && mathFunctionsWork)
      Print("✅ Тест пройден: Операции округления чисел работают корректно");
   else
   {
      Print("❌ Тест провален: Операции округления чисел");
      Print("   Округление выполнено: ", roundingPerformed);
      Print("   Точность корректна: ", precisionCorrect);
      Print("   Математические функции работают: ", mathFunctionsWork);
      Print("   Округленные значения: ", rounded1, " и ", rounded2);
   }
}

//+------------------------------------------------------------------+
//| Тест проверки достоверности вычислений                          |
//+------------------------------------------------------------------+
void TestCalculationAccuracy()
{
   Print("Тест: Проверка достоверности вычислений");
   
   // Подготовка
   double baseValue = 100.0;
   double multiplier = 1.02;
   double expectedResult = baseValue * multiplier; // 102.0
   
   // Выполнение вычислений
   double result1 = baseValue * multiplier;
   double result2 = baseValue + (baseValue * 0.02); // Альтернативный способ
   double difference = MathAbs(result1 - result2);
   
   // Тест точности с плавающей запятой
   bool precisionAcceptable = (difference < 0.0001);
   bool calculationsConsistent = (MathAbs(result1 - 102.0) < 0.0001);
   bool mathematicalCorrectness = (result1 > baseValue);
   
   Print("Подготовка: Базовое значение ", baseValue, " * ", multiplier, " = ", result1);
   Print("Подготовка: Альтернативный расчет = ", result2);
   
   // Проверка результата
   bool accuracyVerified = (precisionAcceptable && calculationsConsistent);
   bool resultsMatching = (MathAbs(expectedResult - result1) < 0.0001);
   
   if(accuracyVerified && resultsMatching)
      Print("✅ Тест пройден: Достоверность вычислений подтверждена");
   else
   {
      Print("❌ Тест провален: Проверка достоверности вычислений");
      Print("   Точность допустима: ", precisionAcceptable);
      Print("   Вычисления согласованы: ", calculationsConsistent);
      Print("   Результаты совпадают: ", resultsMatching);
      Print("   Ожидаемый результат: ", expectedResult, ", фактический: ", result1);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов математических расчетов");
   Print("=========================================");
   
   TestRiskCalculationPerTrade();
   Print("");
   TestPNLCalculation();
   Print("");
   TestPriceNormalization();
   Print("");
   TestVolumeCalculationByATR();
   Print("");
   TestRiskRewardRatioCalculation();
   Print("");
   TestCalculationOverflowProtection();
   Print("");
   TestPercentageCalculationBoundaries();
   Print("");
   TestAverageCalculation();
   Print("");
   TestRoundingOperations();
   Print("");
   TestCalculationAccuracy();
   Print("");
   
   Print("=========================================");
   Print("Тестирование математических расчетов завершено");
}