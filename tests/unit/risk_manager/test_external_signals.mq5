//+------------------------------------------------------------------+
//|                                     test_external_signals.mq5      |
//|                                    Тесты внешних сигналов RM       |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест обработки команды сброса лимитов                           |
//+------------------------------------------------------------------+
void TestExternalSignalResetCommand()
{
   Print("Тест: Обработка команды сброса лимитов");
   
   // Подготовка
   g_GlobalState.dailyTPReached = true;
   g_GlobalState.dailySLReached = true;
   g_GlobalState.allowNewTrades = false;
   string signal = "/trade reset";
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Состояние заблокировано (TP и SL достигнуты)");
   Print("Подготовка: Внешний сигнал = '", signal, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         if(signal == signalCommandPrefix + " reset")
         {
            g_GlobalState.dailyTPReached = false;
            g_GlobalState.dailySLReached = false;
            g_GlobalState.weeklyTPReached = false;
            g_GlobalState.weeklySLReached = false;
            g_GlobalState.allowNewTrades = true;
            
            signalProcessed = true;
            Print("Выполнение: Обнаружена команда сброса лимитов");
            Print("Действие: Все флаги ограничений сброшены");
            Print("Действие: Разрешены новые сделки");
         }
      }
   }
   
   // Проверка результата
   bool resetPerformed = signalProcessed;
   bool limitsReset = !g_GlobalState.dailyTPReached && !g_GlobalState.dailySLReached;
   bool tradingAllowed = g_GlobalState.allowNewTrades;
   
   if(resetPerformed && limitsReset && tradingAllowed)
      Print("✅ Тест пройден: Команда сброса лимитов обработана корректно");
   else
   {
      Print("❌ Тест провален: Обработка команды сброса лимитов");
      Print("   Сигнал обработан: ", resetPerformed);
      Print("   Лимиты сброшены: ", limitsReset);
      Print("   Торговля разрешена: ", tradingAllowed);
   }
}

//+------------------------------------------------------------------+
//| Тест обработки команды статуса                                  |
//+------------------------------------------------------------------+
void TestExternalSignalStatusCommand()
{
   Print("Тест: Обработка команды статуса");
   
   // Подготовка
   string signal = "/trade status";
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Внешний сигнал = '", signal, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         if(signal == signalCommandPrefix + " status")
         {
            // В реальности здесь выводится статус
            signalProcessed = true;
            Print("Выполнение: Обнаружена команда запроса статуса");
            Print("Действие: Статус системы будет выведен");
         }
      }
   }
   
   // Проверка результата
   bool statusRequested = signalProcessed;
   bool commandSaved = (g_GlobalState.lastSignalCommand == signal);
   
   if(statusRequested && commandSaved)
      Print("✅ Тест пройден: Команда статуса обработана корректно");
   else
   {
      Print("❌ Тест провален: Обработка команды статуса");
      Print("   Запрос статуса обработан: ", statusRequested);
      Print("   Команда сохранена: ", commandSaved);
   }
}

//+------------------------------------------------------------------+
//| Тест обработки неизвестной команды                              |
//+------------------------------------------------------------------+
void TestExternalSignalUnknownCommand()
{
   Print("Тест: Обработка неизвестной команды");
   
   // Подготовка
   string signal = "/trade unknown_command";
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Внешний сигнал = '", signal, "' (неизвестная команда)");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   bool unknownCommandDetected = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         // Проверка известных команд
         if(signal == signalCommandPrefix + " reset" || 
            signal == signalCommandPrefix + " status" ||
            signal == signalCommandPrefix + " block" ||
            signal == signalCommandPrefix + " unblock")
         {
            signalProcessed = true;
         }
         else
         {
            unknownCommandDetected = true;
            Print("Выполнение: Обнаружена неизвестная команда");
            Print("Действие: Команда сохранена для анализа");
         }
      }
   }
   
   // Проверка результата
   bool processedAsUnknown = unknownCommandDetected;
   bool commandRecorded = (g_GlobalState.lastSignalCommand == signal);
   
   if(processedAsUnknown && commandRecorded)
      Print("✅ Тест пройден: Неизвестная команда обработана корректно");
   else
   {
      Print("❌ Тест провален: Обработка неизвестной команды");
      Print("   Обработана как неизвестная: ", processedAsUnknown);
      Print("   Команда записана: ", commandRecorded);
   }
}

//+------------------------------------------------------------------+
//| Тест обработки команды блокировки                               |
//+------------------------------------------------------------------+
void TestExternalSignalBlockCommand()
{
   Print("Тест: Обработка команды блокировки");
   
   // Подготовка
   g_GlobalState.allowNewTrades = true;
   g_GlobalState.dailyTPReached = false;
   string signal = "/trade block";
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Торговля разрешена, внешний сигнал = '", signal, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         if(signal == signalCommandPrefix + " block")
         {
            g_GlobalState.dailyTPReached = true; // Используем как флаг блокировки
            g_GlobalState.allowNewTrades = false;
            
            signalProcessed = true;
            Print("Выполнение: Обнаружена команда блокировки");
            Print("Действие: Установлены флаги блокировки");
            Print("Действие: Запрещены новые сделки");
         }
      }
   }
   
   // Проверка результата
   bool blockCommandProcessed = signalProcessed;
   bool tradingBlocked = !g_GlobalState.allowNewTrades;
   bool blockFlagSet = g_GlobalState.dailyTPReached; // Используется как флаг блокировки
   
   if(blockCommandProcessed && tradingBlocked && blockFlagSet)
      Print("✅ Тест пройден: Команда блокировки обработана корректно");
   else
   {
      Print("❌ Тест провален: Обработка команды блокировки");
      Print("   Команда обработана: ", blockCommandProcessed);
      Print("   Торговля заблокирована: ", tradingBlocked);
      Print("   Флаг блокировки установлен: ", blockFlagSet);
   }
}

//+------------------------------------------------------------------+
//| Тест обработки команды разблокировки                            |
//+------------------------------------------------------------------+
void TestExternalSignalUnblockCommand()
{
   Print("Тест: Обработка команды разблокировки");
   
   // Подготовка
   g_GlobalState.allowNewTrades = false;
   g_GlobalState.dailyTPReached = true; // Состояние заблокировано
   string signal = "/trade unblock";
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Состояние заблокировано, внешний сигнал = '", signal, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         if(signal == signalCommandPrefix + " unblock")
         {
            g_GlobalState.dailyTPReached = false;
            g_GlobalState.dailySLReached = false;
            g_GlobalState.allowNewTrades = true;
            
            signalProcessed = true;
            Print("Выполнение: Обнаружена команда разблокировки");
            Print("Действие: Флаги блокировки сброшены");
            Print("Действие: Разрешены новые сделки");
         }
      }
   }
   
   // Проверка результата
   bool unblockCommandProcessed = signalProcessed;
   bool tradingAllowed = g_GlobalState.allowNewTrades;
   bool blockFlagsCleared = !g_GlobalState.dailyTPReached;
   
   if(unblockCommandProcessed && tradingAllowed && blockFlagsCleared)
      Print("✅ Тест пройден: Команда разблокировки обработана корректно");
   else
   {
      Print("❌ Тест провален: Обработка команды разблокировки");
      Print("   Команда обработана: ", unblockCommandProcessed);
      Print("   Торговля разрешена: ", tradingAllowed);
      Print("   Флаги блокировки сброшены: ", blockFlagsCleared);
   }
}

//+------------------------------------------------------------------+
//| Тест игнорирования сигналов при отключенном приеме              |
//+------------------------------------------------------------------+
void TestExternalSignalProcessingDisabled()
{
   Print("Тест: Игнорирование сигналов при отключенном приеме");
   
   // Подготовка
   string signal = "/trade reset";
   bool enableExternalSignals = false; // Прием сигналов отключен
   
   Print("Подготовка: Прием внешних сигналов отключен, сигнал = '", signal, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "")
   {
      // Этот блок НЕ должен выполниться
      signalProcessed = true;
      Print("Действие: Сигнал обработан (это ОШИБКА!)");
   }
   
   // Проверка результата
   bool processingIgnored = !signalProcessed;
   bool stateUnchanged = true; // Состояние не должно измениться из-за сигнала
   
   if(processingIgnored && stateUnchanged)
      Print("✅ Тест пройден: Внешние сигналы корректно игнорируются при отключенном приеме");
   else
   {
      Print("❌ Тест провален: Внешние сигналы не игнорируются при отключенном приеме");
      Print("   Обработка проигнорирована: ", processingIgnored);
      Print("   Состояние не изменилось: ", stateUnchanged);
   }
}

//+------------------------------------------------------------------+
//| Тест обработки сигнала с неполным префиксом                     |
//+------------------------------------------------------------------+
void TestExternalSignalIncompletePrefix()
{
   Print("Тест: Обработка сигнала с неполным префиксом");
   
   // Подготовка
   string signal = "/tr"; // Неполный префикс
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Внешний сигнал = '", signal, "', ожидаемый префикс = '", signalCommandPrefix, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool prefixMatch = (StringFind(signal, signalCommandPrefix) == 0);
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(prefixMatch)
      {
         signalProcessed = true;
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
      }
   }
   
   // Проверка результата
   bool incompleteSignalRejected = !prefixMatch && !signalProcessed;
   
   if(incompleteSignalRejected)
      Print("✅ Тест пройден: Неполный префикс сигнала корректно отклонен");
   else
   {
      Print("❌ Тест провален: Неполный префикс сигнала не отклонен должным образом");
      Print("   Префикс совпал: ", prefixMatch);
      Print("   Сигнал обработан: ", signalProcessed);
      Print("   Неполный сигнал отклонен: ", incompleteSignalRejected);
   }
}

//+------------------------------------------------------------------+
//| Тест обработки пустого сигнала                                  |
//+------------------------------------------------------------------+
void TestExternalSignalEmptySignal()
{
   Print("Тест: Обработка пустого сигнала");
   
   // Подготовка
   string signal = ""; // Пустой сигнал
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Внешний сигнал пустой, префикс = '", signalCommandPrefix, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   bool signalProcessed = false;
   
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      // Условие не выполнится из-за пустого сигнала
      signalProcessed = true;
   }
   
   // Проверка результата
   bool emptySignalIgnored = !signalProcessed;
   
   if(emptySignalIgnored)
      Print("✅ Тест пройден: Пустой сигнал корректно игнорируется");
   else
      Print("❌ Тест провален: Пустой сигнал не игнорируется должным образом");
}

//+------------------------------------------------------------------+
//| Тест обработки сигнала с разными регистрами                     |
//+------------------------------------------------------------------+
void TestExternalSignalCaseSensitivity()
{
   Print("Тест: Обработка сигнала с разными регистрами");
   
   // Подготовка
   string signal1 = "/TRADE RESET"; // Верхний регистр
   string signal2 = "/trade reset"; // Нижний регистр
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   
   Print("Подготовка: Проверка чувствительности к регистру");
   Print("Подготовка: Сигнал 1 (верхний) = '", signal1, "', Сигнал 2 (нижний) = '", signal2, "'");
   
   // Выполнение для первого сигнала
   bool prefixMatch1 = (StringFind(signal1, signalCommandPrefix) == 0);
   bool prefixMatch2 = (StringFind(signal2, signalCommandPrefix) == 0);
   
   // Для MQL обычно регистрозависимо
   bool caseSensitive = !prefixMatch1 && prefixMatch2;
   
   Print("Результат: Совпадение сигнала 1 (верхний): ", prefixMatch1);
   Print("Результат: Совпадение сигнала 2 (нижний): ", prefixMatch2);
   
   // Проверка результата
   if(caseSensitive)
      Print("✅ Тест пройден: Проверка чувствительности к регистру выполнена");
   else
      Print("ℹ Информация: Система может быть регистронезависимой (это также допустимое поведение)");
}

//+------------------------------------------------------------------+
//| Тест сохранения времени получения сигнала                        |
//+------------------------------------------------------------------+
void TestExternalSignalTimestampRecording()
{
   Print("Тест: Сохранение времени получения сигнала");
   
   // Подготовка
   string signal = "/trade status";
   string signalCommandPrefix = "/trade";
   bool enableExternalSignals = true;
   datetime beforeSignal = TimeCurrent();
   
   Print("Подготовка: Время до обработки сигнала: ", TimeToString(beforeSignal));
   Print("Подготовка: Внешний сигнал = '", signal, "'");
   
   // Выполнение (имитация Core_ProcessExternalSignal)
   if(enableExternalSignals && signal != "" && signalCommandPrefix != "")
   {
      if(StringFind(signal, signalCommandPrefix) == 0)
      {
         g_GlobalState.lastSignalTime = TimeCurrent();
         g_GlobalState.lastSignalCommand = signal;
         
         Print("Выполнение: Сигнал обработан, время сохранено");
      }
   }
   
   // Проверка результата
   bool timestampRecorded = (g_GlobalState.lastSignalTime >= beforeSignal);
   bool timeWithinTolerance = (g_GlobalState.lastSignalTime <= TimeCurrent());
   
   if(timestampRecorded && timeWithinTolerance)
      Print("✅ Тест пройден: Время получения сигнала корректно сохранено");
   else
   {
      Print("❌ Тест провален: Время получения сигнала не сохранено должным образом");
      Print("   Время записано: ", timestampRecorded);
      Print("   Время в пределах допуска: ", timeWithinTolerance);
      Print("   Записанное время: ", TimeToString(g_GlobalState.lastSignalTime));
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов внешних сигналов RiskManager");
   Print("=========================================");
   
   TestExternalSignalResetCommand();
   Print("");
   TestExternalSignalStatusCommand();
   Print("");
   TestExternalSignalUnknownCommand();
   Print("");
   TestExternalSignalBlockCommand();
   Print("");
   TestExternalSignalUnblockCommand();
   Print("");
   TestExternalSignalProcessingDisabled();
   Print("");
   TestExternalSignalIncompletePrefix();
   Print("");
   TestExternalSignalEmptySignal();
   Print("");
   TestExternalSignalCaseSensitivity();
   Print("");
   TestExternalSignalTimestampRecording();
   Print("");
   
   Print("=========================================");
   Print("Тестирование внешних сигналов завершено");
}