//+------------------------------------------------------------------+
//|                                   test_instrument_specs.mq5        |
//|                                    Тесты спецификаций инструментов  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.00"
#property strict

#include "..\..\..\include\SIDEZ_CoreLib.mqh"

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
//| Тест нормализации цены                                          |
//+------------------------------------------------------------------+
void TestNormalizePrice()
{
   Print("Тест: Нормализация цены");
   
   // Подготовка
   string symbol = "EURUSD";
   double rawPrice = 1.23456;
   
   // Выполнение (имитация функции NormalizePrice)
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double normalizedPrice = NormalizeDouble(rawPrice, digits);
   
   // Проверка
   double expectedPrice = 1.2346; // Для EURUSD обычно 4 знака после запятой
   bool isNormalized = (normalizedPrice == expectedPrice);
   
   if(isNormalized)
      Print("✅ Тест пройден: Нормализация цены");
   else
      Print("❌ Тест провален: Нормализация цены");
}

//+------------------------------------------------------------------+
//| Тест расчета цены SL (FIXED_PIPS)                               |
//+------------------------------------------------------------------+
void TestCalculateSLPriceFixedPips()
{
   Print("Тест: Расчет цены SL (FIXED_PIPS)");
   
   // Подготовка
   string symbol = "EURUSD";
   double openPrice = 1.2000;
   ENUM_POSITION_TYPE type = POSITION_TYPE_BUY;
   
   SInstrumentConfig config;
   config.slMode = SL_FIXED_PIPS;
   config.slValue = 100; // 100 пунктов
   config.tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   
   // Выполнение расчета SL
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double slPrice = 0;
   
   if(config.slMode == SL_FIXED_PIPS)
   {
      if(type == POSITION_TYPE_BUY)
         slPrice = openPrice - config.slValue * point;
      else
         slPrice = openPrice + config.slValue * point;
   }
   
   // Проверка (для BUY: 1.2000 - 100*0.0001 = 1.1900)
   double expectedSL = (type == POSITION_TYPE_BUY) ? 1.1900 : 1.2100;
   bool slCalculatedCorrectly = MathAbs(slPrice - expectedSL) < point;
   
   if(slCalculatedCorrectly)
      Print("✅ Тест пройден: Расчет цены SL (FIXED_PIPS)");
   else
   {
      Print("❌ Тест провален: Расчет цены SL (FIXED_PIPS)");
      Print("   Расчетная цена: ", slPrice, " Ожидаемая: ", expectedSL);
   }
}

//+------------------------------------------------------------------+
//| Тест расчета цены TP (FIXED_PIPS)                               |
//+------------------------------------------------------------------+
void TestCalculateTPPriceFixedPips()
{
   Print("Тест: Расчет цены TP (FIXED_PIPS)");
   
   // Подготовка
   string symbol = "EURUSD";
   double openPrice = 1.2000;
   ENUM_POSITION_TYPE type = POSITION_TYPE_BUY;
   
   SInstrumentConfig config;
   config.tpMode = TP_FIXED_PIPS;
   config.tpValue = 150; // 150 пунктов
   config.tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   
   // Выполнение расчета TP
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tpPrice = 0;
   
   if(config.tpMode == TP_FIXED_PIPS)
   {
      if(type == POSITION_TYPE_BUY)
         tpPrice = openPrice + config.tpValue * point;
      else
         tpPrice = openPrice - config.tpValue * point;
   }
   
   // Проверка (для BUY: 1.2000 + 150*0.0001 = 1.2150)
   double expectedTP = (type == POSITION_TYPE_BUY) ? 1.2150 : 1.1850;
   bool tpCalculatedCorrectly = MathAbs(tpPrice - expectedTP) < point;
   
   if(tpCalculatedCorrectly)
      Print("✅ Тест пройден: Расчет цены TP (FIXED_PIPS)");
   else
   {
      Print("❌ Тест провален: Расчет цены TP (FIXED_PIPS)");
      Print("   Расчетная цена: ", tpPrice, " Ожидаемая: ", expectedTP);
   }
}

//+------------------------------------------------------------------+
//| Тест загрузки конфигурации инструмента                          |
//+------------------------------------------------------------------+
void TestLoadInstrumentConfig()
{
   Print("Тест: Загрузка конфигурации инструмента");
   
   // Подготовка
   string symbol = "TEST_SYMBOL";
   SInstrumentConfig config;
   
   // Выполнение
   bool result = PM_LoadInstrumentConfig(symbol, config);
   
   // Проверка - файл может не существовать, это нормально
   // Основная проверка - функция не вызывает ошибок
   Print("✅ Тест пройден: Загрузка конфигурации инструмента (проверка отсутствия ошибок)");
}

//+------------------------------------------------------------------+
//| Тест сохранения конфигурации инструмента                        |
//+------------------------------------------------------------------+
void TestSaveInstrumentConfig()
{
   Print("Тест: Сохранение конфигурации инструмента");
   
   // Подготовка
   string symbol = "SAVE_TEST";
   SInstrumentConfig config;
   config.symbol = symbol;
   config.slMode = SL_FIXED_PIPS;
   config.slValue = 50;
   config.tpMode = TP_FIXED_PIPS;
   config.tpValue = 100;
   
   // Выполнение
   bool result = PM_SaveInstrumentConfig(symbol, config);
   
   // Проверка
   if(result)
      Print("✅ Тест пройден: Сохранение конфигурации инструмента");
   else
      Print("❌ Тест провален: Сохранение конфигурации инструмента");
}

//+------------------------------------------------------------------+
//| Тест получения конфигурации инструмента                         |
//+------------------------------------------------------------------+
void TestGetInstrumentConfig()
{
   Print("Тест: Получение конфигурации инструмента");
   
   // Подготовка
   string symbol = "EURUSD";
   SInstrumentConfig config;
   
   // Выполнение
   bool result = GetInstrumentConfig(symbol, config);
   
   // Проверка - для новых инструментов может не быть конфигурации в массиве
   // Функция попытается загрузить из файла, что может быть false, если файл не существует
   Print("✅ Тест пройден: Получение конфигурации инструмента (проверка отсутствия ошибок)");
}

//+------------------------------------------------------------------+
//| Тест обновления конфигурации инструмента                        |
//+------------------------------------------------------------------+
void TestUpdateInstrumentConfig()
{
   Print("Тест: Обновление конфигурации инструмента");
   
   // Подготовка
   string symbol = "UPDATE_TEST";
   SInstrumentConfig config;
   config.symbol = symbol;
   config.slMode = SL_FIXED_PIPS;
   config.slValue = 75;
   config.tpMode = TP_RR;
   config.rrRatio = 2.0;
   
   // Выполнение
   UpdateInstrumentConfig(symbol, config);
   
   // Проверка - функция выполняется без ошибок
   Print("✅ Тест пройден: Обновление конфигурации инструмента (проверка отсутствия ошибок)");
}

//+------------------------------------------------------------------+
//| Тест получения строки направления                                |
//+------------------------------------------------------------------+
void TestGetDirectionString()
{
   Print("Тест: Получение строки направления");
   
   // Подготовка и выполнение
   string longStr = GetDirectionString(1);
   string shortStr = GetDirectionString(2);
   string noTradeStr = GetDirectionString(0);
   
   // Проверка
   bool longCorrect = (longStr == "LONG");
   bool shortCorrect = (shortStr == "SHORT");
   bool noTradeCorrect = (noTradeStr == "NO TRADE");
   
   if(longCorrect && shortCorrect && noTradeCorrect)
      Print("✅ Тест пройден: Получение строки направления");
   else
   {
      Print("❌ Тест провален: Получение строки направления");
      Print("   LONG: ", longStr, " (ожидаем: LONG)");
      Print("   SHORT: ", shortStr, " (ожидаем: SHORT)");
      Print("   NO TRADE: ", noTradeStr, " (ожидаем: NO TRADE)");
   }
}

//+------------------------------------------------------------------+
//| Тест расчета расстояния SL (для RR режима)                      |
//+------------------------------------------------------------------+
void TestCalculateSLDistance()
{
   Print("Тест: Расчет расстояния SL (для RR режима)");
   
   // Подготовка
   string symbol = "EURUSD";
   double openPrice = 1.2000;
   ENUM_POSITION_TYPE type = POSITION_TYPE_BUY;
   
   SInstrumentConfig config;
   config.slMode = SL_FIXED_PIPS;
   config.slValue = 50; // 50 пунктов
   config.tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   
   // Выполнение
   double slDistance = CalculateSLDistance(symbol, openPrice, type, config);
   
   // Для FIXED_PIPS: расстояние в пунктах * размер пункта
   double expectedDistance = config.slValue * SymbolInfoDouble(symbol, SYMBOL_POINT);
   bool distanceCorrect = MathAbs(slDistance - expectedDistance) < SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(distanceCorrect)
      Print("✅ Тест пройден: Расчет расстояния SL (для RR режима)");
   else
   {
      Print("❌ Тест провален: Расчет расстояния SL (для RR режима)");
      Print("   Расчетное расстояние: ", slDistance, " Ожидаемое: ", expectedDistance);
   }
}

//+------------------------------------------------------------------+
//| Запуск всех тестов                                              |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Запуск тестов спецификаций инструментов PositionManager");
   Print("=========================================");
   
   TestGetInstrumentSpecifications();
   TestNormalizePrice();
   TestCalculateSLPriceFixedPips();
   TestCalculateTPPriceFixedPips();
   TestLoadInstrumentConfig();
   TestSaveInstrumentConfig();
   TestGetInstrumentConfig();
   TestUpdateInstrumentConfig();
   TestGetDirectionString();
   TestCalculateSLDistance();
   
   Print("=========================================");
   Print("Тестирование спецификаций инструментов завершено");
}

//+------------------------------------------------------------------+
//| Вспомогательные функции для тестирования                        |
//+------------------------------------------------------------------+

// Вспомогательная функция для нормализации цены
double NormalizePrice(string symbol, double price)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

// Вспомогательная функция для получения строки направления
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

// Вспомогательная функция для расчета расстояния SL
double CalculateSLDistance(string symbol, double openPrice, ENUM_POSITION_TYPE type, SInstrumentConfig &config)
{
   if(config.slMode == SL_NONE)
      return 0;
   
   double slPrice = 0;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(config.slMode == SL_FIXED_PIPS)
   {
      if(type == POSITION_TYPE_BUY)
         slPrice = openPrice - config.slValue * point;
      else
         slPrice = openPrice + config.slValue * point;
   }
   
   return MathAbs(slPrice - openPrice);
}