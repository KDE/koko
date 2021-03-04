/*
 * SPDX-FileCopyrightText: 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.10 as Controls
import QtGraphicalEffects 1.0 as Effects
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.13 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.kquickcontrolsaddons 2.0 as KQA

Kirigami.Page {
    id: root

    title: listView.currentItem.display
    
    property var startIndex
    property var imagesModel
    
    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    Kirigami.ImageColors {
        id: imgColors
        source: listView.currentItem
    }

    KQA.MimeDatabase {
        id: mimeDB
    }
    Kirigami.ContextDrawer {
        id: contextDrawer
        title: i18n("Edit image")
        handleVisible: true
    }


    Kirigami.OverlayDrawer {
        id: infoDrawer
        drawerOpen: false
        property alias imageUrl: extractor.filePath
        edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.LeftEdge : Qt.RightEdge

        Koko.Exiv2Extractor {
            id: extractor
        }

        contentItem: Column {
            Kirigami.Heading {
                level: 2
                text: i18n("Metadata")
            }
            Kirigami.Heading {
                level: 4
                topPadding: Kirigami.Units.smallSpacing
                text: i18n("File Name")
            }
            Controls.Label {
                text: extractor.simplifiedPath
                wrapMode: Text.WordWrap
                width: Kirigami.Units.gridUnit * 15
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Latitude")
                topPadding: Kirigami.Units.smallSpacing
            }
            Controls.Label {
                text: extractor.gpsLatitude
                visible: extractor.gpsLatitude !== 0
            }
            Kirigami.Heading {
                level: 64
                text: i18n("Longitude")
                topPadding: Kirigami.Units.smallSpacing
            }
            Controls.Label {
                text: extractor.gpsLongitude
                visible: extractor.gpsLongitude !== 0
            }
        }
    }

    actions {
        left: Kirigami.Action {
            icon.name: "kdocumentinfo"
            text: i18n("Info")
            tooltip: i18n("See information about image")
            onTriggered: {
                if (infoDrawer.drawerOpen) {
                    infoDrawer.close();
                } else {
                    infoDrawer.imageUrl = listView.currentItem.currentImageSource;
                    infoDrawer.open();
                }
            }
        }
        right: Kirigami.Action {
            id: shareAction
            iconName: "document-share"
            tooltip: i18n("Share Image")
            text: i18nc("verb, share an image", "Share")
            onTriggered: {
                shareDialog.open();
                shareDialog.inputData = {
                    "urls": [ listView.currentItem.currentImageSource.toString() ],
                    "mimeType": mimeDB.mimeTypeForUrl( listView.currentItem.currentImageSource).name
                }
            }
        }
        main: Kirigami.Action {
            id: editingAction
            iconName: "edit-entry"
            text: i18nc("verb, edit an image", "Edit")
            onTriggered: {
                const page = applicationWindow().pageStack.layers.push(editorComponent)
                page.imageEdited.connect(function() {
                    const oldPath = listView.currentItem.currentImageSource;
                    listView.currentItem.currentImageSource = "";
                    listView.currentItem.currentImageSource = oldPath;
                    thumbnailView.currentItem.refresh();
                });
            }
        }
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        listView.forceActiveFocus();
        applicationWindow().header.visible = false;
        applicationWindow().footer.visible = false;
        applicationWindow().globalDrawer.visible = false;
        applicationWindow().globalDrawer.enabled = false;
    }
    function close() {
        applicationWindow().controlsVisible = true;
        if (applicationWindow().footer) {
            applicationWindow().footer.visible = true;
        }
        applicationWindow().globalDrawer.enabled = true;
        applicationWindow().visibility = Window.Windowed;
        applicationWindow().pageStack.layers.pop();
    }

    background: Rectangle {
        color: "black"
    }

    Keys.onPressed: {
        switch(event.key) {
            case Qt.Key_Escape:
                root.close();
                break;
            case Qt.Key_F:
                applicationWindow().visibility = applicationWindow().visibility == Window.FullScreen ? Window.Windowed : Window.FullScreen
                break;
            default:
                break;
        }
    }

    ShareDialog {
        id: shareDialog

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

    ThumbnailStrip {
        id: thumbnailView
        z: 100

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        model: listView.model
        currentIndex: listView.currentIndex
        onActivated: index => listView.currentIndex = index
    }

    ListView {
        id: listView
        anchors.fill: parent
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightMoveDuration: 0
        interactive: true
        highlightRangeMode: ListView.StrictlyEnforceRange

        // Filter out directories
        model: Koko.SortModel {
            sourceModel: imagesModel
            filterRole: Koko.Roles.MimeTypeRole
            filterRegExp: /image\//
        }

        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: imgColors.foreground
        Kirigami.Theme.backgroundColor: imgColors.background
        Kirigami.Theme.highlightColor: imgColors.highlight
        Kirigami.Theme.highlightedTextColor: Kirigami.ColorUtils.brightnessForColor(imgColors.highlight) === Kirigami.ColorUtils.Dark ? imgColors.closestToWhite : imgColors.closestToBlack

        Component.onCompleted: listView.currentIndex = model.mapFromSource(root.startIndex).row

        delegate: ImageDelegate {
            readonly property string display: model.display
            currentImageSource: model.imageurl
            width: root.width
            height: root.height
        }
    }

    Controls.RoundButton {
        anchors {
          left: parent.left
          leftMargin: Kirigami.Units.largeSpacing
          verticalCenter: parent.verticalCenter
        }
        width: Kirigami.Units.gridUnit * 2
        height: width
        icon.name: "arrow-left"
        visible: !Kirigami.Settings.isMobile && applicationWindow().controlsVisible && listView.currentIndex > 0
        Keys.forwardTo: [listView]
        onClicked: {
            listView.currentIndex -= 1
        }
    }

    Controls.RoundButton {
        anchors {
          right: parent.right
          rightMargin: Kirigami.Units.largeSpacing
          verticalCenter: parent.verticalCenter
        }
        width: Kirigami.Units.gridUnit * 2
        height: width
        icon.name: "arrow-right"
        visible: !Kirigami.Settings.isMobile && applicationWindow().controlsVisible && listView.currentIndex < listView.count - 1
        Keys.forwardTo: [listView]
        onClicked: {
            listView.currentIndex += 1
        }
    }
    
    Component {
        id: editorComponent
        EditorView {
            width: root.width
            height: root.height
            imagePath: listView.currentItem.currentImageSource
        }
    }
}
