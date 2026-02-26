import QtQuick 2.12
import "../data/RegisterDefs.js" as RegisterDefs
import "../data/UiConfig.js" as UiConfig

Item {
    id: root

    property bool backendConnected: false
    property bool uartOpen: false
    property bool scanning: false

    property int selectedDeviceIndex: -1
    property int currentTabIndex: 0
    property int uartPortIndex: -1

    property var registersCache: ({})
    property var editedValues: ({})
    property int registerDataVersion: 0

    property string backendHost: "localhost"
    property int backendPort: 8001
    property string apiPrefix: "/jsonrpc"
    property int scanFrom: 1
    property int scanTo: 10
    property int uartBaud: 38400
    property int uartDataBits: 8
    property int uartStopBits: 1
    property string uartParity: "none"
    property int uartTimeoutMs: 1000
    property string selectedDeviceType: "AIN-DC4"

    property bool portSettingsExpanded: true
    property bool foundDevicesExpanded: true
    property bool systemExpanded: true
    property bool modeExpanded: true
    property bool scalingExpanded: true
    property bool measurementExpanded: true

    property string statusMessage: "Отключено"
    property string lastUpdateText: "—"
    property bool statusConnected: false

    readonly property var baudList: UiConfig.BAUD_LIST
    readonly property var deviceTypes: UiConfig.DEVICE_TYPES
    readonly property var registerTabs: UiConfig.REGISTER_TABS

    readonly property var selectedDevice: selectedDeviceIndex >= 0 ? devicesModel.get(selectedDeviceIndex) : null
    readonly property string currentTabKey: registerTabs[currentTabIndex].key

    BackendClient { id: backendClient }   // <-- QML ищет этот файл в той же папке, что и AppController
    RegisterModel { id: registerModel }

    ListModel { id: serialPortsModel }
    ListModel { id: devicesModel }
    ListModel { id: logModel }

    property alias serialPortsModel: serialPortsModel
    property alias devicesModel: devicesModel
    property alias logModel: logModel

    function log(message, type) {
        logModel.append({ ts: Qt.formatTime(new Date(), "hh:mm:ss"), message: message, type: type || "info" })
        statusMessage = message
        lastUpdateText = Qt.formatTime(new Date(), "hh:mm:ss")
    }

    function isWritable(reg) {
        return reg && reg.rwe && reg.rwe.indexOf("W") >= 0
    }

    function getDisplayValue(tabKey, reg) {
        var cachedTab = registersCache[tabKey]
        if (!cachedTab || cachedTab[reg.name] === undefined)
            return "—"
        return registerModel.formatValue(cachedTab[reg.name], reg.fmt)
    }

    function getEditableValue(tabKey, reg) {
        var key = tabKey + "::" + reg.name
        if (editedValues[key] !== undefined)
            return editedValues[key]
        var cachedTab = registersCache[tabKey]
        if (cachedTab && cachedTab[reg.name] !== undefined)
            return cachedTab[reg.name]
        return ""
    }

    function setEditedValue(tabKey, regName, value) {
        editedValues[tabKey + "::" + regName] = value
        registerDataVersion++
    }

    function clearEdits() {
        editedValues = ({})
        registerDataVersion++
    }

    function infoValue(regName) {
        var info = registersCache["info"]
        if (!info || info[regName] === undefined || info[regName] === null)
            return "—"
        return String(info[regName])
    }

    function callBackend(method, params, onSuccess, onError) {
        backendClient.call(method, params || {}, function(result, error) {
            if (error) {
                if (onError) onError(error)
                return
            }
            if (onSuccess) onSuccess(result)
        })
    }

    function updateBackendClient() {
        backendClient.host = backendHost
        backendClient.port = backendPort
        backendClient.apiPrefix = apiPrefix
    }

    function refreshSerialPorts() {
        callBackend("transport.serial_ports", {}, function(result) {
            serialPortsModel.clear()
            var ports = (result && result.ports) ? result.ports : []
            for (var i = 0; i < ports.length; i++)
                serialPortsModel.append({ name: ports[i] })
            if (serialPortsModel.count > 0)
                uartPortIndex = 0
            log("📡 Найдено портов: " + serialPortsModel.count, "recv")
        }, function(error) {
            log("⚠ Не удалось получить порты: " + error.message, "error")
        })
    }

    function toggleBackendConnection() {
        if (backendConnected) {
            if (uartOpen)
                closeUart()
            backendConnected = false
            statusConnected = false
            log("🔌 Backend отключен", "info")
            return
        }

        updateBackendClient()
        log("🔌 Подключение к " + backendHost + ":" + backendPort + apiPrefix, "sent")
        callBackend("ping", {}, function() {
            backendConnected = true
            statusConnected = true
            log("✓ Backend подключен", "recv")
            refreshSerialPorts()
        }, function(error) {
            backendConnected = false
            statusConnected = false
            log("✗ Ошибка backend: " + error.message, "error")
        })
    }

    function openUart() {
        if (uartPortIndex < 0 || uartPortIndex >= serialPortsModel.count) {
            log("⚠ Выберите COM порт", "error")
            return
        }
        var port = serialPortsModel.get(uartPortIndex).name
        callBackend("transport.open", {
            type: "rtu",
            serial_port: port,
            baud_rate: uartBaud,
            data_bits: uartDataBits,
            stop_bits: uartStopBits,
            parity: uartParity,
            timeout_ms: uartTimeoutMs
        }, function() {
            uartOpen = true
            log("✓ UART открыт: " + port + " @ " + uartBaud, "recv")
        }, function(error) {
            uartOpen = false
            log("✗ UART ошибка: " + error.message, "error")
        })
    }

    function closeUart() {
        callBackend("transport.close", {}, function() {
            uartOpen = false
            log("✓ UART закрыт", "recv")
            devicesModel.clear()
            selectedDeviceIndex = -1
        }, function(error) {
            log("⚠ Не удалось закрыть UART: " + error.message, "error")
        })
    }

    function scanDevices() {
        if (!uartOpen || scanning)
            return

        scanning = true
        devicesModel.clear()
        selectedDeviceIndex = -1
        log("🔍 Сканирование адресов " + scanFrom + "-" + scanTo, "sent")

        var addr = scanFrom
        function next() {
            if (addr > scanTo) {
                scanning = false
                log("📦 Найдено устройств: " + devicesModel.count, "info")
                return
            }

            callBackend("modbus.read", {
                slave_id: addr,
                address: "0xF001",
                count: 1,
                timeout_ms: 300
            }, function(result) {
                var values = (result && result.values) ? result.values : (result ? result.data : null)
                if (values && values[0] !== undefined) {
                    devicesModel.append({
                        name: selectedDeviceType + " #" + addr,
                        addr: addr,
                        online: true,
                        type: selectedDeviceType
                    })
                }
                addr++
                next()
            }, function() {
                addr++
                next()
            })
        }
        next()
    }

    function selectDevice(index) {
        selectedDeviceIndex = index
        clearEdits()
        readCurrentTab("info")
        readCurrentTab("system")
        readCurrentTab("mode")
        readCurrentTab("scaling")
        readCurrentTab("measurement")
    }

    function readCurrentTab(tabKeyOverride) {
        if (!selectedDevice)
            return

        var key = tabKeyOverride || currentTabKey
        var regs = RegisterDefs.REGISTERS[key] || []
        var tabData = registersCache[key] || ({})
        log("📥 Чтение вкладки " + key, "sent")

        var i = 0
        function readNext() {
            if (i >= regs.length) {
                var nextCache = {}
                var cacheKeys = Object.keys(registersCache)
                for (var ck = 0; ck < cacheKeys.length; ck++)
                    nextCache[cacheKeys[ck]] = registersCache[cacheKeys[ck]]
                nextCache[key] = tabData
                registersCache = nextCache
                registerDataVersion++
                log("✓ Вкладка обновлена", "recv")
                return
            }

            var reg = regs[i++]
            callBackend("modbus.read", {
                slave_id: selectedDevice.addr,
                address: reg.hex,
                count: reg.count || 1,
                timeout_ms: uartTimeoutMs
            }, function(result) {
                var values = (result && result.values) ? result.values : (result ? result.data : null)
                tabData[reg.name] = registerModel.convertValue(values, reg.fmt, reg.count)
                readNext()
            }, function() {
                readNext()
            })
        }
        readNext()
    }

    function readAll() {
        readCurrentTab("info")
        readCurrentTab("system")
        readCurrentTab("mode")
        readCurrentTab("scaling")
        readCurrentTab("measurement")
    }

    function applyChanges() {
        if (!selectedDevice)
            return

        var keys = Object.keys(editedValues)
        if (keys.length === 0) {
            log("ℹ Нет изменений для отправки", "info")
            return
        }

        var payloads = []
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i]
            var parts = key.split("::")
            if (parts.length !== 2)
                continue
            var tabKey = parts[0]
            var regName = parts[1]
            var regs = RegisterDefs.REGISTERS[tabKey] || []
            for (var r = 0; r < regs.length; r++) {
                if (regs[r].name === regName && isWritable(regs[r])) {
                    payloads.push({ reg: regs[r], value: editedValues[key] })
                    break
                }
            }
        }

        if (payloads.length === 0) {
            log("ℹ Нет записываемых изменений", "info")
            return
        }

        var idx = 0
        function writeNext() {
            if (idx >= payloads.length) {
                log("✓ Изменения применены", "recv")
                clearEdits()
                readAll()
                return
            }

            var item = payloads[idx++]
            callBackend("modbus.write", {
                slave_id: selectedDevice.addr,
                address: item.reg.hex,
                values: [Number(item.value)]
            }, function() {
                writeNext()
            }, function(error) {
                log("✗ Ошибка записи " + item.reg.name + ": " + error.message, "error")
                writeNext()
            })
        }
        writeNext()
    }
}
