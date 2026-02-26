import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "logic"
import "dialogs"
import "data/UiConfig.js" as UiConfig

ApplicationWindow {
    visible: true
    width: 1200
    height: 800
    title: "Modbus App Controller"

    // Цветовая схема
    readonly property color sidebarBg: "#f5f5f5"
    readonly property color sidebarHover: "#e0e0e0"
    readonly property color sidebarSelected: "#d0d0d0"
    readonly property color accentColor: "#0078d4"

    AppController { id: controller }

    // 🔗 Карта секций
    readonly property var sectionSources: {
        "ping": "sections/PingSection.qml",
        "transport": "sections/TransportSection.qml",
        "modbus_read": "sections/ModbusReadSection.qml",
        "modbus_write": "sections/ModbusWriteSection.qml",
        "scan": "sections/ScanSection.qml",
        "devices": "sections/DevicesSection.qml",
        "log": "sections/LogSection.qml"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════════════════════
        // ← ЛЕВАЯ ПАНЕЛЬ: Навигация
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: sidebarBg

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Заголовок
                Label {
                    text: "Настройки"
                    font.pointSize: 20
                    font.bold: true
                    Layout.bottomMargin: 8
                }

                // Поиск
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "🔍 Поиск..."
                        onTextChanged: sidebar.model = getFilteredSections(text)
                    }

                    Button {
                        id: clearButton
                        visible: searchField.text.length > 0
                        text: "✕"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: searchField.implicitHeight
                        onClicked: searchField.text = ""
                    }
                }

                // Разделитель
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#ccc"
                }

                // Список разделов
                ListView {
                    id: sidebar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: 0
                    clip: true
                    model: UiConfig.SECTIONS

                    delegate: ItemDelegate {
                        width: sidebar.width
                        height: 56
                        // 🔧 Безопасное сравнение: проверяем, что currentIndex и index определены
                        highlighted: sidebar.currentIndex !== undefined &&
                                     index !== undefined &&
                                     sidebar.currentIndex === index

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: {
                                if (parent.highlighted) return sidebarSelected
                                if (parent.hovered) return sidebarHover
                                return "transparent"
                            }
                        }
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Label {
                                text: modelData.icon
                                font.pixelSize: 24
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.title
                                    font.pointSize: 11
                                    font.bold: parent.parent.highlighted
                                    color: parent.parent.highlighted ? accentColor : "#333"
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: modelData.description
                                    font.pointSize: 9
                                    color: "#666"
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        onClicked: {
                            sidebar.currentIndex = index
                            loadSection(modelData.key)
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 8
                    }
                }
            }
        }

        // Разделитель
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#ddd"
        }

        // → Правая панель: контент
        Loader {
            id: contentLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            onLoaded: {
                if (item && item.hasOwnProperty("controller")) {
                    item.controller = controller
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // → ФУНКЦИИ (объявлены ОДИН РАЗ)
    // ═══════════════════════════════════════════════════════════

    function loadSection(key) {
        var source = sectionSources[key]
        if (source) {
            contentLoader.source = source
        } else {
            console.warn("Section not found:", key)
        }
    }

    function getFilteredSections(searchText) {
        if (!searchText || searchText.length === 0)
            return UiConfig.SECTIONS

        var filtered = []
        var searchLower = searchText.toLowerCase()
        for (var i = 0; i < UiConfig.SECTIONS.length; i++) {
            var section = UiConfig.SECTIONS[i]
            if (section.title.toLowerCase().indexOf(searchLower) >= 0 ||
                section.description.toLowerCase().indexOf(searchLower) >= 0) {
                filtered.push(section)
            }
        }
        return filtered
    }

    function connectToBackend() {
        connectionDialog.statusLabel.text = "Подключение..."
        connectionDialog.statusLabel.color = "#666"
        connectionDialog.connecting = true

        controller.updateBackendClient()
        controller.callBackend("ping", {},
            function(result) {
                // ✓ Успех
                connectionDialog.close()
                controller.backendConnected = true
                controller.statusConnected = true
                controller.log("✓ Backend подключен", "recv")

                // Загружаем первую секцию ПОСЛЕ успешного подключения
                if (UiConfig.SECTIONS.length > 0) {
                    loadSection(UiConfig.SECTIONS[0].key)
                }
                controller.refreshSerialPorts()
            },
            function(error) {
                // ✗ Ошибка
                connectionDialog.connecting = false
                connectionDialog.statusLabel.text = "✗ Ошибка: " + error.message
                connectionDialog.statusLabel.color = "#d32f2f"
                controller.log("✗ Backend ошибка: " + error.message, "error")
            }
        )
    }

    // ═══════════════════════════════════════════════════════════
    // → ДИАЛОГ ПОДКЛЮЧЕНИЯ
    // ═══════════════════════════════════════════════════════════

    ConnectionDialog {
        id: connectionDialog
        visible: false
        host: controller.backendHost
        port: String(controller.backendPort)
        apiPrefix: controller.apiPrefix

        onAccepted: {
            controller.backendHost = host
            controller.backendPort = parseInt(port)
            controller.apiPrefix = apiPrefix
            connectToBackend()
        }
        onRejected: Qt.quit()
    }

    // ═══════════════════════════════════════════════════════════
    // → ЕДИНЫЙ Component.onCompleted
    // ═══════════════════════════════════════════════════════════

    Component.onCompleted: {
        // Показываем диалог при старте
        // Секция загрузится позже, в connectToBackend() при успехе
        connectionDialog.open()
    }
}
