/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1 as Controls
import org.kde.purpose 1.0 as Purpose
import org.kde.kirigami 2.1 as Kirigami

Kirigami.OverlaySheet
{
    id: window
    property alias inputData: view.inputData
    property bool running: false
    signal finished(var output, int error, string message)
    
    Controls.BusyIndicator {
        visible: window.running
        anchors.fill: parent
    }
    
    contentItem: ColumnLayout {
        height: Kirigami.Units.gridUnit * 16
        
        Kirigami.Heading {
            text: window.inputData.mimeType ? i18n("Shares for '%1'", window.inputData.mimeType) : ""
        }
        Purpose.AlternativesView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            pluginType: "Export"
            
            delegate: Kirigami.BasicListItem {
                label: model.display
                icon: "arrow-right"
                onClicked: view.createJob (model.index)
                Keys.onReturnPressed: view.createJob (model.index)
                Keys.onEnterPressed: view.createJob (model.index)
            }
            
            onRunningChanged: window.running = running
            onFinished: {
                window.finished(output, error, message)
            }
        }
    }
}
