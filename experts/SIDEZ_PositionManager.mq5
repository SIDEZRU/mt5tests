//+------------------------------------------------------------------+
//|                                               SIDEZ_PositionManager.mq5 |
//|                              Copyright © 2025, SIDEZ LLC          |
//|                                             https://www.sidez.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.0"
#property description "Менеджер позиций с трейлинг-стопом, частичным закрытием и SL/TP"
#property strict

//--- Включение основной библиотеки
#include "..\Include\SIDEZ_CoreLib.mqh" // Использовать угловые скобки

//+------------------------------------------------------------------+
//|                         ВХОДНЫЕ ПАРАМЕТРЫ                        |
//+------------------------------------------------------------------+
input group "=== Основные настройки PositionManager ===" input string PM_Name = "SIDEZ PositionManager"; // Название советника
input bool EnablePositionManagement = true;                                                             // Включить управление позициями
input bool EnableTrailingStop = true;                                                                  // Включить трейлинг-стоп
input bool EnablePartialClose = true;                                                                  // Включить частичное закрытие
input bool EnableSLTPSetting = true;                                                                   // Включить установку SL/TP
input string InstrumentList = "XAUUSD,EURUSD,GBPUSD";                                                 // Список инструментов для управления

//+------------------------------------------------------------------+
//|                        РЕЖИМЫ РАБОТЫ                            |
//+------------------------------------------------------------------+
// Режимы SL
#define SL_NONE          0  // Без SL
#define SL_FIXED_PIPS    1  // Фиксированный SL в пунктах
#define SL_FIXED_MONEY   2  // Фиксированный SL в деньгах
#define SL_PERCENT       3  // SL в процентах от баланса
#define SL_ATR           4  // SL на основе ATR
#define SL_RR            5  // SL на основе соотношения риск/прибыль

// Режимы TP
#define TP_NONE          0  // Без TP
#define TP_FIXED_PIPS    1  // Фиксированный TP в пунктах
#define TP_FIXED_MONEY   2  // Фиксированный TP в деньгах
#define TP_PERCENT       3  // TP в процентах от баланса
#define TP_ATR           4  // TP на основе ATR
#define TP_RR            5  // TP на основе соотношения риск/прибыль

// Режимы трейлинга
#define TS_NONE          0  // Без трейлинга
#define TS_FIXED         1  // Фиксированный трейлинг
#define TS_PERCENT       2  // Процентный трейлинг
#define TS_ATR           3  // ATR трейлинг

// Режимы безубытка
#define BE_MODE_NONE     0  // Без безубытка
#define BE_MODE_FIXED_MONEY 1 // Фиксированный в деньгах
#define BE_MODE_FIXED_PIPS  2 // Фиксированный в пунктах
#define BE_MODE_PERCENT_TO_TP 3 // Процент до TP

//+------------------------------------------------------------------+
//|                         ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ                   |
//+------------------------------------------------------------------+
int g_TickCounter = 0;
bool g_IsInitialized = false;
string g_CurrentSymbol = "";
CTrade g_Trade;
CPositionInfo g_PositionInfo;
datetime g_LastCheckTime = 0;

// Конфигурации инструментов
SInstrumentConfig g_InstrumentConfigs[50];
int g_ConfigCount = 0;

// Панель рекомендаций
int g_PanelX = 500;
int g_PanelY = 20;
color g_PanelBgColor = clrDarkBlue;
color g_PanelTextColor = clrWhite;

// Последняя рекомендация
int g_LastRecommendation = 0;
string g_CurrentRecommendedSymbol = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print(PM_Name, " v", CORE_VERSION, " инициализация...");
   
   //--- Инициализируем торговлю
   g_Trade.SetExpertMagicNumber(MAGIC_POSITION_MANAGER);
   g_Trade.SetDeviationInPoints(10);
   
   //--- Загружаем конфигурации инструментов
   LoadInstrumentConfigurations();
   
   //--- Проверяем инициализацию
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
   {
      Print("❌ Терминал не подключен к торговому серверу");
      return INIT_FAILED;
   }
   
   //--- Создаем панель рекомендаций
   if(ShowRecommendationPanel)
   {
      CreateRecommendationPanel();
   }
   
   Print("✅ PositionManager успешно инициализирован");
   Print("Управляемые инструменты: ", InstrumentList);
   Print("========================================");
   
   g_IsInitialized = true;
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_IsInitialized || !EnablePositionManagement)
      return;
   
   g_TickCounter++;
   
   //--- Обработка каждой позиции
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         string symbol = PositionGetString(POSITION_SYMBOL);
         
         //--- Получаем конфигурацию для инструмента
         SInstrumentConfig config;
         if(GetInstrumentConfig(symbol, config))
         {
            //--- Обновляем конфигурацию
            UpdateInstrumentConfig(symbol, config);
            
            //--- Управляем позицией
            ManagePosition(symbol, ticket, config);
         }
      }
   }
   
   //--- Обновляем панель рекомендаций
   if(ShowRecommendationPanel)
   {
      UpdateRecommendationPanel();
   }
}

//+------------------------------------------------------------------+
//| Управление позицией                                             |
//+------------------------------------------------------------------+
void ManagePosition(string symbol, ulong ticket, SInstrumentConfig &config)
{
   if(!EnablePositionManagement)
      return;
   
   //--- Проверяем, является ли позиция нашей (по магику)
   long magic = PositionGetInteger(POSITION_MAGIC);
   if(magic != MAGIC_POSITION_MANAGER && magic != MAGIC_RISK_MANAGER)
   {
      // Если позиция не нашего магика, пропускаем (или можем управлять по настройке)
      if(!ManageExternalPositions)
         return;
   }
   
   //--- Проверяем, включено ли управление для этого инструмента
   if(!config.enabled)
      return;
   
   //--- Обновляем информацию о позиции в конфиге
   config.positionActive = true;
   config.positionOpenTime = (datetime)PositionGetInteger(POSITION_TIME);
   
   //--- 1. Проверяем установку SL/TP (только для новых позиций)
   if(config.originalSL == 0 && config.originalTP == 0)
   {
      if(EnableSLTPSetting)
      {
         SetInitialSLTP(symbol, ticket, config);
      }
   }
   
   //--- 2. Проверяем частичное закрытие
   if(EnablePartialClose && config.partialLevelsCount > 0)
   {
      PM_CheckPartialClose(symbol, ticket, config);
   }
   
   //--- 3. Проверяем трейлинг-стоп
   if(EnableTrailingStop && config.tsMode != TS_NONE)
   {
      PM_CheckTrailingStop(symbol, ticket, config);
   }
   
   //--- 4. Проверяем корректировку SL через RiskManager
   if(AllowSLAdjustmentByRiskManager)
   {
      AdjustSLByRiskManager(symbol, ticket, config);
   }
   
   //--- Сохраняем обновленную конфигурацию
   PM_SaveInstrumentConfig(symbol, config);
}

//+------------------------------------------------------------------+
//| Установка начальных SL/TP                                         |
//+------------------------------------------------------------------+
void SetInitialSLTP(string symbol, ulong ticket, SInstrumentConfig &config)
{
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
   //--- Рассчитываем SL
   double newSL = CalculateSLPrice(symbol, openPrice, type, config);
   
   //--- Рассчитываем TP
   double newTP = CalculateTPPrice(symbol, openPrice, type, config);
   
   //--- Применяем SL/TP если они изменились
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   
   bool needModify = false;
   double modifySL = currentSL;
   double modifyTP = currentTP;
   
   if(newSL != 0 && newSL != currentSL)
   {
      modifySL = newSL;
      needModify = true;
      config.currentSL = newSL;
      config.originalSL = newSL;
   }
   
   if(newTP != 0 && newTP != currentTP)
   {
      modifyTP = newTP;
      needModify = true;
      config.currentTP = newTP;
      config.originalTP = newTP;
   }
   
   if(needModify)
   {
      if(g_Trade.PositionModify(ticket, modifySL, modifyTP))
      {
         Print("Установлены SL/TP для позиции #", ticket, " ", symbol);
         Print("  SL: ", modifySL, " -> ", newSL);
         Print("  TP: ", modifyTP, " -> ", newTP);
         
         //--- Обновляем конфигурацию
         config.currentSL = newSL;
         config.currentTP = newTP;
      }
      else
      {
         Print("❌ Ошибка установки SL/TP для позиции #", ticket, 
               " Код: ", g_Trade.ResultRetcode(),
               " Описание: ", g_Trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//| Расчет цены SL                                                   |
//+------------------------------------------------------------------+
double CalculateSLPrice(string symbol, double openPrice, ENUM_POSITION_TYPE type, SInstrumentConfig &config)
{
   if(config.slMode == SL_NONE)
      return 0;
   
   double slPrice = 0;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   switch(config.slMode)
   {
      case SL_FIXED_PIPS:
         if(type == POSITION_TYPE_BUY)
            slPrice = openPrice - config.slValue * point;
         else
            slPrice = openPrice + config.slValue * point;
         break;
         
      case SL_FIXED_MONEY:
      {
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double lotSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         
         // Рассчитываем расстояние в пунктах
         double slDistance = config.slValue / (lotSize * tickValue);
         if(type == POSITION_TYPE_BUY)
            slPrice = openPrice - slDistance * point;
         else
            slPrice = openPrice + slDistance * point;
         break;
      }
      
      case SL_PERCENT:
      {
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double riskAmount = balance * config.slValue / 100.0;
         double lotSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         
         double slDistance = riskAmount / (lotSize * tickValue);
         if(type == POSITION_TYPE_BUY)
            slPrice = openPrice - slDistance * point;
         else
            slPrice = openPrice + slDistance * point;
         break;
      }
      
      case SL_ATR:
      {
         double atrValue = iATR(symbol, config.atrTimeframe, config.atrPeriod);
         if(atrValue > 0)
         {
            double slDistance = atrValue * config.atrMultiplierSL;
            if(type == POSITION_TYPE_BUY)
               slPrice = openPrice - slDistance;
            else
               slPrice = openPrice + slDistance;
         }
         break;
      }
      
      case SL_RR:
      {
         // Сначала нужно рассчитать TP, чтобы определить базовый риск
         double tpPrice = CalculateTPPrice(symbol, openPrice, type, config);
         if(tpPrice != 0)
         {
            double tpDistance = MathAbs(tpPrice - openPrice);
            double slDistance = tpDistance / config.rrRatio;
            
            if(type == POSITION_TYPE_BUY)
               slPrice = openPrice - slDistance;
            else
               slPrice = openPrice + slDistance;
         }
         break;
      }
   }
   
   //--- Нормализуем цену
   if(slPrice != 0)
   {
      slPrice = NormalizePrice(symbol, slPrice);
   }
   
   return slPrice;
}

//+------------------------------------------------------------------+
//| Расчет цены TP                                                   |
//+------------------------------------------------------------------+
double CalculateTPPrice(string symbol, double openPrice, ENUM_POSITION_TYPE type, SInstrumentConfig &config)
{
   if(config.tpMode == TP_NONE)
      return 0;
   
   double tpPrice = 0;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   switch(config.tpMode)
   {
      case TP_FIXED_PIPS:
         if(type == POSITION_TYPE_BUY)
            tpPrice = openPrice + config.tpValue * point;
         else
            tpPrice = openPrice - config.tpValue * point;
         break;
         
      case TP_FIXED_MONEY:
      {
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double lotSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         
         double tpDistance = config.tpValue / (lotSize * tickValue);
         if(type == POSITION_TYPE_BUY)
            tpPrice = openPrice + tpDistance * point;
         else
            tpPrice = openPrice - tpDistance * point;
         break;
      }
      
      case TP_PERCENT:
      {
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double profitTarget = balance * config.tpValue / 100.0;
         double lotSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         
         double tpDistance = profitTarget / (lotSize * tickValue);
         if(type == POSITION_TYPE_BUY)
            tpPrice = openPrice + tpDistance * point;
         else
            tpPrice = openPrice - tpDistance * point;
         break;
      }
      
      case TP_ATR:
      {
         double atrValue = iATR(symbol, config.atrTimeframe, config.atrPeriod);
         if(atrValue > 0)
         {
            double tpDistance = atrValue * config.atrMultiplierTP;
            if(type == POSITION_TYPE_BUY)
               tpPrice = openPrice + tpDistance;
            else
               tpPrice = openPrice - tpDistance;
         }
         break;
      }
      
      case TP_RR:
      {
         // Сначала нужно рассчитать SL, чтобы определить базовую цель
         double slPrice = CalculateSLPrice(symbol, openPrice, type, config);
         if(slPrice != 0)
         {
            double slDistance = MathAbs(slPrice - openPrice);
            double tpDistance = slDistance * config.rrRatio;
            
            if(type == POSITION_TYPE_BUY)
               tpPrice = openPrice + tpDistance;
            else
               tpPrice = openPrice - tpDistance;
         }
         break;
      }
   }
   
   //--- Нормализуем цену
   if(tpPrice != 0)
   {
      tpPrice = NormalizePrice(symbol, tpPrice);
   }
   
   //--- Сохраняем для использования в частичном закрытии
   if(tpPrice != 0)
   {
      config.calculatedTPPrice = tpPrice;
      config.tpDistancePips = MathAbs(tpPrice - openPrice) / point;
   }
   
   return tpPrice;
}

//+------------------------------------------------------------------+
//| Загрузка конфигураций инструментов                               |
//+------------------------------------------------------------------+
void LoadInstrumentConfigurations()
{
   g_ConfigCount = 0;
   
   //--- Разбиваем список инструментов
   string symbols[];
   int count = StringSplit(InstrumentList, ',', symbols);
   
   for(int i = 0; i < count && i < 50; i++)
   {
      string symbol = symbols[i];
      StringTrimLeft(symbol);
      StringTrimRight(symbol);
      
      if(symbol != "")
      {
         SInstrumentConfig config;
         config.symbol = symbol;
         config.enabled = true;
         
         //--- Загружаем конфигурацию из файла или устанавливаем по умолчанию
         if(LoadDefaultConfigForSymbol(symbol, config))
         {
            g_InstrumentConfigs[g_ConfigCount] = config;
            g_ConfigCount++;
            
            Print("Загружена конфигурация для инструмента: ", symbol);
         }
      }
   }
   
   Print("Загружено конфигураций: ", g_ConfigCount);
}

//+------------------------------------------------------------------+
//| Загрузка конфигурации по умолчанию для символа                  |
//+------------------------------------------------------------------+
bool LoadDefaultConfigForSymbol(string symbol, SInstrumentConfig &config)
{
   //--- Проверяем, существует ли символ
   if(!SymbolSelect(symbol))
   {
      Print("❌ Символ не найден: ", symbol);
      return false;
   }
   
   //--- Устанавливаем спецификации инструмента
   if(!GetInstrumentSpecifications(symbol, config))
   {
      Print("❌ Не удалось получить спецификации для: ", symbol);
      return false;
   }
   
   //--- Устанавливаем настройки по умолчанию
   // SL настройки
   config.slMode = SL_FIXED_PIPS;
   config.slValue = 100; // 100 пунктов
   config.atrMultiplierSL = 2.0;
   config.atrPeriod = 14;
   config.atrTimeframe = PERIOD_H1;
   
   // TP настройки
   config.tpMode = TP_RR;
   config.tpValue = 200; // 200 долларов для FIXED_MONEY
   config.atrMultiplierTP = 3.0;
   config.rrRatio = 2.0; // Risk/Reward ratio 1:2
   
   // Трейлинг настройки
   config.tsMode = TS_FIXED;
   config.tsStartProfit = 50.0; // Начинать трейлинг с 50$
   config.tsStep = 20.0; // Шаг трейлинга 20 пунктов
   config.tsLockProfit = 10.0; // Минимальная прибыль 10 пунктов
   
   // Частичное закрытие - отключено по умолчанию
   config.partialLevelsCount = 0;
   
   // Текущие параметры
   config.positionActive = false;
   config.currentSL = 0;
   config.currentTP = 0;
   config.originalSL = 0;
   config.originalTP = 0;
   config.calculatedTPPrice = 0;
   config.tpDistancePips = 0;
   
   return true;
}

//+------------------------------------------------------------------+
//| Получение конфигурации инструмента                               |
//+------------------------------------------------------------------+
bool GetInstrumentConfig(string symbol, SInstrumentConfig &config)
{
   for(int i = 0; i < g_ConfigCount; i++)
   {
      if(g_InstrumentConfigs[i].symbol == symbol)
      {
         config = g_InstrumentConfigs[i];
         return true;
      }
   }
   
   // Если не найдено, пытаемся загрузить из файла
   return PM_LoadInstrumentConfig(symbol, config);
}

//+------------------------------------------------------------------+
//| Обновление конфигурации инструмента                              |
//+------------------------------------------------------------------+
void UpdateInstrumentConfig(string symbol, SInstrumentConfig &config)
{
   for(int i = 0; i < g_ConfigCount; i++)
   {
      if(g_InstrumentConfigs[i].symbol == symbol)
      {
         g_InstrumentConfigs[i] = config;
         return;
      }
   }
   
   // Если не найдено в массиве, сохраняем в файл
   PM_SaveInstrumentConfig(symbol, config);
}

//+------------------------------------------------------------------+
//| Загрузка конфигурации инструмента из файла                       |
//+------------------------------------------------------------------+
bool PM_LoadInstrumentConfig(string symbol, SInstrumentConfig &config)
{
   string fileName = "SIDEZ/Config_" + symbol + ".bin";
   
   if(!FileIsExist(fileName, FILE_COMMON))
      return false;
   
   int handle = FileOpen(fileName, FILE_READ | FILE_BIN | FILE_COMMON);
   if(handle == INVALID_HANDLE)
      return false;
   
   bool result = FileReadStruct(handle, config);
   FileClose(handle);
   
   return result;
}

//+------------------------------------------------------------------+
//| Сохранение конфигурации инструмента в файл                       |
//+------------------------------------------------------------------+
bool PM_SaveInstrumentConfig(string symbol, SInstrumentConfig &config)
{
   string fileName = "SIDEZ/Config_" + symbol + ".bin";
   
   int handle = FileOpen(fileName, FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(handle == INVALID_HANDLE)
      return false;
   
   bool result = FileWriteStruct(handle, config);
   FileClose(handle);
   
   return result;
}

//+------------------------------------------------------------------+
//| Расчет расстояния SL (для RR режима)                             |
//+------------------------------------------------------------------+
double CalculateSLDistance(string symbol, double openPrice, ENUM_POSITION_TYPE type, SInstrumentConfig &config)
{
   if(config.slMode == SL_NONE)
      return 0;
   
   double slPrice = CalculateSLPrice(symbol, openPrice, type, config);
   if(slPrice == 0)
      return 0;
   
   return MathAbs(slPrice - openPrice);
}

//+------------------------------------------------------------------+
//| Корректировка SL через RiskManager                               |
//+------------------------------------------------------------------+
void AdjustSLByRiskManager(string symbol, ulong ticket, SInstrumentConfig &config)
{
   // Эта функция позволяет RiskManager корректировать SL
   // Основана на настройках AllowSLAdjustmentByRiskManager
   
   if(!AllowSLAdjustmentByRiskManager)
      return;
   
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
   // Пример: перемещение SL в безубыток при достижении определенной прибыли
   if(MoveSLtoBreakevenAtProfit != 0)
   {
      double profit = PositionGetDouble(POSITION_PROFIT);
      
      if(profit >= MoveSLtoBreakevenAtProfit)
      {
         double newSL = openPrice; // Переместить SL в точку открытия (безубыток)
         
         if(type == POSITION_TYPE_BUY && newSL > currentSL)
         {
            if(g_Trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
            {
               Print("SL перемещен в безубыток для позиции #", ticket, 
                     " Прибыль: $", DoubleToString(profit, 2));
               
               config.currentSL = newSL;
            }
         }
         else if(type == POSITION_TYPE_SELL && newSL < currentSL)
         {
            if(g_Trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
            {
               Print("SL перемещен в безубыток для позиции #", ticket, 
                     " Прибыль: $", DoubleToString(profit, 2));
               
               config.currentSL = newSL;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Проверка условий частичного закрытия                              |
//+------------------------------------------------------------------+
void PM_CheckPartialClose(string symbol, ulong ticket, SInstrumentConfig &config)
{
   if(!EnablePartialClose || config.partialLevelsCount == 0)
      return;
   
   if(!PositionSelectByTicket(ticket))
      return;
   
   double profit = PositionGetDouble(POSITION_PROFIT);
   double volume = PositionGetDouble(POSITION_VOLUME);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentPrice = SymbolInfoDouble(symbol, (type == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   //--- Рассчитать целевой TP в деньгах
   double targetProfit = 0;
   
   // Объявляем переменные ДО switch, чтобы они были видны во всех case
   double tickValue = 0;
   double minVolume = 0;
   double balance = 0;
   double atrValue = 0;
   double slDistance = 0;
   
   switch(config.tpMode)
   {
      case TP_MONEY:
         targetProfit = config.tpValue;
         break;
         
      case TP_PIPS:
         // Используем объявленные выше переменные
         tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
         if(minVolume > 0)
            targetProfit = config.tpValue * tickValue * (volume / minVolume);
         break;
         
      case TP_PERCENT:
         // Используем объявленные выше переменные
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         targetProfit = balance * config.tpValue / 100.0;
         break;
         
      case TP_ATR:
         // Используем объявленные выше переменные
         atrValue = iATR(symbol, config.atrTimeframe, config.atrPeriod);
         if(atrValue > 0)
         {
            tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
            targetProfit = atrValue * config.atrMultiplierTP * tickValue;
         }
         break;
         
      case TP_RR:
         // Для RR режима нужно рассчитать на основе риска
         if(config.slMode != SL_NONE)
         {
            slDistance = CalculateSLDistance(symbol, openPrice, type, config);
            if(slDistance > 0)
            {
               tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
               targetProfit = slDistance * config.rrRatio * tickValue;
            }
         }
         break;
         
      default:
         return;
   }
   
   if(targetProfit <= 0)
      return;
   
   //--- Проверить каждый уровень
   for(int i = 0; i < config.partialLevelsCount; i++)
   {
      if(!config.partialLevels[i].enabled || config.partialLevels[i].executed)
         continue;
      
      double levelProfit = targetProfit * config.partialLevels[i].triggerPercent / 100.0;
      
      if(profit >= levelProfit)
      {
         //--- Частичное закрытие
         double closeVolume = volume * config.partialLevels[i].closePercent / 100.0;
         
         if(closeVolume < SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN))
            closeVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
         
         if(g_Trade.PositionClosePartial(ticket, closeVolume))
         {
            Print("Уровень ", i + 1, ": частичное закрытие ", symbol,
                  " объем ", closeVolume, " лот, прибыль $", profit);
            
            config.partialLevels[i].executed = true;
            config.partialLevels[i].executionTime = TimeCurrent();
            
            //--- Проверить безубыток
            PM_CheckBreakevenCondition(symbol, ticket, config, i,
                                      profit, openPrice, currentSL,
                                      currentTP, type, currentPrice, point);
         }
         break;
      }
   }
}

//+------------------------------------------------------------------+
//| Проверка условия безубытка                                       |
//+------------------------------------------------------------------+
void PM_CheckBreakevenCondition(string symbol, ulong ticket, SInstrumentConfig &config, int levelIdx,
                                double profit, double openPrice, double currentSL,
                                double currentTP, ENUM_POSITION_TYPE type, double currentPrice, double point)
{
   if(config.partialLevels[levelIdx].breakevenMode == BE_MODE_NONE)
      return;
   if(currentSL == openPrice)
      return;
   
   bool moveToBreakeven = false;
   
   switch(config.partialLevels[levelIdx].breakevenMode)
   {
      case BE_MODE_FIXED_MONEY:
      {
         if(profit >= config.partialLevels[levelIdx].breakevenValue)
            moveToBreakeven = true;
         break;
      }
      
      case BE_MODE_FIXED_PIPS:
      {
         double requiredPips = config.partialLevels[levelIdx].breakevenValue;
         double requiredMove = requiredPips * point;
         
         if(type == POSITION_TYPE_BUY)
         {
            if(currentPrice >= openPrice + requiredMove)
               moveToBreakeven = true;
         }
         else // SELL
         {
            if(currentPrice <= openPrice - requiredMove)
               moveToBreakeven = true;
         }
         break;
      }
      
      case BE_MODE_PERCENT_TO_TP:
      {
         if(config.calculatedTPPrice > 0 && config.tpDistancePips > 0)
         {
            double currentMove = MathAbs(currentPrice - openPrice) / point;
            double percentToTP = (currentMove / config.tpDistancePips) * 100.0;
            
            if(percentToTP >= config.partialLevels[levelIdx].breakevenValue)
               moveToBreakeven = true;
         }
         break;
      }
   }
   
   //--- Применить безубыток
   if(moveToBreakeven)
   {
      if(g_Trade.PositionModify(ticket, openPrice, currentTP))
      {
         Print("Уровень ", levelIdx + 1, ": SL перенесен в безубыток на цену ", openPrice);
         config.currentSL = openPrice;
      }
   }
}

//+------------------------------------------------------------------+
//| Проверка трейлинг-стопа                                         |
//+------------------------------------------------------------------+
void PM_CheckTrailingStop(string symbol, ulong ticket, SInstrumentConfig &config)
{
   if(config.tsMode == TS_NONE)
      return;
   if(!PositionSelectByTicket(ticket))
      return;
   
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double profit = PositionGetDouble(POSITION_PROFIT);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(profit < config.tsStartProfit)
      return;
   
   double newSL = currentSL;
   
   // Объявляем переменные ДО switch
   double priceMove = 0;
   double trailDistance = 0;
   double atrValue = 0;
   
   switch(config.tsMode)
   {
      case TS_FIXED:
         if(type == POSITION_TYPE_BUY)
         {
            newSL = currentPrice - config.tsStep * point;
            if(newSL > currentSL)
               newSL = MathMax(newSL, openPrice + config.tsLockProfit * point);
         }
         else // SELL
         {
            newSL = currentPrice + config.tsStep * point;
            if(newSL < currentSL)
               newSL = MathMin(newSL, openPrice - config.tsLockProfit * point);
         }
         break;
         
      case TS_PERCENT:
         // Используем объявленные переменные
         priceMove = MathAbs(currentPrice - openPrice);
         trailDistance = priceMove * config.tsStep / 100.0;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = currentPrice - trailDistance;
            if(newSL > currentSL)
               newSL = MathMax(newSL, openPrice + priceMove * config.tsLockProfit / 100.0);
         }
         else // SELL
         {
            newSL = currentPrice + trailDistance;
            if(newSL < currentSL)
               newSL = MathMin(newSL, openPrice - priceMove * config.tsLockProfit / 100.0);
         }
         break;
         
      case TS_ATR:
         // Используем объявленные переменные
         atrValue = iATR(symbol, config.atrTimeframe, config.atrPeriod);
         if(atrValue > 0)
         {
            if(type == POSITION_TYPE_BUY)
            {
               newSL = currentPrice - atrValue * config.tsStep;
               if(newSL > currentSL)
                  newSL = MathMax(newSL, openPrice + atrValue * config.tsLockProfit);
            }
            else // SELL
            {
               newSL = currentPrice + atrValue * config.tsStep;
               if(newSL < currentSL)
                  newSL = MathMin(newSL, openPrice - atrValue * config.tsLockProfit);
            }
         }
         break;
   }
   
   if(newSL != currentSL && newSL > 0)
   {
      if(g_Trade.PositionModify(ticket, newSL, currentTP))
      {
         Print("Трейлинг-стоп: ", symbol, " SL ", currentSL, " -> ", newSL);
      }
   }
}

//+------------------------------------------------------------------+
//|            ФУНКЦИИ TREND FILTER (Модуль 3)                      |
//+------------------------------------------------------------------+

//--- Получить рекомендацию по инструменту
int TF_GetRecommendation(string symbol,
                         ENUM_TIMEFRAMES tf1 = PERIOD_H1,
                         ENUM_TIMEFRAMES tf2 = PERIOD_H4,
                         int maPeriod = 89,
                         ENUM_MA_METHOD maMethod = MODE_SMA)
{
   //--- Инициализируем переменные
   double ma1 = 0, ma2 = 0, price = 0;
   
   //--- Получаем цену закрытия
   double closeBuffer[];
   ArraySetAsSeries(closeBuffer, true);
   if(CopyClose(symbol, tf1, 0, 1, closeBuffer) > 0)
   {
      price = closeBuffer[0];
   }
   else
   {
      Print("Ошибка получения цены для ", symbol);
      return 0;
   }
   
   //--- Получаем MA1
   double maBuffer1[];
   ArraySetAsSeries(maBuffer1, true);
   int maHandle1 = iMA(symbol, tf1, maPeriod, 0, maMethod, PRICE_CLOSE);
   
   if(maHandle1 != INVALID_HANDLE)
   {
      if(CopyBuffer(maHandle1, 0, 0, 1, maBuffer1) > 0)
      {
         ma1 = maBuffer1[0];
      }
      IndicatorRelease(maHandle1);
   }
   
   //--- Получаем MA2
   double maBuffer2[];
   ArraySetAsSeries(maBuffer2, true);
   int maHandle2 = iMA(symbol, tf2, maPeriod, 0, maMethod, PRICE_CLOSE);
   
   if(maHandle2 != INVALID_HANDLE)
   {
      if(CopyBuffer(maHandle2, 0, 0, 1, maBuffer2) > 0)
      {
         ma2 = maBuffer2[0];
      }
      IndicatorRelease(maHandle2);
   }
   
   //--- Проверяем полученные значения
   if(ma1 == 0 || ma2 == 0)
   {
      Print("Ошибка получения MA для ", symbol, ": ma1=", ma1, ", ma2=", ma2);
      return 0;
   }
   
   //--- Определить тренд
   bool uptrend = (price > ma1) && (price > ma2);
   bool downtrend = (price < ma1) && (price < ma2);
   
   if(uptrend)
      return 1; // LONG
   if(downtrend)
      return 2; // SHORT
   
   return 0; // NO TRADE (боковик)
}

//+------------------------------------------------------------------+
//|                    ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ                      |
//+------------------------------------------------------------------+

//--- Нормализовать цену по шагу символа
double NormalizePrice(string symbol, double price)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

//--- Получить строковое представление направления
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

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("PositionManager деинициализация. Причина: ", reason);
   
   //--- Сохраняем все конфигурации
   for(int i = 0; i < g_ConfigCount; i++)
   {
      PM_SaveInstrumentConfig(g_InstrumentConfigs[i].symbol, g_InstrumentConfigs[i]);
   }
   
   //--- Удаляем графические объекты
   if(ShowRecommendationPanel)
   {
      ObjectDelete(0, "PM_Panel_BG");
      ObjectDelete(0, "PM_Panel_Title");
      ObjectDelete(0, "PM_Panel_Rec");
      ObjectDelete(0, "PM_Panel_Reason");
      ObjectDelete(0, "PM_Panel_Symbol");
      ObjectDelete(0, "PM_Panel_TradeStatus");
      ObjectDelete(0, "PM_Panel_Time");
   }
   
   Comment("");
}

//+------------------------------------------------------------------+
//| Обработчик событий                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   //--- Обработка кликов по панели
   if(id == CHARTEVENT_OBJECT_CLICK && sparam != "")
   {
      Print("Клик по объекту: ", sparam);
      
      //--- Пример: переключение режима торговли
      if(sparam == "PM_Panel_TradeStatus")
      {
         // Можно добавить ручное переключение статуса торговли
      }
   }
}

//+------------------------------------------------------------------+