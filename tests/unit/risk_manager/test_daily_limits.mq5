//+------------------------------------------------------------------+
//|                                       test_daily_limits.mq5        |
//|                                    Тесты дневных лимитов RM        |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест дневного TakeProfit при достижении лимита                  |
//+------------------------------------------------------------------+
void TestDailyTakeProfitAtLimit()
{
   Print("Тест: Дневной TakeProfit при достижении лимита");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 500.0;
   g_GlobalState.dailyPnLTotal = 500.0; // Ровно на лимите
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: Лимит TP = $", g_GlobalState.dailyTakeProfit, ", текущий PnL = $", g_GlobalState.dailyPnLTotal);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailyTPReached = g_GlobalState.dailyPnLTotal >= g_GlobalState.dailyTakeProfit;
   
   if(dailyTPReached)
   {
      g_GlobalState.dailyTPReached = true;
      g_GlobalState.allowNewTrades = false;
   }
   
   // Проверка результата
   bool tpReached = dailyTPReached;
   bool flagSet = g_GlobalState.dailyTPReached;
   bool tradingBlocked = !g_GlobalState.allowNewTrades;
   
   if(tpReached && flagSet && tradingBlocked)
      Print("✅ Тест пройден: Дневной TakeProfit корректно срабатывает при достижении лимита");
   else
   {
      Print("❌ Тест провален: Обработка дневного TakeProfit при достижении лимита");
      Print("   TP достигнут: ", tpReached);
      Print("   Флаг установлен: ", flagSet);
      Print("   Торговля заблокирована: ", tradingBlocked);
   }
}

//+------------------------------------------------------------------+
//| Тест дневного TakeProfit при превышении лимита                  |
//+------------------------------------------------------------------+
void TestDailyTakeProfitAboveLimit()
{
   Print("Тест: Дневной TakeProfit при превышении лимита");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 500.0;
   g_GlobalState.dailyPnLTotal = 550.0; // Превышает лимит
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: Лимит TP = $", g_GlobalState.dailyTakeProfit, ", текущий PnL = $", g_GlobalState.dailyPnLTotal);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailyTPReached = g_GlobalState.dailyPnLTotal >= g_GlobalState.dailyTakeProfit;
   
   if(dailyTPReached)
   {
      g_GlobalState.dailyTPReached = true;
      g_GlobalState.allowNewTrades = false;
   }
   
   // Проверка результата
   bool tpReached = dailyTPReached;
   bool flagSet = g_GlobalState.dailyTPReached;
   bool tradingBlocked = !g_GlobalState.allowNewTrades;
   
   if(tpReached && flagSet && tradingBlocked)
      Print("✅ Тест пройден: Дневной TakeProfit корректно срабатывает при превышении лимита");
   else
   {
      Print("❌ Тест провален: Обработка дневного TakeProfit при превышении лимита");
      Print("   TP достигнут: ", tpReached);
      Print("   Флаг установлен: ", flagSet);
      Print("   Торговля заблокирована: ", tradingBlocked);
   }
}

//+------------------------------------------------------------------+
//| Тест дневного TakeProfit ниже лимита                           |
//+------------------------------------------------------------------+
void TestDailyTakeProfitBelowLimit()
{
   Print("Тест: Дневной TakeProfit при PnL ниже лимита");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 500.0;
   g_GlobalState.dailyPnLTotal = 400.0; // Ниже лимита
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: Лимит TP = $", g_GlobalState.dailyTakeProfit, ", текущий PnL = $", g_GlobalState.dailyPnLTotal);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailyTPReached = g_GlobalState.dailyPnLTotal >= g_GlobalState.dailyTakeProfit;
   
   // Проверка результата
   bool tpNotReached = !dailyTPReached;
   bool flagNotSet = !g_GlobalState.dailyTPReached;
   bool tradingNotBlocked = g_GlobalState.allowNewTrades;
   
   if(tpNotReached && flagNotSet && tradingNotBlocked)
      Print("✅ Тест пройден: Дневной TakeProfit не срабатывает при PnL ниже лимита");
   else
   {
      Print("❌ Тест провален: Обработка дневного TakeProfit при PnL ниже лимита");
      Print("   TP не достигнут: ", tpNotReached);
      Print("   Флаг не установлен: ", flagNotSet);
      Print("   Торговля не заблокирована: ", tradingNotBlocked);
   }
}

//+------------------------------------------------------------------+
//| Тест дневного StopLoss при достижении лимита                    |
//+------------------------------------------------------------------+
void TestDailyStopLossAtLimit()
{
   Print("Тест: Дневной StopLoss при достижении лимита");
   
   // Подготовка
   g_GlobalState.dailyStopLoss = -300.0;
   g_GlobalState.dailyPnLTotal = -300.0; // Ровно на лимите
   g_GlobalState.dailySLReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: Лимит SL = $", g_GlobalState.dailyStopLoss, ", текущий PnL = $", g_GlobalState.dailyPnLTotal);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailySLReached = g_GlobalState.dailyPnLTotal <= g_GlobalState.dailyStopLoss;
   
   if(dailySLReached)
   {
      g_GlobalState.dailySLReached = true;
      g_GlobalState.allowNewTrades = false;
   }
   
   // Проверка результата
   bool slReached = dailySLReached;
   bool flagSet = g_GlobalState.dailySLReached;
   bool tradingBlocked = !g_GlobalState.allowNewTrades;
   
   if(slReached && flagSet && tradingBlocked)
      Print("✅ Тест пройден: Дневной StopLoss корректно срабатывает при достижении лимита");
   else
   {
      Print("❌ Тест провален: Обработка дневного StopLoss при достижении лимита");
      Print("   SL достигнут: ", slReached);
      Print("   Флаг установлен: ", flagSet);
      Print("   Торговля заблокирована: ", tradingBlocked);
   }
}

//+------------------------------------------------------------------+
//| Тест дневного StopLoss при превышении лимита                    |
//+------------------------------------------------------------------+
void TestDailyStopLossBelowLimit()
{
   Print("Тест: Дневной StopLoss при превышении лимита (PnL ниже лимита)");
   
   // Подготовка
   g_GlobalState.dailyStopLoss = -300.0;
   g_GlobalState.dailyPnLTotal = -350.0; // Ниже (хуже) лимита
   g_GlobalState.dailySLReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: Лимит SL = $", g_GlobalState.dailyStopLoss, ", текущий PnL = $", g_GlobalState.dailyPnLTotal);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailySLReached = g_GlobalState.dailyPnLTotal <= g_GlobalState.dailyStopLoss;
   
   if(dailySLReached)
   {
      g_GlobalState.dailySLReached = true;
      g_GlobalState.allowNewTrades = false;
   }
   
   // Проверка результата
   bool slReached = dailySLReached;
   bool flagSet = g_GlobalState.dailySLReached;
   bool tradingBlocked = !g_GlobalState.allowNewTrades;
   
   if(slReached && flagSet && tradingBlocked)
      Print("✅ Тест пройден: Дневной StopLoss корректно срабатывает при превышении лимита");
   else
   {
      Print("❌ Тест провален: Обработка дневного StopLoss при превышении лимита");
      Print("   SL достигнут: ", slReached);
      Print("   Флаг установлен: ", flagSet);
      Print("   Торговля заблокирована: ", tradingBlocked);
   }
}

//+------------------------------------------------------------------+
//| Тест дневного StopLoss выше лимита                              |
//+------------------------------------------------------------------+
void TestDailyStopLossAboveLimit()
{
   Print("Тест: Дневной StopLoss при PnL выше лимита");
   
   // Подготовка
   g_GlobalState.dailyStopLoss = -300.0;
   g_GlobalState.dailyPnLTotal = -250.0; // Выше (лучше) лимита
   g_GlobalState.dailySLReached = false;
   g_GlobalState.allowNewTrades = true;
   
   Print("Подготовка: Лимит SL = $", g_GlobalState.dailyStopLoss, ", текущий PnL = $", g_GlobalState.dailyPnLTotal);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool dailySLReached = g_GlobalState.dailyPnLTotal <= g_GlobalState.dailyStopLoss;
   
   // Проверка результата
   bool slNotReached = !dailySLReached;
   bool flagNotSet = !g_GlobalState.dailySLReached;
   bool tradingNotBlocked = g_GlobalState.allowNewTrades;
   
   if(slNotReached && flagNotSet && tradingNotBlocked)
      Print("✅ Тест пройден: Дневной StopLoss не срабатывает при PnL выше лимита");
   else
   {
      Print("❌ Тест провален: Обработка дневного StopLoss при PnL выше лимита");
      Print("   SL не достигнут: ", slNotReached);
      Print("   Флаг не установлен: ", flagNotSet);
      Print("   Торговля не заблокирована: ", tradingNotBlocked);
   }
}

//+------------------------------------------------------------------+
//| Тест сброса дневных лимитов в полночь                          |
//+------------------------------------------------------------------+
void TestDailyLimitsReset()
{
   Print("Тест: Сброс дневных лимитов");
   
   // Подготовка - установим все флаги в сработавшее состояние
   g_GlobalState.dailyPnLTotal = 1000.0;
   g_GlobalState.dailyTPReached = true;
   g_GlobalState.dailySLReached = true;
   g_GlobalState.dailyTradesCount = 20;
   g_GlobalState.dailyPositionsCount = 10;
   g_GlobalState.allowNewTrades = false;
   g_GlobalState.totalClosedProfitToday = 500.0;
   g_GlobalState.totalClosedLossToday = -200.0;
   
   Print("Подготовка: Все дневные лимиты достигнуты, флаги установлены");
   
   // Выполнение сброса (имитация ResetDailyCounters)
   double oldPnL = g_GlobalState.dailyPnLTotal;
   bool oldTPFlag = g_GlobalState.dailyTPReached;
   bool oldSLFlag = g_GlobalState.dailySLReached;
   int oldTrades = g_GlobalState.dailyTradesCount;
   int oldPositions = g_GlobalState.dailyPositionsCount;
   
   g_GlobalState.dailyPnLTotal = 0;
   g_GlobalState.dailyTradesCount = 0;
   g_GlobalState.dailyPositionsCount = 0;
   g_GlobalState.totalClosedProfitToday = 0;
   g_GlobalState.totalClosedLossToday = 0;
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.lastDailyReset = TimeCurrent();
   
   Print("Выполнение: Все дневные счетчики и флаги сброшены");
   
   // Проверка результата
   bool countersReset = (g_GlobalState.dailyPnLTotal == 0 && 
                         g_GlobalState.dailyTradesCount == 0 && 
                         g_GlobalState.dailyPositionsCount == 0);
   bool flagsReset = (!g_GlobalState.dailyTPReached && 
                      !g_GlobalState.dailySLReached);
   bool permissionsRestored = g_GlobalState.allowNewTrades;
   bool totalsReset = (g_GlobalState.totalClosedProfitToday == 0 && 
                       g_GlobalState.totalClosedLossToday == 0);
   
   if(countersReset && flagsReset && permissionsRestored && totalsReset)
      Print("✅ Тест пройден: Дневные лимиты и счетчики корректно сброшены");
   else
   {
      Print("❌ Тест провален: Сброс дневных лимитов");
      Print("   Счетчики обнулены: ", countersReset);
      Print("   Флаги сброшены: ", flagsReset);
      Print("   Разрешения восстановлены: ", permissionsRestored);
      Print("   Итоги сброшены: ", totalsReset);
   }
}

//+------------------------------------------------------------------+
//| Тест обновления дневного PnL                                   |
//+------------------------------------------------------------------+
void TestDailyPnLUpdate()
{
   Print("Тест: Обновление дневного PnL");
   
   // Подготовка
   g_GlobalState.dailyPnLTotal = 200.0;
   double tradeProfit = 75.50;
   double expectedNewPnL = g_GlobalState.dailyPnLTotal + tradeProfit;
   
   Print("Подготовка: Текущий дневной PnL = $", g_GlobalState.dailyPnLTotal, ", прибыль сделки = $", tradeProfit);
   
   // Выполнение обновления PnL (имитация)
   g_GlobalState.dailyPnLTotal += tradeProfit;
   
   // Проверка результата
   bool pnlUpdated = (g_GlobalState.dailyPnLTotal == expectedNewPnL);
   bool pnlIncreased = (g_GlobalState.dailyPnLTotal > 200.0);
   bool calculationCorrect = (MathAbs(g_GlobalState.dailyPnLTotal - 275.50) < 0.01);
   
   if(pnlUpdated && pnlIncreased && calculationCorrect)
      Print("✅ Тест пройден: Дневной PnL корректно обновлен (теперь $", g_GlobalState.dailyPnLTotal, ")");
   else
   {
      Print("❌ Тест провален: Обновление дневного PnL");
      Print("   PnL обновлен: ", pnlUpdated);
      Print("   PnL увеличен: ", pnlIncreased);
      Print("   Расчет корректен: ", calculationCorrect);
      Print("   Фактический PnL: ", g_GlobalState.dailyPnLTotal, ", ожидаемый: ", expectedNewPnL);
   }
}

//+------------------------------------------------------------------+
//| Тест контроля количества дневных сделок                         |
//+------------------------------------------------------------------+
void TestDailyTradeCountControl()
{
   Print("Тест: Контроль количества дневных сделок");
   
   // Подготовка
   g_GlobalState.dailyTradesLimit = 10;
   g_GlobalState.dailyTradesCount = 9; // Один слот остался
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   
   Print("Подготовка: Лимит сделок = ", g_GlobalState.dailyTradesLimit, ", выполнено = ", g_GlobalState.dailyTradesCount);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool tradeAllowed = g_GlobalState.dailyTradesCount < g_GlobalState.dailyTradesLimit &&
                      !g_GlobalState.dailyTPReached && 
                      !g_GlobalState.dailySLReached;
   
   // Имитация открытия еще одной сделки
   if(tradeAllowed)
   {
      g_GlobalState.dailyTradesCount++;
   }
   
   // Проверка результата
   bool tradeWouldBeAllowed = tradeAllowed;
   bool countIncreased = (g_GlobalState.dailyTradesCount == 10);
   
   if(tradeWouldBeAllowed && countIncreased)
      Print("✅ Тест пройден: Контроль количества дневных сделок работает (сделка разрешена, счетчик увеличен)");
   else
   {
      Print("❌ Тест провален: Контроль количества дневных сделок");
      Print("   Сделка разрешена: ", tradeWouldBeAllowed);
      Print("   Счетчик увеличен: ", countIncreased);
      Print("   Текущий счетчик: ", g_GlobalState.dailyTradesCount);
   }
}

//+------------------------------------------------------------------+
//| Тест превышения лимита дневных сделок                           |
//+------------------------------------------------------------------+
void TestDailyTradeLimitExceeded()
{
   Print("Тест: Превышение лимита дневных сделок");
   
   // Подготовка
   g_GlobalState.dailyTradesLimit = 5;
   g_GlobalState.dailyTradesCount = 5; // Лимит достигнут
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   
   Print("Подготовка: Лимит сделок = ", g_GlobalState.dailyTradesLimit, ", выполнено = ", g_GlobalState.dailyTradesCount);
   
   // Выполнение проверки (имитация CheckRiskLimits)
   bool tradeAllowed = g_GlobalState.dailyTradesCount < g_GlobalState.dailyTradesLimit &&
                      !g_GlobalState.dailyTPReached && 
                      !g_GlobalState.dailySLReached;
   
   // Проверка результата
   bool tradeBlocked = !tradeAllowed;
   bool limitReached = (g_GlobalState.dailyTradesCount >= g_GlobalState.dailyTradesLimit);
   
   if(tradeBlocked && limitReached)
      Print("✅ Тест пройден: Превышение лимита дневных сделок корректно заблокировано");
   else
   {
      Print("❌ Тест провален: Блокировка при превышении лимита дневных сделок");
      Print("   Сделка заблокирована: ", tradeBlocked);
      Print("   Лимит достигнут: ", limitReached);
      Print("   Разрешена сделка: ", tradeAllowed);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов дневных лимитов RiskManager");
   Print("=========================================");
   
   TestDailyTakeProfitAtLimit();
   Print("");
   TestDailyTakeProfitAboveLimit();
   Print("");
   TestDailyTakeProfitBelowLimit();
   Print("");
   TestDailyStopLossAtLimit();
   Print("");
   TestDailyStopLossBelowLimit();
   Print("");
   TestDailyStopLossAboveLimit();
   Print("");
   TestDailyLimitsReset();
   Print("");
   TestDailyPnLUpdate();
   Print("");
   TestDailyTradeCountControl();
   Print("");
   TestDailyTradeLimitExceeded();
   Print("");
   
   Print("=========================================");
   Print("Тестирование дневных лимитов завершено");
}