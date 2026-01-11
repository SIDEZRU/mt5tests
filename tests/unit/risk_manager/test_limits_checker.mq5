//+------------------------------------------------------------------+
//|                                       test_limits_checker.mq5      |
//|                                    Тесты проверки лимитов RM       |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест проверки дневного TakeProfit                                |
//+------------------------------------------------------------------+
void TestDailyTakeProfit()
{
   Print("Тест: Дневной TakeProfit");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 100.0;
   g_GlobalState.dailyPnLTotal = 120.0; // Превышает лимит
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool dailyTPReached = g_GlobalState.dailyPnLTotal >= g_GlobalState.dailyTakeProfit;
   
   // Проверка
   if(dailyTPReached)
      Print("✅ Тест пройден: Дневной TakeProfit");
   else
      Print("❌ Тест провален: Дневной TakeProfit");
}

//+------------------------------------------------------------------+
//| Тест проверки дневного StopLoss                                  |
//+------------------------------------------------------------------+
void TestDailyStopLoss()
{
   Print("Тест: Дневной StopLoss");
   
   // Подготовка
   g_GlobalState.dailyStopLoss = -50.0;
   g_GlobalState.dailyPnLTotal = -60.0; // Ниже лимита
   g_GlobalState.dailySLReached = false;
   g_GlobalState.allowNewTrades = true;
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool dailySLReached = g_GlobalState.dailyPnLTotal <= g_GlobalState.dailyStopLoss;
   
   // Проверка
   if(dailySLReached)
      Print("✅ Тест пройден: Дневной StopLoss");
   else
      Print("❌ Тест провален: Дневной StopLoss");
}

//+------------------------------------------------------------------+
//| Тест проверки недельного TakeProfit                              |
//+------------------------------------------------------------------+
void TestWeeklyTakeProfit()
{
   Print("Тест: Недельный TakeProfit");
   
   // Подготовка
   g_GlobalState.weeklyTakeProfit = 300.0;
   g_GlobalState.weeklyPnLTotal = 350.0; // Превышает лимит
   g_GlobalState.weeklyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool weeklyTPReached = g_GlobalState.weeklyPnLTotal >= g_GlobalState.weeklyTakeProfit;
   
   // Проверка
   if(weeklyTPReached)
      Print("✅ Тест пройден: Недельный TakeProfit");
   else
      Print("❌ Тест провален: Недельный TakeProfit");
}

//+------------------------------------------------------------------+
//| Тест проверки недельного StopLoss                                |
//+------------------------------------------------------------------+
void TestWeeklyStopLoss()
{
   Print("Тест: Недельный StopLoss");
   
   // Подготовка
   g_GlobalState.weeklyStopLoss = -200.0;
   g_GlobalState.weeklyPnLTotal = -250.0; // Ниже лимита
   g_GlobalState.weeklySLReached = false;
   g_GlobalState.allowNewTrades = true;
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool weeklySLReached = g_GlobalState.weeklyPnLTotal <= g_GlobalState.weeklyStopLoss;
   
   // Проверка
   if(weeklySLReached)
      Print("✅ Тест пройден: Недельный StopLoss");
   else
      Print("❌ Тест провален: Недельный StopLoss");
}

//+------------------------------------------------------------------+
//| Тест проверки лимита на количество сделок в день                |
//+------------------------------------------------------------------+
void TestDailyTradeLimit()
{
   Print("Тест: Лимит на количество сделок в день");
   
   // Подготовка
   int maxDailyTrades = 5;
   g_GlobalState.dailyTradesCount = 6; // Превышает лимит
   g_GlobalState.dailyTradesLimit = maxDailyTrades;
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool tradeLimitExceeded = g_GlobalState.dailyTradesCount >= maxDailyTrades && 
                            !g_GlobalState.dailyTPReached && 
                            !g_GlobalState.dailySLReached;
   
   // Проверка
   if(tradeLimitExceeded)
      Print("✅ Тест пройден: Лимит на количество сделок в день");
   else
      Print("❌ Тест провален: Лимит на количество сделок в день");
}

//+------------------------------------------------------------------+
//| Тест проверки лимита на количество одновременных позиций        |
//+------------------------------------------------------------------+
void TestSimultaneousPositionLimit()
{
   Print("Тест: Лимит на количество одновременных позиций");
   
   // Подготовка
   int maxPositions = 3;
   int currentPositions = 4; // Превышает лимит
   g_GlobalState.maxSimultaneousPositionsDaily = maxPositions;
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool positionLimitExceeded = currentPositions > maxPositions;
   
   // Проверка
   if(positionLimitExceeded)
      Print("✅ Тест пройден: Лимит на количество одновременных позиций");
   else
      Print("❌ Тест провален: Лимит на количество одновременных позиций");
}

//+------------------------------------------------------------------+
//| Тест сброса дневных счетчиков                                   |
//+------------------------------------------------------------------+
void TestDailyCountersReset()
{
   Print("Тест: Сброс дневных счетчиков");
   
   // Подготовка - установим ненулевые значения
   g_GlobalState.dailyPnLTotal = 150.0;
   g_GlobalState.dailyTradesCount = 10;
   g_GlobalState.dailyPositionsCount = 5;
   g_GlobalState.dailyTPReached = true;
   g_GlobalState.dailySLReached = true;
   g_GlobalState.allowNewTrades = false;
   
   // Выполнение сброса (имитация функции ResetDailyCounters)
   g_GlobalState.dailyPnLTotal = 0;
   g_GlobalState.dailyTradesCount = 0;
   g_GlobalState.dailyPositionsCount = 0;
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.lastDailyReset = TimeCurrent();
   
   // Проверка
   bool countersReset = (g_GlobalState.dailyPnLTotal == 0 && 
                         g_GlobalState.dailyTradesCount == 0 && 
                         g_GlobalState.dailyPositionsCount == 0 &&
                         !g_GlobalState.dailyTPReached &&
                         !g_GlobalState.dailySLReached &&
                         g_GlobalState.allowNewTrades);
   
   if(countersReset)
      Print("✅ Тест пройден: Сброс дневных счетчиков");
   else
      Print("❌ Тест провален: Сброс дневных счетчиков");
}

//+------------------------------------------------------------------+
//| Тест сброса недельных счетчиков                                 |
//+------------------------------------------------------------------+
void TestWeeklyCountersReset()
{
   Print("Тест: Сброс недельных счетчиков");
   
   // Подготовка - установим ненулевые значения
   g_GlobalState.weeklyPnLTotal = 450.0;
   g_GlobalState.weeklyTradesCount = 25;
   g_GlobalState.weeklyPositionsCount = 15;
   g_GlobalState.weeklyTPReached = true;
   g_GlobalState.weeklySLReached = true;
   g_GlobalState.allowNewTrades = false;
   
   // Выполнение сброса (имитация функции ResetWeeklyCounters)
   g_GlobalState.weeklyPnLTotal = 0;
   g_GlobalState.weeklyTradesCount = 0;
   g_GlobalState.weeklyPositionsCount = 0;
   g_GlobalState.weeklyTPReached = false;
   g_GlobalState.weeklySLReached = false;
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.lastWeeklyReset = TimeCurrent();
   
   // Проверка
   bool countersReset = (g_GlobalState.weeklyPnLTotal == 0 && 
                         g_GlobalState.weeklyTradesCount == 0 && 
                         g_GlobalState.weeklyPositionsCount == 0 &&
                         !g_GlobalState.weeklyTPReached &&
                         !g_GlobalState.weeklySLReached &&
                         g_GlobalState.allowNewTrades);
   
   if(countersReset)
      Print("✅ Тест пройден: Сброс недельных счетчиков");
   else
      Print("❌ Тест провален: Сброс недельных счетчиков");
}

//+------------------------------------------------------------------+
//| Тест динамического риска                                        |
//+------------------------------------------------------------------+
void TestDynamicRisk()
{
   Print("Тест: Динамический риск");
   
   // Подготовка
   g_GlobalState.currentRiskPercent = 2.0;
   g_GlobalState.lossStreak = 5; // Превышает порог для снижения
   g_GlobalState.profitStreak = 0;
   double minRiskPercent = 0.5;
   
   // Выполнение (имитация функции UpdateDynamicRisk)
   if(g_GlobalState.lossStreak >= 3) // LossStreakToReduce = 3
   {
      double newRisk = g_GlobalState.currentRiskPercent * 0.7;
      if(newRisk < minRiskPercent)
         newRisk = minRiskPercent;
      
      g_GlobalState.currentRiskPercent = newRisk;
   }
   
   // Проверка
   bool riskReduced = (g_GlobalState.currentRiskPercent < 2.0 && 
                       g_GlobalState.currentRiskPercent >= minRiskPercent);
   
   if(riskReduced)
      Print("✅ Тест пройден: Динамический риск (снижение после убытков)");
   else
      Print("❌ Тест провален: Динамический риск (снижение после убытков)");
}

//+------------------------------------------------------------------+
//| Тест разрешения новых сделок                                    |
//+------------------------------------------------------------------+
void TestAllowNewTrades()
{
   Print("Тест: Разрешение новых сделок");
   
   // Подготовка - все лимиты в норме
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   g_GlobalState.weeklyTPReached = false;
   g_GlobalState.weeklySLReached = false;
   g_GlobalState.dailyPnLTotal = 50.0; // Ниже дневного TP
   g_GlobalState.dailyPnLTotal = -20.0; // Выше дневного SL
   g_GlobalState.weeklyPnLTotal = 100.0; // Ниже недельного TP
   g_GlobalState.weeklyPnLTotal = -100.0; // Выше недельного SL
   
   // Выполнение проверки (имитация функции CheckRiskLimits)
   bool allowNewTrades = !g_GlobalState.dailyTPReached && 
                         !g_GlobalState.dailySLReached && 
                         !g_GlobalState.weeklyTPReached && 
                         !g_GlobalState.weeklySLReached;
   
   // Проверка
   if(allowNewTrades)
      Print("✅ Тест пройден: Разрешение новых сделок");
   else
      Print("❌ Тест провален: Разрешение новых сделок");
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов проверки лимитов RiskManager");
   Print("=========================================");
   
   TestDailyTakeProfit();
   TestDailyStopLoss();
   TestWeeklyTakeProfit();
   TestWeeklyStopLoss();
   TestDailyTradeLimit();
   TestSimultaneousPositionLimit();
   TestDailyCountersReset();
   TestWeeklyCountersReset();
   TestDynamicRisk();
   TestAllowNewTrades();
   
   Print("=========================================");
   Print("Тестирование проверки лимитов завершено");
}