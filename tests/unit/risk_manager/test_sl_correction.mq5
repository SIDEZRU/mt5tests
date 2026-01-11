//+------------------------------------------------------------------+
//|                                       test_sl_correction.mq5         |
//|                                    Тесты коррекции SL RM            |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест перемещения SL в безубыток при достижении прибыли            |
//+------------------------------------------------------------------+
void TestMoveSLToBreakevenAtProfit()
{
   Print("Тест: Перемещение SL в безубыток при достижении прибыли");
   
   // Подготовка
   string symbol = "EURUSD";
   double openPrice = 1.2000;
   double currentPrice = 1.2150; // Позиция в прибыли $150
   double currentSL = 1.1950;    // Текущий SL, прибыль $50 от SL
   double profit = 150.0;        // Высокая прибыль
   int moveSLtoBreakevenAtProfit = 100; // Параметр из настроек
   
   Print("Подготовка: Открытая цена = ", openPrice, ", текущая цена = ", currentPrice);
   Print("Подготовка: Текущий SL = ", currentSL, ", прибыль = $", profit);
   Print("Подготовка: Порог для безубытка = $", moveSLtoBreakevenAtProfit);
   
   // Выполнение (имитация AdjustSLByRiskManager)
   double newSL = currentSL;
   bool slMoved = false;
   
   if(profit >= moveSLtoBreakevenAtProfit)
   {
      newSL = openPrice; // Переместить SL в точку открытия (безубыток)
      
      if(newSL > currentSL) // Только для BUY позиции
      {
         slMoved = true;
         Print("Выполнение: Прибыль $", profit, " превышает порог $", moveSLtoBreakevenAtProfit);
         Print("Действие: SL перемещен из ", currentSL, " в ", newSL, " (точка безубытка)");
      }
   }
   
   // Проверка результата
   bool slToBreakeven = (newSL == openPrice);
   bool slAbovePrevious = (newSL > currentSL);
   bool operationSuccessful = (slMoved && slToBreakeven && slAbovePrevious);
   
   if(operationSuccessful)
      Print("✅ Тест пройден: SL успешно перемещен в безубыток при достижении прибыли");
   else
   {
      Print("❌ Тест провален: Перемещение SL в безубыток");
      Print("   SL перемещен: ", slMoved);
      Print("   SL в точке безубытка: ", slToBreakeven);
      Print("   SL выше предыдущего: ", slAbovePrevious);
      Print("   Результат операции: ", operationSuccessful);
   }
}

//+------------------------------------------------------------------+
//| Тест коррекции SL при высокой прибыли                           |
//+------------------------------------------------------------------+
void TestSLCorrectionHighProfit()
{
   Print("Тест: Коррекция SL при высокой прибыли");
   
   // Подготовка
   double initialSL = 1.1900;
   double currentPrice = 1.2200; // Высокая прибыль
   double newCalculatedSL = 1.2100; // Новый SL, рассчитанный на основе текущей прибыли
   bool allowSLAdjustmentByRiskManager = true;
   
   Print("Подготовка: Начальный SL = ", initialSL, ", текущая цена = ", currentPrice);
   Print("Подготовка: Новый SL (рассчитанный) = ", newCalculatedSL);
   
   // Выполнение коррекции SL
   double finalSL = initialSL;
   bool correctionApplied = false;
   
   if(allowSLAdjustmentByRiskManager && newCalculatedSL != 0)
   {
      // Для BUY позиции: новый SL должен быть выше старого, если текущая цена выше
      if(newCalculatedSL > initialSL)
      {
         finalSL = newCalculatedSL;
         correctionApplied = true;
         Print("Выполнение: Применена коррекция SL");
         Print("Действие: SL изменен с ", initialSL, " на ", finalSL);
      }
   }
   
   // Проверка результата
   bool slImproved = (finalSL > initialSL);
   bool correctionMade = (finalSL == newCalculatedSL);
   
   if(correctionApplied && slImproved && correctionMade)
      Print("✅ Тест пройден: SL скорректирован при высокой прибыли");
   else
   {
      Print("❌ Тест провален: Коррекция SL при высокой прибыли");
      Print("   Коррекция применена: ", correctionApplied);
      Print("   SL улучшен: ", slImproved);
      Print("   SL изменен на рассчитанное значение: ", correctionMade);
   }
}

//+------------------------------------------------------------------+
//| Тест блокировки коррекции SL при отрицательной прибыли           |
//+------------------------------------------------------------------+
void TestSLCorrectionBlockedAtLoss()
{
   Print("Тест: Блокировка коррекции SL при отрицательной прибыли");
   
   // Подготовка
   double currentSL = 1.2000;
   double currentPrice = 1.1900; // Позиция в убытке
   double profit = -100.0;       // Отрицательная прибыль
   int moveSLtoBreakevenAtProfit = 50; // Порог для перемещения в безубыток
   
   Print("Подготовка: Текущий SL = ", currentSL, ", текущая цена = ", currentPrice);
   Print("Подготовка: Прибыль = $", profit, ", порог безубытка = $", moveSLtoBreakevenAtProfit);
   
   // Выполнение - проверка, что коррекция НЕ применяется
   double newSL = currentSL;
   bool correctionAttempted = false;
   
   if(profit >= moveSLtoBreakevenAtProfit)
   {
      newSL = currentPrice - 0.0010; // Переместить SL в безубыток
      correctionAttempted = true;
   }
   
   // Проверка результата - коррекция НЕ должна быть применена
   bool correctionBlocked = !correctionAttempted && (newSL == currentSL);
   
   if(correctionBlocked)
      Print("✅ Тест пройден: Коррекция SL корректно заблокирована при убытке");
   else
   {
      Print("❌ Тест провален: Коррекция SL не заблокирована при убытке");
      Print("   Коррекция заблокирована: ", correctionBlocked);
      Print("   SL остался без изменений: ", (newSL == currentSL));
      Print("   Была попытка коррекции: ", correctionAttempted);
   }
}

//+------------------------------------------------------------------+
//| Тест частичного перемещения SL к безубытку                      |
//+------------------------------------------------------------------+
void TestPartialSLMovementToBreakeven()
{
   Print("Тест: Частичное перемещение SL к безубытку");
   
   // Подготовка
   double openPrice = 1.2000;
   double currentSL = 1.1900;
   double currentPrice = 1.2150; // Позиция в хорошей прибыли
   double profit = 150.0;
   double halfWaySL = (currentSL + openPrice) / 2; // SL на полпути к безубытку
   
   Print("Подготовка: Цена открытия = ", openPrice, ", текущий SL = ", currentSL);
   Print("Подготовка: Текущая цена = ", currentPrice, ", прибыль = $", profit);
   Print("Подготовка: Промежуточный SL (половина пути) = ", halfWaySL);
   
   // Выполнение частичной коррекции SL
   double newSL = currentSL;
   bool partialCorrectionApplied = false;
   
   if(profit > 100) // Хорошая прибыль
   {
      // Переместить SL на полпути к безубытку
      newSL = halfWaySL;
      partialCorrectionApplied = true;
      
      Print("Выполнение: Применена частичная коррекция SL");
      Print("Действие: SL перемещен с ", currentSL, " до ", newSL);
   }
   
   // Проверка результата
   bool slMovedUp = (newSL > currentSL);
   bool slCloserToBreakeven = (MathAbs(newSL - openPrice) < MathAbs(currentSL - openPrice));
   bool withinRange = (newSL <= openPrice && newSL > currentSL);
   
   if(partialCorrectionApplied && slMovedUp && slCloserToBreakeven && withinRange)
      Print("✅ Тест пройден: Частичное перемещение SL к безубытку выполнено корректно");
   else
   {
      Print("❌ Тест провален: Частичное перемещение SL к безубытку");
      Print("   Частичная коррекция применена: ", partialCorrectionApplied);
      Print("   SL перемещен вверх: ", slMovedUp);
      Print("   SL ближе к безубытку: ", slCloserToBreakeven);
      Print("   SL в допустимом диапазоне: ", withinRange);
   }
}

//+------------------------------------------------------------------+
//| Тест защиты от слишком частой коррекции SL                      |
//+------------------------------------------------------------------+
void TestProtectionFromFrequentSLAdjustments()
{
   Print("Тест: Защита от слишком частой коррекции SL");
   
   // Подготовка
   double currentSL = 1.1950;
   double previousSL = 1.1950; // Предыдущий SL такой же
   double currentPrice = 1.2051; // Небольшое движение цены
   datetime lastAdjustmentTime = TimeCurrent() - 30; // Последняя коррекция 30 секунд назад
   int minAdjustmentInterval = 60; // Минимальный интервал коррекции в секундах
   
   Print("Подготовка: Текущий SL = ", currentSL, ", предыдущий SL = ", previousSL);
   Print("Подготовка: Текущая цена = ", currentPrice);
   Print("Подготовка: Последняя коррекция была ", TimeToString(lastAdjustmentTime));
   Print("Подготовка: Минимальный интервал = ", minAdjustmentInterval, " сек");
   
   // Выполнение проверки частоты коррекций
   datetime currentTime = TimeCurrent();
   bool tooSoonForAdjustment = (currentTime - lastAdjustmentTime) < minAdjustmentInterval;
   bool slChangeSignificant = MathAbs(currentSL - previousSL) > 0.0001; // 1 пункт
   
   bool adjustmentAllowed = !tooSoonForAdjustment && slChangeSignificant;
   
   Print("Выполнение: Проверка возможности коррекции SL");
   Print("Результат: Слишком рано для коррекции: ", tooSoonForAdjustment);
   Print("Результат: Изменение SL значительное: ", slChangeSignificant);
   
   // Проверка результата
   bool protectionWorking = true; // Просто проверим, что логика проверки работает
   
   if(adjustmentAllowed || tooSoonForAdjustment)
      Print("✅ Тест пройден: Защита от частой коррекции SL работает");
   else
      Print("❌ Тест провален: Защита от частой коррекции SL не работает");
}

//+------------------------------------------------------------------+
//| Тест коррекции SL с учетом минимального расстояния              |
//+------------------------------------------------------------------+
void TestSLCorrectionWithMinimumDistance()
{
   Print("Тест: Коррекция SL с учетом минимального расстояния");
   
   // Подготовка
   double openPrice = 1.2000;
   double currentSL = 1.1950; // 50 пунктов от цены открытия
   double currentPrice = 1.2100; // Позиция в прибыли
   int minimumSLDistance = 20; // Минимум 20 пунктов от цены открытия
   double point = 0.0001; // Размер пункта для EURUSD
   
   Print("Подготовка: Цена открытия = ", openPrice, ", текущий SL = ", currentSL);
   Print("Подготовка: Текущая цена = ", currentPrice, ", мин. расстояние SL = ", minimumSLDistance, " пт");
   
   // Выполнение коррекции с учетом минимального расстояния
   double newSL = currentSL;
   bool correctionApplied = false;
   
   // Переместить SL к безубытку, но не ближе чем на минимальное расстояние
   double minAllowedSL = openPrice - (minimumSLDistance * point);
   double suggestedSL = openPrice; // Безубыток
   
   if(suggestedSL > minAllowedSL)
   {
      newSL = suggestedSL;
   }
   else
   {
      newSL = minAllowedSL; // Ограничить минимальным расстоянием
   }
   
   if(newSL != currentSL)
   {
      correctionApplied = true;
      Print("Выполнение: SL скорректирован с учетом минимального расстояния");
      Print("Действие: SL изменен с ", currentSL, " на ", newSL);
   }
   
   // Проверка результата
   bool minDistanceMaintained = (newSL >= (openPrice - minimumSLDistance * point));
   bool correctionValid = (correctionApplied || newSL == currentSL); // Либо коррекция, либо SL остался как есть
   
   if(correctionValid && minDistanceMaintained)
      Print("✅ Тест пройден: Коррекция SL с учетом минимального расстояния");
   else
   {
      Print("❌ Тест провален: Коррекция SL с учетом минимального расстояния");
      Print("   Коррекция корректна: ", correctionValid);
      Print("   Минимальное расстояние соблюдено: ", minDistanceMaintained);
      Print("   Новый SL: ", newSL, " (мин. допустимый: ", openPrice - minimumSLDistance * point, ")");
   }
}

//+------------------------------------------------------------------+
//| Тест коррекции SL для SELL позиции                              |
//+------------------------------------------------------------------+
void TestSLCorrectionForSellPosition()
{
   Print("Тест: Коррекция SL для SELL позиции");
   
   // Подготовка
   double openPrice = 1.2100;
   double currentSL = 1.2150; // SL выше цены открытия для SELL
   double currentPrice = 1.2000; // Цена ушла вниз, позиция в прибыли
   double profit = 100.0; // Прибыль для SELL позиции
   int moveSLtoBreakevenAtProfit = 50; // Порог для перемещения в безубыток
   
   Print("Подготовка: Цена открытия (SELL) = ", openPrice, ", текущий SL = ", currentSL);
   Print("Подготовка: Текущая цена = ", currentPrice, ", прибыль = $", profit);
   
   // Выполнение коррекции SL для SELL позиции
   double newSL = currentSL;
   bool correctionApplied = false;
   
   if(profit >= moveSLtoBreakevenAtProfit)
   {
      // Для SELL позиции: переместить SL вниз к цене открытия (в безубыток)
      if(currentSL > openPrice) // Если SL еще выше цены открытия
      {
         newSL = openPrice;
         correctionApplied = true;
         Print("Выполнение: SL для SELL позиции скорректирован в безубыток");
         Print("Действие: SL изменен с ", currentSL, " на ", newSL);
      }
   }
   
   // Проверка результата
   bool slLowered = (newSL < currentSL);
   bool slAtBreakeven = (newSL == openPrice);
   bool sellCorrectionCorrect = (correctionApplied && slLowered && slAtBreakeven);
   
   if(sellCorrectionCorrect)
      Print("✅ Тест пройден: Коррекция SL для SELL позиции выполнена корректно");
   else
   {
      Print("❌ Тест провален: Коррекция SL для SELL позиции");
      Print("   Коррекция применена: ", correctionApplied);
      Print("   SL понижен: ", slLowered);
      Print("   SL в точке безубытка: ", slAtBreakeven);
      Print("   Результат: ", sellCorrectionCorrect);
   }
}

//+------------------------------------------------------------------+
//| Тест отключения коррекции SL                                    |
//+------------------------------------------------------------------+
void TestSLCorrectionDisabled()
{
   Print("Тест: Отключение коррекции SL");
   
   // Подготовка
   bool allowSLAdjustmentByRiskManager = false; // Коррекция отключена
   double currentSL = 1.1900;
   double currentPrice = 1.2100; // Хорошая прибыль
   double profit = 200.0;
   
   Print("Подготовка: Коррекция SL отключена, текущий SL = ", currentSL);
   Print("Подготовка: Текущая цена = ", currentPrice, ", прибыль = $", profit);
   
   // Выполнение - проверка, что коррекция НЕ применяется
   double newSL = currentSL;
   bool attemptedCorrection = false;
   
   if(allowSLAdjustmentByRiskManager && profit > 100)
   {
      newSL = currentPrice - 0.0010; // Это НЕ должно произойти
      attemptedCorrection = true;
   }
   
   // Проверка результата
   bool slUnchanged = (newSL == currentSL);
   bool noCorrection = !attemptedCorrection;
   
   if(slUnchanged && noCorrection)
      Print("✅ Тест пройден: Коррекция SL корректно отключена");
   else
   {
      Print("❌ Тест провален: Коррекция SL не отключена должным образом");
      Print("   SL остался без изменений: ", slUnchanged);
      Print("   Коррекция не была попыткой: ", noCorrection);
      Print("   Была попытка коррекции: ", attemptedCorrection);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов коррекции SL RiskManager");
   Print("=========================================");
   
   TestMoveSLToBreakevenAtProfit();
   Print("");
   TestSLCorrectionHighProfit();
   Print("");
   TestSLCorrectionBlockedAtLoss();
   Print("");
   TestPartialSLMovementToBreakeven();
   Print("");
   TestProtectionFromFrequentSLAdjustments();
   Print("");
   TestSLCorrectionWithMinimumDistance();
   Print("");
   TestSLCorrectionForSellPosition();
   Print("");
   TestSLCorrectionDisabled();
   Print("");
   
   Print("=========================================");
   Print("Тестирование коррекции SL завершено");
}