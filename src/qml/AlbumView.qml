/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.7
import QtQuick.Controls 2.1 as Controls

import org.kde.kirigami 2.12 as Kirigami
import org.kde.koko 0.1 as Koko

Kirigami.ScrollablePage {
    id: page
    
    property alias model: gridView.model
    signal collectionSelected(QtObject selectedModel, string cover)
    signal folderSelected(QtObject selectedModel, string cover)
    
    keyboardNavigationEnabled: true
    focus: true

    states: [
        State {
            name: "browsing"
            when: !model.hasSelectedImages
        },
        State {
            name: "selecting"
            when: model.hasSelectedImages && Kirigami.Settings.tabletMode
        }
    ]

    actions {
        main: Kirigami.Action {
            iconName: "edit-select-none"
            text: i18n("Deselect All")
            tooltip: i18n("De-selects all the selected images")
            enabled: model.hasSelectedImages
            visible: model.hasSelectedImages && Kirigami.Settings.tabletMode
            onTriggered: model.clearSelections()
        }
        contextualActions: [
            Kirigami.Action {
                iconName: "edit-select-all"
                text: i18n("Select All")
                tooltip: i18n("Selects all the images in the current view")
                enabled: model.containImages
                onTriggered: model.selectAll()
            },
            Kirigami.Action {
                iconName: "edit-select-none"
                text: i18n("Deselect All")
                tooltip: i18n("De-selects all the selected images")
                enabled: model.hasSelectedImages
                onTriggered: model.clearSelections()
            },
            Kirigami.Action {
                iconName: "emblem-shared-symbolic"
                text: i18n("Share")
                tooltip: i18n("Share the selected images")
                enabled: model.hasSelectedImages
                onTriggered: {
                    shareMenu.open();
                    shareMenu.inputData = {
                        "urls": model.selectedImages(),
                        "mimeType": "image/"
                    }
                }
            },
            Kirigami.Action {
                iconName: "group-delete"
                text: i18n("Delete Selection")
                tooltip: i18n("Move selected items to trash")
                enabled: model.hasSelectedImages
                onTriggered: model.deleteSelection()
            }
            
        ]
    }

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Escape:
                gridView.model.clearSelections()
                break;
            default:
                break;
        }
    }

    ShareDialog {
        id: shareMenu

        inputData: {
            "urls": [],
            "mimeType": ["image/"]
        }
        onFinished: {
            if (error==0 && output.url !== "") {
                console.assert(output.url !== undefined);
                var resultUrl = output.url;
                console.log("Received", resultUrl)
                notificationManager.showNotification( true, resultUrl);
                clipboard.content = resultUrl;
            } else {
                notificationManager.showNotification( false);
            }
        }
    }  

    GridView {
        id: gridView
        //FIXME: right now if those two objects are out of this, the whole page breaks
        Koko.SortModel {
            id: sortedListModel
        }
        Koko.ImageFolderModel {
            id: imageFolderModel
        }

        keyNavigationEnabled: true

        property real widthToApproximate: (applicationWindow().wideScreen ? applicationWindow().pageStack.defaultColumnWidth : page.width) - (1||Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)

        cellWidth: Math.floor(width/Math.floor(width/(kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2)))

        cellHeight: kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2

        topMargin: Kirigami.Units.gridUnit

        highlightMoveDuration: 0
        highlight: Item {
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
                border.color: Kirigami.Theme.highlightColor
                radius: 2
            }
        }
        
        delegate: AlbumDelegate {
            id: delegate
            modelData: model
            onClicked: {
                if (page.state == "selecting" || (mouse.modifiers & Qt.ControlModifier ) && (model.itemType == Koko.Types.Image)) {
                    gridView.model.toggleSelected(model.index)
                } else {
                    activated();
                }
            }
            onPressAndHold: {
                gridView.model.toggleSelected(model.index)
            }
            onActivated: {
                gridView.model.clearSelections()
                gridView.currentIndex = model.index;
                switch( model.itemType) {
                    case Koko.Types.Album: {
                        imageListModel.query = imageListModel.queryForIndex( model.sourceIndex)
                        sortedListModel.sourceModel = imageListModel
                        collectionSelected( sortedListModel, model.display)
                        break;
                    }
                    case Koko.Types.Folder: {
                        imageFolderModel.url = model.imageurl
                        sortedListModel.sourceModel = imageFolderModel
                        folderSelected( sortedListModel, model.display)
                        break;
                    }
                    case Koko.Types.Image: {
                        applicationWindow().pageStack.layers.push(Qt.resolvedUrl("ImageViewer.qml"), {
                            startIndex: page.model.index(gridView.currentIndex, 0),
                            imagesModel: page.model
                        })
                        break;
                    }
                    default: {
                        console.log("Unknown")
                        break;
                    }
                }
            }
            SelectionButton {
                id: selectionButton
                opacity: ( delegate.containsMouse || page.state == "selecting") && !(model.itemType == Koko.Types.Folder || model.itemType == Koko.Types.Album)

                anchors.top: delegate.top
                anchors.left: delegate.left

                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
        
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No Images Found")
            visible: gridView.count == 0
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
        }
    }
    
    onCollectionSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": i18n(cover)})
    onFolderSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": i18n(cover)})
}
