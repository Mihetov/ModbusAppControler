// dialogs/ConnectionDialog.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Dialog {
    id: root
    modal: true
    focus: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: "Подключение к backend"

    // Свойства для привязки к AppController
    property alias host: hostField.text
    property alias port: portField.text
    property alias apiPrefix: prefixField.text
    property alias statusLabel: statusLabel
    property bool connecting: false

    // Валидация полей
    readonly property bool isValid:
        host.length > 0 &&
        port > 0 && port <= 65535 &&
        apiPrefix.startsWith("/")

    width: 450
    height: 320

    // Закрытие по Esc только если не идёт подключение
    onRejected: {
        if (!connecting) Qt.quit()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Label {
            text: "Укажите параметры JSON-RPC сервера:"
            font.bold: true
            Layout.bottomMargin: 8
        }

        // Host
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Host:"
                Layout.preferredWidth: 80
            }
            TextField {
                id: hostField
                Layout.fillWidth: true
                placeholderText: "localhost"
                text: "localhost"
                onTextChanged: validate()
            }
        }

        // Port
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Port:"
                Layout.preferredWidth: 80
            }
            TextField {
                id: portField
                Layout.preferredWidth: 100
                placeholderText: "8001"
                text: "8001"
                validator: IntValidator { bottom: 1; top: 65535 }
                onTextChanged: validate()
            }
            Label {
                text: "http://" + hostField.text + ":" + portField.text + prefixField.text
                font.pixelSize: 9
                color: "#666"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        // API Prefix
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Prefix:"
                Layout.preferredWidth: 80
            }
            TextField {
                id: prefixField
                Layout.fillWidth: true
                placeholderText: "/jsonrpc"
                text: "/jsonrpc"
                onTextChanged: validate()
            }
        }

        // Статус
        Label {
            id: statusLabel
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#d32f2f"
            visible: text.length > 0
        }

        Item { Layout.fillHeight: true }

        // Кнопка проверки соединения
        Button {
            text: connecting ? "Проверка..." : "🔍 Проверить соединение"
            Layout.alignment: Qt.AlignRight
            enabled: isValid && !connecting

            onClicked: {
                connecting = true
                statusLabel.text = ""
                statusLabel.color = "#666"

                // 🔧 ИСПРАВЛЕНО: используем RegExp и правильное присваивание (=)
                var ipRegex = new RegExp("^\\d+\\.\\d+\\.\\d+\\.\\d+$")

                if (hostField.text === "localhost" || ipRegex.test(hostField.text)) {
                    statusLabel.text = "✓ Формат верен. Попробуйте подключиться."
                    statusLabel.color = "#2e7d32"  // зелёный
                } else {
                    statusLabel.text = "⚠ Неверный формат host"
                    statusLabel.color = "#d32f2f"
                }
                connecting = false
            }
        }
    }

    function validate() {
        return isValid
    }

    Component.onCompleted: {
        hostField.forceActiveFocus()
    }
}
