/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.0 as Controls
import org.kde.purpose 1.0 as Purpose
import org.kde.kirigami 2.1 as Kirigami

Kirigami.OverlaySheet {
    id: window
   // focus: true
    property alias inputData: view.inputData
    property bool running: false
    signal finished(var output, int error, string message)
    leftPadding: 0
    rightPadding: 0
    
    onSheetOpenChanged: {
        if(!sheetOpen) {
            view.reset()
        }
    }

    Controls.BusyIndicator {
        visible: window.running
        anchors.fill: parent
    }

    header: Kirigami.Heading {
        text: i18n("Share")
        leftPadding: Kirigami.Units.largeSpacing
    }
    Purpose.AlternativesView {
        id: view
        clip: true
        pluginType: "Export"
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Math.max(Kirigami.Units.gridUnit * 10, initialItem.contentHeight)
        
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
