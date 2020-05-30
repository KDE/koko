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
import QtQuick.Controls 2.1 as QQC2
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.10 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.koko.private 1.0 as KokoComponent

Kirigami.Page {
    id: rootEditorView
    title: i18n("Edit")
    leftPadding: 0
    rightPadding: 0
    
    property bool resizing: false;
    
    function crop() {
        console.log(resizeRectangle.x, resizeRectangle.y, resizeRectangle.width, resizeRectangle.height);
        console.log(editImage.paintedWidth, rootEditorView.contentItem.width, editImage.paintedHeight, rootEditorView.contentItem.height);
        rootEditorView.resizing = false
        const ratio = editImage.paintedWidth / editImage.nativeWidth;
        imageDoc.crop((rootEditorView.contentItem.width - editImage.paintedWidth + resizeRectangle.x) / ratio, (rootEditorView.contentItem.height - editImage.paintedHeight + resizeRectangle.y) / ratio, resizeRectangle.width / ratio, resizeRectangle.height / ratio);
    }

    header: QQC2.ToolBar {
        contentItem: Kirigami.ActionToolBar {
            id: actionToolBar
            display: QQC2.Button.TextBesideIcon
            actions: [
                Kirigami.Action {
                    iconName: rootEditorView.resizing ? "dialog-cancel" : "transform-crop"
                    text: rootEditorView.resizing ? i18n("Cancel") : i18nc("@action:button Crop an image", "Crop");
                    onTriggered: {
                        rootEditorView.resizing = !rootEditorView.resizing;
                    }
                },
                Kirigami.Action {
                    iconName: "dialog-ok"
                    visible: rootEditorView.resizing
                    text: i18nc("@action:button Rotate an image to the right", "Crop");
                    onTriggered: crop();
                },
                Kirigami.Action {
                    iconName: "object-rotate-left"
                    text: i18nc("@action:button Rotate an image to the left", "Rotate left");
                    onTriggered: {
                        imageDoc.rotate(-90);
                    }
                },
                Kirigami.Action {
                    iconName: "object-rotate-right"
                    text: i18nc("@action:button Rotate an image to the right", "Rotate right");
                    onTriggered: {
                        imageDoc.rotate(90);
                    }
                }
            ]
        }
    }

    
    property string imagePath
    
    Koko.ImageDocument {
        id: imageDoc
        path: imagePath
    }
    
    contentItem: Flickable {
        width: rootEditorView.width
        height: rootEditorView.height
        KQA.QImageItem {
            id: editImage
            fillMode: KQA.QImageItem.PreserveAspectFit
            width: rootEditorView.width
            height: rootEditorView.height
            image: imageDoc.visualImage
        }
    }

    KokoComponent.ResizeRectangle {
        id: resizeRectangle
        
        visible: rootEditorView.resizing
        
        width: 300
        height: 300
        x: 200
        y: 200
        
        onAcceptSize: crop();

        Rectangle {
            color: "#3daee9"
            opacity: 0.6
            anchors.fill: parent
        }
        
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopLeft
            anchors {
                horizontalCenter: parent.left
                verticalCenter: parent.top
            }
        }
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomLeft
            anchors {
                horizontalCenter: parent.left
                verticalCenter: parent.bottom
            }
        }
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomRight
            anchors {
                horizontalCenter: parent.right
                verticalCenter: parent.bottom
            }
        }
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopRight
            anchors {
                horizontalCenter: parent.right
                verticalCenter: parent.top
            }
        }
    }
}
