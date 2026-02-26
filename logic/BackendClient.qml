// logic/BackendClient.qml
import QtQuick 2.15      // ← Должно совпадать с main.qml
  // ← Та же версия!

QtObject {
    property string host: "localhost"
    property int port: 8001
    property string apiPrefix: "/jsonrpc"

    readonly property string baseUrl: "http://" + host + ":" + port + apiPrefix
    property bool connected: false

    signal connectionChanged(bool connected)
    signal responseReceived(string method, var result, var error)

    function call(method, params, callback) {
        var id = Date.now() + Math.random().toString(36).slice(2, 7)
        var payload = {
            jsonrpc: "2.0",
            method: method,
            params: params || {},
            id: id
        }

        var request = new XMLHttpRequest()
        request.open("POST", baseUrl)
        request.setRequestHeader("Content-Type", "application/json")
        request.timeout = 5000

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    try {
                        var data = JSON.parse(request.responseText)
                        if (data.error) {
                            connected = false
                            connectionChanged(false)
                            if (callback) callback(null, data.error)
                            responseReceived(method, null, data.error)
                        } else {
                            connected = true
                            connectionChanged(true)
                            if (callback) callback(data.result, null)
                            responseReceived(method, data.result, null)
                        }
                    } catch(e) {
                        if (callback) callback(null, {message: "Parse error: " + e.message})
                    }
                } else {
                    connected = false
                    connectionChanged(false)
                    if (callback) callback(null, {message: "HTTP " + request.status})
                }
            }
        }
        request.send(JSON.stringify(payload))
        return id
    }

    function ping(callback) { return call("ping", {}, callback) }
    function getSerialPorts(callback) { return call("transport.serial_ports", {}, callback) }

    function openUart(port, baud, dataBits, stopBits, parity, timeout, callback) {
        return call("transport.open", {
            type: "rtu",
            serial_port: port,
            baud_rate: baud,
            data_bits: dataBits,
            stop_bits: stopBits,
            parity: parity,
            timeout_ms: timeout
        }, callback)
    }

    function closeUart(callback) { return call("transport.close", {}, callback) }
    function getTransportStatus(callback) { return call("transport.status", {}, callback) }
}
