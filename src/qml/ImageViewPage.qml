/*
 * SPDX-FileCopyrightText: 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Window 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kcoreaddons 1.0 as KCA
import org.kde.koko.private 0.1 as KokoPrivate

Kirigami.Page {
    id: root

    property var startIndex
    property var imagesModel

    Connections {
        target: imagesModel
        function onFinishedLoading() {
            if (!applicationWindow().fetchImageToOpen || listView.model.sourceModel.indexForUrl(KokoPrivate.OpenFileModel.urlToOpen) === -1) {
                return;
            }
            stopLoadingImages.restart();
            startIndex = listView.model.mapFromSource(listView.model.sourceModel.index(listView.model.sourceModel.indexForUrl(KokoPrivate.OpenFileModel.urlToOpen), 0)).row;
        }
    }

    // sometimes when loading a folder KCoreDirLister "completes" all the jobs before starting another one
    // which means onFinishedLoading sometimes gets called preemptively
    // one easy way to repro this behavior is to open image from one folder and then open one from another
    // so we wait a bit before guarding fetch
    Timer {
        id: stopLoadingImages
        interval: 100
        repeat: false
        onTriggered: {
            applicationWindow().fetchImageToOpen = false;
            // NOTE: for setting index this early on may cause a crash
            // it's definitely has something to do with listview interaction
            // with *potentially* not fully loaded model as setting
            // listView.currentIndex = Math.floor(Math.random() * listView.count)
            // still causes crashes
            // timer mostly remedies it, but it still may *rarely* crash
            listView.currentIndex = startIndex;

            if (listView.currentItem.currentImageMimeType.startsWith("video/")) {
                listView.currentItem.autoplay = true;
            }
        }
    }

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Kirigami.ImageColors {
        id: imgColors
        source: listView.currentItem
    }

    KQA.MimeDatabase {
        id: mimeDB
    }

    Koko.Exiv2Extractor {
        id: exiv2Extractor
        filePath: listView.currentItem ? listView.currentItem.currentImageSource : ""
    }

    Kirigami.ContextDrawer {
        id: contextDrawer
        title: i18n("Edit image")
        handleVisible: true
    }

    actions {
        right: Kirigami.Action {
            id: infoAction
            icon.name: "kdocumentinfo"
            text: i18n("Info")
            tooltip: listView.currentItem ?
                     (listView.currentItem.currentImageMimeType.startsWith("video/") ? i18n("See information about video") :
                                                                                       i18n("See information about image")) :
                                                                                       ""
            checkable: true
            checked: false
            onToggled: if (checked) {
                infoSidebarLoader.forceActiveFocus();
            }
        }
        main: Kirigami.Action {
            iconName: exiv2Extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
            text: exiv2Extractor.favorite ? i18n("Remove") : i18n("Favorite")
            tooltip: exiv2Extractor.favorite ? i18n("Remove from favorites") : i18n("Add to favorites")
            onTriggered: {
                exiv2Extractor.toggleFavorite(listView.currentItem.currentImageSource.replace("file://", ""));
                // makes change immediate
                kokoProcessor.removeFile(listView.currentItem.currentImageSource.replace("file://", ""));
                kokoProcessor.addFile(listView.currentItem.currentImageSource.replace("file://", ""));
            }
        }
        left: Kirigami.Action {
            id: editingAction
            iconName: "edit-entry"
            text: i18nc("verb, edit an image", "Edit")
            visible: listView.currentItem
                     && !listView.currentItem.currentImageMimeType.startsWith("video/")
                     && listView.currentItem.currentImageMimeType !== "image/gif"
                     && listView.currentItem.currentImageMimeType !== "image/svg+xml"
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
                tooltip: listView.currentItem ?
                                (listView.currentItem.currentImageMimeType.startsWith("video/") ? i18n("Share Video") : i18n("Share Image")) :
                                ""
                text: i18nc("verb, share an image/video", "Share")
                onTriggered: {
                    shareDialog.open();
                    shareDialog.inputData = {
                        "urls": [ listView.currentItem.currentImageSource.toString() ],
                        "mimeType": mimeDB.mimeTypeForUrl( listView.currentItem.currentImageSource).name
                    }
                }
            },
            Kirigami.Action {
                iconName: slideshowManager.running ? "media-playback-stop" : "view-presentation"
                tooltip: slideshowManager.running ? i18n("Stop Slideshow") : i18n("Start Slideshow")
                text: slideshowManager.running ? i18n("Stop Slideshow") : i18n("Slideshow")
                visible: listView.count > 1
                onTriggered: {
                    if (slideshowManager.running) {
                        slideshowManager.stop();
                        applicationWindow().visibility = Window.Windowed;
                    } else {
                        slideshowManager.start();
                        applicationWindow().visibility = Window.FullScreen;
                        applicationWindow().controlsVisible = false;
                    }
                }
            },
            Kirigami.Action {
                icon.name: "view-preview"
                // be more descriptive on mobile, since we're less constrained there
                text: !Kirigami.Settings.isMobile ? i18n("Thumbnail Bar") :
                       kokoConfig.imageViewPreview ? i18n("Hide Thumbnail Bar") : i18n("Show Thumbnail Bar")
                tooltip: i18n("Toggle Thumbnail Bar")
                shortcut: "T"
                visible: thumbnailView.count > 1
                onTriggered: {
                    // you can't do imageViewPreview != imageViewPreview for some reason
                    if (kokoConfig.imageViewPreview) {
                        kokoConfig.imageViewPreview = false;
                    } else {
                        kokoConfig.imageViewPreview = true;
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
                        applicationWindow().visibility = Window.Windowed;
                    } else {
                        applicationWindow().visibility = Window.FullScreen;
                    }
                    listView.forceActiveFocus();
                }
            }
        ]
    }

    SlideshowManager {
        id: slideshowManager

        // next slide
        onTriggered: {
            if (kokoConfig.randomizeImages) {
                listView.currentIndex = getNextSlide();
                return;
            }
            if (listView.currentIndex < listView.count - 1) {
                listView.incrementCurrentIndex();
            } else {
                if (kokoConfig.loopImages) {
                    listView.currentIndex = 0;
                } else {
                    slideshowTimer.stop();
                }
            }
        }
        // function that gets the next slide
        // ensures we don't land on the same image
        function getNextSlide() {
            if (listView.count < 2) { // stop if there's only 1 image
                slideshowTimer.stop();
                return 0;
            }
            const roll = Math.floor(Math.random() * Math.floor(listView.count));
            if (roll != listView.currentIndex) {
                return roll;
            } else {
                return getNextSlide();
            }
        }
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
                    applicationWindow().visibility = Window.Windowed;
                    applicationWindow().controlsVisible = true;
                    slideshowManager.stop();
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
            "mimeType": [(listView.currentItem ? listView.currentItem.currentImageMimeType : "")]
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

    ListView {
        id: listView
        readonly property bool isCurrentItemDragging: currentItem !== null && currentItem.dragging
        readonly property bool isCurrentItemInteractive: currentItem !== null && currentItem.interactive
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: thumbnailScrollView.top
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightMoveDuration: 0
        interactive: !isCurrentItemInteractive
        highlightRangeMode: ListView.StrictlyEnforceRange
        pixelAligned: true

        // Filter out directories
        model: Koko.SortModel {
            sourceModel: imagesModel
            filterRole: Koko.Roles.MimeTypeRole
            filterRegExp: /image\/|video\//
        }

        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: imgColors.foreground
        Kirigami.Theme.backgroundColor: imgColors.background
        Kirigami.Theme.highlightColor: imgColors.highlight
        Kirigami.Theme.highlightedTextColor: Kirigami.ColorUtils.brightnessForColor(imgColors.highlight) === Kirigami.ColorUtils.Dark ? imgColors.closestToWhite : imgColors.closestToBlack

        // we start with this index, so we don't flash initial image
        currentIndex: -1

        // don't show initial image if index is not set yet
        visible: currentIndex !== -1

        Component.onCompleted: { // fun fact: without null guard this function will crash the app after a certain number of calls (I think)
            if (root.startIndex) {
                listView.currentIndex = model.mapFromSource(root.startIndex).row;
            }
        }

        property alias slideshow: slideshowManager

        onCountChanged: {
            if (count === 0) {
                infoAction.checked = false
                root.close();
            }
            if (currentIndex >= count) {
                currentIndex = count - 1
            }
        }

        onCurrentItemChanged: {
            if (currentItem) {
                exiv2Extractor.updateFavorite(currentItem.currentImageSource.replace("file://", ""))
                const title = currentItem.display
                if (title.includes("/")) {
                    root.title = title.split("/")[title.split("/").length-1]
                } else {
                    root.title = title
                }
            }
        }

        delegate: ImageDelegate {
            // Don't show other images when resizing the view
            visible: ListView.isCurrentItem
                || ((listView.moving || listView.dragging)
                    && (index === listView.currentIndex - 1
                        || index === listView.currentIndex + 1))
            readonly property string display: model.display
            currentImageSource: model.imageurl
            currentImageMimeType: model.mimeType
            width: listView.width
            height: listView.height

            listView: ListView.view
        }

        QQC2.RoundButton {
            anchors {
                left: parent.left
                leftMargin: Kirigami.Units.largeSpacing
                verticalCenter: parent.verticalCenter
            }
            width: Kirigami.Units.gridUnit * 2
            height: width
            icon.name: "arrow-left"
            Accessible.name: i18n("Previous image")
            onClicked: {
                if (opacity === 0) return; // the best we can do without flicker unfortunately
                listView.decrementCurrentIndex()
            }

            visible: !Kirigami.Settings.isMobile // Using `&& opacity > 0` causes reappearing to be delayed
            opacity: applicationWindow().controlsVisible
                && listView.currentIndex > 0
                && !listView.isCurrentItemDragging
                && !overviewControl.pressed
                ? 1 : 0

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: !applicationWindow().controlsVisible ? Easing.InOutQuad : Easing.InCubic
                }
            }
        }

        QQC2.RoundButton {
            anchors {
                right: parent.right
                rightMargin: Kirigami.Units.largeSpacing
                verticalCenter: parent.verticalCenter
            }
            width: Kirigami.Units.gridUnit * 2
            height: width
            icon.name: "arrow-right"
            Accessible.name: i18n("Next image")
            onClicked: {
                if (opacity === 0) return;
                listView.incrementCurrentIndex()
            }

            visible: !Kirigami.Settings.isMobile // Using `&& opacity > 0` causes flickering
            opacity: applicationWindow().controlsVisible
                && listView.currentIndex < listView.count - 1
                && !listView.isCurrentItemDragging
                && !overviewControl.pressed
                ? 1 : 0

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: !applicationWindow().controlsVisible ? Easing.InOutQuad : Easing.InCubic
                }
            }
        }

        OverviewControl {
            id: overviewControl
            target: listView.currentItem
            visible: !Kirigami.Settings.tabletMode && opacity > 0
            opacity: listView.currentItem !== null
                && listView.isCurrentItemInteractive
                && !listView.isCurrentItemDragging
                && applicationWindow().controlsVisible
                ? 1 : 0
            parent: listView
            // NOTE: The x and y values will often not be integers.
            // Not a problem unless you want to use them to position other elements.
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Kirigami.Units.gridUnit
            z: 1
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: !applicationWindow().controlsVisible ? Easing.InOutQuad : Easing.InCubic
                }
            }
            Binding {
                target: overviewControl.target
                property: "contentX"
                value: overviewControl.target ?
                    -overviewControl.normalizedX * (overviewControl.target.contentWidth - overviewControl.target.width)
                    : 0
                when: overviewControl.pressed
                restoreMode: Binding.RestoreNone
            }
            Binding {
                target: overviewControl.target
                property: "contentY"
                value: overviewControl.target ?
                    -overviewControl.normalizedY * (overviewControl.target.contentHeight - overviewControl.target.height)
                    : 0
                when: overviewControl.pressed
                restoreMode: Binding.RestoreNone
            }
        }

        QQC2.BusyIndicator {
            id: busyIndicator
            property Item target: listView.currentItem
            anchors.centerIn: parent
            parent: listView
            visible: running
            z: 1
            running: target && target.loading
            background: Rectangle {
                radius: height/2
                color: busyIndicator.palette.base
            }
            SequentialAnimation {
                running: busyIndicator.visible
                PropertyAction {
                    target: busyIndicator
                    property: "opacity"
                    value: 0
                }
                // Don't show if the waiting time is pretty short.
                // If we had some way to predict how long it might take,
                // it would be better to use that to decide whether or not
                // to show the BusyIndicator.
                PauseAnimation {
                    duration: 200
                }
                NumberAnimation {
                    target: busyIndicator
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Kirigami.Units.veryLongDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    QQC2.ScrollView {
        id: thumbnailScrollView
        visible: thumbnailView.count > 1
        height: kokoConfig.iconSize + Kirigami.Units.largeSpacing
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff
        property real mobileFABHeight: (applicationWindow().controlsVisible && Kirigami.Settings.isMobile) * Kirigami.Units.gridUnit * 4

        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.smallSpacing

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: applicationWindow().controlsVisible && thumbnailScrollView.visible && kokoConfig.imageViewPreview ?
                            Kirigami.Units.smallSpacing + mobileFABHeight :
                           -height + mobileFABHeight
        }

        opacity: applicationWindow().controlsVisible && kokoConfig.imageViewPreview ? 1 : 0

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        ThumbnailStrip {
            id: thumbnailView

            model: listView.model
            currentIndex: listView.currentIndex
            onActivated: index => listView.currentIndex = index
        }
    }

    // For some reason having MouseArea under ListView on the z axis
    // causes decrementCurrentIndex to change index but not snap to the current item
    // which causes weird desync issues
    // so we place it above instead
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        // don't override cursor shape
        cursorShape: undefined

        onClicked: {
            if (mouse.button == Qt.BackButton) {
                listView.decrementCurrentIndex()
            } else if (mouse.button == Qt.ForwardButton) {
                listView.incrementCurrentIndex()
            }
        }
    }

    Kirigami.Separator {
        id: splitter
        z: 1
        x: root.mirrored ? 0 : root.width
        visible: infoSidebarLoader.active
        height: parent.height
        width: visible ? implicitWidth : 0
        MouseArea {
            cursorShape: Qt.SplitHCursor
            drag {
                axis: Drag.XAxis
                target: splitter
                minimumX: root.mirrored ? 0 : root.width - splitter.width - infoSidebarLoader.implicitWidth
                maximumX: root.mirrored ? infoSidebarLoader.implicitWidth : root.width - splitter.width
                threshold: 0
            }
            anchors.fill: parent
            anchors.margins: -Kirigami.Units.largeSpacing
        }
        states: [
            State { name: "opened"; when: splitter.visible
                PropertyChanges {
                    explicit: true
                    target: splitter
                    x: root.mirrored ? infoSidebarLoader.implicitWidth : root.width - splitter.implicitWidth - infoSidebarLoader.implicitWidth
                }
            },
            State { name: "closed"; when: !splitter.visible
                PropertyChanges {
                    explicit: true
                    target: splitter
                    x: root.mirrored ? 0 : root.width
                }
            }
        ]
        transitions: [
            Transition {
                from: "*"; to: "closed"
                SequentialAnimation {
                    NumberAnimation { property: "x"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                    PropertyAction {
                        target: listView
                        property: "anchors.right"
                        value: listView.parent.right
                    }
                }
            },
            Transition {
                from: "*"; to: "opened"
                SequentialAnimation {
                    PropertyAction {
                        target: listView
                        property: "anchors.right"
                        value: splitter.left
                    }
                    NumberAnimation { property: "x"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }
            }
        ]
    }

    Loader {
        id: infoSidebarLoader
        active: !Kirigami.Settings.isMobile && infoAction.checked
        visible: active
        sourceComponent: InfoSidebar {
            extractor: exiv2Extractor
            anchors.fill: parent
        }
        anchors.left: splitter.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        Connections {
            target: infoSidebarLoader.item
            function onClosed() {
                infoAction.checked = false
            }
        }
    }

    Loader {
        id: infoDrawerLoader
        active: Kirigami.Settings.isMobile && infoAction.checked
        visible: active
        anchors.fill: parent
        sourceComponent: InfoDrawer {
            extractor: exiv2Extractor
        }
        Connections {
            target: infoDrawerLoader.item
            function onClosed() {
                infoAction.checked = false
            }
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

    Shortcut {
        sequence: "Left"
        onActivated: listView.decrementCurrentIndex()
    }

    Shortcut {
        sequence: "Right"
        onActivated: listView.incrementCurrentIndex()
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (slideshowManager.running) {
                slideshowManager.stop()
            }
        }
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        listView.forceActiveFocus();
    }
}