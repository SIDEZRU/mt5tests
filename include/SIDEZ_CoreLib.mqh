//+------------------------------------------------------------------+
//|                                                     SIDEZ_CoreLib.mqh |
//|                              Copyright © 2025, SIDEZ LLC          |
//|                                             https://www.sidez.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"

//+------------------------------------------------------------------+
//|                       КОНСТАНТЫ СИСТЕМЫ                          |
//+------------------------------------------------------------------+
#define CORE_VERSION "1.0"
#define MAGIC_RISK_MANAGER 10001001
#define MAGIC_POSITION_MANAGER 20002002

//+------------------------------------------------------------------+
//|                    ГЛОБАЛЬНЫЕ СТРУКТУРЫ                         |
//+------------------------------------------------------------------+

// Структура для хранения настроек инструмента
struct SInstrumentConfig
{
   string symbol;
   double tickSize;
   double tickValue;
   double contractSize;
   double minLot;
   double maxLot;
   double swapLong;
   double swapShort;
   double marginRequirement;
   
   // Настройки SL/TP для PositionManager
   int slMode;
   int tpMode;
   double slValue;
   double tpValue;
   double atrMultiplierSL;
   double atrMultiplierTP;
   int atrPeriod;
   ENUM_TIMEFRAMES atrTimeframe;
   double rrRatio;
   
   // Трейлинг-стоп
   int tsMode;
   double tsStartProfit;
   double tsStep;
   double tsLockProfit;
   
   // Частичное закрытие
   struct SPCLvl
   {
      bool enabled;
      double triggerPercent;
      double closePercent;
      int breakevenMode;
      double breakevenValue;
      bool executed;
      datetime executionTime;
   };
   SPCLvl partialLevels[3];
   int partialLevelsCount;
   
   // Текущие параметры позиции
   bool positionActive;
   datetime positionOpenTime;
   double calculatedTPPrice;
   double tpDistancePips;
   double currentSL;
   double currentTP;
   double originalSL;
   double originalTP;
   
   bool enabled;
};

// Структура для хранения глобального состояния
struct SGlobalState
{
   // Счетчики и лимиты
   double dailyTakeProfit;
   double dailyStopLoss;
   double weeklyTakeProfit;
   double weeklyStopLoss;
   
   // Счетчики сделок
   int dailyTradesCount;
   int weeklyTradesCount;
   int dailyTradesLimit;
   int weeklyTradesLimit;
   
   // Счетчики позиций
   int dailyPositionsCount;
   int weeklyPositionsCount;
   int dailyPositionsLimit;
   int weeklyPositionsLimit;
   int maxSimultaneousPositionsDaily;
   int maxSimultaneousPositionsWeekly;
   
   // Состояния лимитов
   bool dailyTPReached;
   bool dailySLReached;
   bool weeklyTPReached;
   bool weeklySLReached;
   
   // Флаги разрешений
   bool allowNewTrades;
   bool blockManualTrading;
   bool blockOtherExperts;
   bool useWhiteList;
   
   // Данные PnL
   double dailyPnLTotal;
   double weeklyPnLTotal;
   double dailyPnLStart;
   double weeklyPnLStart;
   double maxDailyPnL;
   double maxWeeklyPnL;
   
   // Закрытые сделки за сегодня/неделю
   double totalClosedProfitToday;
   double totalClosedLossToday;
   double totalClosedProfitWeek;
   double totalClosedLossWeek;
   
   // Временные метки
   datetime lastDailyReset;
   datetime lastWeeklyReset;
   datetime lastPnLUpdate;
   
   // Динамический риск
   double maxRiskPerTrade;
   double currentRiskPercent;
   int lossStreak;
   int profitStreak;
   
   // Белый список инструментов
   SInstrumentConfig allowedInstruments[50];
   int allowedInstrumentsCount;
   
   // Корреляционный анализ
   string correlationPairs[20];
   int correlationCount;
   double correlationValues[20];
   
   // Внешние сигналы
   datetime lastSignalTime;
   string lastSignalCommand;
   
   // Состояния рекомендаций (для панели)
   struct STempRecommendation
   {
      string symbol;
      int recommendation;
      string reason;
      datetime timestamp;
   };
   STempRecommendation tempRecommendations[10];
   int tempRecommendationCount;
   
   // Флаги для синхронизации
   datetime lastSyncTime;
   bool syncRequired;
};

//+------------------------------------------------------------------+
//|                    ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ                        |
//+------------------------------------------------------------------+
SGlobalState g_GlobalState;

// Проверяем, объявлены ли уже эти переменные как input-параметры в других файлах
#ifndef ENABLE_CORRELATION_CHECK_DEFINED
input bool EnableCorrelationCheck = true;
#endif

#ifndef SIGNAL_COMMAND_PREFIX_DEFINED
input string SignalCommandPrefix = "/trade";
#endif

//+------------------------------------------------------------------+
//|                    ФУНКЦИИ УПРАВЛЕНИЯ СОСТОЯНИЕМ                 |
//+------------------------------------------------------------------+

// Сохранение глобального состояния
bool Core_SaveGlobalState()
{
   int handle = FileOpen("SIDEZ/GlobalState.bin", FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(handle == INVALID_HANDLE)
      return false;
   
   FileWriteStruct(handle, g_GlobalState);
   FileClose(handle);
   return true;
}

// Загрузка глобального состояния
bool Core_LoadGlobalState()
{
   if(!FileIsExist("SIDEZ/GlobalState.bin", FILE_COMMON))
      return false;
   
   int handle = FileOpen("SIDEZ/GlobalState.bin", FILE_READ | FILE_BIN | FILE_COMMON);
   if(handle == INVALID_HANDLE)
      return false;
   
   bool result = FileReadStruct(handle, g_GlobalState);
   FileClose(handle);
   
   if(result)
   {
      Print("Глобальное состояние загружено");
   }
   else
   {
      Print("Ошибка загрузки глобального состояния");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//|                    ФУНКЦИИ РАБОТЫ С ИНСТРУМЕНТАМИ              |
//+------------------------------------------------------------------+

// Проверить, разрешен ли инструмент
bool IsInstrumentAllowed(string symbol)
{
   if(!g_GlobalState.useWhiteList)
      return true;
   
   // Очищаем лишние пробелы и делаем регистронезависимое сравнение
   StringTrimLeft(symbol);
   StringTrimRight(symbol);
   StringToUpper(symbol);
   
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      string allowedSymbol = g_GlobalState.allowedInstruments[i].symbol;
      StringTrimLeft(allowedSymbol);
      StringTrimRight(allowedSymbol);
      StringToUpper(allowedSymbol);
      
      if(allowedSymbol == symbol)
         return true;
   }
   
   return false;
}

// Загрузка белого списка из строки
void LoadWhiteListFromString(string instrumentsList)
{
   // Очищаем существующий список
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      ZeroMemory(g_GlobalState.allowedInstruments[i]);
   }
   g_GlobalState.allowedInstrumentsCount = 0;
   
   if(instrumentsList == "")
      return;
   
   string symbols[];
   int count = StringSplit(instrumentsList, ',', symbols);
   
   for(int i = 0; i < count && i < 50; i++)
   {
      string symbol = symbols[i];
      StringTrimLeft(symbol);
      StringTrimRight(symbol);
      StringToUpper(symbol);
      
      if(symbol != "")
      {
         // Инициализируем спецификации инструмента
         SInstrumentConfig config;
         config.symbol = symbol;
         
         if(GetInstrumentSpecifications(symbol, config))
         {
            g_GlobalState.allowedInstruments[g_GlobalState.allowedInstrumentsCount] = config;
            g_GlobalState.allowedInstrumentsCount++;
            Print("Добавлен инструмент в белый список: ", symbol);
         }
         else
         {
            Print("⚠ ОШИБКА: Невозможно получить спецификации для инструмента: ", symbol);
         }
      }
   }
   
   Print("Белый список загружен: ", g_GlobalState.allowedInstrumentsCount, " инструментов");
}

// Получение спецификаций инструмента
bool GetInstrumentSpecifications(string symbol, SInstrumentConfig &config)
{
   if(!SymbolSelect(symbol))
   {
      Print("⚠ ОШИБКА: Невозможно выбрать символ: ", symbol);
      return false;
   }
   
   config.symbol = symbol;
   config.tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   config.tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   config.contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   config.minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   config.maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   config.swapLong = SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
   config.swapShort = SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);
   config.marginRequirement = SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL);
   
   // Проверяем, что полученные значения корректны
   if(config.tickSize <= 0 || config.tickValue <= 0 || config.contractSize <= 0)
   {
      Print("⚠ ОШИБКА: Некорректные спецификации для ", symbol, ": tickSize=", config.tickSize, 
            ", tickValue=", config.tickValue, ", contractSize=", config.contractSize);
      return false;
   }
   
   return true;
}

// Печать белого списка
void PrintWhiteList()
{
   Print("=== БЕЛЫЙ СПИСОК ИНСТРУМЕНТОВ ===");
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      Print("[", i+1, "] ", g_GlobalState.allowedInstruments[i].symbol,
            " | Тик: $", DoubleToString(g_GlobalState.allowedInstruments[i].tickValue, 4),
            " | Контракт: ", DoubleToString(g_GlobalState.allowedInstruments[i].contractSize, 0));
   }
   Print("===============================");
}

// Добавление в белый список
bool AddToWhiteList(string symbol, bool getSpecs = true, double customTickValue = 0, double customContractSize = 0, string comment = "")
{
   // Проверяем, не существует ли уже
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      if(g_GlobalState.allowedInstruments[i].symbol == symbol)
      {
         Print("Инструмент ", symbol, " уже в белом списке");
         return true;
      }
   }
   
   if(g_GlobalState.allowedInstrumentsCount >= 50)
   {
      Print("Белый список полон (максимум 50 инструментов)");
      return false;
   }
   
   SInstrumentConfig config;
   config.symbol = symbol;
   
   if(getSpecs)
   {
      if(!GetInstrumentSpecifications(symbol, config))
      {
         Print("⚠ ОШИБКА: Не удалось получить спецификации для ", symbol);
         return false;
      }
   }
   else
   {
      config.tickValue = customTickValue;
      config.contractSize = customContractSize;
   }
   
   g_GlobalState.allowedInstruments[g_GlobalState.allowedInstrumentsCount] = config;
   g_GlobalState.allowedInstrumentsCount++;
   
   Print("✅ Инструмент '", symbol, "' добавлен в белый список");
   if(comment != "") Print("   Комментарий: ", comment);
   
   return true;
}

// Удаление из белого списка
bool RemoveFromWhiteList(string symbol)
{
   for(int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
   {
      if(g_GlobalState.allowedInstruments[i].symbol == symbol)
      {
         // Сдвигаем все элементы после удаляемого
         for(int j = i; j < g_GlobalState.allowedInstrumentsCount - 1; j++)
         {
            g_GlobalState.allowedInstruments[j] = g_GlobalState.allowedInstruments[j+1];
         }
         g_GlobalState.allowedInstrumentsCount--;
         
         Print("✅ Инструмент '", symbol, "' удален из белого списка");
         return true;
      }
   }
   
   Print("⚠ Инструмент '", symbol, "' не найден в белом списке");
   return false;
}

//+------------------------------------------------------------------+
//|                    ФУНКЦИИ СИНХРОНИЗАЦИИ МОДУЛЕЙ                 |
//+------------------------------------------------------------------+

// Синхронизация белого списка между модулями
void SyncWhiteListBetweenModules()
{
   // Сохраняем в общий файл
   int handle = FileOpen("SIDEZ/WhiteListSync.bin", FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(handle != INVALID_HANDLE)
   {
      FileWriteStruct(handle, g_GlobalState.allowedInstruments);
      FileWriteLong(handle, g_GlobalState.allowedInstrumentsCount);
      FileWriteLong(handle, TimeCurrent());
      FileClose(handle);
      
      g_GlobalState.lastSyncTime = TimeCurrent();
      g_GlobalState.syncRequired = false;
      
      Print("Белый список синхронизирован между модулями");
   }
}

// Загрузка белого списка из синхронизации
bool LoadWhiteListFromSync()
{
   if(!FileIsExist("SIDEZ/WhiteListSync.bin", FILE_COMMON))
   {
      Print("Файл синхронизации белого списка не найден");
      return false;
   }
   
   int handle = FileOpen("SIDEZ/WhiteListSync.bin", FILE_READ | FILE_BIN | FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      Print("Ошибка открытия файла синхронизации");
      return false;
   }
   
   SInstrumentConfig tempInstruments[50];
   int tempCount;
   datetime syncTime;
   
   if(FileReadStruct(handle, tempInstruments) && 
      (tempCount = (int)FileReadLong(handle)) > 0 &&
      (syncTime = (datetime)FileReadLong(handle)) > 0)
   {
      // Копируем в глобальное состояние
      for(int i = 0; i < tempCount && i < 50; i++)
      {
         g_GlobalState.allowedInstruments[i] = tempInstruments[i];
      }
      g_GlobalState.allowedInstrumentsCount = tempCount;
      g_GlobalState.lastSyncTime = syncTime;
      g_GlobalState.syncRequired = false;
      
      Print("Белый список загружен из синхронизации (", tempCount, " инструментов)");
      return true;
   }
   
   FileClose(handle);
   return false;
}

//+------------------------------------------------------------------+
//|                    ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ                      |
//+------------------------------------------------------------------+

// Преобразование структуры даты в datetime
datetime StructToTime(MqlDateTime &dt)
{
   return (datetime)(dt.year * 10000 + dt.mon * 100 + dt.day) * 86400 + 
          dt.hour * 3600 + dt.min * 60 + dt.sec;
}

// Парсинг строки времени
bool ParseTimeString(string timeStr, int &hour, int &minute)
{
   string parts[];
   if(StringSplit(timeStr, ':', parts) == 2)
   {
      hour = (int)StringToInteger(parts[0]);
      minute = (int)StringToInteger(parts[1]);
      return (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59);
   }
   return false;
}

// Получение дня недели (0-воскресенье, 1-понедельник, ..., 6-суббота)
int GetDayOfWeek(datetime time)
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.day_of_week;
}

//+------------------------------------------------------------------+
//|                    ФУНКЦИИ РАСЧЕТА РИСКА                        |
//+------------------------------------------------------------------+

// Расчет риска на сделку в $
double CalculateRiskInMoney(double balance, double riskPercent)
{
   return balance * riskPercent / 100.0;
}

// Расчет необходимого объема для риска
double CalculateLotForRisk(double balance, double riskPercent, double stopDistance, double tickValue, double contractSize)
{
   if(stopDistance <= 0 || tickValue <= 0 || contractSize <= 0)
      return 0;
   
   double riskInMoney = CalculateRiskInMoney(balance, riskPercent);
   double ticksInStop = stopDistance / tickValue;
   
   return riskInMoney / (ticksInStop * tickValue * contractSize);
}

//+------------------------------------------------------------------+
//|                    ФУНКЦИИ РАБОТЫ С СИГНАЛАМИ                   |
//+------------------------------------------------------------------+

// Обработка внешнего сигнала
void Core_ProcessExternalSignal(string signal)
{
   if(signal == "" || SignalCommandPrefix == "")
      return;
   
   if(StringFind(signal, SignalCommandPrefix) == 0)
   {
      Print("Получен внешний сигнал: ", signal);
      
      // Сохраняем информацию о сигнале
      g_GlobalState.lastSignalTime = TimeCurrent();
      g_GlobalState.lastSignalCommand = signal;
      
      // Пример обработки команд
      if(signal == SignalCommandPrefix + "reset")
      {
         Print("Команда сброса лимитов получена");
         // Здесь можно добавить сброс лимитов
      }
      else if(signal == SignalCommandPrefix + "status")
      {
         Print("Команда запроса статуса получена");
         // Здесь можно добавить вывод статуса
      }
      else
      {
         Print("Неизвестная команда: ", signal);
      }
   }
}

//+------------------------------------------------------------------+