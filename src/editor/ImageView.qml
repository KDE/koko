/*
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtCore
import QtQuick
import QtQml
import QtQuick.Templates as T
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor as KQuickImageEditor

Controls.Page {
    id: root

    property alias document: annotationEditor.document

    readonly property real fitZoom: Math.min(flickable.width / annotationEditor.document.canvasRect.width,
                                             flickable.height / annotationEditor.document.canvasRect.height)
    readonly property real minZoom: Math.min(fitZoom, 1)
    readonly property real maxZoom: Math.max(minZoom, 8)
    readonly property real currentZoom: annotationEditor.scale
    property bool showCropTool: false

    function dprRound(v: double): double {
        return Math.round(v * Screen.devicePixelRatio) / Screen.devicePixelRatio
    }

    function zoomToPercent(percent, center = flickable.mapToItem(flickable.contentItem,
                                                                 flickable.width / 2,
                                                                 flickable.height / 2)) {
        const oldW = annotationEditor.document.canvasRect.width * annotationEditor.scale
        const oldH = annotationEditor.document.canvasRect.height * annotationEditor.scale
        annotationEditor.scale = Math.max(root.minZoom, Math.min(percent, root.maxZoom))
        const w = annotationEditor.document.canvasRect.width * annotationEditor.scale
        const h = annotationEditor.document.canvasRect.height * annotationEditor.scale

        if (center.x !== 0) {
            const min = flickable.width - Math.max(w, flickable.contentItem.width)
            const target = dprRound(flickable.contentItem.x + center.x + (-center.x * w / oldW))
            flickable.contentX = -Math.max(min, Math.min(target, 0)) // max
        }
        if (center.y !== 0) {
            const min = flickable.height - Math.max(h, flickable.contentItem.height)
            const target = dprRound(flickable.contentItem.y + center.y + (-center.y * w / oldW))
            flickable.contentY = -Math.max(min, Math.min(target, 0)) // max
        }
        flickable.returnToBounds()
    }

    function zoomIn(centerPos = flickable.mapToItem(flickable.contentItem,
                                                    flickable.width / 2,
                                                    flickable.height / 2)) {
        let stepSize = 1
        if (currentZoom < 1) {
            stepSize = 0.25
        } else if (currentZoom < 2) {
            stepSize = 0.5
        }
        zoomToPercent(currentZoom - (currentZoom % stepSize) + stepSize, centerPos)
    }

    function zoomOut(centerPos = flickable.mapToItem(flickable.contentItem,
                                                     flickable.width / 2,
                                                     flickable.height / 2)) {
        let inverseRemainder = 1 - (currentZoom % 1)
        let stepSize = 1
        if (currentZoom <= 1) {
            stepSize = 0.25
        } else if (currentZoom <= 2) {
            stepSize = 0.5
        }
        zoomToPercent(currentZoom + (inverseRemainder % stepSize) - stepSize, centerPos)
    }

    leftPadding: mirrored && verticalScrollBar.visible ? verticalScrollBar.width : 0
    rightPadding: !mirrored && verticalScrollBar.visible ? verticalScrollBar.width : 0
    bottomPadding: horizontalScrollBar.visible ? horizontalScrollBar.height : 0

    contentItem: Flickable {
        id: flickable

        clip: true
        interactive: annotationEditor.document.tool.type === KQuickImageEditor.AnnotationTool.NoTool
        boundsBehavior: Flickable.StopAtBounds
        rebound: Transition {} // Instant transition. Null doesn't do this.
        contentWidth: Math.max(width, annotationEditor.document.canvasRect.width * annotationEditor.scale)
        contentHeight: Math.max(height, annotationEditor.document.canvasRect.height * annotationEditor.scale)

        Kirigami.WheelHandler {
            property point angleDelta: Qt.point(0,0)
            target: flickable
            keyNavigationEnabled: true
            scrollFlickableTarget: true
            horizontalStepSize: dprRound(Application.styleHints.wheelScrollLines * 20)
            verticalStepSize: dprRound(Application.styleHints.wheelScrollLines * 20)
            onWheel: wheel => {
                    if (wheel.modifiers & Qt.ControlModifier && scrollFlickableTarget) {
                    // apparently it's impossible to add points to each other directly in QML
                    angleDelta.x += wheel.angleDelta.x
                    angleDelta.y += wheel.angleDelta.y
                    if (angleDelta.x >= 120 || angleDelta.y >= 120) {
                        angleDelta = Qt.point(0,0)
                        const centerPos = flickable.mapToItem(flickable.contentItem, wheel.x, wheel.y)
                        root.zoomIn(centerPos)
                    } else if (angleDelta.x <= -120 || angleDelta.y <= -120) {
                        angleDelta = Qt.point(0,0)
                        const centerPos = flickable.mapToItem(flickable.contentItem, wheel.x, wheel.y)
                        root.zoomOut(centerPos)
                    }
                    wheel.accepted = true
                }
            }
        }

        PinchHandler {
            id: pinchHandler
            acceptedButtons: Qt.LeftButton
            target: null
            // No 2 finger drag because it's difficult to make without the
            // viewport moving in janky ways. The viewport still moves in janky
            // ways near edges, but it's not as bad as with 2 finger drag.
            onScaleChanged: (delta) => {
                root.zoomToPercent(root.currentZoom * delta)
            }
        }

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: verticalScrollBar
            parent: root
            z: 1
            anchors.right: parent.right
            y: root.topPadding
            height: root.availableHeight
            active: horizontalScrollBar.active
        }
        Controls.ScrollBar.horizontal: Controls.ScrollBar {
            id: horizontalScrollBar
            parent: root
            z: 1
            x: root.leftPadding
            anchors.bottom: parent.bottom
            width: root.availableWidth
            active: verticalScrollBar.active
        }

        MouseArea {
            z: -1
            anchors.fill: annotationEditor
            transformOrigin: annotationEditor.transformOrigin
            scale: annotationEditor.scale
            enabled: flickable.interactive
                    && (flickable.contentItem.width > flickable.width
                        || flickable.contentItem.height > flickable.height)
            cursorShape: enabled ?
                (containsPress || flickable.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                : undefined
        }

        AnnotationEditor {
            id: annotationEditor
            x: dprRound((flickable.contentItem.width - annotationEditor.document.canvasRect.width * scale) / 2)
            y: dprRound((flickable.contentItem.height - annotationEditor.document.canvasRect.height * scale) / 2)
            implicitWidth: annotationEditor.document.canvasRect.width
            implicitHeight: annotationEditor.document.canvasRect.height
            transformOrigin: Item.TopLeft
            scale: 1
            visible: true
            enabled: true
            Keys.forwardTo: cropTool
            Keys.priority: Keys.AfterItem
        }

        KQuickImageEditor.CropTool {
            id: cropTool
            anchors.fill: annotationEditor
            transformOrigin: annotationEditor.transformOrigin
            scale: annotationEditor.scale
            viewport: annotationEditor
            active: root.showCropTool
        }

        AnimatedLoader {
            parent: flickable
            anchors.centerIn: parent
            state: cropTool.item && !cropTool.item.activeFocus && cropTool.item.opacity === 0 ? "active" : "inactive"
            sourceComponent: Kirigami.Heading {
                id: cropToolHelp
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18nc("@info crop tool explanation", "Click and drag to make a selection.\nDouble click the selection to accept and crop.\nRight click to clear the selection.")
                padding: cropToolHelpMetrics.height - cropToolHelpMetrics.descent
                leftPadding: cropToolHelpMetrics.height
                rightPadding: cropToolHelpMetrics.height
                background: Kirigami.ShadowedRectangle {
                    color: Qt.rgba(palette.window.r, palette.window.g, palette.window.b, 0.9)
                    radius: cropToolHelpMetrics.height
                    shadow.color: Qt.rgba(0,0,0,0.2)
                    shadow.size: 9
                    shadow.yOffset: 2
                }
                FontMetrics {
                    id: cropToolHelpMetrics
                    font: cropToolHelp.font
                }
            }
        }
    }
}
