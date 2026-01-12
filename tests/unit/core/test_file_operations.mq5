//+------------------------------------------------------------------+
//|                                           test_file_operations.mq5 |
//|                                    Тесты операций с файлами        |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//| Тест сохранения глобального состояния                            |
//+------------------------------------------------------------------+
void TestCore_SaveGlobalState()
{
   Print("Тест: Сохранение глобального состояния");
   
   // Подготовка данных
   g_GlobalState.dailyTakeProfit = 100.0;
   g_GlobalState.dailyStopLoss = -50.0;
   g_GlobalState.dailyPnLTotal = 25.5;
   
   // Выполнение
   bool result = Core_SaveGlobalState();
   
   // Проверка результата
   if(result)
      Print("✅ Тест пройден: Сохранение глобального состояния");
   else
      Print("❌ Тест провален: Сохранение глобального состояния");
}

//+------------------------------------------------------------------+
//| Тест загрузки глобального состояния                              |
//+------------------------------------------------------------------+
void TestCore_LoadGlobalState()
{
   Print("Тест: Загрузка глобального состояния");
   
   // Подготовка - сначала сохраним что-то
   g_GlobalState.dailyTakeProfit = 200.0;
   g_GlobalState.dailyStopLoss = -100.0;
   g_GlobalState.dailyPnLTotal = 75.5;
   
   Core_SaveGlobalState();
   
   // Сбросим значения
   g_GlobalState.dailyTakeProfit = 0.0;
   g_GlobalState.dailyStopLoss = 0.0;
   g_GlobalState.dailyPnLTotal = 0.0;
   
   // Выполнение
   bool result = Core_LoadGlobalState();
   
   // Проверка результата
   if(result && g_GlobalState.dailyTakeProfit == 200.0 && 
      g_GlobalState.dailyStopLoss == -100.0 && 
      g_GlobalState.dailyPnLTotal == 75.5)
   {
      Print("✅ Тест пройден: Загрузка глобального состояния");
   }
   else
   {
      Print("❌ Тест провален: Загрузка глобального состояния");
      Print("   Значения после загрузки: TP=", g_GlobalState.dailyTakeProfit, 
            " SL=", g_GlobalState.dailyStopLoss, " PnL=", g_GlobalState.dailyPnLTotal);
   }
}

//+------------------------------------------------------------------+
//| Тест проверки разрешенных инструментов                           |
//+------------------------------------------------------------------+
void TestIsInstrumentAllowed()
{
   Print("Тест: Проверка разрешенных инструментов");
   
   // Подготовка - настроим белый список
   g_GlobalState.useWhiteList = true;
   
   // Добавим несколько инструментов в белый список
   AddToWhiteList("EURUSD");
   AddToWhiteList("XAUUSD");
   
   // Выполнение и проверка
   bool result1 = IsInstrumentAllowed("EURUSD");
   bool result2 = IsInstrumentAllowed("XAUUSD");
   bool result3 = IsInstrumentAllowed("GBPUSD"); // Не в списке
   
   if(result1 && result2 && !result3)
      Print("✅ Тест пройден: Проверка разрешенных инструментов");
   else
   {
      Print("❌ Тест провален: Проверка разрешенных инструментов");
      Print("   EURUSD разрешен: ", result1, " XAUUSD разрешен: ", result2, " GBPUSD разрешен: ", result3);
   }
}

//+------------------------------------------------------------------+
//| Тест загрузки белого списка из строки                           |
//+------------------------------------------------------------------+
void TestLoadWhiteListFromString()
{
   Print("Тест: Загрузка белого списка из строки");
   
   // Подготовка
   string instruments = "EURUSD,XAUUSD,GBPUSD";
   
   // Выполнение
   LoadWhiteListFromString(instruments);
   
   // Проверка
   bool foundEURUSD = false;
   bool foundXAUUSD = false;
   bool foundGBPUSD = false;
   
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      string symbol = g_GlobalState.allowedInstruments[i].symbol;
      if(symbol == "EURUSD") foundEURUSD = true;
      if(symbol == "XAUUSD") foundXAUUSD = true;
      if(symbol == "GBPUSD") foundGBPUSD = true;
   }
   
   if(foundEURUSD && foundXAUUSD && foundGBPUSD && g_GlobalState.allowedInstrumentsCount == 3)
      Print("✅ Тест пройден: Загрузка белого списка из строки");
   else
   {
      Print("❌ Тест провален: Загрузка белого списка из строки");
      Print("   Найдено инструментов: ", g_GlobalState.allowedInstrumentsCount);
      Print("   EURUSD найден: ", foundEURUSD, " XAUUSD найден: ", foundXAUUSD, " GBPUSD найден: ", foundGBPUSD);
   }
}

//+------------------------------------------------------------------+
//| Тест добавления в белый список                                  |
//+------------------------------------------------------------------+
void TestAddToWhiteList()
{
   Print("Тест: Добавление в белый список");
   
   // Подготовка
   int countBefore = g_GlobalState.allowedInstrumentsCount;
   
   // Выполнение
   bool result = AddToWhiteList("TESTSYMBOL");
   
   // Проверка
   int countAfter = g_GlobalState.allowedInstrumentsCount;
   bool symbolFound = false;
   
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      if(g_GlobalState.allowedInstruments[i].symbol == "TESTSYMBOL")
      {
         symbolFound = true;
         break;
      }
   }
   
   if(result && countAfter == countBefore + 1 && symbolFound)
      Print("✅ Тест пройден: Добавление в белый список");
   else
   {
      Print("❌ Тест провален: Добавление в белый список");
      Print("   Результат добавления: ", result);
      Print("   Количество до: ", countBefore, " после: ", countAfter);
      Print("   Символ найден: ", symbolFound);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов операций с файлами и управления состоянием");
   Print("=========================================");
   
   TestCore_SaveGlobalState();
   TestCore_LoadGlobalState();
   TestIsInstrumentAllowed();
   TestLoadWhiteListFromString();
   TestAddToWhiteList();
   
   Print("=========================================");
   Print("Тестирование операций с файлами завершено");
}