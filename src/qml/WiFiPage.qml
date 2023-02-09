/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
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
    id: root

    NetworkTechnology {
        id: wifiStatus
        path: "/net/connman/technology/wifi"
        onPoweredChanged: {
            if (wifiStatus.powered)
                wifiModel.requestScan()
        }
    }

    ListView {
        id: wifiList
        model: TechnologyModel {
            id: wifiModel
            name: "wifi"
        }
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        header: Item {
            //this is meant to look like an org.asteroid.controls StatusPage when collapsed
            width: root.width
            height: wifiStatus.powered ? width*0.6 : root.height
            Behavior on height { NumberAnimation { duration: 100 } }
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                id: statusIconBackground
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -parent.width*0.13
                color: "black"
                radius: width/2
                opacity: wifiStatus.powered ? 0.4 : 0.2
                width: parent.width*0.25
                height: width
                Icon {
                    id: statusIcon
                    anchors.fill: statusIconBackground
                    anchors.margins: parent.width*0.12
                    name: wifiStatus.powered ? "ios-wifi" : "ios-wifi-outline"
                }
                MouseArea {
                    id: statusMA
                    enabled: true
                    anchors.fill: parent
                    onClicked: wifiStatus.powered = !wifiStatus.powered
                }
            }

            Label {
                id: statusLabel
                font.pixelSize: parent.width*0.05
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: parent.width*0.04; anchors.rightMargin: anchors.leftMargin
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parent.width*0.15
                text: "<h3>" + (wifiStatus.powered ?
                    //% "WiFi on"
                    qsTrId("id-wifi-on") :
                    //% "WiFi off"
                    qsTrId("id-wifi-off")) + "</h3>\n" + (wifiStatus.powered ? (wifiStatus.connected ?
                    //% "Connected"
                    qsTrId("id-wifi-connected") :
                    //% "Not connected"
                    qsTrId("id-wifi-disconnected")) : "")
            }
        }

        footer: Item {height: wifiStatus.powered ? root.height*0.15 : 0; width: parent.width}

        delegate: Item {
            id: networkListItem
            visible: wifiStatus.powered
            height: wifiStatus.powered ? Dims.h(21) : 0
            width: parent.width
            HighlightBar {
                id: highlight
                onClicked: {
                    if (!modelData.connected) {
                        layerStack.push(connectionDialog, {modelData: modelData})
                        modelData.requestConnect()
                    } else {
                        layerStack.push(connectionDialog, {modelData: modelData})
                    }
                }
                onPressAndHold: layerStack.push(connectionDialog, {modelData: modelData})
            }
            Marquee {
                id: wifiNameLabel
                //% "Hidden network"
                text: modelData.name ? modelData.name : qsTrId("id-wifi-hiddennetwork")
                height: parent.height*0.6
                clip: false
                anchors.horizontalCenter: parent.horizontalCenter
                width: DeviceSpecs.hasRoundScreen ? parent.width - Dims.w(36) : parent.width - Dims.w(24)
            }
            Label {
                anchors {
                    top: wifiNameLabel.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                opacity: 0.8
                font.pixelSize: parent.width*0.07
                font.weight: Font.Thin
                text: {
                    if (modelData.connected) {
                        //% "Connected"
                        qsTrId("id-wifi-connected")
                    } else if (modelData.favorite){
                        //% "Saved"
                        qsTrId("id-wifi-saved")
                    } else {
                        //% "Available"
                        qsTrId("id-wifi-available")
                    }
                }
            }
        }
    }

    Component {
        id: connectionDialog
        WiFiConnectionDialog {}
    }
}

