// data/SerialPortDefs.js
.pragma library

// Baud rates
var BAUD_RATES = [
    {value: 9600, label: "9600"},
    {value: 19200, label: "19200"},
    {value: 38400, label: "38400"},
    {value: 57600, label: "57600"},
    {value: 115200, label: "115200"}
]

// Data bits
var DATA_BITS = [
    {value: 8, label: "8"},
    {value: 7, label: "7"}
]

// Stop bits
var STOP_BITS = [
    {value: 1, label: "1"},
    {value: 2, label: "2"}
]

// Parity
var PARITY_OPTIONS = [
    {value: "none", label: "None"},
    {value: "even", label: "Even"},
    {value: "odd", label: "Odd"}
]

// Default settings
var DEFAULTS = {
    host: "192.168.1.100",
    port: 8001,
    apiPrefix: "/api",
    baud: 38400,
    dataBits: 8,
    stopBits: 1,
    parity: "none",
    timeout: 1000
}
