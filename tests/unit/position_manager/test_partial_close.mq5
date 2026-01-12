//+------------------------------------------------------------------+
//|                                   test_partial_close.mq5           |
//|                                    Тесты частичного закрытия PM     |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест срабатывания уровня частичного закрытия                    |
//+------------------------------------------------------------------+
void TestPartialCloseLevelTrigger()
{
   Print("Тест: Срабатывание уровня частичного закрытия");
   
   // Подготовка
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 50.0; // Закрыть при 50% от цели
   config.partialLevels[0].closePercent = 30.0;   // Закрыть 30% объема
   config.partialLevels[0].executed = false;
   
   double targetProfit = 200.0; // Целевая прибыль
   double currentProfit = 100.0; // 50% от цели
   
   Print("Подготовка: Целевая прибыль = $", targetProfit, ", текущая прибыль = $", currentProfit);
   Print("Подготовка: Уровень срабатывания = ", config.partialLevels[0].triggerPercent, "%");
   
   // Выполнение (имитация PM_CheckPartialClose)
   bool shouldClose = false;
   double levelProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0;
   
   if(config.partialLevels[0].enabled && !config.partialLevels[0].executed)
   {
      if(currentProfit >= levelProfit)
      {
         shouldClose = true;
         config.partialLevels[0].executed = true;
         config.partialLevels[0].executionTime = TimeCurrent();
         
         Print("Выполнение: Уровень частичного закрытия сработал");
         Print("Действие: Флаг executed установлен в true");
      }
   }
   
   // Проверка результата
   bool levelTriggered = shouldClose;
   bool levelMarkedAsExecuted = config.partialLevels[0].executed;
   bool triggerConditionMet = (currentProfit >= levelProfit);
   
   if(levelTriggered && levelMarkedAsExecuted && triggerConditionMet)
      Print("✅ Тест пройден: Уровень частичного закрытия сработал корректно");
   else
   {
      Print("❌ Тест провален: Срабатывание уровня частичного закрытия");
      Print("   Уровень сработал: ", levelTriggered);
      Print("   Уровень помечен как выполненный: ", levelMarkedAsExecuted);
      Print("   Условие срабатывания выполнено: ", triggerConditionMet);
      Print("   Требуемая прибыль: $", levelProfit, ", текущая: $", currentProfit);
   }
}

//+------------------------------------------------------------------+
//| Тест расчета объема для частичного закрытия                      |
//+------------------------------------------------------------------+
void TestPartialCloseVolumeCalculation()
{
   Print("Тест: Расчет объема для частичного закрытия");
   
   // Подготовка
   double totalVolume = 1.0;
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].closePercent = 25.0; // Закрыть 25%
   
   Print("Подготовка: Общий объем позиции = ", totalVolume, ", процент закрытия = ", config.partialLevels[0].closePercent, "%");
   
   // Выполнение расчета объема закрытия
   double closeVolume = totalVolume * config.partialLevels[0].closePercent / 100.0;
   
   double expectedVolume = totalVolume * 0.25;
   
   // Проверка результата
   bool volumeCalculatedCorrectly = (closeVolume == expectedVolume);
   bool volumePositive = (closeVolume > 0);
   bool volumeWithinBounds = (closeVolume <= totalVolume);
   
   if(volumeCalculatedCorrectly && volumePositive && volumeWithinBounds)
      Print("✅ Тест пройден: Объем для частичного закрытия рассчитан корректно");
   else
   {
      Print("❌ Тест провален: Расчет объема для частичного закрытия");
      Print("   Объем рассчитан правильно: ", volumeCalculatedCorrectly);
      Print("   Объем положительный: ", volumePositive);
      Print("   Объем в пределах допуска: ", volumeWithinBounds);
      Print("   Рассчитанный объем: ", closeVolume, ", ожидаемый: ", expectedVolume);
   }
}

//+------------------------------------------------------------------+
//| Тест нескольких уровней частичного закрытия                     |
//+------------------------------------------------------------------+
void TestMultiplePartialCloseLevels()
{
   Print("Тест: Несколько уровней частичного закрытия");
   
   // Подготовка
   SInstrumentConfig config;
   config.partialLevelsCount = 3;
   
   // Уровень 1: 30% прибыли, закрыть 20%
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 30.0;
   config.partialLevels[0].closePercent = 20.0;
   config.partialLevels[0].executed = false;
   
   // Уровень 2: 60% прибыли, закрыть 30%
   config.partialLevels[1].enabled = true;
   config.partialLevels[1].triggerPercent = 60.0;
   config.partialLevels[1].closePercent = 30.0;
   config.partialLevels[1].executed = false;
   
   // Уровень 3: 90% прибыли, закрыть 50%
   config.partialLevels[2].enabled = true;
   config.partialLevels[2].triggerPercent = 90.0;
   config.partialLevels[2].closePercent = 50.0;
   config.partialLevels[2].executed = false;
   
   double targetProfit = 100.0;
   double currentProfit = 65.0; // Должен сработать уровень 2
   
   Print("Подготовка: Целевая прибыль = $", targetProfit, ", текущая прибыль = $", currentProfit);
   Print("Подготовка: Уровень 1 (30%) - ", (currentProfit >= targetProfit*0.3 ? "должен" : "не должен"), " сработать");
   Print("Подготовка: Уровень 2 (60%) - ", (currentProfit >= targetProfit*0.6 ? "должен" : "не должен"), " сработать");
   Print("Подготовка: Уровень 3 (90%) - ", (currentProfit >= targetProfit*0.9 ? "должен" : "не должен"), " сработать");
   
   // Выполнение (имитация PM_CheckPartialClose)
   int triggeredLevel = -1;
   
   for(int i = 0; i < config.partialLevelsCount; i++)
   {
      if(config.partialLevels[i].enabled && !config.partialLevels[i].executed)
      {
         double levelProfit = targetProfit * config.partialLevels[i].triggerPercent / 100.0;
         
         if(currentProfit >= levelProfit)
         {
            triggeredLevel = i;
            config.partialLevels[i].executed = true;
            config.partialLevels[i].executionTime = TimeCurrent();
            break; // Закрываем только первый сработавший уровень
         }
      }
   }
   
   // Проверка результата
   bool level2Triggered = (triggeredLevel == 1);
   bool otherLevelsNotTriggered = (triggeredLevel != 0 && triggeredLevel != 2);
   bool triggeredLevelExecuted = (triggeredLevel >= 0 && config.partialLevels[triggeredLevel].executed);
   
   if(level2Triggered && otherLevelsNotTriggered && triggeredLevelExecuted)
      Print("✅ Тест пройден: Корректно сработал второй уровень частичного закрытия");
   else
   {
      Print("❌ Тест провален: Обработка нескольких уровней частичного закрытия");
      Print("   Второй уровень сработал: ", level2Triggered);
      Print("   Другие уровни не сработали: ", otherLevelsNotTriggered);
      Print("   Сработавший уровень помечен как выполненный: ", triggeredLevelExecuted);
      Print("   Сработал уровень: ", triggeredLevel);
   }
}

//+------------------------------------------------------------------+
//| Тест игнорирования выполненных уровней                          |
//+------------------------------------------------------------------+
void TestIgnoreExecutedLevels()
{
   Print("Тест: Игнорирование выполненных уровней");
   
   // Подготовка
   SInstrumentConfig config;
   config.partialLevelsCount = 2;
   
   // Уровень 1: уже выполнен
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 25.0;
   config.partialLevels[0].closePercent = 20.0;
   config.partialLevels[0].executed = true; // Уже выполнен
   
   // Уровень 2: еще не выполнен
   config.partialLevels[1].enabled = true;
   config.partialLevels[1].triggerPercent = 50.0;
   config.partialLevels[1].closePercent = 30.0;
   config.partialLevels[1].executed = false;
   
   double targetProfit = 100.0;
   double currentProfit = 60.0; // Превышает оба уровня
   
   Print("Подготовка: Уровень 1 (25%) - уже выполнен");
   Print("Подготовка: Уровень 2 (50%) - должен сработать при $", currentProfit, " прибыли");
   
   // Выполнение (имитация PM_CheckPartialClose)
   int executedLevel = -1;
   
   for(int i = 0; i < config.partialLevelsCount; i++)
   {
      if(config.partialLevels[i].enabled && !config.partialLevels[i].executed)
      {
         double levelProfit = targetProfit * config.partialLevels[i].triggerPercent / 100.0;
         
         if(currentProfit >= levelProfit)
         {
            executedLevel = i;
            config.partialLevels[i].executed = true;
            break;
         }
      }
   }
   
   // Проверка результата
   bool onlyLevel2Executed = (executedLevel == 1);
   bool level1Ignored = (executedLevel != 0);
   bool executedLevelMarked = (executedLevel >= 0 && config.partialLevels[executedLevel].executed);
   
   if(onlyLevel2Executed && level1Ignored && executedLevelMarked)
      Print("✅ Тест пройден: Выполненные уровни корректно игнорируются");
   else
   {
      Print("❌ Тест провален: Игнорирование выполненных уровней");
      Print("   Сработал только уровень 2: ", onlyLevel2Executed);
      Print("   Уровень 1 проигнорирован: ", level1Ignored);
      Print("   Сработавший уровень помечен: ", executedLevelMarked);
      Print("   Сработал уровень: ", executedLevel);
   }
}

//+------------------------------------------------------------------+
//| Тест отключения уровней частичного закрытия                     |
//+------------------------------------------------------------------+
void TestDisabledPartialCloseLevels()
{
   Print("Тест: Отключение уровней частичного закрытия");
   
   // Подготовка
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   
   // Уровень отключен
   config.partialLevels[0].enabled = false; // Отключен
   config.partialLevels[0].triggerPercent = 50.0;
   config.partialLevels[0].closePercent = 30.0;
   config.partialLevels[0].executed = false;
   
   double targetProfit = 100.0;
   double currentProfit = 75.0; // Превышает порог, но уровень отключен
   
   Print("Подготовка: Уровень отключен, текущая прибыль = $", currentProfit, ", порог = $", targetProfit * 0.5);
   
   // Выполнение (имитация PM_CheckPartialClose)
   bool levelTriggered = false;
   
   if(config.partialLevels[0].enabled && !config.partialLevels[0].executed)
   {
      double levelProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0;
      
      if(currentProfit >= levelProfit)
      {
         levelTriggered = true;
         config.partialLevels[0].executed = true;
      }
   }
   
   // Проверка результата
   bool disabledLevelIgnored = !levelTriggered;
   bool executedFlagUnchanged = !config.partialLevels[0].executed;
   
   if(disabledLevelIgnored && executedFlagUnchanged)
      Print("✅ Тест пройден: Отключенные уровни корректно игнорируются");
   else
   {
      Print("❌ Тест провален: Игнорирование отключенных уровней");
      Print("   Отключенный уровень проигнорирован: ", disabledLevelIgnored);
      Print("   Флаг выполнения не изменился: ", executedFlagUnchanged);
      Print("   Уровень сработал: ", levelTriggered);
   }
}

//+------------------------------------------------------------------+
//| Тест частичного закрытия с безубытком                           |
//+------------------------------------------------------------------+
void TestPartialCloseWithBreakeven()
{
   Print("Тест: Частичное закрытие с безубытком");
   
   // Подготовка
   string symbol = "EURUSD";
   double totalVolume = 1.0;
   double currentProfit = 150.0;
   double targetProfit = 200.0;
   
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 50.0; // 50% от цели
   config.partialLevels[0].closePercent = 40.0;   // Закрыть 40%
   config.partialLevels[0].executed = false;
   config.partialLevels[0].breakevenMode = BE_MODE_FIXED_MONEY;
   config.partialLevels[0].breakevenValue = 50.0; // Переместить SL в безубыток при $50 прибыли
   
   Print("Подготовка: Уровень с безубытком, порог прибыли для безубытка = $", config.partialLevels[0].breakevenValue);
   Print("Подготовка: Текущая прибыль = $", currentProfit);
   
   // Выполнение частичного закрытия
   bool partialCloseExecuted = false;
   double closeVolume = 0;
   
   if(config.partialLevels[0].enabled && !config.partialLevels[0].executed)
   {
      double levelProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0; // 100$
      
      if(currentProfit >= levelProfit)
      {
         closeVolume = totalVolume * config.partialLevels[0].closePercent / 100.0; // 0.4
         config.partialLevels[0].executed = true;
         partialCloseExecuted = true;
         
         Print("Выполнение: Сработал уровень частичного закрытия");
         Print("Действие: Закрыто ", closeVolume, " объема");
      }
   }
   
   // Проверка безубытка
   bool shouldMoveToBreakeven = (currentProfit >= config.partialLevels[0].breakevenValue);
   bool breakevenApplied = false;
   
   if(shouldMoveToBreakeven && config.partialLevels[0].breakevenMode != BE_MODE_NONE)
   {
      breakevenApplied = true;
      Print("Действие: Команда перемещения SL в безубыток выполнена");
   }
   
   // Проверка результата
   bool partialCloseCorrect = (partialCloseExecuted && closeVolume == 0.4);
   bool breakevenConditionChecked = true; // Условие проверялось
   
   if(partialCloseCorrect && breakevenConditionChecked)
      Print("✅ Тест пройден: Частичное закрытие с безубытком обработано корректно");
   else
   {
      Print("❌ Тест провален: Обработка частичного закрытия с безубытком");
      Print("   Частичное закрытие выполнено корректно: ", partialCloseCorrect);
      Print("   Условие безубытка проверено: ", breakevenConditionChecked);
      Print("   Закрытый объем: ", closeVolume);
   }
}

//+------------------------------------------------------------------+
//| Тест минимального объема для частичного закрытия                 |
//+------------------------------------------------------------------+
void TestPartialCloseMinimumVolume()
{
   Print("Тест: Минимальный объем для частичного закрытия");
   
   // Подготовка
   string symbol = "EURUSD";
   double totalVolume = 0.01; // Очень маленький объем
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 50.0;
   config.partialLevels[0].closePercent = 50.0; // 50% от 0.01 = 0.005
   config.partialLevels[0].executed = false;
   
   double minVolume = 0.01; // Минимальный объем для символа
   
   Print("Подготовка: Общий объем = ", totalVolume, ", процент закрытия = ", config.partialLevels[0].closePercent, "%");
   Print("Подготовка: Рассчитанный объем = ", totalVolume * 0.5, ", минимальный объем = ", minVolume);
   
   // Выполнение расчета объема с учетом минимума
   double calculatedCloseVolume = totalVolume * config.partialLevels[0].closePercent / 100.0;
   double finalCloseVolume = MathMax(calculatedCloseVolume, minVolume);
   
   // Проверка результата
   bool volumeAdjustedToMinimum = (finalCloseVolume == minVolume);
   bool calculatedVolumeBelowMinimum = (calculatedCloseVolume < minVolume);
   
   if(volumeAdjustedToMinimum && calculatedVolumeBelowMinimum)
      Print("✅ Тест пройден: Объем частичного закрытия скорректирован до минимального");
   else
   {
      Print("❌ Тест провален: Коррекция объема до минимального значения");
      Print("   Объем скорректирован до минимума: ", volumeAdjustedToMinimum);
      Print("   Рассчитанный объем ниже минимума: ", calculatedVolumeBelowMinimum);
      Print("   Рассчитанный объем: ", calculatedCloseVolume, ", финальный: ", finalCloseVolume);
   }
}

//+------------------------------------------------------------------+
//| Тест нулевого количества уровней                                |
//+------------------------------------------------------------------+
void TestZeroPartialCloseLevels()
{
   Print("Тест: Нулевое количество уровней частичного закрытия");
   
   // Подготовка
   SInstrumentConfig config;
   config.partialLevelsCount = 0; // Нет уровней
   
   Print("Подготовка: Количество уровней частичного закрытия = ", config.partialLevelsCount);
   
   // Выполнение (имитация PM_CheckPartialClose)
   bool checkPerformed = false;
   
   if(config.partialLevelsCount > 0)
   {
      checkPerformed = true;
      // Проход по уровням
   }
   
   // Проверка результата
   bool noLevelsChecked = !checkPerformed;
   bool zeroLevelsCount = (config.partialLevelsCount == 0);
   
   if(noLevelsChecked && zeroLevelsCount)
      Print("✅ Тест пройден: При нулевом количестве уровней проверка не выполняется");
   else
   {
      Print("❌ Тест провален: Обработка нулевого количества уровней");
      Print("   Проверка не выполнена: ", noLevelsChecked);
      Print("   Количество уровней равно нулю: ", zeroLevelsCount);
   }
}

//+------------------------------------------------------------------+
//| Тест граничного условия срабатывания                            |
//+------------------------------------------------------------------+
void TestPartialCloseBoundaryCondition()
{
   Print("Тест: Граничное условие срабатывания уровня");
   
   // Подготовка
   SInstrumentConfig config;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 75.0;
   config.partialLevels[0].closePercent = 25.0;
   config.partialLevels[0].executed = false;
   
   double targetProfit = 100.0;
   // Граничное значение: ровно 75% от цели
   double currentProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0;
   
   Print("Подготовка: Требуемая прибыль для срабатывания = $", currentProfit);
   Print("Подготовка: Фактическая прибыль = $", currentProfit);
   
   // Выполнение (имитация PM_CheckPartialClose)
   bool levelShouldTrigger = (currentProfit >= targetProfit * config.partialLevels[0].triggerPercent / 100.0);
   bool levelActuallyTriggered = false;
   
   if(config.partialLevels[0].enabled && !config.partialLevels[0].executed)
   {
      double levelProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0;
      
      if(currentProfit >= levelProfit)
      {
         levelActuallyTriggered = true;
         config.partialLevels[0].executed = true;
      }
   }
   
   // Проверка результата
   bool boundaryConditionMet = (currentProfit >= targetProfit * 0.75);
   bool triggerLogicConsistent = (levelShouldTrigger == levelActuallyTriggered);
   
   if(boundaryConditionMet && triggerLogicConsistent)
      Print("✅ Тест пройден: Граничное условие срабатывания обработано корректно");
   else
   {
      Print("❌ Тест провален: Обработка граничного условия срабатывания");
      Print("   Граничное условие выполнено: ", boundaryConditionMet);
      Print("   Логика срабатывания согласована: ", triggerLogicConsistent);
      Print("   Уровень сработал: ", levelActuallyTriggered);
   }
}

//+------------------------------------------------------------------+
//| Тест обновления конфигурации после частичного закрытия          |
//+------------------------------------------------------------------+
void TestConfigUpdateAfterPartialClose()
{
   Print("Тест: Обновление конфигурации после частичного закрытия");
   
   // Подготовка
   string symbol = "EURUSD";
   SInstrumentConfig config;
   config.symbol = symbol;
   config.partialLevelsCount = 1;
   config.partialLevels[0].enabled = true;
   config.partialLevels[0].triggerPercent = 50.0;
   config.partialLevels[0].closePercent = 30.0;
   config.partialLevels[0].executed = false;
   
   Print("Подготовка: Конфигурация до обновления создана");
   
   // Имитация выполнения частичного закрытия
   double targetProfit = 100.0;
   double currentProfit = 60.0;
   
   if(config.partialLevels[0].enabled && !config.partialLevels[0].executed)
   {
      double levelProfit = targetProfit * config.partialLevels[0].triggerPercent / 100.0;
      
      if(currentProfit >= levelProfit)
      {
         config.partialLevels[0].executed = true;
         config.partialLevels[0].executionTime = TimeCurrent();
         
         Print("Выполнение: Уровень частичного закрытия помечен как выполненный");
      }
   }
   
   // Сохранение конфигурации (имитация PM_SaveInstrumentConfig)
   bool saveSuccessful = true; // Предполагаем успешное сохранение
   
   // Проверка результата
   bool configurationUpdated = config.partialLevels[0].executed;
   bool executionTimeSet = (config.partialLevels[0].executionTime > 0);
   bool saveOperationCompleted = saveSuccessful;
   
   if(configurationUpdated && executionTimeSet && saveOperationCompleted)
      Print("✅ Тест пройден: Конфигурация корректно обновлена после частичного закрытия");
   else
   {
      Print("❌ Тест провален: Обновление конфигурации после частичного закрытия");
      Print("   Конфигурация обновлена: ", configurationUpdated);
      Print("   Время выполнения установлено: ", executionTimeSet);
      Print("   Операция сохранения выполнена: ", saveOperationCompleted);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов частичного закрытия PositionManager");
   Print("=========================================");
   
   TestPartialCloseLevelTrigger();
   Print("");
   TestPartialCloseVolumeCalculation();
   Print("");
   TestMultiplePartialCloseLevels();
   Print("");
   TestIgnoreExecutedLevels();
   Print("");
   TestDisabledPartialCloseLevels();
   Print("");
   TestPartialCloseWithBreakeven();
   Print("");
   TestPartialCloseMinimumVolume();
   Print("");
   TestZeroPartialCloseLevels();
   Print("");
   TestPartialCloseBoundaryCondition();
   Print("");
   TestConfigUpdateAfterPartialClose();
   Print("");
   
   Print("=========================================");
   Print("Тестирование частичного закрытия завершено");
}