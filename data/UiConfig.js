.pragma library

// === Устройство и UART ===
var DEVICE_TYPES = ["AIN-DC4", "AIN-DC2", "SIN-DISP", "Пользовательский"]
var BAUD_LIST = [9600, 19200, 38400, 57600, 115200]

// === Вкладки регистров (для внутренней навигации) ===
var REGISTER_TABS = [
    { key: "system", title: "Системный интерфейс" },
    { key: "mode", title: "Режим работы" },
    { key: "scaling", title: "Масштабирование" },
    { key: "measurement", title: "Измерение" }
]

// === Навигация левой панели (Ubuntu Settings style) ===
var SECTIONS = [
    // --- Подключение ---
    {
        key: "ping",
        title: "Ping",
        icon: "📶",
        category: "connection",
        description: "Проверка связи с backend"
    },
    {
        key: "transport",
        title: "Транспорт (UART)",
        icon: "🔌",
        category: "connection",
        description: "Настройка COM-порта"
    },
    // --- Устройства ---
    {
        key: "scan",
        title: "Сканирование",
        icon: "🔍",
        category: "devices",
        description: "Поиск устройств в сети"
    },
    {
        key: "devices",
        title: "Список устройств",
        icon: "📦",
        category: "devices",
        description: "Управление найденными устройствами"
    },
    // --- Modbus ---
    {
        key: "modbus_read",
        title: "Чтение регистров",
        icon: "📥",
        category: "modbus",
        description: "Чтение данных с устройства"
    },
    {
        key: "modbus_write",
        title: "Запись регистров",
        icon: "📤",
        category: "modbus",
        description: "Запись данных в устройство"
    },
    // --- Система ---
    {
        key: "log",
        title: "Лог событий",
        icon: "📋",
        category: "system",
        description: "Журнал операций"
    }
]
