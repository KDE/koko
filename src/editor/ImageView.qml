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
            Keys.forwardTo: resizeTool.active ? resizeTool : cropTool
            Keys.priority: Keys.AfterItem
        }

        Loader {
            id: cropTool
            anchors.fill: annotationEditor
            transformOrigin: annotationEditor.transformOrigin
            scale: annotationEditor.scale
            active: root.document.tool.type === KQuickImageEditor.AnnotationTool.CropTool
            visible: active
            sourceComponent: KQuickImageEditor.RectangleSelectionTool {
                viewport: annotationEditor
                onAccepted: (geometry) => {
                    document.cropCanvas(geometry)
                    tool.geometry = undefined
                }
            }
        }

        Loader {
            id: resizeTool
            anchors.fill: annotationEditor
            transformOrigin: annotationEditor.transformOrigin
            scale: annotationEditor.scale
            active: root.document.tool.type === KQuickImageEditor.AnnotationTool.ResizeTool
            visible: active
            sourceComponent: KQuickImageEditor.RectangleSelectionTool {
                id: rectangleSelectionTool
                viewport: annotationEditor
                background: Item {
                    parent: rectangleSelectionTool
                    anchors.fill: parent
                    z: -1
                    visible: rectangleSelectionTool.tool.geometry.width !== 0
                        && rectangleSelectionTool.tool.geometry.height !== 0
                    Rectangle {
                        anchors.fill: parent
                        // anchors.margins: -1 // just in case the image below peeks out slightly
                        color: palette.window
                    }
                }
                ShaderEffectSource {
                    readonly property alias tool: rectangleSelectionTool.tool
                    visible: tool.geometry.width !== 0 && tool.geometry.height !== 0
                    x: tool.geometry.x
                    y: tool.geometry.y
                    width: tool.geometry.width
                    height: tool.geometry.height
                    sourceItem: rectangleSelectionTool.viewport
                    sourceRect: Qt.rect(0, 0, sourceItem.width, sourceItem.height)
                    smooth: true
                }
                onAccepted: (geometry) => {
                    let matrix = Qt.matrix4x4()
                    const sx = tool.geometry.width / document.imageSize.width
                    const sy = tool.geometry.height / document.imageSize.height
                    const zDegrees = Math.atan2(matrix.m21, matrix.m11) // in radians
                                   * (180 / Math.PI) // to degrees
                    const rotationAxes = Qt.vector3d(0, 0, 1)
                    matrix.rotate(-zDegrees, rotationAxes)
                    matrix.scale(sx, sy, 1)
                    matrix.rotate(zDegrees, rotationAxes)
                    document.applyTransform(matrix)
                    tool.geometry = undefined
                }
            }
        }

        component HelpHeadingLoader : AnimatedLoader {
            id: loader
            property Item target: null
            property string text: ""
            parent: flickable
            anchors.centerIn: parent
            state: target && !target.activeFocus && target.opacity === 0 ? "active" : "inactive"
            sourceComponent: Kirigami.Heading {
                id: helpHeading
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: loader.text
                padding: helpMetrics.height - helpMetrics.descent
                leftPadding: helpMetrics.height
                rightPadding: helpMetrics.height
                background: Kirigami.ShadowedRectangle {
                    color: Qt.rgba(palette.window.r, palette.window.g, palette.window.b, 0.9)
                    radius: helpMetrics.height
                    shadow.color: Qt.rgba(0,0,0,0.2)
                    shadow.size: 9
                    shadow.yOffset: 2
                }
                FontMetrics {
                    id: helpMetrics
                    font: helpHeading.font
                }
            }
        }

        HelpHeadingLoader {
            target: cropTool.item
            text: i18nc("@info crop tool explanation", "Click and drag to make a selection.\nDouble click the selection to accept and crop.\nRight click to clear the selection.")
        }

        HelpHeadingLoader {
            target: resizeTool.item
            text: i18nc("@info resize tool explanation", "Click and drag to start resizing.\nDouble click the image to accept and complete the resize.\nRight click to clear the resize.\nUse the controls at the bottom of the window for more precise control.")
        }
    }
}
