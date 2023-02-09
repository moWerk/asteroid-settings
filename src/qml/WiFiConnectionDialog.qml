/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2022 - Ed Beroset <github.com/beroset>
 *               2017-2022 - Chupligin Sergey <neochapay@gmail.com>
 *               2021 - Darrel Griët <idanlcontact@gmail.com>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* A large proportion of this code has been referenced from Nemomobile-UX Glacier-Settings, published at https://github.com/nemomobile-ux/glacier-settings/blob/master/src/plugins/wifi/WifiSettings.qml
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Connman
import QtQuick.VirtualKeyboard

Item {
    id: dialogItem
    property string servicePath
    property NetworkService modelData: NetworkService {path: dialogItem.servicePath}
    UserAgent {
        id: userAgent
        onUserInputRequested: (requestServicePath, fields) => {
            dialogItem.servicePath = requestServicePath
            dialogItem.sourceFields = fields
        }
        onErrorReported: {
            console.log("Got error from model: " + error)
        }
    }
    property var sourceFields: ({})
    property var loginFields: ({})

    onSourceFieldsChanged: () => { //keep any fields that already exist, add new ones, discard old ones
        var fieldsBackup = loginFields
        loginFields = {}
        for (const [field, args] of Object.entries(sourceFields)) {
            if(fieldsBackup[field]) {
                loginFields[field] = fieldsBackup[field]
                delete fieldsBackup[field]
            } else {
                loginFields[field] = loginField.createObject(loginFieldsColumn,{"fieldName": field, "fieldArgs": args})
            }
        }
        for (const [field, fieldInstance] of Object.entries(fieldsBackup)) {
            fieldInstance.destroy()
        }
    }

    property real rowHeight: Dims.h(25)
    property real rowMargin: Dims.w(15)

    InputPanel {
        id: inputPanel
        z: 99
        visible: active
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: -Dims.h(25)
        height: Dims.h(100)

        width: Dims.w(100)
        externalLanguageSwitchEnabled: false
    }

    Connections {
        target: modelData
        function onConnectRequestFailed(error) {
            console.log(error)
            layerStack.push(errorPopup, {networkService: modelData, text: qsTrId("id-wifi-connectionError")})
        }

        function onConnectedChanged(connected) {
            if(connected) {
                sourceFields = {}
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight
        Column {
            id: contentColumn
            width: parent.width
            Item {height: Dims.h(15); width: parent.width}
            Marquee {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: dialogItem.rowMargin
                    rightMargin: dialogItem.rowMargin
                }
                text: modelData.name
                font.pixelSize: Dims.l(6)
                height: Dims.l(8)
            }

            Column {
                id: loginFieldsColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: dialogItem.rowMargin
                    rightMargin: dialogItem.rowMargin
                }
            }
            Column {
                visible: modelData.connected
                width: parent.width
                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: dialogItem.rowMargin
                        rightMargin: dialogItem.rowMargin
                    }
                    text: "IP: " + modelData.ipv4["Address"]
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Dims.l(6)
                }
                LabeledActionButton {
                    width: parent.width
                    height: dialogItem.rowHeight
                    //% "Disconnect"
                    text: qsTrId("id-wifi-disconnect")
                    icon: "ios-close-circle-outline"
                    onClicked: {
                        modelData.requestDisconnect()
                        layerStack.pop(layerStack.currentLayer)
                    }
                }
            }
            LabeledSwitch {
                id: autoConnectCheckBox
                width: parent.width
                height: dialogItem.rowHeight
                //% "Autoconnect"
                text: qsTrId("id-wifi-autoconnect")
                checked: modelData.autoConnect
                onClicked: modelData.autoConnect = checked
            }
            LabeledActionButton {
                visible: modelData.connected || modelData.favorite
                width: parent.width
                height: dialogItem.rowHeight
                //% "Forget network"
                text: qsTrId("id-wifi-removenetwork")
                icon: "ios-trash-circle"
                onClicked: {
                    modelData.remove()
                    layerStack.pop(layerStack.currentLayer)
                }
            }

            IconButton {
                visible: loginFieldsColumn.children.length // easiest way to check if we've got some active agent fields
                iconName: "ios-checkmark-circle-outline"
                height: width
                width: Dims.w(20)
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: () => {
                    if(!modelData.connected) {
                        var reply = {}
                        for (const [field, args] of Object.entries(sourceFields)) {
                            if(loginFields[field].text != "" && args["Requirement"] != "informational")
                                reply[field] = loginFields[field].text
                        }
                        userAgent.sendUserReply(reply)
                    }
                }
            }
        }
    }
    Component {
        id: loginField

        Column {
            width: parent.width
            property string fieldName
            property var fieldArgs
            property alias text: fieldInput.text
            visible: fieldArgs["Requirement"] != "informational"
            Component.onCompleted: if(fieldArgs["Requirement"] == "mandatory" && sourceFields["PreviousPassphrase"]) fieldInput.text = sourceFields["PreviousPassphrase"]["Value"]
            Label {
                id: fieldLabel
                text: switch (fieldName) {
                    //% "Name (SSID):"
                    case "Name": qsTrId("id-wifi-ssid"); break;
                    //% "Name (Identity):"
                    case "Identity": qsTrId("id-wifi-identity"); break;
                    //% "Passphrase:"
                    case "Passphrase": qsTrId("id-wifi-passphrase"); break;
                    //% "WPS:"
                    case "WPS": qsTrId("id-wifi-wps"); break;
                    //% "Username:"
                    case "Username": qsTrId("id-wifi-username"); break;
                    //% "Password:"
                    case "Password": qsTrId("id-wifi-password"); break;
                }
                font.pixelSize: Dims.l(6)
            }
            TextField {
                id: fieldInput
                text: modelData
                width: parent.width
            }
        }
    }

    Component {
        id: errorPopup
        StatusPage {
            icon: "ios-remove-circle"
            anchors.fill: undefined
            property NetworkService networkService
            Component.onDestruction: networkService.requestConnect()
        }
    }
}
