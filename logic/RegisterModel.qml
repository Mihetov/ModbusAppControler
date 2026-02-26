// logic/RegisterModel.qml
import QtQuick 2.12

QtObject {
    // Конвертация сырых Modbus-значений в целевой формат
    function convertValue(values, fmt, count) {
        if (!values || values.length === 0) return null

        // Строки Char[N]
        if (fmt.indexOf("Char[") === 0) {
            const charCount = parseInt(fmt.match(/\d+/)[0])
            let str = ""
            for (let v of values) {
                str += String.fromCharCode((v >> 8) & 0xFF)  // high byte
                str += String.fromCharCode(v & 0xFF)          // low byte
            }
            return str.substring(0, charCount).replace(/\0/g, '').trim()
        }

        // Float32 (Modbus big-endian: high word first)
        if (fmt.toLowerCase() === "float32") {
            if (values.length < 2) return null
            const buf = new ArrayBuffer(4)
            const view = new Uint16Array(buf)
            view[0] = values[1]  // low word
            view[1] = values[0]  // high word
            return new Float32Array(buf)[0]
        }

        // Uint32
        if (fmt.toLowerCase() === "uint32") {
            if (values.length < 2) return values[0] || 0
            return ((values[0] << 16) | values[1]) >>> 0
        }

        // Int32
        if (fmt.toLowerCase() === "int32") {
            if (values.length < 2) return values[0] || 0
            return (values[0] << 16) | values[1]
        }

        // Byte / Word / default
        return values[0]
    }

    // Форматирование для отображения
    function formatValue(val, fmt) {
        if (val === undefined || val === null) return "—"
        if (fmt && fmt.indexOf("Char") >= 0) return `"${val}"`
        if (fmt && fmt.toLowerCase().indexOf("float") >= 0)
            return Number(val).toFixed(3)
        if (fmt === "Word" || fmt === "Byte")
            return val + " (0x" + Number(val).toString(16).toUpperCase() + ")"
        return String(val)
    }
}
