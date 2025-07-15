/*
 * SPDX-FileCopyrightText: 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQml
import QtQuick.Window
import QtQuick.Templates as T
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.coreaddons as KCA
import org.kde.koko.private as KokoPrivate

Kirigami.Page {
    id: root

    property var startIndex
    required property var imagesModel
    required property Koko.PhotosApplication application
    required property Kirigami.ApplicationWindow mainWindow
    property int lastWindowVisibility: mainWindow.visibility

    Connections {
        target: imagesModel
        ignoreUnknownSignals: true
        function onFinishedLoading() {
            if (!root.mainWindow.fetchImageToOpen || listView.model.sourceModel.indexForUrl(KokoPrivate.OpenFileModel.urlToOpen) === -1) {
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
            root.mainWindow.fetchImageToOpen = false;
            // NOTE: for setting index this early on may cause a crash
            // it's definitely has something to do with listview interaction
            // with *potentially* not fully loaded model as setting
            // listView.currentIndex = Math.floor(Math.random() * listView.count)
            // still causes crashes
            // timer mostly remedies it, but it still may *rarely* crash
            listView.currentIndex = startIndex;
        }
    }

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Koko.Exiv2Extractor {
        id: exiv2Extractor
        filePath: listView.currentItem ? listView.currentItem.imageurl : ""
    }

    actions: [
        Kirigami.Action {
            text: i18nc("@action:intoolbar Favorite an image/video", "Favorite")
            icon.name: exiv2Extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
            tooltip: exiv2Extractor.favorite ? i18nc("@info:tooltip", "Remove from favorites") : i18nc("@info:tooltip", "Add to favorites")

            checkable: true
            checked: exiv2Extractor.favorite
            onToggled: {
                exiv2Extractor.toggleFavorite(listView.currentItem.imageurl.toString().replace("file://", ""));
                // makes change immediate
                kokoProcessor.removeFile(listView.currentItem.imageurl.toString().replace("file://", ""));
                kokoProcessor.addFile(listView.currentItem.imageurl.toString().replace("file://", ""));
            }
        },
        Kirigami.Action {
            text: i18nc("@action:intoolbar Edit an image", "&Edit")
            icon.name: "edit-entry"
            tooltip: i18nc("@info:tooltip", "Edit this image")

            visible: listView.currentItem && listView.currentItem.type == Koko.FileInfo.RasterImageType
            onTriggered: {
                const page = root.mainWindow.pageStack.layers.push(Qt.resolvedUrl("EditorView.qml"), {
                    imagePath: listView.currentItem.imageurl,
                    // Without this, there's an odd glitch where the page will show for a brief moment
                    // before the show animation runs.
                    visible: false
                })
                page.imageEdited.connect(function() {
                    thumbnailView.currentItem.refresh();
                });
            }
        },
        ShareAction {
            id: shareAction

            text: i18nc("@action:intoolbar Share an image/video", "&Share")
            tooltip: {
                if (!listView.currentItem) {
                    return "";
                }
                if (listView.currentItem.type === Koko.FileInfo.VideoType) {
                    return i18nc("@info:tooltip", "Share this video");
                }
                return i18nc("@info:tooltip", "Share this image");
            }

            property Connections connection: Connections {
                target: listView
                function onCurrentItemChanged() {
                    shareAction.inputData = {
                        urls: [listView.currentItem.imageurl.toString()],
                        mimeType: [listView.currentItem.mimeType]
                    };
                }
            }
        },
        Kirigami.Action {
            id: infoAction

            displayHint: Kirigami.DisplayHint.KeepVisible

            text: i18nc("@action:intoolbar Show information about an image/video", "&Info")
            icon.name: "info-symbolic"
            tooltip: {
                if (!listView.currentItem) {
                    return "";
                }
                if (listView.currentItem.type === Koko.FileInfo.VideoType) {
                    return i18nc("@info:tooltip", "See information about this video");
                }
                return i18nc("@info:tooltip", "See information about this image");
            }

            shortcut: "I"
            enabled: Kirigami.Settings.isMobile ? true : root.mainWindow.controlsVisible
            checkable: true
            checked: false
            onToggled: if (checked) {
                // TODO: Should probably do this in infoSidebarLoader
                infoSidebarLoader.forceActiveFocus();
            }
        },
        /* Hidden actions */
        Kirigami.Action {
            id: slideshowAction

            displayHint: Kirigami.DisplayHint.AlwaysHide

            // TODO: Checkable would be best, then toggle slideshow with changed i18n hint in text and dynamic tooltip text
            text: i18nc("@action:intoolbar Start a slideshow", "&Slideshow")
            icon.name: "view-presentation-symbolic"
            tooltip: i18nc("@info:tooltip", "Start slideshow")

            visible: listView.count > 1 && !slideshowManager.running && !Kirigami.Settings.isMobile
            onTriggered: slideshowManager.start()
        },
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide
            separator: true
            visible: slideshowAction.visible
        },
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide

            text: i18nc("@action:intoolbar Toggle visibility of toolbars and other UI elements", "Show &Controls")
            tooltip: root.mainWindow.controlsVisible ? i18nc("@info:tooltip", "Enter immersive viewing mode")
                                                     : i18nc("@info:tooltip", "Exit immersive viewing mode")

            visible: !Kirigami.Settings.isMobile
            checkable: true
            checked: root.mainWindow.controlsVisible
            onToggled: root.mainWindow.controlsVisible = !root.mainWindow.controlsVisible
        },
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide

            text: i18nc("@action:intoolbar Toggle visibility of toolbar", "Show &Thumbnail Toolbar")
            tooltip: !Koko.Config.imageViewPreview ? i18nc("@info:tooltip", "Show the thumbnail toolbar")
                                                   : i18nc("@info:tooltip", "Hide the thumbnail toolbar")

            visible: !Kirigami.Settings.isMobile
            enabled: root.mainWindow.controlsVisible
            shortcut: "T"
            checkable: true
            checked: Koko.Config.imageViewPreview
            onToggled: {
                Koko.Config.imageViewPreview = !Koko.Config.imageViewPreview;
                Koko.Config.save();
            }
        },
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide
            separator: true
            visible: fullscreenAction.visible
        },
        Kirigami.Action {
            id: fullscreenAction

            displayHint: Kirigami.DisplayHint.AlwaysHide

            text: i18nc("@action:intoolbar", "&Full Screen")
            icon.name: !checked ? "view-fullscreen-symbolic" : "view-restore-symbolic"
            tooltip: !checked ? i18nc("@info:tooltip", "Enter Full Screen") : i18nc("@info:tooltip", "Exit Full Screen")

            visible: !Kirigami.Settings.isMobile && !slideshowManager.running
            shortcut: "F"
            checkable: true
            checked: root.mainWindow.visibility === Window.FullScreen
            onToggled: {
                if (checked) {
                    // Enter full screen
                    Koko.Controller.saveWindowGeometry(root.mainWindow);
                    lastWindowVisibility = root.mainWindow.visibility
                    root.mainWindow.visibility = Window.FullScreen;
                } else {
                    // Exit full screen
                    root.mainWindow.visibility = lastWindowVisibility
                }

                listView.forceActiveFocus();
            }
        }
    ]

    // TODO: Integrate file actions into menus (hidden actions on mobile toolbar, More > Actions… on desktop)
    /*
    KokoPrivate.FileMenu {
        id: fileMenu
        url: listView.currentItem?.imageurl ?? ''
    }
    */

    SlideshowManager {
        id: slideshowManager

        // next slide
        onTriggered: {
            if (Koko.Config.randomizeImages) {
                listView.currentIndex = getNextSlide();
                return;
            }
            if (listView.currentIndex < listView.count - 1) {
                listView.incrementCurrentIndex();
            } else {
                if (Koko.Config.loopImages) {
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
        Koko.Controller.restoreWindowGeometry(root.mainWindow);
        if (root.mainWindow.footer) {
            root.mainWindow.footer.visible = true;
        }
        root.mainWindow.globalDrawer.enabled = true;
        root.mainWindow.pageStack.layers.pop();
    }

    background: Rectangle {
        color: "black"
    }

    Keys.onPressed: (event) => {
        switch(event.key) {
            case Qt.Key_Escape:
                if (slideshowManager.running) {
                    slideshowManager.stop();
                } else if (root.mainWindow.visibility == Window.FullScreen) {
                    root.mainWindow.visibility = lastWindowVisibility;
                } else {
                    root.close();
                }
                break;
            default:
                break;
        }
    }

    ListView {
        id: listView

        readonly property bool isCurrentItemDragging: currentItem !== null && currentItem.dragging
        readonly property bool isCurrentItemInteractive: currentItem !== null && currentItem.interactive

        anchors {
            top: parent.top
            left: parent.left
            right: infoSideBar.left
            bottom: Kirigami.Settings.isMobile ? mobileActionsToolBar.top : thumbnailToolBar.top
        }

        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightMoveDuration: 0
        interactive: !isCurrentItemInteractive
        highlightRangeMode: ListView.StrictlyEnforceRange
        pixelAligned: true
        reuseItems: true

        // Filter out directories
        model: Koko.SortModel {
            filterRole: Koko.Roles.MimeTypeRole
            filterRegularExpression: /image\/|video\//
            sourceModel: imagesModel
        }

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
                exiv2Extractor.updateFavorite(currentItem.imageurl.toString().replace("file://", ""))
                const title = currentItem.content
                if (title.includes("/")) {
                    root.title = title.split("/")[title.split("/").length-1]
                } else {
                    root.title = title
                }
            }
        }

        delegate: Loader {
            id: loader

            required property int index
            required property url imageurl
            required property string content
            readonly property alias type: info.type
            readonly property alias mimeType: info.mimeType

            readonly property bool dragging: item && item.dragging
            readonly property bool interactive: item && item.interactive

            width: ListView.view.width
            height: ListView.view.height

            visible: {
                if (ListView.isCurrentItem) {
                    return true;
                }

                // Ensure we have previous and next images loaded, to avoid a blank frame when switching
                if (index === listView.currentIndex - 1 || index === listView.currentIndex + 1) {
                    return true;
                }

                return false;
            }

            // Don't load images that are not going to be visible.
            active: visible
            onActiveChanged: {
                if (active && info.delegateSource && info.initialProperties) {
                    setSource(info.delegateSource, info.initialProperties);
                }
            }

            asynchronous: true

            Koko.FileInfo {
                id: info

                source: loader.imageurl

                // Unfortunately, just binding active to visible above and using
                // setSource in the onStatusChanged handler leads to occasional
                // invisible images due to a slight race condition. Therefore,
                // we need to store them separately and update whenever either
                // delegateSource changes or the loader's active property changes.
                property var initialProperties
                property url delegateSource

                onDelegateSourceChanged: {
                    if (loader.active && delegateSource && initialProperties) {
                        loader.setSource(delegateSource, initialProperties);
                    }
                }

                onStatusChanged: {
                    if (status != Koko.FileInfo.Ready) {
                        return;
                    }

                    let delegate = "";
                    let properties = {
                        source: Qt.binding(() => loader.imageurl),
                        isCurrent: Qt.binding(() => loader.ListView.isCurrentItem),
                        mainWindow: root.mainWindow,
                    };

                    switch (type) {
                    case Koko.FileInfo.VideoType:
                        properties.autoplay = Qt.binding(() => loader.index === root.startIndex);
                        properties.slideShow = slideshowManager;
                        delegate = Qt.resolvedUrl("imagedelegate/VideoDelegate.qml");
                        break;
                    case Koko.FileInfo.VectorImageType:
                        delegate = Qt.resolvedUrl("imagedelegate/VectorImageDelegate.qml");
                        break;
                    case Koko.FileInfo.AnimatedImageType:
                        delegate = Qt.resolvedUrl("imagedelegate/AnimatedImageDelegate.qml");
                        break;
                    case Koko.FileInfo.RasterImageType:
                        delegate = Qt.resolvedUrl("imagedelegate/RasterImageDelegate.qml");
                        break;
                    default:
                        console.warn("Unknown file type for URL", loader.imageurl);
                        break;
                    }

                    if (delegate) {
                        // Important: Since the signal handler responsible for
                        // loading is attached to the onDelegateSourceChanged,
                        // this needs to make sure initialProperties is changed
                        // before delegateSource, as otherwise the code will
                        // ignore the new initialProperties.
                        initialProperties = properties;
                        delegateSource = delegate;
                    } else {
                        initialProperties = {};
                        delegateSource = "";
                    }
                }
            }
        }

        QQC2.RoundButton {
            id: previousButton

            readonly property bool shouldShow: !Kirigami.Settings.isMobile
                                            && root.mainWindow.controlsVisible
                                            && !listView.isCurrentItemDragging
                                            && !overviewControl.pressed
                                            && listView.currentIndex > 0

            anchors {
                left: parent.left
                leftMargin: Kirigami.Units.largeSpacing
                verticalCenter: parent.verticalCenter
            }

            visible: opacity > 0
            opacity: previousButton.shouldShow ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            width: Kirigami.Units.gridUnit * 2
            height: width

            Accessible.name: i18n("Previous image")
            icon.name: Qt.application.layoutDirection === Qt.RightToLeft ? "arrow-right-symbolic" : "arrow-left-symbolic"

            onClicked: listView.decrementCurrentIndex()
        }

        QQC2.RoundButton {
            id: nextButton

            readonly property bool shouldShow: !Kirigami.Settings.isMobile
                                            && root.mainWindow.controlsVisible
                                            && !listView.isCurrentItemDragging
                                            && !overviewControl.pressed
                                            && listView.currentIndex < listView.count - 1

            anchors {
                right: parent.right
                rightMargin: Kirigami.Units.largeSpacing
                verticalCenter: parent.verticalCenter
            }

            visible: opacity > 0
            opacity: previousButton.shouldShow ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            width: Kirigami.Units.gridUnit * 2
            height: width

            Accessible.name: i18n("Next image")
            icon.name: Qt.application.layoutDirection === Qt.RightToLeft ? "arrow-left-symbolic" : "arrow-right-symbolic"

            onClicked: listView.incrementCurrentIndex()
        }

        OverviewControl {
            id: overviewControl
            target: listView.currentItem ? listView.currentItem.item : null
            visible: !Kirigami.Settings.tabletMode && opacity > 0
            opacity: listView.currentItem !== null
                && listView.isCurrentItemInteractive
                && root.mainWindow.controlsVisible
                ? 1 : 0
            parent: listView
            // NOTE: The x and y values will often not be integers.
            // Not a problem unless you want to use them to position other elements.
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: Kirigami.Units.gridUnit
            }
            z: 1
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: !root.mainWindow.controlsVisible ? Easing.InOutQuad : Easing.InCubic
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
            running: target && (target.status == Loader.Loading || target.item && target.item.loading)
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

    // Desktop thumbnail toolbar
    QQC2.ToolBar {
        id: thumbnailToolBar

        readonly property bool shouldShow: !Kirigami.Settings.isMobile
                                        && root.mainWindow.controlsVisible
                                        && Koko.Config.imageViewPreview
                                        && listView.count > 1

        anchors {
            left: parent.left
            right: infoSideBar.left
            bottom: parent.bottom
            bottomMargin: thumbnailToolBar.shouldShow ? 0 : -height
        }

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        visible: anchors.bottomMargin > -height
        implicitHeight: thumbnailView.delegateSize + (padding * 2)

        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false

        padding: Kirigami.Units.largeSpacing
        position: QQC2.ToolBar.Footer

        contentItem: QQC2.ScrollView {
            id: thumbnailScrollView

            implicitWidth: -1 // Prevents binding loop, is unused due to anchors

            opacity: thumbnailToolBar.shouldShow ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff

            ThumbnailStrip {
                id: thumbnailView
                // Don't unload the model until we're off-screen
                model: (thumbnailToolBar.shouldShow || thumbnailToolBar.visible) ? listView.model : []
                currentIndex: listView.currentIndex
                onActivated: (index) => { listView.currentIndex = index; }
                containerPadding: thumbnailToolBar.padding
            }
        }
    }

    // Mobile actions toolbar
    QQC2.ToolBar {
        id: mobileActionsToolBar

        readonly property bool shouldShow: Kirigami.Settings.isMobile && root.mainWindow.controlsVisible

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: mobileActionsToolBar.shouldShow ? 0 : -height
        }

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        visible: anchors.bottomMargin > -height

        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false

        position: QQC2.ToolBar.Footer

        contentItem: Kirigami.ActionToolBar {
            opacity: mobileActionsToolBar.shouldShow ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            actions: root.actions
            alignment: Qt.AlignCenter
            display: QQC2.Button.TextUnderIcon
        }
    }

    // Information sidebar & drawer (mobile)
    Row {
        id: infoSideBar

        readonly property bool shouldShow: !Kirigami.Settings.isMobile && root.mainWindow.controlsVisible && infoAction.checked

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: infoSideBar.shouldShow ? 0 : -width
            bottom: parent.bottom
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        visible: anchors.rightMargin > -width

        Kirigami.Separator {
            height: parent.height
        }

        Loader {
            id: infoSidebarLoader

            height: parent.height
            width: Math.min(Kirigami.Units.gridUnit * 14, root.width / 2)

            active: visible
            sourceComponent: InfoSidebar {
                extractor: exiv2Extractor
                application: root.application
                anchors.fill: parent
            }
        }
    }

    Loader {
        id: infoDrawerLoader
        anchors.fill: parent

        active: Kirigami.Settings.isMobile && infoAction.checked
        visible: active

        sourceComponent: InfoDrawer {
            extractor: exiv2Extractor
            application: root.application
        }

        Connections {
            target: infoDrawerLoader.item
            function onClosed() {
                infoAction.checked = false
            }
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

        onClicked: (mouse) => {
            if (mouse.button == Qt.BackButton) {
                listView.decrementCurrentIndex()
            } else if (mouse.button == Qt.ForwardButton) {
                listView.incrementCurrentIndex()
            }
        }
    }

    // Not a QQC2 ToolBar because those block mouse input
    FocusScope {
        id: hoverToolBar
        z: 1
        visible: !Kirigami.Settings.isMobile && (slideshowManager.running || !root.mainWindow.controlsVisible)
        width: parent.width
        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight
        Kirigami.Theme.colorSet: root.mainWindow.controlsVisible ?
            Kirigami.Theme.Window : Kirigami.Theme.Header
        Kirigami.Theme.inherit: false
        Kirigami.ShadowedRectangle {
            id: background
            visible: root.mainWindow.controlsVisible || hoverHandler.hovered || y > -height
            y: if (root.mainWindow.controlsVisible || hoverHandler.hovered) {
                -implicitHeight
            } else {
                -height
            }
            Behavior on y {
                enabled: !root.mainWindow.controlsVisible || hoverHandler.hovered
                NumberAnimation {
                    property: "y"
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.OutCubic
                }
            }
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, parent.width)
            height: implicitHeight * 2
            implicitWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
            implicitHeight: row.implicitHeight
            radius: 3
            color: Kirigami.Theme.backgroundColor
            shadow.color: Qt.rgba(0,0,0,0.2)
            shadow.size: 9
            shadow.yOffset: 2
            // Prevent non-hover mouse events from passing through
            TapHandler {}
            WheelHandler {}
            RowLayout {
                id: row
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label {
                    visible: slideshowManager.running
                    text: i18nc("@label:spinbox Slideshow image changing interval", "Slideshow interval:")
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                }
                // Reset the spinbox whenever visibility changes.
                // QQC2 SpinBox doesn't have a good way to reset the displayText.
                Loader {
                    visible: slideshowManager.running
                    active: visible
                    sourceComponent: QQC2.SpinBox {
                        id: intervalSpinBox
                        from: 1
                        // limited to hundreds for now because I don't want
                        // to deal with regexing for locale formatted numbers
                        to: 999
                        value: Koko.Config.nextImageInterval
                        editable: true
                        textFromValue: (value) => i18ncp("Slideshow image changing interval",
                                                         "1 second", "%1 seconds", value)
                        valueFromText: (text) => {
                            const match = text.match(/\d{1,3}/)
                            return match !== null ? match[0] : intervalSpinBox.value
                        }
                        TextMetrics {
                            id: intervalMetrics
                            text: intervalSpinBox.textFromValue(intervalSpinBox.to)
                        }
                        wheelEnabled: true
                        contentItem: QQC2.TextField {
                            property int oldCursorPosition: cursorPosition
                            implicitWidth: intervalMetrics.width + leftPadding + rightPadding
                            implicitHeight: Math.ceil(contentHeight) + topPadding + bottomPadding
                            palette: parent.palette
                            leftPadding: parent.spacing
                            rightPadding: parent.spacing
                            topPadding: 0
                            bottomPadding: 0
                            font: parent.font
                            color: palette.text
                            selectionColor: palette.highlight
                            selectedTextColor: palette.highlightedText
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !parent.editable
                            validator: parent.validator
                            inputMethodHints: parent.inputMethodHints
                            selectByMouse: true
                            background: null
                            // Trying to mimic some of QSpinBox's behavior with suffixes
                            onTextChanged: if (!inputMethodComposing) {
                                const valueText = parent.valueFromText(text).toString()
                                const valueIndex = parent.displayText.indexOf(valueText)
                                if (valueIndex >= 0) {
                                    console.log(valueIndex, cursorPosition)
                                    cursorPosition = Math.min(Math.max(valueIndex, oldCursorPosition), valueIndex + valueText.length)
                                }
                            }
                            Component.onCompleted: oldCursorPosition = cursorPosition
                        }
                        // Can't just use a binding because modifying the text
                        // elsewhere will break bindings.
                        onValueChanged: {
                            contentItem.oldCursorPosition = contentItem.cursorPosition
                            contentItem.text = displayText
                        }
                        onValueModified: {
                            Koko.Config.nextImageInterval = value;
                            Koko.Config.save();
                        }
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                    }
                }
                QQC2.CheckBox {
                    visible: slideshowManager.running
                    text: i18nc("@option:check", "Loop")
                    checked: Koko.Config.loopImages
                    onToggled: {
                        Koko.Config.loopImages = checked;
                        Koko.Config.save();
                    }
                }
                QQC2.CheckBox {
                    visible: slideshowManager.running
                    text: i18nc("@option:check", "Randomize")
                    checked: Koko.Config.randomizeImages
                    onToggled: {
                        Koko.Config.randomizeImages = checked;
                        Koko.Config.save();
                    }
                }
                QQC2.ToolButton {
                    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                             implicitContentHeight + topPadding + bottomPadding)
                    visible: slideshowManager.running
                    icon.name: "media-playback-stop"
                    text: i18n("Stop Slideshow")
                    onClicked: slideshowManager.stop()
                    topInset: Kirigami.Units.smallSpacing
                    bottomInset: Kirigami.Units.smallSpacing
                    Layout.fillHeight: true
                }
                QQC2.ToolSeparator {
                    visible: slideshowManager.running && !root.mainWindow.controlsVisible
                }
                QQC2.ToolButton {
                    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                             implicitContentHeight + topPadding + bottomPadding)
                    visible: !root.mainWindow.controlsVisible
                    icon.name: "visibility"
                    text: i18n("Show All Controls")
                    onClicked: root.mainWindow.controlsVisible = true
                    topInset: Kirigami.Units.smallSpacing
                    bottomInset: Kirigami.Units.smallSpacing
                    Layout.fillHeight: true
                }
            }
        }
        HoverHandler {
            id: hoverHandler
            margin: parent.implicitHeight/2
        }
    }

    Shortcut {
        sequence: Qt.application.layoutDirection === Qt.RightToLeft ? "Right" : "Left"
        onActivated: listView.decrementCurrentIndex()
    }

    Shortcut {
        sequence: Qt.application.layoutDirection === Qt.RightToLeft ? "Left" : "Right"
        onActivated: listView.incrementCurrentIndex()
    }

    Component.onCompleted: {
        root.mainWindow.controlsVisible = true;
        listView.forceActiveFocus();
    }
}
