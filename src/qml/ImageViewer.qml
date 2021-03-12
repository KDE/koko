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
import org.kde.kcoreaddons 1.0 as KCA

Kirigami.Page {
    id: root

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
        handleVisible: false

        Koko.Exiv2Extractor {
            id: extractor
        }

        Koko.ImageTagsModel {
            id: tagList
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
                text: i18n("Dimension")
                topPadding: Kirigami.Units.smallSpacing
                visible: extractor.width > 0 && extractor.height > 0
            }
            Controls.Label {
                text: i18nc("dimensions", "%1 x %2", extractor.width, extractor.height)
                visible: extractor.width > 0 && extractor.height > 0
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Size")
                topPadding: Kirigami.Units.smallSpacing
                visible: extractor.size !== 0
            }
            Controls.Label {
                text: KCA.Format.formatByteSize(extractor.size, 2)
                visible: extractor.size !== 0
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Created")
                topPadding: Kirigami.Units.smallSpacing
                visible: extractor.time.length > 0
            }
            Controls.Label {
                text: extractor.time
                visible: extractor.time.length > 0
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Model")
                topPadding: Kirigami.Units.smallSpacing
                visible: extractor.model.length > 0
            }
            Controls.Label {
                text: extractor.model
                visible: extractor.model.length > 0
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Latitude")
                topPadding: Kirigami.Units.smallSpacing
                visible: extractor.gpsLatitude !== 0
            }
            Controls.Label {
                text: extractor.gpsLatitude
                visible: extractor.gpsLatitude !== 0
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Longitude")
                topPadding: Kirigami.Units.smallSpacing
                visible: extractor.gpsLongitude !== 0
            }
            Controls.Label {
                text: extractor.gpsLongitude
                visible: extractor.gpsLongitude !== 0
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Tags")
            }
            Flow {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing * 2
                topPadding: Kirigami.Units.smallSpacing
                Repeater {
                    model: extractor.tags
                    Tag {
                        text: modelData
                        icon.name: "edit-delete-remove"
                        actionText: i18n("Remove %1 tag", modelData)
                        reverse: true
                        onClicked: {
                            const index = extractor.tags.indexOf(modelData);
                            if (index > -1) {
                                extractor.tags.splice(index, 1);
                            }
                        }
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing * 2
                topPadding: Kirigami.Units.smallSpacing
                bottomPadding: Kirigami.Units.smallSpacing
                Repeater {
                    model: tagList.tags
                    Tag {
                        text: modelData
                        icon.name: "list-add"
                        actionText: i18n("Add %1 tag", modelData)
                        visible: !extractor.tags.includes(modelData)
                        onClicked: {
                            extractor.tags.push(modelData)
                        }
                    }
                }
                Controls.ToolButton {
                    // there's no size smaller than small unfortunately
                    icon.width: Kirigami.Settings.isMobile ? Kirigami.Units.iconSizes.small : 16
                    icon.height: Kirigami.Settings.isMobile ? Kirigami.Units.iconSizes.small : 16
                    display: Controls.AbstractButton.IconOnly
                    icon.name: "list-add"
                    text: i18n("Add new tag")
                    onClicked: newTagField.visible = true
                }
            }
            RowLayout {
                width: parent.width
                Controls.TextField {
                    id: newTagField
                    visible: false
                    placeholderText: i18n("New tag...")
                    Layout.fillWidth: true
                }
                Controls.ToolButton {
                    display: Controls.AbstractButton.IconOnly
                    icon.name: "checkbox"
                    text: i18n("Finished")
                    visible: newTagField.visible
                    onClicked: {
                        if (newTagField.text.trim().length > 0) {
                            extractor.tags.push(newTagField.text.trim())
                            newTagField.text = ""
                            newTagField.visible = false
                        }
                    }
                }
                Controls.ToolButton {
                    // there's no size smaller than small unfortunately
                    display: Controls.AbstractButton.IconOnly
                    icon.name: "dialog-cancel"
                    text: i18n("Cancel")
                    visible: newTagField.visible
                    onClicked: {
                        newTagField.text = ""
                        newTagField.visible = false
                    }
                }
            }
        }
    }

    actions {
        right: Kirigami.Action {
            icon.name: "kdocumentinfo"
            text: i18n("Info")
            tooltip: i18n("See information about image")
            onTriggered: {
                if (infoDrawer.drawerOpen) {
                    infoDrawer.close();
                } else {
                    infoDrawer.imageUrl = listView.currentItem.currentImageSource;
                    newTagField.text = ""
                    newTagField.visible = false
                    infoDrawer.open();
                }
            }
        }
        main: Kirigami.Action {
            iconName: extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
            text: extractor.favorite ? i18n("Remove") : i18n("Favorite")
            tooltip: extractor.favorite ? i18n("Remove from favorites") : i18n("Add to favorites")
            onTriggered: {
                extractor.toggleFavorite(listView.currentItem.currentImageSource.replace("file://", ""))
                // makes change immediate
                kokoProcessor.removeFile(listView.currentItem.currentImageSource.replace("file://", ""))
                kokoProcessor.addFile(listView.currentItem.currentImageSource.replace("file://", ""))
            }
        }
        left: Kirigami.Action {
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
        contextualActions: [
            Kirigami.Action {
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
            },
            Kirigami.Action {
                iconName: slideshowTimer.running ? "media-playback-stop" : "view-presentation"
                tooltip: slideshowTimer.running ? i18n("Stop Slideshow") : i18n("Start Slideshow")
                text: slideshowTimer.running ? i18n("Stop Slideshow") : i18n("Slideshow")
                visible: listView.count > 1
                onTriggered: {
                    if (slideshowTimer.running) {
                        slideshowTimer.stop()
                        applicationWindow().visibility = Window.Windowed
                    } else {
                        slideshowTimer.start()
                        applicationWindow().visibility = Window.FullScreen
                        applicationWindow().controlsVisible = false
                    }
                }
            },
            Kirigami.Action {
                property bool windowed: applicationWindow().visibility == Window.Windowed
                icon.name: windowed ? "view-fullscreen" : "view-restore"
                text: windowed ? i18n("Fullscreen") : i18n("Exit Fullscreen")
                tooltip: windowed ? i18n("Enter Fullscreen") : i18n("Exit Fullscreen")
                shortcut: "F"
                visible: !Kirigami.Settings.isMobile
                onTriggered: {
                    if (applicationWindow().visibility == Window.FullScreen) {
                        applicationWindow().visibility = Window.Windowed
                    } else {
                        applicationWindow().visibility = Window.FullScreen
                    }
                }
            }
        ]
    }

    // ensure we don't land on the same image
    function nextSlide() {
        if (listView.count < 2) { // stop if there's only 1 image
            slideshowTimer.stop()
            return 0;
        }
        var roll = Math.floor(Math.random() * Math.floor(listView.count))
        if (roll != listView.currentIndex) {
            return roll
        } else {
            return nextSlide()
        }
    }

    Timer {
        id: slideshowTimer
        interval: kokoConfig.nextImageInterval * 1000
        repeat: true
        onTriggered: {
            if (kokoConfig.randomizeImages) {
                listView.currentItem.resetZoom()
                listView.currentIndex = root.nextSlide()
                return
            }
            if (listView.currentIndex < listView.count - 1) {
                listView.currentItem.resetZoom()
                listView.currentIndex++
            } else {
                listView.currentItem.resetZoom()
                if (kokoConfig.loopImages) {
                    listView.currentIndex = 0
                } else {
                    slideshowTimer.stop()
                }
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
                if (applicationWindow().visibility == Window.FullScreen) {
                    applicationWindow().visibility = Window.Windowed
                    applicationWindow().controlsVisible = true
                    slideshowTimer.stop()
                } else {
                    root.close();
                }
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
                notificationManager.showNotification(true, resultUrl);
                clipboard.content = resultUrl;
            } else {
                notificationManager.showNotification(false);
            }
        }
    }

    Controls.ScrollView {
        z: 100
        height: kokoConfig.iconSize
        Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
        Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AlwaysOff

        clip: false

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        ThumbnailStrip {
            id: thumbnailView

            model: listView.model
            currentIndex: listView.currentIndex
            onActivated: index => listView.currentIndex = index
        }
    }

    MouseArea {
        z: 1
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onClicked: {
            if (mouse.button == Qt.BackButton) {
                if (listView.currentIndex > 0) {
                    listView.currentItem.resetZoom()
                    listView.currentIndex--
                }
                mouse.accepted = true
            } else if (mouse.button == Qt.ForwardButton) {
                if (listView.currentIndex < listView.count - 1) {
                    listView.currentItem.resetZoom()
                    listView.currentIndex++
                }
                mouse.accepted = true
            }
        }
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

        onCountChanged: {
            if (count === 0) {
                root.close();
            }
            if (currentIndex >= count) {
                currentIndex = count - 1
            }
        }

        onCurrentItemChanged: {
            if (currentItem) {
                extractor.updateFavorite(currentItem.currentImageSource.replace("file://", ""))
                const title = currentItem.display
                if (title.includes("/")) {
                    root.title = title.split("/")[title.split("/").length-1]
                } else {
                    root.title = title
                }
            }
        }

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
            listView.currentItem.resetZoom()
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
            listView.currentItem.resetZoom()
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
