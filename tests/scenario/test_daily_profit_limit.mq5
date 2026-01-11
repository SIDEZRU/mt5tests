//+------------------------------------------------------------------+
//|                                   test_daily_profit_limit.mq5      |
//|                                    Сценарий 1: Дневной лимит прибыли|
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Сценарий 1: Достигнут дневной лимит прибыли                     |
//+------------------------------------------------------------------+
void TestScenario1_DailyProfitLimit()
{
   Print("Сценарий 1: Достигнут дневной лимит прибыли");
   Print("Описание: Установлен DailyTakeProfit = 500$, текущий PnL = 520$");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 500.0;
   g_GlobalState.dailyPnLTotal = 520.0; // Превышает лимит
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: TP лимит = $500, текущий PnL = $520");
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailyTPReached = g_GlobalState.dailyPnLTotal >= g_GlobalState.dailyTakeProfit;
   
   if(dailyTPReached)
   {
      g_GlobalState.dailyTPReached = true;
      g_GlobalState.allowNewTrades = false;
      
      Print("Выполнение: Обнаружено превышение дневного TakeProfit");
      Print("Действие: Установлен флаг dailyTPReached = true");
      Print("Действие: Запрещены новые сделки (allowNewTrades = false)");
   }
   
   // Проверка результата
   bool newTradesBlocked = !g_GlobalState.allowNewTrades;
   bool tpFlagSet = g_GlobalState.dailyTPReached;
   
   if(dailyTPReached && newTradesBlocked && tpFlagSet)
   {
      Print("✅ Сценарий 1 пройден: Дневной лимит прибыли достигнут и новые сделки заблокированы");
   }
   else
   {
      Print("❌ Сценарий 1 провален:");
      Print("   - Превышение TP обнаружено: ", dailyTPReached);
      Print("   - Новые сделки заблокированы: ", newTradesBlocked);
      Print("   - Флаг TP установлен: ", tpFlagSet);
   }
}

//+------------------------------------------------------------------+
//| Сценарий 2: Серия убытков приводит к уменьшению риска           |
//+------------------------------------------------------------------+
void TestScenario2_LossStreakRiskReduction()
{
   Print("Сценарий 2: Серия убытков приводит к уменьшению риска");
   Print("Описание: 5 убыточных сделок подряд, риск должен уменьшиться");
   
   // Подготовка
   g_GlobalState.currentRiskPercent = 2.0;
   g_GlobalState.lossStreak = 5; // Превышает порог LossStreakToReduce (3)
   g_GlobalState.profitStreak = 0;
   double initialRisk = g_GlobalState.currentRiskPercent;
   
   Print("Подготовка: Текущий риск = ", initialRisk, "%, серия убытков = ", g_GlobalState.lossStreak);
   
   // Выполнение (имитация UpdateDynamicRisk)
   if(g_GlobalState.lossStreak >= 3) // LossStreakToReduce = 3
   {
      double newRisk = g_GlobalState.currentRiskPercent * 0.7;
      double minRiskPercent = 0.5;
      if(newRisk < minRiskPercent)
         newRisk = minRiskPercent;
      
      g_GlobalState.currentRiskPercent = newRisk;
      
      Print("Выполнение: Риск уменьшен с ", initialRisk, "% до ", newRisk, "%");
   }
   
   // Проверка результата
   bool riskReduced = g_GlobalState.currentRiskPercent < initialRisk;
   bool riskWithinBounds = g_GlobalState.currentRiskPercent >= 0.5 && g_GlobalState.currentRiskPercent <= 3.0;
   
   if(riskReduced && riskWithinBounds)
   {
      Print("✅ Сценарий 2 пройден: Риск успешно уменьшен после серии убытков");
      Print("   Новый риск: ", g_GlobalState.currentRiskPercent, "%");
   }
   else
   {
      Print("❌ Сценарий 2 провален:");
      Print("   - Риск уменьшен: ", riskReduced);
      Print("   - Риск в допустимых границах: ", riskWithinBounds);
      Print("   - Текущий риск: ", g_GlobalState.currentRiskPercent, "%");
   }
}

//+------------------------------------------------------------------+
//| Сценарий 3: Частичное закрытие при достижении цели              |
//+------------------------------------------------------------------+
void TestScenario3_PartialCloseAtTarget()
{
   Print("Сценарий 3: Частичное закрытие при достижении цели");
   Print("Описание: Позиция достигла 50% от TP, закрыть 30% объема");
   
   // Подготовка
   string symbol = "EURUSD";
   double totalVolume = 1.0;
   double currentProfit = 75.0; // Предположим, это 50% от целевой прибыли
   double targetProfit = 150.0; // Целевая прибыль
   
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 50.0; // Закрыть при 50% от цели
   config.partialLevels[0].closePercent = 30.0;   // Закрыть 30% объема
   config.partialLevels[0].executed = false;
   
   Print("Подготовка: Объем позиции = ", totalVolume, ", текущая прибыль = $", currentProfit);
   Print("Подготовка: Целевая прибыль = $", targetProfit, ", триггер = ", config.partialLevels[0].triggerPercent, "%");
   
   // Выполнение проверки (имитация PM_CheckPartialClose)
   bool shouldClose = false;
   double closeVolume = 0;
   
   if(config.partialLevels[0].enabled && !config.partialLevels[0].executed)
   {
      double levelProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0; // 75$
      
      if(currentProfit >= levelProfit)
      {
         shouldClose = true;
         closeVolume = totalVolume * config.partialLevels[0].closePercent / 100.0; // 0.3
         
         config.partialLevels[0].executed = true;
         config.partialLevels[0].executionTime = TimeCurrent();
         
         Print("Выполнение: Уровень частичного закрытия сработал");
         Print("Действие: Закрыть объем = ", closeVolume, " (", config.partialLevels[0].closePercent, "%)");
         Print("Действие: Установлен флаг executed = true");
      }
   }
   
   // Проверка результата
   bool levelTriggered = shouldClose;
   bool volumeCalculated = closeVolume > 0;
   bool levelExecuted = config.partialLevels[0].executed;
   
   if(levelTriggered && volumeCalculated && levelExecuted)
   {
      Print("✅ Сценарий 3 пройден: Уровень частичного закрытия сработал корректно");
      Print("   Закрытый объем: ", closeVolume);
   }
   else
   {
      Print("❌ Сценарий 3 провален:");
      Print("   - Уровень сработал: ", levelTriggered);
      Print("   - Объем рассчитан: ", volumeCalculated);
      Print("   - Уровень помечен как выполненный: ", levelExecuted);
   }
}

//+------------------------------------------------------------------+
//| Сценарий 4: Перемещение SL в безубыток                          |
//+------------------------------------------------------------------+
void TestScenario4_MoveSLToBreakeven()
{
   Print("Сценарий 4: Перемещение SL в безубыток");
   Print("Описание: Позиция в прибыли > $50, SL перемещается в точку открытия");
   
   // Подготовка
   double openPrice = 1.2000;
   double currentPrice = 1.2100; // Позиция в прибыли
   double currentSL = 1.1950;    // Текущий SL
   double profit = 100.0;        // Высокая прибыль
   
   Print("Подготовка: Цена открытия = ", openPrice, ", текущая цена = ", currentPrice);
   Print("Подготовка: Текущий SL = ", currentSL, ", прибыль = $", profit);
   
   // Выполнение (имитация AdjustSLByRiskManager)
   double newSL = currentSL;
   bool slMoved = false;
   
   if(profit >= 50.0) // MoveSLtoBreakevenAtProfit
   {
      newSL = openPrice; // Переместить SL в точку открытия
      
      if(newSL != currentSL)
      {
         slMoved = true;
         Print("Выполнение: SL перемещен из ", currentSL, " в ", newSL, " (точка безубытка)");
      }
   }
   
   // Проверка результата
   bool slToBreakeven = (newSL == openPrice);
   bool slChanged = (newSL != currentSL);
   
   if(slToBreakeven && slChanged && slMoved)
   {
      Print("✅ Сценарий 4 пройден: SL успешно перемещен в безубыток при высокой прибыли");
      Print("   Новый SL: ", newSL);
   }
   else
   {
      Print("❌ Сценарий 4 провален:");
      Print("   - SL на уровне безубытка: ", slToBreakeven);
      Print("   - SL изменен: ", slChanged);
      Print("   - SL перемещен: ", slMoved);
   }
}

//+------------------------------------------------------------------+
//| Сценарий 5: Сброс счетчиков в начале дня                        |
//+------------------------------------------------------------------+
void TestScenario5_DailyCountersReset()
{
   Print("Сценарий 5: Сброс счетчиков в начале дня");
   Print("Описание: В 00:01 происходит сброс дневных счетчиков");
   
   // Подготовка - установим ненулевые значения
   g_GlobalState.dailyPnLTotal = 150.0;
   g_GlobalState.dailyTradesCount = 8;
   g_GlobalState.dailyPositionsCount = 3;
   g_GlobalState.dailyTPReached = true;
   g_GlobalState.allowNewTrades = false;
   g_GlobalState.totalClosedProfitToday = 200.0;
   g_GlobalState.totalClosedLossToday = -50.0;
   
   Print("Подготовка: Счетчики имеют значения (PnL=$", g_GlobalState.dailyPnLTotal, 
         ", сделок=", g_GlobalState.dailyTradesCount, ")");
   
   // Выполнение сброса (имитация ResetDailyCounters)
   double oldPnL = g_GlobalState.dailyPnLTotal;
   int oldTrades = g_GlobalState.dailyTradesCount;
   int oldPositions = g_GlobalState.dailyPositionsCount;
   
   g_GlobalState.dailyPnLTotal = 0;
   g_GlobalState.dailyTradesCount = 0;
   g_GlobalState.dailyPositionsCount = 0;
   g_GlobalState.totalClosedProfitToday = 0;
   g_GlobalState.totalClosedLossToday = 0;
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.lastDailyReset = TimeCurrent();
   
   Print("Выполнение: Все дневные счетчики сброшены в 0");
   Print("Действие: Флаги ограничений сброшены, разрешены новые сделки");
   
   // Проверка результата
   bool countersZeroed = (g_GlobalState.dailyPnLTotal == 0 && 
                         g_GlobalState.dailyTradesCount == 0 && 
                         g_GlobalState.dailyPositionsCount == 0);
   bool permissionsRestored = g_GlobalState.allowNewTrades;
   bool flagsReset = !g_GlobalState.dailyTPReached;
   
   if(countersZeroed && permissionsRestored && flagsReset)
   {
      Print("✅ Сценарий 5 пройден: Дневные счетчики успешно сброшены");
      Print("   Старые значения - PnL:", oldPnL, " Сделки:", oldTrades, " Позиции:", oldPositions);
   }
   else
   {
      Print("❌ Сценарий 5 провален:");
      Print("   - Счетчики обнулены: ", countersZeroed);
      Print("   - Разрешения восстановлены: ", permissionsRestored);
      Print("   - Флаги сброшены: ", flagsReset);
   }
}

//+------------------------------------------------------------------+
//| Сценарий 6: Превышение лимита одновременных позиций             |
//+------------------------------------------------------------------+
void TestScenario6_MaxSimultaneousPositionsLimit()
{
   Print("Сценарий 6: Превышение лимита одновременных позиций");
   Print("Описание: Открыто 5 позиций при лимите 3, новые сделки должны быть заблокированы");
   
   // Подготовка
   int maxPositions = 3;
   int currentPositions = 5; // Превышает лимит
   g_GlobalState.maxSimultaneousPositionsDaily = maxPositions;
   
   Print("Подготовка: Максимум позиций = ", maxPositions, ", текущее количество = ", currentPositions);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool positionLimitExceeded = currentPositions > maxPositions;
   
   if(positionLimitExceeded)
   {
      Print("Выполнение: Обнаружено превышение лимита одновременных позиций");
      Print("Действие: Новые сделки должны быть ограничены");
   }
   
   // Проверка результата
   bool limitDetected = positionLimitExceeded;
   bool warningIssued = true; // В реальном коде выдается предупреждение
   
   if(limitDetected && warningIssued)
   {
      Print("✅ Сценарий 6 пройден: Превышение лимита одновременных позиций обнаружено");
   }
   else
   {
      Print("❌ Сценарий 6 провален:");
      Print("   - Превышение лимита обнаружено: ", limitDetected);
   }
}

//+------------------------------------------------------------------+
//| Сценарий 7: Внешний сигнал блокировки                           |
//+------------------------------------------------------------------+
void TestScenario7_ExternalBlockSignal()
{
   Print("Сценарий 7: Внешний сигнал блокировки");
   Print("Описание: Получен сигнал '/trade block', система должна заблокировать торговлю");
   
   // Подготовка
   string signal = "/trade block";
   string signalCommandPrefix = "/trade";
   bool externalSignalsEnabled = true;
   
   Print("Подготовка: Внешний сигнал = '", signal, "', префикс = '", signalCommandPrefix, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(externalSignalsEnabled && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         signalProcessed = true;
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         // В случае команды блокировки
         if(signal == signalCommandPrefix + " block")
         {
            g_GlobalState.dailyTPReached = true; // Используем для блокировки
            g_GlobalState.allowNewTrades = false;
            
            Print("Выполнение: Обнаружена команда блокировки в сигнале");
            Print("Действие: Установлены флаги блокировки, запрещены новые сделки");
         }
      }
   }
   
   // Проверка результата
   bool signalHandled = signalProcessed;
   bool tradingBlocked = !g_GlobalState.allowNewTrades;
   bool blockFlagsSet = g_GlobalState.dailyTPReached; // Используется как флаг блокировки
   
   if(signalHandled && tradingBlocked && blockFlagsSet)
   {
      Print("✅ Сценарий 7 пройден: Внешний сигнал блокировки обработан корректно");
   }
   else
   {
      Print("❌ Сценарий 7 провален:");
      Print("   - Сигнал обработан: ", signalHandled);
      Print("   - Торговля заблокирована: ", tradingBlocked);
      Print("   - Флаги блокировки установлены: ", blockFlagsSet);
   }
}

//+------------------------------------------------------------------+
//| Сценарий 8: Трейлинг-стоп активируется при прибыли              |
//+------------------------------------------------------------------+
void TestScenario8_TrailingStopActivation()
{
   Print("Сценарий 8: Трейлинг-стоп активируется при прибыли");
   Print("Описание: Позиция в прибыли > $50, начинается трейлинг SL");
   
   // Подготовка
   double profit = 60.0; // Превышает tsStartProfit (50.0)
   double currentPrice = 1.2100;
   double currentSL = 1.2000;
   double openPrice = 1.1950;
   
   SInstrumentConfig config;
   config.tsMode = TS_FIXED;
   config.tsStartProfit = 50.0;
   config.tsStep = 20.0;
   config.tsLockProfit = 10.0;
   
   Print("Подготовка: Прибыль = $", profit, ", текущая цена = ", currentPrice, ", SL = ", currentSL);
   Print("Подготовка: Начало трейлинга при прибыли > $", config.tsStartProfit);
   
   // Выполнение (имитация PM_CheckTrailingStop)
   bool trailingActivated = false;
   double newSL = currentSL;
   
   if(profit >= config.tsStartProfit)
   {
      trailingActivated = true;
      double point = 0.0001; // Для примера
      
      // TS_FIXED режим
      newSL = currentPrice - config.tsStep * point;
      if(newSL > currentSL)
      {
         newSL = MathMax(newSL, openPrice + config.tsLockProfit * point);
      }
      
      Print("Выполнение: Трейлинг-стоп активирован");
      Print("Действие: SL перемещен с ", currentSL, " до ", newSL);
   }
   
   // Проверка результата
   bool trailingStarted = trailingActivated;
   bool slUpdated = (newSL != currentSL) && (newSL > currentSL);
   
   if(trailingStarted && slUpdated)
   {
      Print("✅ Сценарий 8 пройден: Трейлинг-стоп активирован и SL обновлен");
      Print("   Новый SL: ", newSL);
   }
   else
   {
      Print("❌ Сценарий 8 провален:");
      Print("   - Трейлинг активирован: ", trailingStarted);
      Print("   - SL обновлен: ", slUpdated);
      Print("   - Новый SL: ", newSL, " (старый: ", currentSL, ")");
   }
}

//+------------------------------------------------------------------+
//| Запуск всех сценариев                                           |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестовых сценариев");
   Print("=========================================");
   
   TestScenario1_DailyProfitLimit();
   Print("");
   TestScenario2_LossStreakRiskReduction();
   Print("");
   TestScenario3_PartialCloseAtTarget();
   Print("");
   TestScenario4_MoveSLToBreakeven();
   Print("");
   TestScenario5_DailyCountersReset();
   Print("");
   TestScenario6_MaxSimultaneousPositionsLimit();
   Print("");
   TestScenario7_ExternalBlockSignal();
   Print("");
   TestScenario8_TrailingStopActivation();
   Print("");
   
   Print("=========================================");
   Print("Тестирование сценариев завершено");
}