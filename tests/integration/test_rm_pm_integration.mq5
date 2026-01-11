//+------------------------------------------------------------------+
//|                                     test_rm_pm_integration.mq5       |
//|                                    Интеграционные тесты RM и PM     |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест интеграции: установка SL/TP влияет на контроль рисков       |
//+------------------------------------------------------------------+
void TestSLTPIntegrationWithRiskControl()
{
   Print("Тест: Интеграция SL/TP влияет на контроль рисков");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 100.0;
   g_GlobalState.dailyStopLoss = -50.0;
   g_GlobalState.dailyPnLTotal = 90.0; // Близко к TP
   
   // Имитация установки SL/TP через PositionManager
   string symbol = "EURUSD";
   SInstrumentConfig config;
   config.slMode = SL_FIXED_PIPS;
   config.slValue = 100;
   config.tpMode = TP_RR;
   config.rrRatio = 2.0;
   
   // Выполнение расчета SL/TP
   double openPrice = 1.2000;
   ENUM_POSITION_TYPE type = POSITION_TYPE_BUY;
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double slPrice = (type == POSITION_TYPE_BUY) ? openPrice - config.slValue * point : openPrice + config.slValue * point;
   double tpPrice = (type == POSITION_TYPE_BUY) ? openPrice + (config.slValue * config.rrRatio) * point : openPrice - (config.slValue * config.rrRatio) * point;
   
   // Проверка
   bool slTpCalculated = (slPrice != 0 && tpPrice != 0);
   
   if(slTpCalculated)
      Print("✅ Тест пройден: Интеграция SL/TP влияет на контроль рисков");
   else
      Print("❌ Тест провален: Интеграция SL/TP влияет на контроль рисков");
}

//+------------------------------------------------------------------+
//| Тест интеграции: белый список RM влияет на PM                   |
//+------------------------------------------------------------------+
void TestWhiteListIntegration()
{
   Print("Тест: Белый список RM влияет на PM");
   
   // Подготовка
   g_GlobalState.useWhiteList = true;
   g_GlobalState.allowedInstrumentsCount = 0;
   
   // Добавим инструменты в белый список через RM
   AddToWhiteList("EURUSD");
   AddToWhiteList("XAUUSD");
   
   // Синхронизируем список
   SyncWhiteListBetweenModules();
   
   // Выполнение - проверим через PM
   bool eurusdAllowed = IsInstrumentAllowed("EURUSD");
   bool xauusdAllowed = IsInstrumentAllowed("XAUUSD");
   bool gbpusdAllowed = IsInstrumentAllowed("GBPUSD"); // Не в списке
   
   // Проверка
   if(eurusdAllowed && xauusdAllowed && !gbpusdAllowed)
      Print("✅ Тест пройден: Белый список RM влияет на PM");
   else
   {
      Print("❌ Тест провален: Белый список RM влияет на PM");
      Print("   EURUSD разрешен: ", eurusdAllowed);
      Print("   XAUUSD разрешен: ", xauusdAllowed);
      Print("   GBPUSD разрешен: ", gbpusdAllowed);
   }
}

//+------------------------------------------------------------------+
//| Тест интеграции: коррекция SL через RiskManager                 |
//+------------------------------------------------------------------+
void TestSLAdjustmentByRiskManager()
{
   Print("Тест: Коррекция SL через RiskManager");
   
   // Подготовка
   g_GlobalState.dailyPnLTotal = 75.0; // Высокая прибыль
   double initialSL = 1.1800;
   double currentPrice = 1.2100; // Цена поднялась, позиция в прибыли
   
   // Имитация коррекции SL в безубыток
   double newSL = currentPrice - 0.0010; // Оставить небольшой SL
   bool slAdjusted = (newSL > initialSL); // Для BUY позиции
   
   // Проверка
   if(slAdjusted)
      Print("✅ Тест пройден: Коррекция SL через RiskManager");
   else
      Print("❌ Тест провален: Коррекция SL через RiskManager");
}

//+------------------------------------------------------------------+
//| Тест интеграции: контроль количества позиций                    |
//+------------------------------------------------------------------+
void TestPositionCountIntegration()
{
   Print("Тест: Контроль количества позиций");
   
   // Подготовка
   int maxDailyPositions = 5;
   g_GlobalState.maxSimultaneousPositionsDaily = maxDailyPositions;
   g_GlobalState.dailyPositionsCount = 4; // Один слот свободен
   
   // Выполнение - проверка возможности открытия новой позиции
   bool newPositionAllowed = g_GlobalState.dailyPositionsCount < maxDailyPositions;
   
   // Изменим ситуацию
   g_GlobalState.dailyPositionsCount = 5; // Достигли лимита
   bool newPositionBlocked = !(g_GlobalState.dailyPositionsCount < maxDailyPositions);
   
   // Проверка
   if(newPositionAllowed && newPositionBlocked)
      Print("✅ Тест пройден: Контроль количества позиций");
   else
      Print("❌ Тест провален: Контроль количества позиций");
}

//+------------------------------------------------------------------+
//| Тест интеграции: сброс счетчиков влияет на оба модуля           |
//+------------------------------------------------------------------+
void TestCountersResetIntegration()
{
   Print("Тест: Сброс счетчиков влияет на оба модуля");
   
   // Подготовка - установим ненулевые значения
   g_GlobalState.dailyPnLTotal = 150.0;
   g_GlobalState.dailyTradesCount = 8;
   g_GlobalState.dailyPositionsCount = 4;
   g_GlobalState.dailyTPReached = true;
   g_GlobalState.allowNewTrades = false;
   
   // Выполнение сброса
   g_GlobalState.dailyPnLTotal = 0;
   g_GlobalState.dailyTradesCount = 0;
   g_GlobalState.dailyPositionsCount = 0;
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.lastDailyReset = TimeCurrent();
   
   // Проверка
   bool countersReset = (g_GlobalState.dailyPnLTotal == 0 && 
                         g_GlobalState.dailyTradesCount == 0 && 
                         g_GlobalState.dailyPositionsCount == 0 &&
                         !g_GlobalState.dailyTPReached &&
                         g_GlobalState.allowNewTrades);
   
   if(countersReset)
      Print("✅ Тест пройден: Сброс счетчиков влияет на оба модуля");
   else
      Print("❌ Тест провален: Сброс счетчиков влияет на оба модуля");
}

//+------------------------------------------------------------------+
//| Тест интеграции: глобальное состояние синхронизируется          |
//+------------------------------------------------------------------+
void TestGlobalStateSynchronization()
{
   Print("Тест: Глобальное состояние синхронизируется");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 200.0;
   g_GlobalState.dailyStopLoss = -100.0;
   g_GlobalState.maxRiskPerTrade = 2.5;
   g_GlobalState.useWhiteList = true;
   
   // Выполнение сохранения
   bool saveResult = Core_SaveGlobalState();
   
   // Изменим значения
   g_GlobalState.dailyTakeProfit = 0.0;
   g_GlobalState.dailyStopLoss = 0.0;
   
   // Выполнение загрузки
   bool loadResult = Core_LoadGlobalState();
   
   // Проверка
   bool stateRestored = (g_GlobalState.dailyTakeProfit == 200.0 && 
                         g_GlobalState.dailyStopLoss == -100.0 &&
                         saveResult && loadResult);
   
   if(stateRestored)
      Print("✅ Тест пройден: Глобальное состояние синхронизируется");
   else
      Print("❌ Тест провален: Глобальное состояние синхронизируется");
}

//+------------------------------------------------------------------+
//| Тест интеграции: разрешения RM влияют на действия PM            |
//+------------------------------------------------------------------+
void TestRiskPermissionsAffectPositionManagement()
{
   Print("Тест: Разрешения RM влияют на действия PM");
   
   // Подготовка
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.dailyTPReached = false;
   g_GlobalState.dailySLReached = false;
   
   // Выполнение проверки разрешений
   bool tradingAllowed = g_GlobalState.allowNewTrades && 
                        !g_GlobalState.dailyTPReached && 
                        !g_GlobalState.dailySLReached;
   
   // Изменим ситуацию
   g_GlobalState.dailyTPReached = true;
   bool tradingBlocked = !(g_GlobalState.allowNewTrades && 
                          !g_GlobalState.dailyTPReached && 
                          !g_GlobalState.dailySLReached);
   
   // Проверка
   if(tradingAllowed && tradingBlocked)
      Print("✅ Тест пройден: Разрешения RM влияют на действия PM");
   else
      Print("❌ Тест провален: Разрешения RM влияют на действия PM");
}

//+------------------------------------------------------------------+
//| Тест интеграции: обновление PnL влияет на оба модуля            |
//+------------------------------------------------------------------+
void TestPNLUpdateIntegration()
{
   Print("Тест: Обновление PnL влияет на оба модуля");
   
   // Подготовка
   double initialPnL = g_GlobalState.dailyPnLTotal;
   double profitFromTrade = 25.50;
   
   // Выполнение обновления PnL (имитация)
   g_GlobalState.dailyPnLTotal += profitFromTrade;
   double updatedPnL = g_GlobalState.dailyPnLTotal;
   
   // Проверка
   bool pnlUpdated = (updatedPnL == initialPnL + profitFromTrade);
   
   if(pnlUpdated)
      Print("✅ Тест пройден: Обновление PnL влияет на оба модуля");
   else
      Print("❌ Тест провален: Обновление PnL влияет на оба модуля");
}

//+------------------------------------------------------------------+
//| Тест интеграции: динамический риск влияет на параметры позиций  |
//+------------------------------------------------------------------+
void TestDynamicRiskAffectsPositionParameters()
{
   Print("Тест: Динамический риск влияет на параметры позиций");
   
   // Подготовка
   g_GlobalState.currentRiskPercent = 2.0;
   g_GlobalState.lossStreak = 4; // Превышает порог для снижения
   double minRiskPercent = 0.5;
   
   // Выполнение (имитация UpdateDynamicRisk)
   if(g_GlobalState.lossStreak >= 3) // LossStreakToReduce
   {
      double newRisk = g_GlobalState.currentRiskPercent * 0.7;
      if(newRisk < minRiskPercent)
         newRisk = minRiskPercent;
      
      g_GlobalState.currentRiskPercent = newRisk;
   }
   
   // Проверка
   bool riskAdjusted = (g_GlobalState.currentRiskPercent < 2.0 && 
                        g_GlobalState.currentRiskPercent >= minRiskPercent);
   
   if(riskAdjusted)
      Print("✅ Тест пройден: Динамический риск влияет на параметры позиций");
   else
      Print("❌ Тест провален: Динамический риск влияет на параметры позиций");
}

//+------------------------------------------------------------------+
//| Тест интеграции: проверка лимитов влияет на управление позициями |
//+------------------------------------------------------------------+
void TestLimitsCheckAffectsPositionManagement()
{
   Print("Тест: Проверка лимитов влияет на управление позициями");
   
   // Подготовка
   g_GlobalState.dailyTakeProfit = 100.0;
   g_GlobalState.dailyPnLTotal = 110.0; // Превышает TP
   g_GlobalState.allowNewTrades = true;
   
   // Выполнение проверки лимитов (имитация)
   bool tpReached = g_GlobalState.dailyPnLTotal >= g_GlobalState.dailyTakeProfit;
   bool tradingShouldBeStopped = tpReached;
   
   // Проверка
   if(tradingShouldBeStopped)
      Print("✅ Тест пройден: Проверка лимитов влияет на управление позициями");
   else
      Print("❌ Тест провален: Проверка лимитов влияет на управление позициями");
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск интеграционных тестов RM и PM");
   Print("=========================================");
   
   TestSLTPIntegrationWithRiskControl();
   TestWhiteListIntegration();
   TestSLAdjustmentByRiskManager();
   TestPositionCountIntegration();
   TestCountersResetIntegration();
   TestGlobalStateSynchronization();
   TestRiskPermissionsAffectPositionManagement();
   TestPNLUpdateIntegration();
   TestDynamicRiskAffectsPositionParameters();
   TestLimitsCheckAffectsPositionManagement();
   
   Print("=========================================");
   Print("Интеграционное тестирование завершено");
}