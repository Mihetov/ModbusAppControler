import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

ScrollView {
    property string title
    property string description
    property alias controller: null

    contentWidth: -1
    clip: true

    ColumnLayout {
        width: parent.width
        spacing: 8
        anchors.margins: 16

        Label {
            text: title
            font.pointSize: 18
            font.bold: true
        }
        Label {
            text: description
            wrapMode: Text.WordWrap
            opacity: 0.8
        }
        Rectangle {
            height: 1; color: "#ddd"; Layout.fillWidth: true
        }
        // Контент секции добавляется наследником
        default property alias content: contentItem.children
        Item { id: contentItem; Layout.fillWidth: true; height: childrenRect.height }
    }
}
