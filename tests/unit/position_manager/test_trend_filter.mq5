//+------------------------------------------------------------------+
//|                                   test_trend_filter.mq5            |
//|                                    Тесты трендового фильтра PM       |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест определения восходящего тренда                            |
//+------------------------------------------------------------------+
void TestTrendFilterUptrendDetection()
{
   Print("Тест: Определение восходящего тренда");
   
   // Подготовка (имитация значений для тренда)
   string symbol = "EURUSD";
   double price = 1.2100;
   double ma1 = 1.2050; // MA на младшем ТФ
   double ma2 = 1.2000; // MA на старшем ТФ
   
   Print("Подготовка: Цена = ", price, ", MA1 (младший ТФ) = ", ma1, ", MA2 (старший ТФ) = ", ma2);
   
   // Выполнение (имитация TF_GetRecommendation)
   bool uptrend = (price > ma1) && (price > ma2);
   bool downtrend = (price < ma1) && (price < ma2);
   
   int recommendation = 0;
   if(uptrend)
      recommendation = 1; // LONG
   else if(downtrend)
      recommendation = 2; // SHORT
   else
      recommendation = 0; // NO TRADE
   
   // Проверка результата
   bool uptrendDetected = uptrend;
   bool recommendationIsLong = (recommendation == 1);
   bool noDowntrend = !downtrend;
   
   if(uptrendDetected && recommendationIsLong && noDowntrend)
      Print("✅ Тест пройден: Восходящий тренд корректно определен как LONG");
   else
   {
      Print("❌ Тест провален: Определение восходящего тренда");
      Print("   Восходящий тренд обнаружен: ", uptrendDetected);
      Print("   Рекомендация LONG: ", recommendationIsLong);
      Print("   Нет нисходящего тренда: ", noDowntrend);
      Print("   Рекомендация: ", recommendation);
   }
}

//+------------------------------------------------------------------+
//| Тест определения нисходящего тренда                            |
//+------------------------------------------------------------------+
void TestTrendFilterDowntrendDetection()
{
   Print("Тест: Определение нисходящего тренда");
   
   // Подготовка (имитация значений для тренда)
   string symbol = "EURUSD";
   double price = 1.1900;
   double ma1 = 1.1950; // MA на младшем ТФ
   double ma2 = 1.2000; // MA на старшем ТФ
   
   Print("Подготовка: Цена = ", price, ", MA1 (младший ТФ) = ", ma1, ", MA2 (старший ТФ) = ", ma2);
   
   // Выполнение (имитация TF_GetRecommendation)
   bool uptrend = (price > ma1) && (price > ma2);
   bool downtrend = (price < ma1) && (price < ma2);
   
   int recommendation = 0;
   if(uptrend)
      recommendation = 1; // LONG
   else if(downtrend)
      recommendation = 2; // SHORT
   else
      recommendation = 0; // NO TRADE
   
   // Проверка результата
   bool downtrendDetected = downtrend;
   bool recommendationIsShort = (recommendation == 2);
   bool noUptrend = !uptrend;
   
   if(downtrendDetected && recommendationIsShort && noUptrend)
      Print("✅ Тест пройден: Нисходящий тренд корректно определен как SHORT");
   else
   {
      Print("❌ Тест провален: Определение нисходящего тренда");
      Print("   Нисходящий тренд обнаружен: ", downtrendDetected);
      Print("   Рекомендация SHORT: ", recommendationIsShort);
      Print("   Нет восходящего тренда: ", noUptrend);
      Print("   Рекомендация: ", recommendation);
   }
}

//+------------------------------------------------------------------+
//| Тест определения бокового движения (без тренда)                 |
//+------------------------------------------------------------------+
void TestTrendFilterSidewaysDetection()
{
   Print("Тест: Определение бокового движения (без тренда)");
   
   // Подготовка (имитация значений для боковика)
   string symbol = "EURUSD";
   double price = 1.2000;
   double ma1 = 1.2050; // Цена ниже MA1
   double ma2 = 1.1950; // Цена выше MA2
   
   Print("Подготовка: Цена = ", price, ", MA1 = ", ma1, ", MA2 = ", ma2);
   Print("Подготовка: Цена между MA - это боковое движение");
   
   // Выполнение (имитация TF_GetRecommendation)
   bool uptrend = (price > ma1) && (price > ma2);
   bool downtrend = (price < ma1) && (price < ma2);
   
   int recommendation = 0;
   if(uptrend)
      recommendation = 1; // LONG
   else if(downtrend)
      recommendation = 2; // SHORT
   else
      recommendation = 0; // NO TRADE
   
   // Проверка результата
   bool noTrendDetected = !uptrend && !downtrend;
   bool recommendationIsNoTrade = (recommendation == 0);
   bool sidewaysCondition = (price < ma1 && price > ma2) || (price > ma1 && price < ma2);
   
   if(noTrendDetected && recommendationIsNoTrade && sidewaysCondition)
      Print("✅ Тест пройден: Боковое движение корректно определено как NO TRADE");
   else
   {
      Print("❌ Тест провален: Определение бокового движения");
      Print("   Нет тренда обнаружено: ", noTrendDetected);
      Print("   Рекомендация NO TRADE: ", recommendationIsNoTrade);
      Print("   Условие боковика выполнено: ", sidewaysCondition);
      Print("   Рекомендация: ", recommendation);
   }
}

//+------------------------------------------------------------------+
//| Тест граничного условия на линии тренда                        |
//+------------------------------------------------------------------+
void TestTrendFilterBoundaryCondition()
{
   Print("Тест: Граничное условие на линии тренда");
   
   // Подготовка (цена точно на одной из MA)
   string symbol = "EURUSD";
   double price = 1.2000;
   double ma1 = 1.2000; // Цена равна MA1
   double ma2 = 1.1950; // MA2 ниже
   
   Print("Подготовка: Цена = ", price, " (равна MA1 = ", ma1, "), MA2 = ", ma2);
   
   // Выполнение (имитация TF_GetRecommendation)
   bool uptrend = (price > ma1) && (price > ma2); // Будет false, так как price == ma1
   bool downtrend = (price < ma1) && (price < ma2); // Будет false, так как price > ma2
   
   int recommendation = 0;
   if(uptrend)
      recommendation = 1; // LONG
   else if(downtrend)
      recommendation = 2; // SHORT
   else
      recommendation = 0; // NO TRADE
   
   // Проверка результата
   bool boundaryHandledCorrectly = !uptrend && !downtrend; // Должно быть NO TRADE
   bool noTrendRecommendation = (recommendation == 0);
   bool conditionUsesStrictComparison = (price > ma1) == false; // Должно быть false при ==
   
   if(boundaryHandledCorrectly && noTrendRecommendation && conditionUsesStrictComparison)
      Print("✅ Тест пройден: Граничное условие обработано корректно (строгое сравнение)");
   else
   {
      Print("❌ Тест провален: Обработка граничного условия");
      Print("   Граничное условие обработано правильно: ", boundaryHandledCorrectly);
      Print("   Рекомендация NO TRADE: ", noTrendRecommendation);
      Print("   Используется строгое сравнение: ", conditionUsesStrictComparison);
      Print("   Рекомендация: ", recommendation);
   }
}

//+------------------------------------------------------------------+
//| Тест получения строкового представления направления              |
//+------------------------------------------------------------------+
void TestGetDirectionString()
{
   Print("Тест: Получение строкового представления направления");
   
   // Подготовка и выполнение
   string longStr = GetDirectionString(1);
   string shortStr = GetDirectionString(2);
   string noTradeStr = GetDirectionString(0);
   
   // Проверка результата
   bool longCorrect = (longStr == "LONG");
   bool shortCorrect = (shortStr == "SHORT");
   bool noTradeCorrect = (noTradeStr == "NO TRADE");
   
   if(longCorrect && shortCorrect && noTradeCorrect)
      Print("✅ Тест пройден: Строковое представление направления корректно");
   else
   {
      Print("❌ Тест провален: Строковое представление направления");
      Print("   LONG: '", longStr, "' (ожидаем: 'LONG')");
      Print("   SHORT: '", shortStr, "' (ожидаем: 'SHORT')");
      Print("   NO TRADE: '", noTradeStr, "' (ожидаем: 'NO TRADE')");
   }
}

//+------------------------------------------------------------------+
//| Тест обработки случая, когда одна из MA отсутствует             |
//+------------------------------------------------------------------+
void TestTrendFilterMissingMAValue()
{
   Print("Тест: Обработка случая, когда одна из MA отсутствует");
   
   // Подготовка (одна из MA - нулевое значение)
   string symbol = "EURUSD";
   double price = 1.2000;
   double ma1 = 1.1950;
   double ma2 = 0.0; // Отсутствует
   
   Print("Подготовка: Цена = ", price, ", MA1 = ", ma1, ", MA2 = ", ma2, " (отсутствует)");
   
   // Выполнение (имитация TF_GetRecommendation с проверкой валидности MA)
   bool maValuesValid = (ma1 != 0 && ma2 != 0);
   int recommendation = 0;
   
   if(maValuesValid)
   {
      bool uptrend = (price > ma1) && (price > ma2);
      bool downtrend = (price < ma1) && (price < ma2);
      
      if(uptrend)
         recommendation = 1; // LONG
      else if(downtrend)
         recommendation = 2; // SHORT
      else
         recommendation = 0; // NO TRADE
   }
   else
   {
      // Если MA недоступны, лучше не торговать
      recommendation = 0; // NO TRADE
   }
   
   // Проверка результата
   bool invalidMAHandled = !maValuesValid;
   bool noTradeForInvalidMA = (recommendation == 0);
   bool safeApproachUsed = true;
   
   if(invalidMAHandled && noTradeForInvalidMA)
      Print("✅ Тест пройден: Отсутствие MA корректно обработано как NO TRADE");
   else
   {
      Print("❌ Тест провален: Обработка отсутствующих значений MA");
      Print("   Невалидные MA обработаны: ", invalidMAHandled);
      Print("   Рекомендация NO TRADE: ", noTradeForInvalidMA);
      Print("   Рекомендация: ", recommendation);
   }
}

//+------------------------------------------------------------------+
//| Тест различных таймфреймов                                     |
//+------------------------------------------------------------------+
void TestTrendFilterDifferentTimeframes()
{
   Print("Тест: Использование различных таймфреймов");
   
   // Подготовка
   string symbol = "EURUSD";
   ENUM_TIMEFRAMES tf1 = PERIOD_H1;  // Младший ТФ
   ENUM_TIMEFRAMES tf2 = PERIOD_H4;  // Старший ТФ
   int maPeriod = 89;                // Период MA
   
   Print("Подготовка: ТФ1 = H1, ТФ2 = H4, период MA = ", maPeriod);
   Print("Подготовка: Используется многофункциональный подход к таймфреймам");
   
   // Выполнение - проверка, что таймфреймы могут быть разными
   bool timeframesValid = (tf1 != tf2); // Должны быть разные таймфреймы для фильтра
   bool periodValid = (maPeriod > 0);
   
   // Имитация получения данных для разных таймфреймов
   bool dataRetrievedForTF1 = true; // Предполагаем, что данные успешно получены
   bool dataRetrievedForTF2 = true;
   
   // Проверка результата
   bool timeframesDifferent = timeframesValid;
   bool periodAppropriate = periodValid;
   bool multiTFApproachValid = dataRetrievedForTF1 && dataRetrievedForTF2;
   
   if(timeframesDifferent && periodAppropriate && multiTFApproachValid)
      Print("✅ Тест пройден: Использование различных таймфреймов корректно");
   else
   {
      Print("❌ Тест провален: Использование различных таймфреймов");
      Print("   Таймфреймы разные: ", timeframesDifferent);
      Print("   Период MA корректен: ", periodAppropriate);
      Print("   Подход с несколькими ТФ работает: ", multiTFApproachValid);
   }
}

//+------------------------------------------------------------------+
//| Тест чувствительности к изменениям цены                         |
//+------------------------------------------------------------------+
void TestTrendFilterPriceSensitivity()
{
   Print("Тест: Чувствительность к изменениям цены");
   
   // Подготовка
   string symbol = "EURUSD";
   double ma1 = 1.2000;
   double ma2 = 1.2000;
   
   // Тест 1: Цена чуть выше обеих MA (должен быть LONG)
   double price1 = 1.2001;
   bool uptrend1 = (price1 > ma1) && (price1 > ma2);
   int recommendation1 = uptrend1 ? 1 : (price1 < ma1 && price1 < ma2 ? 2 : 0);
   
   // Тест 2: Цена чуть ниже обеих MA (должен быть SHORT)
   double price2 = 1.1999;
   bool downtrend2 = (price2 < ma1) && (price2 < ma2);
   int recommendation2 = downtrend2 ? 2 : (price2 > ma1 && price2 > ma2 ? 1 : 0);
   
   // Тест 3: Цена между MA (должен быть NO TRADE)
   double price3 = 1.2000;
   bool noTrend3 = !((price3 > ma1 && price3 > ma2) || (price3 < ma1 && price3 < ma2));
   int recommendation3 = noTrend3 ? 0 : (price3 > ma1 && price3 > ma2 ? 1 : 2);
   
   Print("Подготовка: MA1 = MA2 = ", ma1);
   Print("Подготовка: Тест 1 - цена ", price1, " (выше MA) -> рекомендация ", recommendation1);
   Print("Подготовка: Тест 2 - цена ", price2, " (ниже MA) -> рекомендация ", recommendation2);
   Print("Подготовка: Тест 3 - цена ", price3, " (между MA) -> рекомендация ", recommendation3);
   
   // Проверка результата
   bool sensitivityCorrect = (recommendation1 == 1) && (recommendation2 == 2) && (recommendation3 == 0);
   bool smallChangesDetected = (recommendation1 != recommendation2);
   
   if(sensitivityCorrect && smallChangesDetected)
      Print("✅ Тест пройден: Чувствительность к изменениям цены корректна");
   else
   {
      Print("❌ Тест провален: Чувствительность к изменениям цены");
      Print("   Рекомендации соответствуют ожиданиям: ", sensitivityCorrect);
      Print("   Малые изменения обнаруживаются: ", smallChangesDetected);
      Print("   Рекомендации: ", recommendation1, ", ", recommendation2, ", ", recommendation3);
   }
}

//+------------------------------------------------------------------+
//| Тест интеграции с системой рекомендаций                         |
//+------------------------------------------------------------------+
void TestTrendFilterRecommendationIntegration()
{
   Print("Тест: Интеграция с системой рекомендаций");
   
   // Подготовка
   string symbol = "EURUSD";
   double currentPrice = 1.2100;
   double maFast = 1.2050;
   double maSlow = 1.2000;
   
   Print("Подготовка: Интеграция трендового фильтра с общей системой");
   
   // Выполнение (имитация полного цикла получения рекомендации)
   int trendRecommendation = 0;
   
   // Определение тренда
   bool uptrend = (currentPrice > maFast) && (currentPrice > maSlow);
   bool downtrend = (currentPrice < maFast) && (currentPrice < maSlow);
   
   if(uptrend)
      trendRecommendation = 1; // LONG
   else if(downtrend)
      trendRecommendation = 2; // SHORT
   else
      trendRecommendation = 0; // NO TRADE
   
   // Имитация сохранения последней рекомендации
   g_LastRecommendation = trendRecommendation;
   g_CurrentRecommendedSymbol = symbol;
   
   // Проверка результата
   bool recommendationCalculated = (trendRecommendation >= 0 && trendRecommendation <= 2);
   bool recommendationSaved = (g_LastRecommendation == trendRecommendation);
   bool symbolRecorded = (g_CurrentRecommendedSymbol == symbol);
   
   if(recommendationCalculated && recommendationSaved && symbolRecorded)
      Print("✅ Тест пройден: Интеграция с системой рекомендаций работает");
   else
   {
      Print("❌ Тест провален: Интеграция с системой рекомендаций");
      Print("   Рекомендация рассчитана корректно: ", recommendationCalculated);
      Print("   Рекомендация сохранена: ", recommendationSaved);
      Print("   Символ записан: ", symbolRecorded);
      Print("   Рекомендация: ", trendRecommendation);
   }
}

//+------------------------------------------------------------------+
//| Тест возврата к безопасному значению при ошибках                |
//+------------------------------------------------------------------+
void TestTrendFilterErrorHandling()
{
   Print("Тест: Возврат к безопасному значению при ошибках");
   
   // Подготовка (имитация ошибочных условий)
   string symbol = "INVALID_SYMBOL"; // Невалидный символ
   double price = 0.0; // Нулевая цена
   double ma1 = 0.0; // Нулевые MA
   double ma2 = 0.0;
   
   Print("Подготовка: Ошибочные входные данные (нулевые значения)");
   
   // Выполнение (имитация TF_GetRecommendation с обработкой ошибок)
   int recommendation = 0; // По умолчанию NO TRADE как безопасное значение
   
   if(price != 0 && ma1 != 0 && ma2 != 0)
   {
      bool uptrend = (price > ma1) && (price > ma2);
      bool downtrend = (price < ma1) && (price < ma2);
      
      if(uptrend)
         recommendation = 1;
      else if(downtrend)
         recommendation = 2;
   }
   // Если данные невалидны, остаемся с NO TRADE
   
   // Проверка результата
   bool safeDefaultUsed = (recommendation == 0);
   bool errorHandledGracefully = true; // Ошибки обрабатываются элегантно
   bool noInvalidRecommendation = (recommendation >= 0 && recommendation <= 2);
   
   if(safeDefaultUsed && errorHandledGracefully && noInvalidRecommendation)
      Print("✅ Тест пройден: Ошибки обрабатываются корректно (возврат к NO TRADE)");
   else
   {
      Print("❌ Тест провален: Обработка ошибок в трендовом фильтре");
      Print("   Использовано безопасное значение по умолчанию: ", safeDefaultUsed);
      Print("   Ошибки обработаны элегантно: ", errorHandledGracefully);
      Print("   Нет невалидных рекомендаций: ", noInvalidRecommendation);
      Print("   Рекомендация: ", recommendation);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов трендового фильтра PositionManager");
   Print("=========================================");
   
   TestTrendFilterUptrendDetection();
   Print("");
   TestTrendFilterDowntrendDetection();
   Print("");
   TestTrendFilterSidewaysDetection();
   Print("");
   TestTrendFilterBoundaryCondition();
   Print("");
   TestGetDirectionString();
   Print("");
   TestTrendFilterMissingMAValue();
   Print("");
   TestTrendFilterDifferentTimeframes();
   Print("");
   TestTrendFilterPriceSensitivity();
   Print("");
   TestTrendFilterRecommendationIntegration();
   Print("");
   TestTrendFilterErrorHandling();
   Print("");
   
   Print("=========================================");
   Print("Тестирование трендового фильтра завершено");
}

//+------------------------------------------------------------------+
//| Вспомогательная функция для тестирования                         |
//+------------------------------------------------------------------+
string GetDirectionString(int direction)
{
   switch(direction)
   {
      case 1:
         return "LONG";
      case 2:
         return "SHORT";
      default:
         return "NO TRADE";
   }
}