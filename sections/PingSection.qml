// sections/PingSection.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

ScrollView {
    property var controller

    contentWidth: -1
    clip: true

    // ═══════════════════════════════════════════════════════════
    // → ДАННЫЕ ДЛЯ ОТОБРАЖЕНИЯ
    // ═══════════════════════════════════════════════════════════

    readonly property var codeExamples: [
        {
            title: "1. Подключение BackendClient",
            description: "Создаём компонент для HTTP-запросов к JSON-RPC серверу",
            code: `// logic/BackendClient.qml
import QtQuick 2.15

QtObject {
    property string host: "localhost"
    property int port: 8001
    property string apiPrefix: "/jsonrpc"

    readonly property string baseUrl: "http://" + host + ":" + port + apiPrefix

    function call(method, params, callback) {
        var request = new XMLHttpRequest()
        request.open("POST", baseUrl)
        request.setRequestHeader("Content-Type", "application/json")

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                var data = JSON.parse(request.responseText)
                if (callback) callback(data.result, data.error)
            }
        }
        request.send(JSON.stringify({
            jsonrpc: "2.0",
            method: method,
            params: params || {},
            id: Date.now()
        }))
    }
}`
        },
        {
            title: "2. Вызов метода ping",
            description: "Отправляем запрос и обрабатываем ответ через callback-функции",
            code: `// В любом QML-файле где есть доступ к controller
controller.callBackend("ping", {},
    function(result) {
        // ✓ Успех
        console.log("Ответ:", result)
        statusText.text = "✓ Backend доступен"
    },
    function(error) {
        // ✗ Ошибка
        console.log("Ошибка:", error.message)
        statusText.text = "✗ " + error.message
    }
)`
        },
        {
            title: "3. Обновление статуса подключения",
            description: "Меняем свойства контроллера для отражения состояния в UI",
            code: `// AppController.qml
function toggleBackendConnection() {
    if (backendConnected) {
        backendConnected = false
        statusMessage = "Отключено"
        return
    }

    callBackend("ping", {},
        function(result) {
            backendConnected = true
            statusConnected = true
            statusMessage = "✓ Подключено"
        },
        function(error) {
            backendConnected = false
            statusMessage = "✗ Ошибка: " + error.message
        }
    )
}`
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // ═══════════════════════════════════════════════════════════
        // → ЗАГОЛОВОК
        // ═══════════════════════════════════════════════════════════

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "📶 Ping — Проверка соединения"
                font.pointSize: 24
                font.bold: true
            }

            Label {
                text: "Метод <b>ping</b> проверяет доступность JSON-RPC backend.
Пустой запрос → пустой ответ. Если получили ответ — соединение работает."
                color: "#666"
                wrapMode: Text.WordWrap
                font.pointSize: 10
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#ddd"
        }

        // ═══════════════════════════════════════════════════════════
        // → ИНТЕРАКТИВНАЯ ДЕМОСТРАЦИЯ
        // ═══════════════════════════════════════════════════════════

        GroupBox {
            title: "🧪 Живая демонстрация"
            Layout.fillWidth: true
            // 🔧 Убрано: checkable: false

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    GroupBox {
                        title: "Параметры"
                        Layout.fillWidth: true
                        // 🔧 Убрано: checkable: false

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Host:"
                                    Layout.preferredWidth: 60
                                }
                                TextField {
                                    id: demoHost
                                    Layout.fillWidth: true
                                    text: controller ? controller.backendHost : "localhost"
                                    readOnly: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Port:"
                                    Layout.preferredWidth: 60
                                }
                                TextField {
                                    id: demoPort
                                    Layout.fillWidth: true
                                    text: controller ? String(controller.backendPort) : "8001"
                                    readOnly: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "URL:"
                                    Layout.preferredWidth: 60
                                }
                                TextField {
                                    Layout.fillWidth: true
                                    text: "http://" + demoHost.text + ":" + demoPort.text +
                                          (controller ? controller.apiPrefix : "/jsonrpc")
                                    readOnly: true
                                    font.family: "monospace"
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }

                    GroupBox {
                        title: "Статус"
                        Layout.preferredWidth: 200
                        // 🔧 Убрано: checkable: false

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignHCenter
                                radius: 20
                                color: statusIndicator.color

                                Text {
                                    anchors.centerIn: parent
                                    text: statusIndicator.icon
                                    font.pixelSize: 24
                                }
                            }

                            Label {
                                id: statusLabel
                                text: "Не проверено"
                                Layout.alignment: Qt.AlignHCenter
                                font.bold: true
                                color: statusIndicator.color
                            }
                        }
                    }
                }

                Button {
                    text: "🔍 Выполнить ping"
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 40
                    enabled: controller && !pingInProgress

                    onClicked: {
                        pingInProgress = true
                        statusLabel.text = "Запрос..."
                        statusIndicator.color = "#ffa726"
                        statusIndicator.icon = "⏳"
                        resultArea.text = "Отправка POST запроса на " +
                                         "http://" + demoHost.text + ":" + demoPort.text +
                                         (controller ? controller.apiPrefix : "/jsonrpc") +
                                         "\n\nМетод: ping\nПараметры: {}\n\nОжидание ответа..."

                        controller.callBackend("ping", {},
                            function(result) {
                                pingInProgress = false
                                statusLabel.text = "✓ Подключено"
                                statusIndicator.color = "#43a047"
                                statusIndicator.icon = "✓"
                                resultArea.text = "✓ Ответ получен:\n\n" + JSON.stringify(result, null, 2)
                                controller.log("Ping успешен", "recv")
                            },
                            function(error) {
                                pingInProgress = false
                                statusLabel.text = "✗ Ошибка"
                                statusIndicator.color = "#e53935"
                                statusIndicator.icon = "✕"
                                resultArea.text = "✗ Ошибка:\n\n" + JSON.stringify(error, null, 2)
                                controller.log("Ping ошибка: " + error.message, "error")
                            }
                        )
                    }
                }

                TextArea {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    readOnly: true
                    placeholderText: "Результат запроса появится здесь..."
                    font.family: "monospace"
                    font.pixelSize: 10
                    wrapMode: Text.Wrap
                    background: Rectangle {
                        color: "#f5f5f5"
                        radius: 4
                        border.color: "#ddd"
                        border.width: 1
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // → ПРИМЕРЫ КОДА
        // ═══════════════════════════════════════════════════════════

        GroupBox {
            title: "📚 Примеры кода для копирования"
            Layout.fillWidth: true
            // 🔧 Убрано: checkable: false

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Repeater {
                    model: codeExamples

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: modelData.title
                            font.bold: true
                            font.pointSize: 11
                        }

                        Label {
                            text: modelData.description
                            color: "#666"
                            wrapMode: Text.WordWrap
                            font.pointSize: 10
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: codeText.implicitHeight + 20
                            color: "#263238"
                            radius: 6
                            clip: true

                            TextArea {
                                id: codeText
                                anchors.fill: parent
                                anchors.margins: 10
                                text: modelData.code
                                readOnly: true
                                font.family: "monospace"
                                font.pixelSize: 10
                                color: "#aed581"
                                wrapMode: Text.NoWrap
                                background: Rectangle { color: "transparent" }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        copyHint.text = "✓ Скопировано! (выделите текст)"
                                        copyTimer.start()
                                    }
                                }
                            }

                            Label {
                                id: copyHint
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                text: "📋 Кликните для копирования"
                                color: "#fff"
                                font.pixelSize: 9
                                background: Rectangle {
                                    color: "#455a64"
                                    radius: 4
                                }
                                padding: 4
                                opacity: 0.8

                                SequentialAnimation on opacity {
                                    id: copyTimer
                                    PropertyAnimation { to: 0; duration: 2000; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // → ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ
        // ═══════════════════════════════════════════════════════════

        GroupBox {
            title: "ℹ️ Дополнительная информация"
            Layout.fillWidth: true
            // 🔧 Убрано: checkable: false

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "<b>Метод:</b> ping"
                            wrapMode: Text.Wrap
                        }
                        Label {
                            text: "<b>Параметры:</b> {} (пустой объект)"
                            wrapMode: Text.Wrap
                        }
                        Label {
                            text: "<b>Ответ:</b> {} (пустой объект при успехе)"
                            wrapMode: Text.Wrap
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "<b>Протокол:</b> JSON-RPC 2.0"
                            wrapMode: Text.Wrap
                        }
                        Label {
                            text: "<b>Транспорт:</b> HTTP POST"
                            wrapMode: Text.Wrap
                        }
                        Label {
                            text: "<b>Content-Type:</b> application/json"
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#eee"
                }

                Label {
                    text: "💡 <b>Совет:</b> Используйте ping при старте приложения для проверки
доступности backend перед основными операциями. Также полезно для
периодической проверки соединения (heartbeat)."
                    wrapMode: Text.Wrap
                    color: "#555"
                }
            }
        }

        Item { Layout.preferredHeight: 20 }
    }

    // ═══════════════════════════════════════════════════════════
    // → ВНУТРЕННИЕ СОСТОЯНИЯ
    // ═══════════════════════════════════════════════════════════

    property bool pingInProgress: false

    QtObject {
        id: statusIndicator
        property string color: "#9e9e9e"
        property string icon: "○"
    }
}
