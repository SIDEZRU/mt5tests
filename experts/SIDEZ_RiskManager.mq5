//+------------------------------------------------------------------+
//|                                                    SIDEZ_RiskManager.mq5 |
//|                              Copyright © 2025, SIDEZ LLC          |
//|                                             https://www.sidez.ru  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025, SIDEZ LLC"
#property link      "https://www.sidez.ru"
#property version   "1.0"
#property description "Глобальный контроллер рисков и менеджер портфеля"
#property strict

// Помечаем для CoreLib, что эти переменные уже объявлены как input-параметры
#define ENABLE_CORRELATION_CHECK_DEFINED
#define SIGNAL_COMMAND_PREFIX_DEFINED

//--- Включение основной библиотеки
#include "..\Include\SIDEZ_CoreLib.mqh"

//+------------------------------------------------------------------+
//|                         ВХОДНЫЕ ПАРАМЕТРЫ                        |
//+------------------------------------------------------------------+
input group "=== Основные настройки RiskManager ===" input string RiskManagerName = "SIDEZ RiskManager"; // Название советника
input int CheckInterval = 1;                                                                             // Интервал проверки (тики)
input bool EnableAutoReset = true;                                                                       // Автосброс в начале дня/недели
input string DailyResetTime = "01:01";                                                                   // Время сброса дневных счетчиков
input string WeeklyResetTime = "Mon 01:01";                                                              // Время сброса недельных счетчиков

input group "=== Дневные лимиты риска ===" input double DailyTakeProfit = 250.0; // Дневной TP ($)
input double DailyStopLoss = -150.0;                                             // Дневной SL ($)
input int MaxDailyTrades = 5;                                                    // Макс. СДЕЛОК в день (все сделки)
input int MaxSimultaneousPositions = 3;                                          // Макс. ОДНОВРЕМЕННЫХ позиций

input group "=== Недельные лимиты риска ===" input double WeeklyTakeProfit = 1250.0; // Недельный TP ($)
input double WeeklyStopLoss = -750.0;                                                // Недельный SL ($)
input int MaxWeeklyTrades = 25;                                                      // Макс. СДЕЛОК в неделю
input int MaxSimultaneousPositionsWeekly = 10;                                       // Макс. ОДНОВРЕМЕННЫХ позиций (неделя)

input group "=== Управление риском на сделку ===" input double MaxRiskPerTrade = 2; // Макс. риск на сделку (% от баланса)
input bool UseDynamicRisk = true;                                                   // Динамический риск
input double MinRiskPercent = 0.5;                                                  // Мин. риск после убытков (%)
input double MaxRiskPercent = 3.0;                                                  // Макс. риск после прибылей (%)
input int LossStreakToReduce = 3;                                                   // Серия убытков для уменьшения риска
input int ProfitStreakToIncrease = 3;                                               // Серия прибылей для увеличения риска

input group "=== Корреляционный риск ===" input bool EnableCorrelationCheck = true; // Проверять корреляции
input string CorrelationPairs = "FUTMESZ25:FUTMGCG26, FUTMESZ25:FUTCLZ25";          // Пары через запятую

input group "=== Автоматическое закрытие ===" input bool CloseAllAtSessionEnd = true; // Закрывать всё в конце сессии
input string TradingSessionEnd = "23:45";                                             // Окончание торговой сессии
input bool CloseAllOnFriday = true;                                                   // Закрывать всё в пятницу
input string FridayCloseTime = "23:45";                                               // Время закрытия в пятницу

input group "=== Внешние сигналы (Telegram) ===" input bool EnableExternalSignals = true; // Принимать внешние сигналы
input string SignalCommandPrefix = "/trade";                                              // Префикс команд

input group "=== Настройки торгового шлюза ===" input bool RM_EnableTradeGateway = true; // Включить торговый шлюз
input string RM_GatewayAllowedMagics = "10001001,20002002,50005000";                     // Разрешенные магики

input group "=== Контроль инструментов и доступа ===" input bool UseWhiteList = true; // ВКЛЮЧИТЬ белый список инструментов
input string AllowedInstruments = "XAUUSD,FUTMESH26,FUTMGCG26,EURUSD,GBPUSD";         // Разрешенные инструменты (через запятую)
input bool BlockOtherExperts = false;                                                 // Блокировать другие советники
input bool BlockManualTradingOnLimit = true;                                          // Блокировать ручную торговлю при достижении лимитов

//+------------------------------------------------------------------+
//|                    ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ                        |
//+------------------------------------------------------------------+
int g_TickCounter = 0;
datetime g_LastCheckTime = 0;
bool g_IsInitialized = false;
string g_CurrentSymbol = "";
double g_LastBalance = 0;
double g_LastEquity = 0;
bool g_ForceCloseAll = false;          // Флаг принудительного закрытия
datetime g_LastTradeExecutionTime = 0; // Время последней исполненной сделки

//+------------------------------------------------------------------+
//| Получение количества дневных сделок (всех торговых операций)     |
//+------------------------------------------------------------------+
int GetDailyTradesCount()
{
    int count = 0;
    datetime todayStart = iTime(_Symbol, PERIOD_D1, 0);

    int totalDeals = HistoryDealsTotal();

    for (int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);

            if ((dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL) &&
                dealTime >= todayStart &&
                dealTime > g_GlobalState.lastDailyReset) // Только после последнего сброса
            {
                count++;
            }
        }
    }

    return count;
}

//+------------------------------------------------------------------+
//| Получение количества недельных сделок                            |
//+------------------------------------------------------------------+
int GetWeeklyTradesCount()
{
    int count = 0;
    datetime weekStart = GetWeekStartTime();

    int totalDeals = HistoryDealsTotal();

    for (int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);

            if ((dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL) &&
                dealTime >= weekStart &&
                dealTime > g_GlobalState.lastWeeklyReset) // Только после последнего сброса
            {
                count++;
            }
        }
    }

    return count;
}

//+------------------------------------------------------------------+
//| Получение времени начала недели                                  |
//+------------------------------------------------------------------+
datetime GetWeekStartTime()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    // Находим понедельник этой недели
    int daysToMonday = (dt.day_of_week == 0) ? 6 : (dt.day_of_week - 1);
    dt.day -= daysToMonday;
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;

    return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Получение количества дневных позиций                             |
//+------------------------------------------------------------------+
int GetDailyPositionsCount()
{
    int count = 0;
    datetime todayStart = iTime(_Symbol, PERIOD_D1, 0);

    int totalDeals = HistoryDealsTotal();

    for (int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);

            if ((dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL) && dealTime >= todayStart)
            {
                count++;
            }
        }
    }

    return count;
}

//+------------------------------------------------------------------+
//| Получение количества недельных позиций                           |
//+------------------------------------------------------------------+
int GetWeeklyPositionsCount()
{
    int count = 0;
    datetime weekStart = GetWeekStartTime();

    int totalDeals = HistoryDealsTotal();

    for (int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);

            if ((dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL) && dealTime >= weekStart)
            {
                count++;
            }
        }
    }

    return count;
}

//+------------------------------------------------------------------+
//| Получение максимального количества одновременных позиций за день |
//+------------------------------------------------------------------+
int GetMaxDailySimultaneousPositions()
{
    // Эта функция отслеживает исторически максимальное количество одновременно открытых позиций за день
    // Для простоты возвращаем текущее количество
    return PositionsTotal();
}

//+------------------------------------------------------------------+
//| Обновление счетчиков сделок (RiskManager версия)                    |
//+------------------------------------------------------------------+
void RiskManager_UpdateTradeCountersLocal()
{
    // Получаем количество сделок за день и неделю
    g_GlobalState.dailyTradesCount = GetDailyTradesCount();
    g_GlobalState.weeklyTradesCount = GetWeeklyTradesCount();

    // Получаем количество одновременно открытых позиций
    g_GlobalState.dailyPositionsCount = PositionsTotal();  // Текущие открытые позиции
    g_GlobalState.weeklyPositionsCount = PositionsTotal(); // Для недели тоже текущие
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("========================================");
    Print(RiskManagerName, " v", CORE_VERSION, " инициализация...");

    // --- ПРИОРИТЕТНАЯ ПРОВЕРКА АКТИВНОЙ БЛОКИРОВКИ ---
    bool hasActiveLock = IsGlobalTradeLockActive();

    if (hasActiveLock)
    {
        Print("⚠ ВНИМАНИЕ: Обнаружена активная глобальная блокировка!");

        // ДОБАВЛЯЕМ: лог для отладки
        Print("Проверка блокировки в ", TimeToString(TimeCurrent()));

        // ПРОВЕРЯЕМ, НЕ УСТАРЕЛА ЛИ БЛОКИРОВКА
        datetime lockTime = 0;
        string lockMessage = "";
        double reason = 0;
        double dailyPnL = 0;
        double weeklyPnL = 0;

        if (FileIsExist("SIDEZ/TradeLock.bin", FILE_COMMON))
        {
            int handle = FileOpen("SIDEZ/TradeLock.bin", FILE_READ | FILE_BIN | FILE_COMMON);
            if (handle != INVALID_HANDLE)
            {
                lockTime = (datetime)FileReadLong(handle);
                reason = FileReadDouble(handle);
                lockMessage = FileReadString(handle);
                dailyPnL = FileReadDouble(handle);
                weeklyPnL = FileReadDouble(handle);
                FileClose(handle);

                // ДОБАВЛЯЕМ: подробный лог
                Print("Блокировка найдена: время=", TimeToString(lockTime),
                      " причина=", lockMessage,
                      " dailyPnL=", dailyPnL, " weeklyPnL=", weeklyPnL);

                // ОПРЕДЕЛЯЕМ, УСТАРЕЛА ЛИ БЛОКИРОВКА (старше начала текущего дня)
                datetime startOfToday = iTime(_Symbol, PERIOD_D1, 0);

                // ДОБАВЛЯЕМ: лог для сравнения времени
                Print("Сравниваем: блокировка=", TimeToString(lockTime),
                      " vs начало дня=", TimeToString(startOfToday));

                if (lockTime < startOfToday)
                {
                    // БЛОКИРОВКА УСТАРЕЛА - СНИМАЕМ АВТОМАТИЧЕСКИ
                    Print("⚠ Снимаем УСТАРЕВШУЮ блокировку от ", TimeToString(lockTime));
                    Print("Причина блокировки была: ", lockMessage);
                    Print("PnL на момент блокировки: День=$", dailyPnL, " Неделя=$", weeklyPnL);

                    RemoveGlobalTradeLock();
                    hasActiveLock = false;

                    // Сбрасываем флаги в глобальном состоянии
                    g_GlobalState.dailyTPReached = false;
                    g_GlobalState.dailySLReached = false;
                    g_GlobalState.weeklyTPReached = false;
                    g_GlobalState.weeklySLReached = false;
                    g_GlobalState.allowNewTrades = true;
                    g_GlobalState.blockManualTrading = false;

                    // ДОБАВЛЯЕМ: сброс счетчиков PnL на момент блокировки
                    Print("PnL на момент снятия блокировки: День=$", g_GlobalState.dailyPnLTotal,
                          " Неделя=$", g_GlobalState.weeklyPnLTotal);

                    Print("✅ Устаревшая блокировка снята. Торговля РАЗРЕШЕНА.");

                    // ДОБАВЛЯЕМ: немедленное сохранение состояния
                    Core_SaveGlobalState();
                }
                else
                {
                    // БЛОКИРОВКА АКТУАЛЬНА - ВОССТАНАВЛИВАЕМ СОСТОЯНИЕ
                    Print("⚠ Актуальная блокировка от ", TimeToString(lockTime));
                    Print("Причина: ", lockMessage);
                    Print("PnL на момент блокировки: День=$", dailyPnL, " Неделя=$", weeklyPnL);

                    // Восстанавливаем флаги
                    if (MathRound(reason) == 1)
                    {
                        g_GlobalState.dailyTPReached = true;
                        Print("Восстановлен: дневной TP достигнут");
                    }
                    else if (MathRound(reason) == 2)
                    {
                        g_GlobalState.dailySLReached = true;
                        Print("Восстановлен: дневной SL достигнут");
                    }
                    else if (MathRound(reason) == 3)
                    {
                        g_GlobalState.weeklyTPReached = true;
                        Print("Восстановлен: недельный TP достигнут");
                    }
                    else if (MathRound(reason) == 4)
                    {
                        g_GlobalState.weeklySLReached = true;
                        Print("Восстановлен: недельный SL достигнут");
                    }
                    else if (MathRound(reason) == 5)
                    {
                        Print("Восстановлен: ручная/системная блокировка");
                    }

                    g_GlobalState.allowNewTrades = false;

                    // ДОБАВЛЯЕМ: проверяем, не изменился ли PnL с момента блокировки
                    double currentDailyPnL = RiskManager_CalculateTotalPnL(true, true);
                    double currentWeeklyPnL = RiskManager_CalculateTotalPnL(false, true);

                    Print("Текущий PnL vs момент блокировки:",
                          " День: $", currentDailyPnL, " vs $", dailyPnL,
                          " Неделя: $", currentWeeklyPnL, " vs $", weeklyPnL);

                    // ДОБАВЛЯЕМ: если PnL улучшился, возможно стоит снять блокировку?
                    if (currentDailyPnL > dailyPnL && reason == 2) // Если был SL, но сейчас лучше
                    {
                        Print("⚠ Текущий PnL лучше чем на момент блокировки. Проверка...");
                    }

                    // НЕ закрываем позиции сразу - это сделает OnTick()
                    // Но ДОБАВЛЯЕМ предупреждение
                    Print("⚠ ВНИМАНИЕ: Активная блокировка! Все позиции будут закрыты в OnTick()");
                }
            }
            else
            {
                Print("❌ Ошибка чтения файла блокировки!");
                // Попробуем удалить некорректный файл
                FileDelete("SIDEZ/TradeLock.bin", FILE_COMMON);
                RemoveGlobalTradeLock();
                hasActiveLock = false;
                Print("Удален поврежденный файл блокировки");
            }
        }
        else
        {
            // Файла нет, но глобальная переменная есть - очищаем
            Print("⚠ Файл блокировки не найден, но глобальная переменная активна");

            // ДОБАВЛЯЕМ: проверяем, есть ли другие признаки блокировки
            if (g_GlobalState.dailyTPReached || g_GlobalState.dailySLReached ||
                g_GlobalState.weeklyTPReached || g_GlobalState.weeklySLReached)
            {
                Print("⚠ Обнаружены флаги блокировки в состоянии:");
                Print("  dailyTPReached=", g_GlobalState.dailyTPReached);
                Print("  dailySLReached=", g_GlobalState.dailySLReached);
                Print("  weeklyTPReached=", g_GlobalState.weeklyTPReached);
                Print("  weeklySLReached=", g_GlobalState.weeklySLReached);

                // Спрашиваем пользователя что делать?
                Print("⚠ ВНИМАНИЕ: Несоответствие! Флаги есть, но файла нет.");
            }

            RemoveGlobalTradeLock();
            hasActiveLock = false;

            // ДОБАВЛЯЕМ: сбрасываем флаги на всякий случай
            g_GlobalState.dailyTPReached = false;
            g_GlobalState.dailySLReached = false;
            g_GlobalState.weeklyTPReached = false;
            g_GlobalState.weeklySLReached = false;
            g_GlobalState.allowNewTrades = true;
            g_GlobalState.blockManualTrading = false;

            Print("✅ Очищена некорректная блокировка");
        }

        // ДОБАВЛЯЕМ: итоговый статус
        if (!hasActiveLock)
        {
            Print("✅ ИТОГ: Блокировка НЕ активна. Торговля разрешена.");
            // Обновляем панель сразу
            UpdateInfoPanel();
        }
        else
        {
            Print("🔴 ИТОГ: Блокировка АКТИВНА. Торговля запрещена.");
            Print("Причина: ", lockMessage, " (", TimeToString(lockTime), ")");

            // ДОБАВЛЯЕМ: немедленное закрытие позиций (на всякий случай)
            if (PositionsTotal() > 0)
            {
                Print("🚨 Немедленное закрытие всех позиций по активной блокировке...");
                ForceCloseAllPositionsInstantly();
            }
        }
    }
    else
    {
        // ДОБАВЛЯЕМ: лог когда блокировки нет
        Print("✅ Глобальная блокировка НЕ активна. Торговля разрешена.");

        // ДОБАВЛЯЕМ: проверяем внутренние флаги на всякий случай
        if (g_GlobalState.dailyTPReached || g_GlobalState.dailySLReached ||
            g_GlobalState.weeklyTPReached || g_GlobalState.weeklySLReached)
        {
            Print("⚠ ВНИМАНИЕ: Обнаружены флаги блокировки при отсутствии глобальной блокировки!");
            Print("Сбрасываем флаги для безопасности...");

            g_GlobalState.dailyTPReached = false;
            g_GlobalState.dailySLReached = false;
            g_GlobalState.weeklyTPReached = false;
            g_GlobalState.weeklySLReached = false;
            g_GlobalState.allowNewTrades = true;
            g_GlobalState.blockManualTrading = false;

            Core_SaveGlobalState();
        }
    }

    // Инициализируем шлюз
    if (RM_EnableTradeGateway)
    {
        g_TradeGateway.SetExpertMagicNumber(MAGIC_RISK_MANAGER);
        g_TradeGateway.SetDeviationInPoints(10);

        // Парсим разрешенные магики
        ParseAllowedMagics(RM_GatewayAllowedMagics, g_AllowedMagicsArray, g_AllowedMagicsCount);

        Print("Торговый шлюз АКТИВИРОВАН");
        Print("Разрешенные магические номера: ", RM_GatewayAllowedMagics);
    }

    // --- САМОВОССТАНАВЛИВАЮЩАЯСЯ БЛОКИРОВКА ---
    // 1. Загружаем состояние
    if (!Core_LoadGlobalState())
    {
        Print("Создано новое глобальное состояние");
    }
    else
    {
        // 2. ВОССТАНАВЛИВАЕМ БЛОКИРОВКУ при перезапуске
        if (g_GlobalState.dailyTPReached || g_GlobalState.dailySLReached ||
            g_GlobalState.weeklyTPReached || g_GlobalState.weeklySLReached)
        {
            Print("ВОССТАНОВЛЕНИЕ ГЛОБАЛЬНОЙ БЛОКИРОВКИ...");

            // Проверяем, не установлена ли уже блокировка
            if (!IsGlobalTradeLockActive())
            {
                // Восстанавливаем блокировку
                int reason = 0;
                if (g_GlobalState.dailyTPReached)
                    reason = 1;
                else if (g_GlobalState.dailySLReached)
                    reason = 2;
                else if (g_GlobalState.weeklyTPReached)
                    reason = 3;
                else if (g_GlobalState.weeklySLReached)
                    reason = 4;

                SetGlobalTradeLock(reason, "Auto-restored on RiskManager restart");

                // Немедленно закрываем все позиции (на случай, если открылись пока RiskManager был выключен)
                ForceCloseAllPositionsInstantly();
            }
            else
            {
                Print("Глобальная блокировка уже активна");
            }
        }
    }

    // --- ИНИЦИАЛИЗАЦИЯ КОРРЕЛЯЦИОННОГО АНАЛИЗА ---
    if (EnableCorrelationCheck)
    {
        // Парсинг CorrelationPairs и инициализация
        string pairs[];
        int count = StringSplit(CorrelationPairs, ',', pairs);
        for (int i = 0; i < count; i++)
        {
            Print("Корреляционная пара: ", pairs[i]);
            // TODO: Инициализация мониторинга пар
        }
    }

    //--- Инициализируем объекты торговли
    g_Trade.SetExpertMagicNumber(MAGIC_RISK_MANAGER);
    g_Trade.SetDeviationInPoints(10);
    //--- Устанавливаем лимиты из входных параметров
    g_GlobalState.dailyTradesLimit = MaxDailyTrades;
    g_GlobalState.weeklyTradesLimit = MaxWeeklyTrades;
    g_GlobalState.maxSimultaneousPositionsDaily = MaxSimultaneousPositions;
    g_GlobalState.maxSimultaneousPositionsWeekly = MaxSimultaneousPositionsWeekly;
    g_GlobalState.maxRiskPerTrade = MaxRiskPerTrade;
    g_GlobalState.dailyTakeProfit = DailyTakeProfit;
    g_GlobalState.dailyStopLoss = DailyStopLoss;
    g_GlobalState.weeklyTakeProfit = WeeklyTakeProfit;
    g_GlobalState.weeklyStopLoss = WeeklyStopLoss;

    //--- НАСТРОЙКА БЕЛОГО СПИСКА И КОНТРОЛЯ ДОСТУПА
    g_GlobalState.useWhiteList = UseWhiteList;
    g_GlobalState.blockManualTrading = false; // По умолчанию ручная торговля разрешена
    g_GlobalState.blockOtherExperts = BlockOtherExperts;

    // Загружаем белый список из input параметра
    if (UseWhiteList && AllowedInstruments != "")
    {
        Print("=== ЗАГРУЗКА БЕЛОГО СПИСКА ===");
        Print("Параметр AllowedInstruments: '", AllowedInstruments, "'");

        // ОЧИЩАЕМ СУЩЕСТВУЮЩИЙ СПИСОК
        for (int i = 0; i < g_GlobalState.allowedInstrumentsCount; i++)
        {
            ZeroMemory(g_GlobalState.allowedInstruments[i]);
        }
        g_GlobalState.allowedInstrumentsCount = 0;

        // Загружаем новый список
        LoadWhiteListFromString(AllowedInstruments);

        // ПРОВЕРЯЕМ, ЧТО ЗАГРУЗИЛОСЬ
        Print("Загружено инструментов: ", g_GlobalState.allowedInstrumentsCount);
        PrintWhiteList();

        // ТЕСТ: проверяем работу IsInstrumentAllowed
        string testSymbols = "XAUUSD,FUTMGCG26,EURUSD,GBPUSD,FUTMESH26";
        string symbols[];
        int count = StringSplit(testSymbols, ',', symbols);

        for (int i = 0; i < count; i++)
        {
            string sym = symbols[i];
            bool allowed = IsInstrumentAllowed(sym);
            Print("ТЕСТ IsInstrumentAllowed[", sym, "] = ", allowed ? "ДА" : "НЕТ");
        }

        // ОБЯЗАТЕЛЬНО сохраняем после изменения
        Core_SaveGlobalState();
        Print("=== КОНЕЦ ЗАГРУЗКИ БЕЛОГО СПИСКА ===");
    }

    // Загружаем белый список из input параметра
    if (UseWhiteList && AllowedInstruments != "")
    {
        Print("=== ЗАГРУЗКА БЕЛОГО СПИСКА ===");

        // Загружаем новый список
        LoadWhiteListFromString(AllowedInstruments);

        // СИНХРОНИЗИРУЕМ С ДРУГИМИ МОДУЛЯМИ
        SyncWhiteListBetweenModules();

        Print("=== КОНЕЦ ЗАГРУЗКИ БЕЛОГО СПИСКА ===");
    }
    else if (UseWhiteList)
    {
        // Если белый список включен, но параметр пустой - пытаемся загрузить из синхронизации
        LoadWhiteListFromSync();
    }

    //--- Для обратной совместимости
    g_GlobalState.dailyPositionsLimit = MaxDailyTrades;
    g_GlobalState.weeklyPositionsLimit = MaxWeeklyTrades;

    //--- Получаем текущие данные
    g_LastBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_LastEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_CurrentSymbol = Symbol();

    //--- Обновляем счетчики сделок и PnL
    RiskManager_UpdateTradeCountersLocal();
    RiskManager_UpdateClosedPnLCounters();

    //--- Проверяем сброс счетчиков
    CheckResetConditions();

    //--- Сохраняем состояние
    Core_SaveGlobalState();

    //--- Создаем информационную панель
    CreateInfoPanel();

    Print("Текущий баланс: $", DoubleToString(g_LastBalance, 2));
    Print("Дневных сделок: ", g_GlobalState.dailyTradesCount, "/", MaxDailyTrades);
    Print("Одновременных позиций: ", PositionsTotal(), "/", MaxSimultaneousPositions);
    Print("Дневной PnL: $", DoubleToString(g_GlobalState.dailyPnLTotal, 2));
    Print("Разрешены новые сделки: ", g_GlobalState.allowNewTrades ? "ДА" : "НЕТ");
    Print("========================================");

    g_IsInitialized = true;
    EventSetTimer(1);
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| ДИАГНОСТИКА БЛОКИРОВКИ                                          |
//+------------------------------------------------------------------+
void DebugTradeLockStatus()
{
    Print("=== ДИАГНОСТИКА БЛОКИРОВКИ ===");

    // 1. Глобальная переменная
    if (GlobalVariableCheck(GLOBAL_LOCK_VAR))
    {
        double value = GlobalVariableGet(GLOBAL_LOCK_VAR);
        Print("1. Глобальная переменная: ", value, " (", (value > 0 ? "АКТИВНА" : "не активна"), ")");
    }
    else
    {
        Print("1. Глобальная переменная: НЕ СУЩЕСТВУЕТ");
    }

    // 2. Файл блокировки
    if (FileIsExist("SIDEZ/TradeLock.bin", FILE_COMMON))
    {
        int handle = FileOpen("SIDEZ/TradeLock.bin", FILE_READ | FILE_BIN | FILE_COMMON);
        if (handle != INVALID_HANDLE)
        {
            datetime lockTime = (datetime)FileReadLong(handle);
            double reason = FileReadDouble(handle);
            string message = FileReadString(handle);
            FileClose(handle);

            Print("2. Файл блокировки: СУЩЕСТВУЕТ");
            Print("   Время: ", TimeToString(lockTime));
            Print("   Причина: ", message, " (код: ", reason, ")");
            Print("   Возраст: ", (TimeCurrent() - lockTime), " секунд");
        }
        else
        {
            Print("2. Файл блокировки: ПОВРЕЖДЕН");
        }
    }
    else
    {
        Print("2. Файл блокировки: НЕТ");
    }

    // 3. Флаги в состоянии
    Print("3. Флаги в g_GlobalState:");
    Print("   dailyTPReached: ", g_GlobalState.dailyTPReached);
    Print("   dailySLReached: ", g_GlobalState.dailySLReached);
    Print("   weeklyTPReached: ", g_GlobalState.weeklyTPReached);
    Print("   weeklySLReached: ", g_GlobalState.weeklySLReached);
    Print("   allowNewTrades: ", g_GlobalState.allowNewTrades);
    Print("   blockManualTrading: ", g_GlobalState.blockManualTrading);

    // 4. Текущие позиции
    Print("4. Текущие позиции: ", PositionsTotal());

    // 5. Результат IsGlobalTradeLockActive()
    Print("5. IsGlobalTradeLockActive(): ", IsGlobalTradeLockActive() ? "ДА" : "НЕТ");

    Print("=================================");
}

// Вызвать эту функцию можно через кнопку или в OnTick() для отладки

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if (!g_IsInitialized)
        return;

    g_TickCounter++;

    // Оптимизация: проверяем чаще
    if (g_TickCounter % 10 != 0)
        return; // Каждые 10 тиков!

    // --- МГНОВЕННАЯ ПРОВЕРКА БЛОКИРОВКИ ---
    static bool lastLockStatus = false;

    bool currentLockStatus = IsGlobalTradeLockActive();

    if (currentLockStatus)
    {
        // Печатаем только при изменении статуса
        if (!lastLockStatus)
        {
            Print("🔴 Глобальная блокировка активирована");
        }

        // Если блокировка активна, немедленно закрываем всё
        if (PositionsTotal() > 0)
        {
            Print("🔴 Закрываем все позиции по глобальной блокировке");
            ForceCloseAllPositionsInstantly();
        }

        // Удаляем все отложенные ордера
        if (OrdersTotal() > 0)
        {
            Print("🔴 Удаляем все отложенные ордера");
            BlockAllPendingOrders();
        }

        // Обновляем статус
        lastLockStatus = true;

        // Выходим из OnTick - больше ничего не делаем
        return;
    }
    else
    {
        // Если блокировка снята, печатаем один раз
        if (lastLockStatus)
        {
            Print("✅ Глобальная блокировка снята");
            lastLockStatus = false;
        }
    }

    //--- Обновляем баланс и эквити
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

    if (currentBalance != g_LastBalance || currentEquity != g_LastEquity)
    {
        g_LastBalance = currentBalance;
        g_LastEquity = currentEquity;
    }

    //--- Проверяем условия сброса
    if (EnableAutoReset)
    {
        CheckResetConditions();
    }

    //--- Обновляем счетчики сделок (ВСЕГДА при тике!)
    RiskManager_UpdateTradeCountersLocal();

    //--- Обновляем счетчики PnL (ЧИСТОМУ PnL!)
    RiskManager_UpdateClosedPnLCounters();

    //--- Обновляем максимальный PnL
    if (g_GlobalState.dailyPnLTotal > g_GlobalState.maxDailyPnL)
        g_GlobalState.maxDailyPnL = g_GlobalState.dailyPnLTotal;

    if (g_GlobalState.weeklyPnLTotal > g_GlobalState.maxWeeklyPnL)
        g_GlobalState.maxWeeklyPnL = g_GlobalState.weeklyPnLTotal;

    //--- Проверяем лимиты (по ЧИСТОМУ PnL!)
    CheckRiskLimits();

    //--- Проверяем окончание торговой сессии
    if (CloseAllAtSessionEnd)
    {
        CheckSessionEnd();
    }

    //--- Проверяем конец недели (пятница)
    if (CloseAllOnFriday)
    {
        CheckFridayClose();
    }

    //--- Обновляем риск на основе серий
    UpdateDynamicRisk();

    //--- Проверяем принудительное закрытие
    if (g_ForceCloseAll)
    {
        ExecuteForceCloseAll();
    }

    //--- Логируем каждые 200 тиков
    if (g_TickCounter % 200 == 0)
    {
        Print("RiskManager status: Daily PnL=$", DoubleToString(g_GlobalState.dailyPnLTotal, 2),
              " | Weekly PnL=$", DoubleToString(g_GlobalState.weeklyPnLTotal, 2),
              " | Daily TP=$", DailyTakeProfit, " | Daily SL=$", DailyStopLoss,
              " | Positions=", PositionsTotal(),
              " | Risk=", DoubleToString(g_GlobalState.currentRiskPercent, 1), "%",
              " | Daily Trades=", g_GlobalState.dailyPositionsCount, "/", MaxDailyTrades);
    }

    //--- Сохраняем состояние каждую минуту ИЛИ при изменении
    static datetime lastAutoSave = 0;
    if (TimeCurrent() - lastAutoSave >= 60)
    {
        Core_SaveGlobalState();
        lastAutoSave = TimeCurrent();
    }

    //--- Обновляем информационную панель
    UpdateInfoPanel();

    //--- Обновляем комментарий на графике...ВАНА.
        }
    }
}

//+------------------------------------------------------------------+
//| Обновление дневного и недельного PnL                           |
//+------------------------------------------------------------------+
void RiskManager_UpdateClosedPnLCounters()
{
    //--- Инициализируем начальные значения если первый запуск
    if (g_GlobalState.dailyPnLStart == 0 && g_GlobalState.weeklyPnLStart == 0)
    {
        g_GlobalState.dailyPnLStart = AccountInfoDouble(ACCOUNT_BALANCE);
        g_GlobalState.weeklyPnLStart = AccountInfoDouble(ACCOUNT_BALANCE);
    }

    //--- Рассчитываем дневной PnL (чисто для отображения)
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_GlobalState.dailyPnLTotal = currentBalance - g_GlobalState.dailyPnLStart;
    g_GlobalState.weeklyPnLTotal = currentBalance - g_GlobalState.weeklyPnLStart;

    //--- Также обновляем счетчики закрытых сделок за сегодня/неделю
    UpdateClosedDealsCounters();
}

//+------------------------------------------------------------------+
//| Обновление счетчиков закрытых сделок                            |
//+------------------------------------------------------------------+
void UpdateClosedDealsCounters()
{
    //--- Обнуляем счетчики
    g_GlobalState.totalClosedProfitToday = 0;
    g_GlobalState.totalClosedLossToday = 0;
    g_GlobalState.totalClosedProfitWeek = 0;
    g_GlobalState.totalClosedLossWeek = 0;

    //--- Получаем начальное время дня и недели
    datetime todayStart = iTime(_Symbol, PERIOD_D1, 0);
    datetime weekStart = GetWeekStartTime();

    //--- Проходим по всем сделкам
    int totalDeals = HistoryDealsTotal();
    for (int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);

            //--- Обновляем дневные счетчики
            if (dealTime >= todayStart)
            {
                if (profit > 0)
                    g_GlobalState.totalClosedProfitToday += profit;
                else
                    g_GlobalState.totalClosedLossToday += profit;
            }

            //--- Обновляем недельные счетчики
            if (dealTime >= weekStart)
            {
                if (profit > 0)
                    g_GlobalState.totalClosedProfitWeek += profit;
                else
                    g_GlobalState.totalClosedLossWeek += profit;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Расчет общего PnL (для проверки лимитов)                        |
//+------------------------------------------------------------------+
double RiskManager_CalculateTotalPnL(bool daily = true, bool includeOpenPositions = true)
{
    double pnl = 0;

    //--- Добавляем PnL закрытых сделок
    if (daily)
        pnl = g_GlobalState.totalClosedProfitToday + g_GlobalState.totalClosedLossToday;
    else
        pnl = g_GlobalState.totalClosedProfitWeek + g_GlobalState.totalClosedLossWeek;

    //--- Добавляем PnL открытых позиций если нужно
    if (includeOpenPositions)
    {
        for (int i = 0; i < PositionsTotal(); i++)
        {
            if (PositionSelectByTicket(PositionGetTicket(i)))
            {
                pnl += PositionGetDouble(POSITION_PROFIT);
            }
        }
    }

    return pnl;
}

//+------------------------------------------------------------------+
//| Проверка условий сброса                                         |
//+------------------------------------------------------------------+
void CheckResetConditions()
{
    datetime now = TimeCurrent();
    MqlDateTime dtNow;
    TimeCurrent(dtNow);

    //--- Проверка дневного сброса
    if (EnableAutoReset)
    {
        int resetHour, resetMin;
        if (ParseTimeString(DailyResetTime, resetHour, resetMin))
        {
            if (dtNow.hour == resetHour && dtNow.min == resetMin && dtNow.sec == 0)
            {
                // Проверяем, не сбрасывали ли мы уже сегодня
                MqlDateTime lastReset;
                TimeToStruct((datetime)g_GlobalState.lastDailyReset, lastReset);

                if (lastReset.day != dtNow.day || lastReset.month != dtNow.month || lastReset.year != dtNow.year)
                {
                    Print("🔄 ДНЕВНОЙ СБРОС в ", TimeToString(now));
                    ResetDailyCounters();
                }
            }
        }
    }

    //--- Проверка недельного сброса
    string dayPart = StringSubstr(WeeklyResetTime, 0, 3);
    string timePart = StringSubstr(WeeklyResetTime, 4);

    if (dayPart == "Mon" || dayPart == "Tue" || dayPart == "Wed" || 
        dayPart == "Thu" || dayPart == "Fri" || dayPart == "Sat" || dayPart == "Sun")
    {
        int resetHour, resetMin;
        if (ParseTimeString(timePart, resetHour, resetMin))
        {
            // Определяем день недели
            string weekdays[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
            int targetDay = -1;
            for (int i = 0; i < 7; i++)
            {
                if (weekdays[i] == dayPart)
                {
                    targetDay = i;
                    break;
                }
            }

            if (targetDay >= 0 && dtNow.day_of_week == targetDay && 
                dtNow.hour == resetHour && dtNow.min == resetMin && dtNow.sec == 0)
            {
                // Проверяем, не сбрасывали ли мы уже на этой неделе
                datetime weekStart = GetWeekStartTime();
                if (g_GlobalState.lastWeeklyReset < weekStart)
                {
                    Print("🔄 НЕДЕЛЬНЫЙ СБРОС в ", TimeToString(now));
                    ResetWeeklyCounters();
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Сброс дневных счетчиков                                        |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
    g_GlobalState.dailyPnLStart = AccountInfoDouble(ACCOUNT_BALANCE);
    g_GlobalState.dailyPnLTotal = 0;
    g_GlobalState.dailyTradesCount = 0;
    g_GlobalState.dailyPositionsCount = 0;
    g_GlobalState.totalClosedProfitToday = 0;
    g_GlobalState.totalClosedLossToday = 0;
    g_GlobalState.dailyTPReached = false;
    g_GlobalState.dailySLReached = false;
    g_GlobalState.lastDailyReset = TimeCurrent();

    Print("Дневные счетчики сброшены");
    Core_SaveGlobalState();
}

//+------------------------------------------------------------------+
//| Сброс недельных счетчиков                                      |
//+------------------------------------------------------------------+
void ResetWeeklyCounters()
{
    g_GlobalState.weeklyPnLStart = AccountInfoDouble(ACCOUNT_BALANCE);
    g_GlobalState.weeklyPnLTotal = 0;
    g_GlobalState.weeklyTradesCount = 0;
    g_GlobalState.weeklyPositionsCount = 0;
    g_GlobalState.totalClosedProfitWeek = 0;
    g_GlobalState.totalClosedLossWeek = 0;
    g_GlobalState.weeklyTPReached = false;
    g_GlobalState.weeklySLReached = false;
    g_GlobalState.lastWeeklyReset = TimeCurrent();

    Print("Недельные счетчики сброшены");
    Core_SaveGlobalState();
}

//+------------------------------------------------------------------+
//| Проверка лимитов риска                                         |
//+------------------------------------------------------------------+
void CheckRiskLimits()
{
    //--- Получаем текущий PnL
    double currentDailyPnL = RiskManager_CalculateTotalPnL(true, true);
    double currentWeeklyPnL = RiskManager_CalculateTotalPnL(false, true);

    //--- Проверяем дневной TakeProfit
    if (!g_GlobalState.dailyTPReached && currentDailyPnL >= DailyTakeProfit)
    {
        Print("🎯 ДНЕВНОЙ TAKE PROFIT ДОСТИГНУТ: $", DoubleToString(currentDailyPnL, 2),
              " >= $", DailyTakeProfit);
        
        g_GlobalState.dailyTPReached = true;
        g_GlobalState.allowNewTrades = false;
        
        string blockReason = "Дневной TP достигнут: $" + DoubleToString(currentDailyPnL, 2) + 
                            " >= $" + DoubleToString(DailyTakeProfit, 2);
        
        SetGlobalTradeLock(1, blockReason); // 1 = Daily TP
        
        // Закрываем все позиции при достижении лимитов
        if (PositionsTotal() > 0)
        {
            Print("🚨 Закрытие всех позиций по достижению дневного TP...");
            ForceCloseAllPositionsInstantly();
        }
        
        Alert("ДНЕВНОЙ TAKE PROFIT ДОСТИГНУТ: " + DoubleToString(currentDailyPnL, 2));
    }

    //--- Проверяем дневной StopLoss
    if (!g_GlobalState.dailySLReached && currentDailyPnL <= DailyStopLoss)
    {
        Print("🛑 ДНЕВНОЙ STOP LOSS ДОСТИГНУТ: $", DoubleToString(currentDailyPnL, 2),
              " <= $", DailyStopLoss);
        
        g_GlobalState.dailySLReached = true;
        g_GlobalState.allowNewTrades = false;
        
        string blockReason = "Дневной SL достигнут: $" + DoubleToString(currentDailyPnL, 2) + 
                            " <= $" + DoubleToString(DailyStopLoss, 2);
        
        SetGlobalTradeLock(2, blockReason); // 2 = Daily SL
        
        // Закрываем все позиции при достижении лимитов
        if (PositionsTotal() > 0)
        {
            Print("🚨 Закрытие всех позиций по достижению дневного SL...");
            ForceCloseAllPositionsInstantly();
        }
        
        Alert("ДНЕВНОЙ STOP LOSS ДОСТИГНУТ: " + DoubleToString(currentDailyPnL, 2));
    }

    //--- Проверяем недельный TakeProfit
    if (!g_GlobalState.weeklyTPReached && currentWeeklyPnL >= WeeklyTakeProfit)
    {
        Print("🎯 НЕДЕЛЬНЫЙ TAKE PROFIT ДОСТИГНУТ: $", DoubleToString(currentWeeklyPnL, 2),
              " >= $", WeeklyTakeProfit);
        
        g_GlobalState.weeklyTPReached = true;
        g_GlobalState.allowNewTrades = false;
        
        string blockReason = "Недельный TP достигнут: $" + DoubleToString(currentWeeklyPnL, 2) + 
                            " >= $" + DoubleToString(WeeklyTakeProfit, 2);
        
        SetGlobalTradeLock(3, blockReason); // 3 = Weekly TP
        
        // Закрываем все позиции при достижении лимитов
        if (PositionsTotal() > 0)
        {
            Print("🚨 Закрытие всех позиций по достижению недельного TP...");
            ForceCloseAllPositionsInstantly();
        }
        
        Alert("НЕДЕЛЬНЫЙ TAKE PROFIT ДОСТИГНУТ: " + DoubleToString(currentWeeklyPnL, 2));
    }

    //--- Проверяем недельный StopLoss
    if (!g_GlobalState.weeklySLReached && currentWeeklyPnL <= WeeklyStopLoss)
    {
        Print("🛑 НЕДЕЛЬНЫЙ STOP LOSS ДОСТИГНУТ: $", DoubleToString(currentWeeklyPnL, 2),
              " <= $", WeeklyStopLoss);
        
        g_GlobalState.weeklySLReached = true;
        g_GlobalState.allowNewTrades = false;
        
        string blockReason = "Недельный SL достигнут: $" + DoubleToString(currentWeeklyPnL, 2) + 
                            " <= $" + DoubleToString(WeeklyStopLoss, 2);
        
        SetGlobalTradeLock(4, blockReason); // 4 = Weekly SL
        
        // Закрываем все позиции при достижении лимитов
        if (PositionsTotal() > 0)
        {
            Print("🚨 Закрытие всех позиций по достижению недельного SL...");
            ForceCloseAllPositionsInstantly();
        }
        
        Alert("НЕДЕЛЬНЫЙ STOP LOSS ДОСТИГНУТ: " + DoubleToString(currentWeeklyPnL, 2));
    }

    //--- Проверяем ограничения на количество сделок
    if (g_GlobalState.dailyTradesCount >= MaxDailyTrades && !g_GlobalState.dailyTPReached && !g_GlobalState.dailySLReached)
    {
        Print("📊 ДНЕВНОЕ ОГРАНИЧЕНИЕ НА СДЕЛКИ ДОСТИГНУТО: ", g_GlobalState.dailyTradesCount, 
              " >= ", MaxDailyTrades);
        
        g_GlobalState.dailyTPReached = true; // Используем этот флаг для блокировки
        g_GlobalState.allowNewTrades = false;
        
        string blockReason = "Дневное ограничение на сделки: " + IntegerToString(g_GlobalState.dailyTradesCount) + 
                            " >= " + IntegerToString(MaxDailyTrades);
        
        SetGlobalTradeLock(5, blockReason); // 5 = Manual/System lock

        // Закрываем все позиции при достижении лимитов
        if (PositionsTotal() > 0)
        {
            Print("🚨 Закрытие всех позиций по достижению лимитов...");
            ForceCloseAllPositionsInstantly();
        }

        Alert("ТОРГОВЛЯ ЗАБЛОКИРОВАНА: " + blockReason);
    }

    //--- Проверяем ограничения на количество одновременных позиций
    if (PositionsTotal() > MaxSimultaneousPositions && !g_GlobalState.dailyTPReached && !g_GlobalState.dailySLReached)
    {
        Print("💼 ПРЕВЫШЕНО ОГРАНИЧЕНИЕ НА ОДНОВРЕМЕННЫЕ ПОЗИЦИИ: ", PositionsTotal(), 
              " > ", MaxSimultaneousPositions);
        
        g_GlobalState.allowNewTrades = false;
        
        string blockReason = "Превышено ограничение на одновременные позиции: " + IntegerToString(PositionsTotal()) + 
                            " > " + IntegerToString(MaxSimultaneousPositions);
        
        // Только устанавливаем флаг, не блокируем полностью
        Print("Предупреждение: ", blockReason);
    }
}

//+------------------------------------------------------------------+
//| Обновление динамического риска                                   |
//+------------------------------------------------------------------+
void UpdateDynamicRisk()
{
    if (!UseDynamicRisk)
        return;

    //--- Рассчитываем серии на основе закрытых сделок
    CalculateProfitLossStreaks();

    //--- Если была серия убытков - уменьшаем риск
    if (g_GlobalState.lossStreak >= LossStreakToReduce)
    {
        double newRisk = g_GlobalState.currentRiskPercent * 0.7;
        if (newRisk < MinRiskPercent)
            newRisk = MinRiskPercent;

        if (newRisk != g_GlobalState.currentRiskPercent)
        {
            g_GlobalState.currentRiskPercent = newRisk;
            Print("Уменьшен риск до ", DoubleToString(g_GlobalState.currentRiskPercent, 1), "% после ",
                  g_GlobalState.lossStreak, " убытков подряд");
        }
    }

    //--- Если была серия прибылей - увеличиваем риск (с ограничением)
    if (g_GlobalState.profitStreak >= ProfitStreakToIncrease)
    {
        double newRisk = g_GlobalState.currentRiskPercent * 1.2;
        if (newRisk > MaxRiskPercent)
            newRisk = MaxRiskPercent;

        if (newRisk != g_GlobalState.currentRiskPercent)
        {
            g_GlobalState.currentRiskPercent = newRisk;
            Print("Увеличен риск до ", DoubleToString(g_GlobalState.currentRiskPercent, 1), "% после ",
                  g_GlobalState.profitStreak, " прибылей подряд");
        }
    }
}

//+------------------------------------------------------------------+
//| Расчет серий прибылей/убытков                                    |
//+------------------------------------------------------------------+
void CalculateProfitLossStreaks()
{
    //--- Эта функция должна анализировать историю сделок
    //--- Для простоты будем использовать последние 100 сделок

    int totalDeals = HistoryDealsTotal();
    int recentDeals = MathMin(totalDeals, 100);
    int profitCount = 0;
    int lossCount = 0;

    for (int i = 0; i < recentDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket > 0)
        {
            long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);
            if (dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
            {
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);

                if (profit > 0)
                {
                    profitCount++;
                    lossCount = 0;
                }
                else if (profit < 0)
                {
                    lossCount++;
                    profitCount = 0;
                }
            }
        }
    }

    //--- Обновляем серии
    if (profitCount > 0)
    {
        g_GlobalState.profitStreak = profitCount;
        g_GlobalState.lossStreak = 0;
    }
    else if (lossCount > 0)
    {
        g_GlobalState.lossStreak = lossCount;
        g_GlobalState.profitStreak = 0;
    }
}

//+------------------------------------------------------------------+
//| Проверка окончания торговой сессии                               |
//+------------------------------------------------------------------+
void CheckSessionEnd()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    int currentMinutes = dt.hour * 60 + dt.min;
    int endHour, endMinute;

    if (ParseTimeString(TradingSessionEnd, endHour, endMinute))
    {
        int endMinutes = endHour * 60 + endMinute;

        //--- Закрываем за 25 минут до окончания
        if (currentMinutes >= endMinutes - 25 && currentMinutes < endMinutes)
        {
            if (PositionsTotal() > 0)
            {
                Print("Заканчивается торговая сессия, закрываем все позиции...");
                g_ForceCloseAll = true;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Проверка закрытия в пятницу                                      |
//+------------------------------------------------------------------+
void CheckFridayClose()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    if (dt.day_of_week == 5) // Пятница
    {
        int currentMinutes = dt.hour * 60 + dt.min;
        int closeHour, closeMinute;

        if (ParseTimeString(FridayCloseTime, closeHour, closeMinute))
        {
            int closeMinutes = closeHour * 60 + closeMinute;

            //--- Закрываем за 30 минут до указанного времени
            if (currentMinutes >= closeMinutes - 30 && currentMinutes < closeMinutes)
            {
                if (PositionsTotal() > 0)
                {
                    Print("Пятница, закрываем все позиции перед выходными...");
                    g_ForceCloseAll = true;
                }
            }
        }
    }
}

/* 
//+------------------------------------------------------------------+
//| Проверка корреляционных рисков                                   |
//+------------------------------------------------------------------+
void CheckCorrelationRisks()
{
   //--- Проверяем, не торгуем ли мы сильно коррелированные инструменты
   for(int i = 0; i < g_GlobalState.correlationCount; i++)
   {
      string pair = g_GlobalState.correlationPairs[i];
      string symbols[];

      if(StringSplit(pair, ':', symbols) == 2)
      {
         string sym1 = symbols[0];
         string sym2 = symbols[1];

         //--- Проверяем, есть ли открытые позиции по обоим символам
         bool hasSym1 = HasOpenPositions(sym1);
         bool hasSym2 = HasOpenPositions(sym2);

         if(hasSym1 && hasSym2)
         {
            Print("ВНИМАНИЕ: Открыты позиции по коррелированной паре ", sym1, " и ", sym2);

            //--- Можно добавить логику закрытия одной из позиций
            if(g_GlobalState.correlationValues[i] > 0.7) // Высокая корреляция
            {
               Print("Высокая корреляция (", g_GlobalState.correlationValues[i], "). Рекомендуется закрыть одну из позиций.");
            }
         }
      }
   }
}
*/

//+------------------------------------------------------------------+
//| Проверка наличия открытых позиций по символу                     |
//+------------------------------------------------------------------+
bool HasOpenPositions(string symbol)
{
    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            string posSymbol = PositionGetString(POSITION_SYMBOL);
            if (posSymbol == symbol)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Выполнить принудительное закрытие всех позиций                   |
//+------------------------------------------------------------------+
void ExecuteForceCloseAll()
{
    if (!g_ForceCloseAll)
        return;

    Print("Выполняется принудительное закрытие всех позиций...");

    int closedCount = CloseAllPositions("Force Close");

    if (closedCount > 0)
    {
        Print("Закрыто ", closedCount, " позиций");
    }

    g_ForceCloseAll = false;

    //--- После закрытия обновляем PnL
    RiskManager_UpdateClosedPnLCounters();
}

//+------------------------------------------------------------------+
//| Закрытие всех позиций                                            |
//+------------------------------------------------------------------+
int CloseAllPositions(string reason)
{
    Print("Закрытие всех позиций. Причина: ", reason);
    Print("Всего позиций для закрытия: ", PositionsTotal());

    int closedCount = 0;
    int totalPositions = PositionsTotal();

    //--- Собираем все тикеты
    ulong tickets[];
    ArrayResize(tickets, totalPositions);

    for (int i = 0; i < totalPositions; i++)
    {
        tickets[i] = PositionGetTicket(i);
    }

    //--- Закрываем каждую позицию
    for (int i = 0; i < totalPositions; i++)
    {
        if (tickets[i] == 0)
            continue;

        if (PositionSelectByTicket(tickets[i]))
        {
            string symbol = PositionGetString(POSITION_SYMBOL);
            double volume = PositionGetDouble(POSITION_VOLUME);
            long type = PositionGetInteger(POSITION_TYPE);
            double profit = PositionGetDouble(POSITION_PROFIT);

            Print("Закрытие позиции #", tickets[i], ": ", symbol,
                  " Объем: ", DoubleToString(volume, 2),
                  " Тип: ", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                  " Прибыль: $", DoubleToString(profit, 2));

            //--- Закрываем позицию
            if (g_Trade.PositionClose(tickets[i]))
            {
                closedCount++;
                Print("  Успешно закрыта");

                //--- Обновляем счетчик закрытых позиций
                g_GlobalState.dailyPositionsCount++;
                g_GlobalState.weeklyPositionsCount++;
            }
            else
            {
                Print("  ОШИБКА при закрытии. Код: ", g_Trade.ResultRetcode(),
                      " - ", g_Trade.ResultRetcodeDescription());
            }

            Sleep(50); // Небольшая пауза
        }
    }

    Print("Операция закрытия завершена: ", closedCount, " закрыто из ", totalPositions);

    if (PositionsTotal() > 0)
    {
        Alert("Внимание: ", PositionsTotal(), " позиций не удалось закрыть автоматически!");
    }

    //--- Сохраняем состояние
    Core_SaveGlobalState();

    return closedCount;
}

//+------------------------------------------------------------------+
//| Создание информационной панели                                   |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
    //--- Фон панели
    ObjectCreate(0, "RiskManager_Panel_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_YDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_XSIZE, 300);
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_YSIZE, 220); // Увеличили на 20
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, "RiskManager_Panel_BG", OBJPROP_BORDER_COLOR, clrGray);

    //--- Заголовок
    ObjectCreate(0, "RiskManager_Panel_Title", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_Title", OBJPROP_TEXT, RiskManagerName);
    ObjectSetInteger(0, "RiskManager_Panel_Title", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_Title", OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(0, "RiskManager_Panel_Title", OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(0, "RiskManager_Panel_Title", OBJPROP_FONTSIZE, 10);

    //--- Дневной PnL
    ObjectCreate(0, "RiskManager_Panel_DailyPnL", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_DailyPnL", OBJPROP_TEXT, "Дневной PnL: $0.00");
    ObjectSetInteger(0, "RiskManager_Panel_DailyPnL", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_DailyPnL", OBJPROP_YDISTANCE, 55);
    ObjectSetInteger(0, "RiskManager_Panel_DailyPnL", OBJPROP_COLOR, clrWhite);

    //--- Недельный PnL
    ObjectCreate(0, "RiskManager_Panel_WeeklyPnL", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_WeeklyPnL", OBJPROP_TEXT, "Недельный PnL: $0.00");
    ObjectSetInteger(0, "RiskManager_Panel_WeeklyPnL", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_WeeklyPnL", OBJPROP_YDISTANCE, 75);
    ObjectSetInteger(0, "RiskManager_Panel_WeeklyPnL", OBJPROP_COLOR, clrWhite);

    //--- Статус торговли
    ObjectCreate(0, "RiskManager_Panel_TradeStatus", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_TradeStatus", OBJPROP_TEXT, "Торговля: РАЗРЕШЕНА");
    ObjectSetInteger(0, "RiskManager_Panel_TradeStatus", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_TradeStatus", OBJPROP_YDISTANCE, 95);
    ObjectSetInteger(0, "RiskManager_Panel_TradeStatus", OBJPROP_COLOR, clrLime);

    //--- Дневные сделки
    ObjectCreate(0, "RiskManager_Panel_DailyTrades", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_DailyTrades", OBJPROP_TEXT, "Дневные сделки: 0/10");
    ObjectSetInteger(0, "RiskManager_Panel_DailyTrades", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_DailyTrades", OBJPROP_YDISTANCE, 115);
    ObjectSetInteger(0, "RiskManager_Panel_DailyTrades", OBJPROP_COLOR, clrWhite);

    //--- Одновременные позиции
    ObjectCreate(0, "RiskManager_Panel_Simultaneous", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_Simultaneous", OBJPROP_TEXT, "Одновр. позиции: 0/3");
    ObjectSetInteger(0, "RiskManager_Panel_Simultaneous", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_Simultaneous", OBJPROP_YDISTANCE, 135);
    ObjectSetInteger(0, "RiskManager_Panel_Simultaneous", OBJPROP_COLOR, clrWhite);

    //--- Риск
    ObjectCreate(0, "RiskManager_Panel_Risk", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_Risk", OBJPROP_TEXT, "Текущий риск: 1.0%");
    ObjectSetInteger(0, "RiskManager_Panel_Risk", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_Risk", OBJPROP_YDISTANCE, 155);
    ObjectSetInteger(0, "RiskManager_Panel_Risk", OBJPROP_COLOR, clrWhite);

    //--- Открытые позиции
    ObjectCreate(0, "RiskManager_Panel_OpenPositions", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_OpenPositions", OBJPROP_TEXT, "Открыто позиций: 0");
    ObjectSetInteger(0, "RiskManager_Panel_OpenPositions", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_OpenPositions", OBJPROP_YDISTANCE, 175);
    ObjectSetInteger(0, "RiskManager_Panel_OpenPositions", OBJPROP_COLOR, clrWhite);

    //--- Время
    ObjectCreate(0, "RiskManager_Panel_Time", OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, "RiskManager_Panel_Time", OBJPROP_TEXT, "Обновлено: --:--:--");
    ObjectSetInteger(0, "RiskManager_Panel_Time", OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, "RiskManager_Panel_Time", OBJPROP_YDISTANCE, 195);
    ObjectSetInteger(0, "RiskManager_Panel_Time", OBJPROP_COLOR, clrSilver);
    ObjectSetInteger(0, "RiskManager_Panel_Time", OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Обновление информационной панели                                 |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
    //--- Дневной PnL
    string dailyPnLText = "Дневной PnL: $" + DoubleToString(g_GlobalState.dailyPnLTotal, 2);
    color dailyPnLColor = (g_GlobalState.dailyPnLTotal >= 0) ? clrLime : clrRed;
    ObjectSetString(0, "RiskManager_Panel_DailyPnL", OBJPROP_TEXT, dailyPnLText);
    ObjectSetInteger(0, "RiskManager_Panel_DailyPnL", OBJPROP_COLOR, dailyPnLColor);

    //--- Недельный PnL
    string weeklyPnLText = "Недельный PnL: $" + DoubleToString(g_GlobalState.weeklyPnLTotal, 2);
    color weeklyPnLColor = (g_GlobalState.weeklyPnLTotal >= 0) ? clrLime : clrRed;
    ObjectSetString(0, "RiskManager_Panel_WeeklyPnL", OBJPROP_TEXT, weeklyPnLText);
    ObjectSetInteger(0, "RiskManager_Panel_WeeklyPnL", OBJPROP_COLOR, weeklyPnLColor);

    //--- Статус торговли
    string tradeStatus = "Торговля: ";
    color statusColor = clrLime;

    if (!g_GlobalState.allowNewTrades || g_GlobalState.dailyTPReached || g_GlobalState.dailySLReached ||
        g_GlobalState.weeklyTPReached || g_GlobalState.weeklySLReached)
    {
        tradeStatus += "ЗАПРЕЩЕНА";
        statusColor = clrRed;
    }
    else
    {
        tradeStatus += "РАЗРЕШЕНА";
    }

    ObjectSetString(0, "RiskManager_Panel_TradeStatus", OBJPROP_TEXT, tradeStatus);
    ObjectSetInteger(0, "RiskManager_Panel_TradeStatus", OBJPROP_COLOR, statusColor);

    //--- Дневные сделки (ВСЕ торговые операции)
    string dailyTradesText = "Дневные сделки: " + IntegerToString(g_GlobalState.dailyTradesCount) +
                             "/" + IntegerToString(MaxDailyTrades);
    ObjectSetString(0, "RiskManager_Panel_DailyTrades", OBJPROP_TEXT, dailyTradesText);

    //--- Одновременные позиции (открытые сейчас)
    int simultaneousPositions = PositionsTotal();
    string simultaneousText = "Одновр. позиции: " + IntegerToString(simultaneousPositions) +
                              "/" + IntegerToString(MaxSimultaneousPositions);
    color simultaneousColor = (simultaneousPositions < MaxSimultaneousPositions) ? clrWhite : clrRed;
    ObjectSetString(0, "RiskManager_Panel_Simultaneous", OBJPROP_TEXT, simultaneousText);
    ObjectSetInteger(0, "RiskManager_Panel_Simultaneous", OBJPROP_COLOR, simultaneousColor);

    //--- Риск
    string riskText = "Текущий риск: " + DoubleToString(g_GlobalState.currentRiskPercent, 1) + "%";
    ObjectSetString(0, "RiskManager_Panel_Risk", OBJPROP_TEXT, riskText);

    //--- Открытые позиции (детализация)
    string positionsText = "Открыто позиций: " + IntegerToString(simultaneousPositions);
    ObjectSetString(0, "RiskManager_Panel_OpenPositions", OBJPROP_TEXT, positionsText);

    //--- Время
    string timeText = "Обновлено: " + TimeToString(TimeCurrent(), TIME_SECONDS);
    ObjectSetString(0, "RiskManager_Panel_Time", OBJPROP_TEXT, timeText);
}

//+------------------------------------------------------------------+
//| Обновление комментария на графике                                |
//+------------------------------------------------------------------+
void UpdateChartComment()
{
    string comment = RiskManagerName + " v" + CORE_VERSION + "\n";
    comment += "================================\n";

    //--- Статус
    if (g_GlobalState.dailyTPReached)
        comment += "СТАТУС: ДНЕВНОЙ TP ДОСТИГНУТ\n";
    else if (g_GlobalState.dailySLReached)
        comment += "СТАТУС: ДНЕВНОЙ SL ДОСТИГНУТ\n";
    else if (g_GlobalState.weeklyTPReached)
        comment += "СТАТУС: НЕДЕЛЬНЫЙ TP ДОСТИГНУТ\n";
    else if (g_GlobalState.weeklySLReached)
        comment += "СТАТУС: НЕДЕЛЬНЫЙ SL ДОСТИГНУТ\n";
    else if (!g_GlobalState.allowNewTrades)
        comment += "СТАТУС: ТОРГОВЛЯ ЗАПРЕЩЕНА\n";
    else
        comment += "СТАТУС: АКТИВЕН\n";

    comment += "================================\n";

    //--- PnL
    comment += "Дневной PnL: $" + DoubleToString(g_GlobalState.dailyPnLTotal, 2) + "\n";
    comment += "Недельный PnL: $" + DoubleToString(g_GlobalState.weeklyPnLTotal, 2) + "\n";
    comment += "Макс. дневной PnL: $" + DoubleToString(g_GlobalState.maxDailyPnL, 2) + "\n";

    comment += "--------------------------------\n";

    //--- Счетчики
    comment += "Дневных сделок: " + IntegerToString(g_GlobalState.dailyPositionsCount) +
               "/" + IntegerToString(MaxDailyTrades) + "\n";
    comment += "Недельных сделок: " + IntegerToString(g_GlobalState.weeklyPositionsCount) +
               "/" + IntegerToString(MaxWeeklyTrades) + "\n";
    comment += "Открыто сейчас: " + IntegerToString(PositionsTotal()) + "\n";

    comment += "--------------------------------\n";

    //--- Риск
    comment += "Текущий риск: " + DoubleToString(g_GlobalState.currentRiskPercent, 1) + "%\n";
    comment += "Серия убытков: " + IntegerToString(g_GlobalState.lossStreak) + "\n";
    comment += "Серия прибылей: " + IntegerToString(g_GlobalState.profitStreak) + "\n";

    comment += "--------------------------------\n";

    //--- Лимиты
    comment += "Дневной TP: $" + DoubleToString(DailyTakeProfit, 0) + "\n";
    comment += "Дневной SL: $" + DoubleToString(DailyStopLoss, 0) + "\n";
    comment += "Недельный TP: $" + DoubleToString(WeeklyTakeProfit, 0) + "\n";
    comment += "Недельный SL: $" + DoubleToString(WeeklyStopLoss, 0);

    Comment(comment);
}

//+------------------------------------------------------------------+
//| Обработчик торговых событий                                      |
//+------------------------------------------------------------------+
void OnTrade()
{
    //--- Обновляем время последней сделки
    g_LastTradeExecutionTime = TimeCurrent();

    //--- При торговом событии обновляем счетчики
    RiskManager_UpdateClosedPnLCounters();

    //--- Проверяем лимиты
    CheckRiskLimits();

    //--- Сохраняем состояние
    Core_SaveGlobalState();
}

//+------------------------------------------------------------------+
//| Обработчик событий (для внешних сигналов)                        |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    //--- Пример обработки текстовых команд из чата графика
    if (id == CHARTEVENT_OBJECT_CREATE && StringFind(sparam, "Command_") >= 0)
    {
        if (EnableExternalSignals)
        {
            Core_ProcessExternalSignal(sparam);
        }
    }

    // В функции OnChartEvent() добавить:
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == "ShowWhiteListBtn")
        {
            PrintWhiteList();
            Alert("Белый список выведен в журнал");
        }
        else if (sparam == "AddCurrentSymbolBtn")
        {
            if (AddToWhiteList(Symbol(), true, 0, 0, "Добавлено вручную"))
            {
                Alert("Символ " + Symbol() + " добавлен в белый список!");
            }
        }
        if (sparam == "TestLockBtn")
        {
            if (MessageBox("Тест: Установить блокировку?",
                           "Тест блокировки", MB_YESNO | MB_ICONQUESTION) == IDYES)
            {
                // Устанавливаем тестовую блокировку
                g_GlobalState.dailySLReached = true;
                g_GlobalState.allowNewTrades = false;
                SetGlobalTradeLock(2, "Тестовая блокировка");
                ForceCloseAllPositionsInstantly();
                Alert("✅ Тестовая блокировка установлена!");
            }
        }
        else if (sparam == "TestUnlockBtn")
        {
            if (MessageBox("Тест: Снять блокировку?",
                           "Тест разблокировки", MB_YESNO | MB_ICONQUESTION) == IDYES)
            {
                RemoveGlobalTradeLock();
                g_GlobalState.dailySLReached = false;
                g_GlobalState.allowNewTrades = true;
                Alert("✅ Блокировка снята!");
            }
        }
    }

    // В функцию OnChartEvent() добавьте обработку:
    else if (sparam == "ClearOldLockBtn")
    {
        if (MessageBox("Снять устаревшую блокировку? (автоматически снимается утром)",
                       "Снятие блокировки", MB_YESNO | MB_ICONQUESTION) == IDYES)
        {
            // Проверяем, устарела ли блокировка
            if (FileIsExist("SIDEZ/TradeLock.bin", FILE_COMMON))
            {
                int handle = FileOpen("SIDEZ/TradeLock.bin", FILE_READ | FILE_BIN | FILE_COMMON);
                if (handle != INVALID_HANDLE)
                {
                    datetime lockTime = (datetime)FileReadLong(handle);
                    FileClose(handle);

                    Print("Блокировка установлена: ", TimeToString(lockTime));

                    RemoveGlobalTradeLock();
                    g_GlobalState.dailyTPReached = false;
                    g_GlobalState.dailySLReached = false;
                    g_GlobalState.weeklyTPReached = false;
                    g_GlobalState.weeklySLReached = false;
                    g_GlobalState.allowNewTrades = true;
                    g_GlobalState.blockManualTrading = false;

                    Alert("✅ Блокировка снята! Торговля разрешена.");
                }
            }
        }
    }

    //--- Обработка кликов по панели
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        //--- Пример: кнопка принудительного закрытия
        if (sparam == "RiskManager_CloseAllBtn")
        {
            if (MessageBox("Закрыть ВСЕ позиции?", "Подтверждение", MB_YESNO | MB_ICONQUESTION) == IDYES)
            {
                g_ForceCloseAll = true;
                Alert("Запущено принудительное закрытие всех позиций!");
            }
        }
    }
    else if (sparam == "DebugLockBtn")
    {
        DebugTradeLockStatus();
        Alert("Диагностика блокировки выполнена, смотрите журнал");
    }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("RiskManager деинициализация. Причина: ", reason);

    //--- СИНХРОНИЗИРУЕМ БЕЛЫЙ СПИСОК ПЕРЕД ВЫХОДОМ
    if (g_GlobalState.useWhiteList)
    {
        SyncWhiteListBetweenModules();
    }

    //--- Отключаем таймер
    EventKillTimer();

    //--- Сохраняем состояние перед выходом
    Core_SaveGlobalState();

    //--- Удаляем графические объекты
    ObjectDelete(0, "RiskManager_Panel_BG");
    ObjectDelete(0, "RiskManager_Panel_Title");
    ObjectDelete(0, "RiskManager_Panel_DailyPnL");
    ObjectDelete(0, "RiskManager_Panel_WeeklyPnL");
    ObjectDelete(0, "RiskManager_Panel_TradeStatus");
    ObjectDelete(0, "RiskManager_Panel_DailyTrades");
    ObjectDelete(0, "RiskManager_Panel_Risk");
    ObjectDelete(0, "RiskManager_Panel_OpenPositions");
    ObjectDelete(0, "RiskManager_Panel_Time");

    //--- Очищаем комментарий
    Comment("");
}

//+------------------------------------------------------------------+
//| Сброс всех лимитов                                               |
//+------------------------------------------------------------------+
void RiskManager_ResetAllLimits()
{
    g_GlobalState.dailyTPReached = false;
    g_GlobalState.dailySLReached = false;
    g_GlobalState.weeklyTPReached = false;
    g_GlobalState.weeklySLReached = false;
    g_GlobalState.allowNewTrades = true;
    g_GlobalState.dailyPositionsCount = 0;
    g_GlobalState.weeklyPositionsCount = 0;
    g_GlobalState.dailyPnLStart = RiskManager_CalculateTotalPnL(true, false);
    g_GlobalState.weeklyPnLStart = RiskManager_CalculateTotalPnL(false, false);
    g_GlobalState.dailyPnLTotal = 0;
    g_GlobalState.weeklyPnLTotal = 0;
    g_GlobalState.totalClosedProfitToday = 0;
    g_GlobalState.totalClosedLossToday = 0;
    g_GlobalState.totalClosedProfitWeek = 0;
    g_GlobalState.totalClosedLossWeek = 0;

    Print("Все лимиты сброшены!");
    Core_SaveGlobalState();
}

//+------------------------------------------------------------------+
//| МОНИТОР НЕАВТОРИЗОВАННЫХ СДЕЛОК (ИНСТРУМЕНТ-ЦЕНТРИЧНАЯ ЛОГИКА) |
//+------------------------------------------------------------------+
void MonitorUnauthorizedTrades()
{
    if (!RM_EnableTradeGateway && false) // Временно отключено
        return;

    int closedCount = 0;

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            string symbol = PositionGetString(POSITION_SYMBOL);
            long magic = PositionGetInteger(POSITION_MAGIC);

            bool shouldClose = false;
            string reason = "";

            // 1. ПРИОРИТЕТ: проверка белого списка (если включен)
            if (g_GlobalState.useWhiteList && !IsInstrumentAllowed(symbol))
            {
                shouldClose = true;
                reason = "Инструмент '" + symbol + "' не в белом списке";
            }
            // 2. Проверка блокировки ручной торговли (если позиция ручная)
            else if (magic == 0 && g_GlobalState.blockManualTrading)
            {
                shouldClose = true;
                reason = "Ручная торговля временно заблокирована (достигнуты лимиты)";
            }
            // 3. Проверка других советников (если включена блокировка)
            else if (g_GlobalState.blockOtherExperts && magic != 0 &&
                     magic != MAGIC_RISK_MANAGER && magic != MAGIC_POSITION_MANAGER)
            {
                shouldClose = true;
                reason = "Торговля другими советниками запрещена";
            }

            if (shouldClose)
            {
                Print("⚠ Обнаружена неавторизованная позиция #", ticket,
                      " символ: ", symbol, " магик: ", magic, " причина: ", reason);

                Print("🚨 Закрытие неавторизованной позиции");
                ClosePositionImmediately(ticket, reason);
                closedCount++;
            }
        }
    }

    if (closedCount > 0)
    {
        Print("✅ Закрыто ", closedCount, " неавторизованных позиций");
    }
}

//+------------------------------------------------------------------+
//| ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ШЛЮЗА                              |
//+------------------------------------------------------------------+

//--- Создание тестовой кнопки для блокировки (для отладки)
void CreateTestButtons()
{
    // Кнопка тестовой блокировки
    ObjectCreate(0, "TestLockBtn", OBJ_BUTTON, 0, 0, 0);
    ObjectSetString(0, "TestLockBtn", OBJPROP_TEXT, "Тест: Заблокировать");
    ObjectSetInteger(0, "TestLockBtn", OBJPROP_XDISTANCE, 320);
    ObjectSetInteger(0, "TestLockBtn", OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(0, "TestLockBtn", OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, "TestLockBtn", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "TestLockBtn", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "TestLockBtn", OBJPROP_BGCOLOR, clrRed);

    // Кнопка тестовой разблокировки
    ObjectCreate(0, "TestUnlockBtn", OBJ_BUTTON, 0, 0, 0);
    ObjectSetString(0, "TestUnlockBtn", OBJPROP_TEXT, "Тест: Разблокировать");
    ObjectSetInteger(0, "TestUnlockBtn", OBJPROP_XDISTANCE, 320);
    ObjectSetInteger(0, "TestUnlockBtn", OBJPROP_YDISTANCE, 55);
    ObjectSetInteger(0, "TestUnlockBtn", OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, "TestUnlockBtn", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "TestUnlockBtn", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "TestUnlockBtn", OBJPROP_BGCOLOR, clrGreen);

    // Кнопка снятия устаревшей блокировки
    ObjectCreate(0, "ClearOldLockBtn", OBJ_BUTTON, 0, 0, 0);
    ObjectSetString(0, "ClearOldLockBtn", OBJPROP_TEXT, "Снять устаревшую блокировку");
    ObjectSetInteger(0, "ClearOldLockBtn", OBJPROP_XDISTANCE, 320);
    ObjectSetInteger(0, "ClearOldLockBtn", OBJPROP_YDISTANCE, 80);
    ObjectSetInteger(0, "ClearOldLockBtn", OBJPROP_XSIZE, 150);
    ObjectSetInteger(0, "ClearOldLockBtn", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "ClearOldLockBtn", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "ClearOldLockBtn", OBJPROP_BGCOLOR, clrOrange);

    // Кнопка диагностики блокировки
    ObjectCreate(0, "DebugLockBtn", OBJ_BUTTON, 0, 0, 0);
    ObjectSetString(0, "DebugLockBtn", OBJPROP_TEXT, "Диагностика блокировки");
    ObjectSetInteger(0, "DebugLockBtn", OBJPROP_XDISTANCE, 320);
    ObjectSetInteger(0, "DebugLockBtn", OBJPROP_YDISTANCE, 130);
    ObjectSetInteger(0, "DebugLockBtn", OBJPROP_XSIZE, 150);
    ObjectSetInteger(0, "DebugLockBtn", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "DebugLockBtn", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "DebugLockBtn", OBJPROP_BGCOLOR, clrPurple);
}

//+------------------------------------------------------------------+
//| КНОПКИ ДЛЯ УПРАВЛЕНИЯ БЕЛЫМ СПИСКОМ                            |
//+------------------------------------------------------------------+
void CreateWhiteListButtons()
{
    // Кнопка показа белого списка
    ObjectCreate(0, "ShowWhiteListBtn", OBJ_BUTTON, 0, 0, 0);
    ObjectSetString(0, "ShowWhiteListBtn", OBJPROP_TEXT, "Показать белый список");
    ObjectSetInteger(0, "ShowWhiteListBtn", OBJPROP_XDISTANCE, 320);
    ObjectSetInteger(0, "ShowWhiteListBtn", OBJPROP_YDISTANCE, 80);
    ObjectSetInteger(0, "ShowWhiteListBtn", OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, "ShowWhiteListBtn", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "ShowWhiteListBtn", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "ShowWhiteListBtn", OBJPROP_BGCOLOR, clrBlue);

    // Кнопка добавления текущего символа
    ObjectCreate(0, "AddCurrentSymbolBtn", OBJ_BUTTON, 0, 0, 0);
    ObjectSetString(0, "AddCurrentSymbolBtn", OBJPROP_TEXT, "Добавить " + Symbol());
    ObjectSetInteger(0, "AddCurrentSymbolBtn", OBJPROP_XDISTANCE, 320);
    ObjectSetInteger(0, "AddCurrentSymbolBtn", OBJPROP_YDISTANCE, 105);
    ObjectSetInteger(0, "AddCurrentSymbolBtn", OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, "AddCurrentSymbolBtn", OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, "AddCurrentSymbolBtn", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "AddCurrentSymbolBtn", OBJPROP_BGCOLOR, clrGreen);
}

//+------------------------------------------------------------------+