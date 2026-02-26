import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

ScrollView {
    property var controller

    contentWidth: -1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Label {
            text: "📶 Ping"
            font.pointSize: 24
            font.bold: true
        }

        Label {
            text: "Проверка соединения с backend"
            color: "#666"
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#ddd"
        }

        Button {
            text: "Выполнить ping"
            Layout.preferredWidth: 200
            Layout.preferredHeight: 40

            onClicked: {
                if (controller) {
                    resultText.text = "Отправка запроса..."
                    controller.callBackend("ping", {},
                        function(result) {
                            resultText.text = "✓ Ответ:\n" + JSON.stringify(result, null, 2)
                            controller.log("Ping успешен", "recv")
                        },
                        function(error) {
                            resultText.text = "✗ Ошибка:\n" + error.message
                            controller.log("Ping ошибка: " + error.message, "error")
                        }
                    )
                }
            }
        }

        TextArea {
            id: resultText
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            readOnly: true
            placeholderText: "Нажмите кнопку для проверки связи..."
            font.family: "monospace"
            wrapMode: Text.Wrap
        }
    }
}
