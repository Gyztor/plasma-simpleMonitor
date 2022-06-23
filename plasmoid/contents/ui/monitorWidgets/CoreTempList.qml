/**
 * Copyright 2013-2016 Dhaby Xiloj, Konstantin Shtepa
 *
 * This file is part of plasma-simpleMonitor.
 *
 * plasma-simpleMonitor is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or any later version.
 *
 * plasma-simpleMonitor is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with plasma-simpleMonitor.  If not, see <http://www.gnu.org/licenses/>.
 **/

import QtQuick 2.9
import org.kde.plasma.core 2.0 as PlasmaCore

ListView {
    id: coreTempList

    property int direction: Qt.LeftToRight
    LayoutMirroring.enabled: direction === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitHeight: childrenRect.height
    implicitWidth: 100 * PlasmaCore.Units.devicePixelRatio

    interactive: false

    property int highTemp: 80
    property int criticalTemp : 95
    property int maxTemp : 100
    /* tempUnit
        used for change how to show temperature unit
        0=Celsius 1=Fahrenheit */
    property int tempUnit: 0

    delegate: Item {
        id: coreListTemp
        implicitHeight: 25 * PlasmaCore.Units.devicePixelRatio
        implicitWidth: coreLabel.implicitWidth + unitLabel.implicitWidth
        width: parent.width
        height: (20 + indicatorHeight) * PlasmaCore.Units.devicePixelRatio
        Text {
            id: coreLabel
            anchors.left: parent.left
            text: if (coreLabelStr == "") i18n('CPU %1:', model.index); else i18n(coreLabelStr)
            font.bold: true
            font { family: doppioOneRegular.name; pointSize: 10 }
            color: "#ffdd55"
        }
        Text {
            id: unitLabel
            text: if (tempUnit === 0) Math.round(val) + dataUnits
                  else Math.round(val*9/5+32) + "°F"
            font.bold: true
            font.pointSize: 10
            color: "white"
            anchors.right: parent.right
        }

        Rectangle {
            id: rectValue
            height: indicatorHeight * PlasmaCore.Units.devicePixelRatio
            width: Math.round(val/coreTempList.maxTemp*parent.width)
            color: if (Math.round(val) >= coreTempList.criticalTemp) "red"
                   else if (Math.round(val) >= coreTempList.highTemp) "#ffac2a"
                   else "#85a9ff"
            anchors.top: coreLabel.bottom
            anchors.right: parent.right
            anchors.topMargin: PlasmaCore.Units.devicePixelRatio
        }
        ListView.onAdd: SequentialAnimation {
            PropertyAction { target: coreListTemp; property: "height"; value: 0 }
            NumberAnimation { target: coreListTemp; property: "height"; to: (20 + indicatorHeight) * PlasmaCore.Units.devicePixelRatio; duration: 250; easing.type: Easing.InOutQuad }
        }
    }

    FontLoader {
        id: doppioOneRegular
        source: "../../fonts/Doppio_One/DoppioOne-Regular.ttf"
    }
}
