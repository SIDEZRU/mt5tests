//+------------------------------------------------------------------+
//|                                       test_state_management.mq5    |
//|                                    Тесты управления состоянием    |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест синхронизации белого списка между модулями                 |
//+------------------------------------------------------------------+
void TestSyncWhiteListBetweenModules()
{
   Print("Тест: Синхронизация белого списка между модулями");
   
   // Подготовка - добавим несколько инструментов
   g_GlobalState.allowedInstrumentsCount = 0;
   AddToWhiteList("EURUSD");
   AddToWhiteList("XAUUSD");
   
   int originalCount = g_GlobalState.allowedInstrumentsCount;
   
   // Выполнение
   SyncWhiteListBetweenModules();
   
   // Проверка - проверим наличие файла синхронизации
   bool fileExists = FileIsExist("SIDEZ/WhiteListSync.bin", FILE_COMMON);
   
   if(fileExists)
      Print("✅ Тест пройден: Синхронизация белого списка между модулями");
   else
      Print("❌ Тест провален: Синхронизация белого списка между модулями");
}

//+------------------------------------------------------------------+
//| Тест загрузки белого списка из синхронизации                    |
//+------------------------------------------------------------------+
void TestLoadWhiteListFromSync()
{
   Print("Тест: Загрузка белого списка из синхронизации");
   
   // Подготовка - сначала синхронизируем
   g_GlobalState.allowedInstrumentsCount = 0;
   AddToWhiteList("GBPUSD");
   AddToWhiteList("AUDUSD");
   
   SyncWhiteListBetweenModules();
   
   // Очистим текущий список
   g_GlobalState.allowedInstrumentsCount = 0;
   
   // Выполнение
   bool result = LoadWhiteListFromSync();
   
   // Проверка
   bool foundGBPUSD = false;
   bool foundAUDUSD = false;
   
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      string symbol = g_GlobalState.allowedInstruments[i].symbol;
      if(symbol == "GBPUSD") foundGBPUSD = true;
      if(symbol == "AUDUSD") foundAUDUSD = true;
   }
   
   if(result && foundGBPUSD && foundAUDUSD)
      Print("✅ Тест пройден: Загрузка белого списка из синхронизации");
   else
   {
      Print("❌ Тест провален: Загрузка белого списка из синхронизации");
      Print("   Результат загрузки: ", result);
      Print("   GBPUSD найден: ", foundGBPUSD, " AUDUSD найден: ", foundAUDUSD);
      Print("   Количество загруженных: ", g_GlobalState.allowedInstrumentsCount);
   }
}

//+------------------------------------------------------------------+
//| Тест получения спецификаций инструмента                         |
//+------------------------------------------------------------------+
void TestGetInstrumentSpecifications()
{
   Print("Тест: Получение спецификаций инструмента");
   
   // Подготовка
   SInstrumentConfig config;
   string symbol = "EURUSD";
   
   // Выполнение
   bool result = GetInstrumentSpecifications(symbol, config);
   
   // Проверка основных параметров
   bool validParams = (config.tickSize > 0 && config.tickValue > 0 && config.contractSize > 0);
   
   if(result && validParams)
      Print("✅ Тест пройден: Получение спецификаций инструмента");
   else
   {
      Print("❌ Тест провален: Получение спецификаций инструмента");
      Print("   Результат: ", result);
      Print("   Параметры корректны: ", validParams);
      Print("   tickSize: ", config.tickSize, " tickValue: ", config.tickValue, " contractSize: ", config.contractSize);
   }
}

//+------------------------------------------------------------------+
//| Тест удаления из белого списка                                  |
//+------------------------------------------------------------------+
void TestRemoveFromWhiteList()
{
   Print("Тест: Удаление из белого списка");
   
   // Подготовка - добавим инструмент
   g_GlobalState.allowedInstrumentsCount = 0;
   AddToWhiteList("REMOVE_TEST");
   
   int countBefore = g_GlobalState.allowedInstrumentsCount;
   
   // Проверим, что инструмент добавлен
   bool symbolAdded = false;
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      if(g_GlobalState.allowedInstruments[i].symbol == "REMOVE_TEST")
      {
         symbolAdded = true;
         break;
      }
   }
   
   if(!symbolAdded)
   {
      Print("❌ Тест провален: Не удалось добавить инструмент для теста удаления");
      return;
   }
   
   // Выполнение
   bool result = RemoveFromWhiteList("REMOVE_TEST");
   
   // Проверка
   int countAfter = g_GlobalState.allowedInstrumentsCount;
   bool symbolRemoved = true;
   
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      if(g_GlobalState.allowedInstruments[i].symbol == "REMOVE_TEST")
      {
         symbolRemoved = false;
         break;
      }
   }
   
   if(result && countAfter == countBefore - 1 && symbolRemoved)
      Print("✅ Тест пройден: Удаление из белого списка");
   else
   {
      Print("❌ Тест провален: Удаление из белого списка");
      Print("   Результат удаления: ", result);
      Print("   Количество до: ", countBefore, " после: ", countAfter);
      Print("   Символ удален: ", symbolRemoved);
   }
}

//+------------------------------------------------------------------+
//| Тест функций времени                                            |
//+------------------------------------------------------------------+
void TestTimeFunctions()
{
   Print("Тест: Функции времени");
   
   // Тест парсинга времени
   int hour, minute;
   bool parseResult = ParseTimeString("14:30", hour, minute);
   
   bool timeCorrect = (parseResult && hour == 14 && minute == 30);
   
   // Тест получения дня недели
   int dayOfWeek = GetDayOfWeek(TimeCurrent());
   bool dayValid = (dayOfWeek >= 0 && dayOfWeek <= 6);
   
   if(timeCorrect && dayValid)
      Print("✅ Тест пройден: Функции времени");
   else
   {
      Print("❌ Тест провален: Функции времени");
      Print("   Парсинг времени: ", timeCorrect, " (час: ", hour, ", минута: ", minute, ")");
      Print("   День недели корректен: ", dayValid, " (день: ", dayOfWeek, ")");
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов управления состоянием");
   Print("=========================================");
   
   TestSyncWhiteListBetweenModules();
   TestLoadWhiteListFromSync();
   TestGetInstrumentSpecifications();
   TestRemoveFromWhiteList();
   TestTimeFunctions();
   
   Print("=========================================");
   Print("Тестирование управления состоянием завершено");
}