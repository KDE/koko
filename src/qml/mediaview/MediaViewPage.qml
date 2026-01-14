/*
 * SPDX-FileCopyrightText: 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 * SPDX-FileCopyrightText: 2025 Anders Lund <anders@alweb.dk>
 * SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Window
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KAC
import org.kde.koko as Koko
import org.kde.photos.thumbnails as KokoThumbnails

Kirigami.Page {
    id: root

    required property Koko.PhotosApplication application
    required property Kirigami.ApplicationWindow mainWindow
    required property Koko.GallerySortFilterProxyModel gallerySortFilterProxyModel
    required property url url

    property int lastWindowVisibility: mainWindow.visibility

    // A model that is still populating might not yet contain the index we want to show
    property bool modelReady: false

    function updateModelReady() {
        if (modelReady) {
            return;
        }

        if (root.gallerySortFilterProxyModel.galleryModel.status === Koko.AbstractGalleryModel.Loaded) {
            // Find index of the image we're showing in the model
            for (let i = 0; i < mediaViewFilterModel.rowCount(); ++i) {
                let index = mediaViewFilterModel.index(i, 0);
                if (mediaViewFilterModel.data(index, Koko.AbstractGalleryModel.UrlRole) === root.url) {
                    listView.currentIndex = i;
                    thumbnailView.positionViewAtIndex(index, ListView.Center);
                    root.modelReady = true;
                }
            }
        }
    }

    Connections {
        target: root.gallerySortFilterProxyModel.galleryModel

        function onStatusChanged() {
            updateModelReady();
        }
    }

    // exit full screen on mobile, where only image view should be full screen.
    onBackRequested: {
        if (Kirigami.Settings.isMobile && applicationWindow().visibility === Window.FullScreen) {
            applicationWindow().visibility = Window.Windowed
        }
    }

    Koko.MediaViewFilterModel {
        id: mediaViewFilterModel

        gallerySortFilterProxyModel: root.gallerySortFilterProxyModel
    }

    Component.onCompleted: {
        root.mainWindow.controlsVisible = true;
        listView.forceActiveFocus();

        updateModelReady();
    }

    title: Koko.DirModelUtils.fileNameOfUrl(root.url)

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    onUrlChanged: exiv2Extractor.updateFavorite(root.url.toString().replace("file://", ""))
    Koko.Exiv2Extractor {
        id: exiv2Extractor
        filePath: root.url
    }

    readonly property list<QtObject> toolBarActions: [
        Kirigami.Action {
            text: i18nc("@action:intoolbar Favorite an image/video", "Favorite")
            icon.name: exiv2Extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
            tooltip: exiv2Extractor.favorite ? i18nc("@info:tooltip", "Remove from favorites") : i18nc("@info:tooltip", "Add to favorites")

            checkable: true
            checked: exiv2Extractor.favorite
            onToggled: {
                exiv2Extractor.toggleFavorite(listView.currentItem.url.toString().replace("file://", ""));
                // makes change immediate
                kokoProcessor.removeFile(listView.currentItem.url.toString().replace("file://", ""));
                kokoProcessor.addFile(listView.currentItem.url.toString().replace("file://", ""));
            }
        },
        Kirigami.Action {
            text: i18nc("@action:intoolbar Edit an image", "&Edit")
            icon.name: "edit-entry"
            tooltip: i18nc("@info:tooltip", "Edit this image")

            visible: (listView.currentItem && listView.currentItem.type === Koko.FileInfo.RasterImageType) || (imagePlaceholder && imagePlaceholder.type === Koko.FileInfo.RasterImageType)
            onTriggered: {
                const page = root.mainWindow.pageStack.layers.push(Qt.createComponent("org.kde.photos.editor", "EditorView"), {
                    mainWindow: root.mainWindow,
                    imagePath: listView.currentItem.url,
                    // Without this, there's an odd glitch where the page will show for a brief moment
                    // before the show animation runs.
                    visible: false
                })
                page.imageEdited.connect(function() {
                    KokoThumbnails.ThumbnailManager.refreshThumbnail(page.imagePath);
                });
            }
        },
        ShareAction {
            text: i18nc("@action:intoolbar Share an image/video", "&Share")
            application: root.mainWindow
            tooltip: {
                if (!listView.currentItem) {
                    return "";
                }
                if (listView.currentItem.type === Koko.FileInfo.VideoType) {
                    return i18nc("@info:tooltip", "Share this video");
                }
                return i18nc("@info:tooltip", "Share this image");
            }

            inputData: {
                return {
                    urls: [root.url.toString()],
                    mimeType: [listView.currentItem?.mimeType ?? imagePlaceholder?.mimeType]
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
        }
    ]

    readonly property list<QtObject> otherHiddenUiActions: [
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide
            separator: true
            visible: slideshowAction.visible || !Kirigami.Settings.isMobile
        },
        Kirigami.Action {
            id: slideshowAction

            displayHint: Kirigami.DisplayHint.AlwaysHide

            // TODO: Checkable would be best, then toggle slideshow with changed i18n hint in text and dynamic tooltip text
            text: i18nc("@action:intoolbar Start a slideshow", "&Slideshow")
            icon.name: "view-presentation-symbolic"
            tooltip: i18nc("@info:tooltip", "Start slideshow")

            visible: listView.count > 1 && !slideshowManager.running
            onTriggered: Kirigami.Settings.isMobile ? mobileSlideshowConfig.open() : slideshowManager.start()
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
                    root.lastWindowVisibility = root.mainWindow.visibility
                    root.mainWindow.visibility = Window.FullScreen;
                } else {
                    // Exit full screen
                    root.mainWindow.visibility = root.lastWindowVisibility
                }

                listView.forceActiveFocus();
            }
        }
    ]

    Component {
        id: kirigamiActionComponent
        Kirigami.Action {}
    }
    Binding {
        target: Koko.FileMenuActions
        property: "url"
        value: listView.currentItem?.url ?? ""
        restoreMode: Binding.RestoreNone
    }

    actions: {
        let list = [];
        for (let action of toolBarActions) {
            list.push(action);
        }
        /* Hidden actions */
        const fileMenuActions = Koko.FileMenuActions.actions;
        for (let fileMenuAction of fileMenuActions) {
            let kirigamiAction = kirigamiActionComponent.createObject(this, {
                displayHint: Kirigami.DisplayHint.AlwaysHide,
                fromQAction: fileMenuAction
            });
            list.push(kirigamiAction);
        }
        for (let action of otherHiddenUiActions) {
            list.push(action);
        }
        return list;
    }

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
        function getNextSlide(): int {
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

    function close(): void {
        if (root.mainWindow.footer) {
            root.mainWindow.footer.visible = true;
        }
        root.mainWindow.globalDrawer.enabled = true;
        root.mainWindow.pageStack.layers.pop();
    }

    background: Rectangle {
        color: {
            switch (Koko.Config.imageViewBackgroundColor) {
                case 0:
                    return "black";
                case 1:
                    return "white";
                case 2:
                    return Kirigami.Theme.backgroundColor;
            }
        }
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

    DelegateLoader {
        id: imagePlaceholder
        anchors.fill: listView

        z: 1
        index: 0

        asynchronous: false
        url: root.url
        supportsVideo: false

        visible: !root.modelReady || !listView.currentItem || listView.currentItem.status !== Loader.Ready || !listView.currentItem.item.loaded
        onVisibleChanged: {
            if (!visible) {
                if (item && item.loaded) {
                    // Transfer zoom and position to the new delegate
                    listView.currentItem.item.contentWidth = item.contentWidth;
                    listView.currentItem.item.contentHeight = item.contentHeight;
                    listView.currentItem.item.contentX = item.contentX;
                    listView.currentItem.item.contentY = item.contentY;
                }
                imagePlaceholder.destroy();
            }
        }

        Component.onCompleted: {
            if (root.modelReady) {
                imagePlaceholder.destroy();
            }
        }

        Rectangle {
            anchors.fill: parent
            z: -1
            color: {
                switch (Koko.Config.imageViewBackgroundColor) {
                    case 0:
                        return "black";
                    case 1:
                        return "white";
                    case 2:
                        return Kirigami.Theme.backgroundColor;
                }
            }
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

        model: mediaViewFilterModel

        // we start with this index, so we don't flash initial image
        currentIndex: -1

        Component.onCompleted: { // fun fact: without null guard this function will crash the app after a certain number of calls (I think)
            if (root.startIndex) {
                listView.currentIndex = model.mapFromSource(root.startIndex).row;
            }
        }

        property alias slideshow: slideshowManager

        onCountChanged: {
            if (count === 0 && modelReady) {
                infoAction.checked = false
                root.close();
            }
            if (currentIndex >= count) {
                currentIndex = count - 1
            }
        }

        onCurrentItemChanged: {
            if (currentItem) {
                root.url = currentItem.url;
            }
        }

        delegate: DelegateLoader {
            id: loader
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
            icon.name: Application.layoutDirection === Qt.RightToLeft ? "arrow-right-symbolic" : "arrow-left-symbolic"

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
            icon.name: Application.layoutDirection === Qt.RightToLeft ? "arrow-left-symbolic" : "arrow-right-symbolic"

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
            property Loader target: listView.currentItem as Loader
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

        KAC.FloatingToolBar {
            id: zoomBar
            readonly property bool shouldShow: listView.currentItem !== null && root.mainWindow.controlsVisible
            Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
            parent: listView
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                margins: Kirigami.Units.gridUnit
            }
            z: 1
            visible: opacity > 0
            opacity: shouldShow ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: !root.mainWindow.controlsVisible ? Easing.InOutQuad : Easing.InCubic
                }
            }
            padding: Kirigami.Units.smallSpacing
            // TODO: remove this Binding when we depend on the Kirigami Addons version after 1.11.0
            Binding {
                target: zoomBar.background.Kirigami.Theme
                property: "inherit"
                value: true
            }
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.ComboBox {
                    id: zoomBox
                    // Strips other characters from a string to get a number
                    function parsePercent(string: string): real {
                        // Remove mnemonics and percent signs.
                        // We don't remove all non-number characters because attempting
                        // to do so could break locale specific number parsing.
                        let filtered = string.replace(RegExp(`${locale.percent}|[&%٪％]`, "gi"), "").trim()
                        // Number.fromLocaleString may throw an exception if the
                        // string isn't perfectly formatted for the locale.
                        try {
                            return Number.fromLocaleString(locale, filtered)
                        } catch (e1) {
                            try {
                                // Try US if non-US fails.
                                // Maybe the user forgot to use their locale?
                                // US number formatting has a lot in common with
                                // various South American, African and Asian locales.
                                if (locale.name !== "en_US") {
                                    return Number.fromLocaleString(Qt.locale("en_US"), filtered)
                                }
                                // Try parseFloat if already using US locale.
                                // Maybe the user wrote the number in a simpler way?

                                // Search for the locale's group separator and group separators that aren't sometimes decimal points.
                                // Escape periods so the group separator regex works correctly with periods.
                                const groupRegex = RegExp(`(${locale.groupSeparator.replace(/\./g, "\\.")}|[\s'’٬])+`, "g")
                                // Search for the locale's decimal point and common non-period decimal points.
                                const decimalRegex = RegExp(`(${locale.decimalPoint.replace(/\./g, "\\.")}|[,٫])+`)
                                // Remove group separators and replace decimal points with period to make it work better with parseFloat.
                                filtered = string.replace(groupRegex, "").replace(decimalRegex, ".")
                                return parseFloat(filtered)
                            } catch (e2) {
                                // Try parseFloat if US fails.
                                const groupRegex = RegExp(`(${locale.groupSeparator.replace(/\./g, "\\.")}|[\s'’٬])+`, "g")
                                const decimalRegex = RegExp(`(${locale.decimalPoint.replace(/\./g, "\\.")}|[,٫])+`)
                                filtered = string.replace(groupRegex, "").replace(decimalRegex, ".")
                                return parseFloat(filtered)
                            }
                        }
                    }
                    Kirigami.Theme.inherit: true
                    implicitContentWidthPolicy: QQC2.ComboBox.WidestText
                    model: [
                        {text: i18nc("@item:inlistbox zoom percent", "25%"), zoom: 0.25},
                        {text: i18nc("@item:inlistbox zoom percent", "50%"), zoom: 0.5},
                        {text: i18nc("@item:inlistbox zoom percent", "75%"), zoom: 0.75},
                        {text: i18nc("@item:inlistbox zoom percent", "100%"), zoom: 1},
                        {text: i18nc("@item:inlistbox zoom percent", "150%"), zoom: 1.5},
                        {text: i18nc("@item:inlistbox zoom percent", "200%"), zoom: 2},
                        {text: i18nc("@item:inlistbox zoom percent", "300%"), zoom: 3},
                        {text: i18nc("@item:inlistbox zoom percent", "400%"), zoom: 4},
                        {text: i18nc("@item:inlistbox zoom percent", "600%"), zoom: 6},
                        {text: i18nc("@item:inlistbox zoom percent", "800%"), zoom: 8}
                    ]
                    textRole: "text"
                    valueRole: "zoom"
                    currentIndex: indexOfValue(Koko.State.zoom)
                    editable: true
                    // Prevent changing the text while the user is editing it using a timer.
                    Timer {
                        id: textEditedTimer
                        interval: 100
                        repeat: false
                        running: false
                    }
                    onActivated: (index) => {
                        if (index >= 0) {
                            Koko.State.zoom = zoomBox.currentValue
                        }
                    }
                    // The order in which text changed signals are emitted and
                    // currentIndex/currentText/currentValue changed signals are
                    // emitted makes it so we have to parse the text first to react
                    // in a timely manner to user input.
                    Connections {
                        target: zoomBox.contentItem
                        function onTextEdited() {
                            textEditedTimer.restart()
                            const text = zoomBox.contentItem.text
                            // Exact match first, then parse, then fallback to whatever the currentIndex is
                            const index = zoomBox.find(text, Qt.MatchExactly)
                            const value = index > 0 ? zoomBox.valueAt(index) : zoomBox.parsePercent(text) / 100 || zoomBox.valueAt(zoomBox.currentIndex)
                            if (!value || value === Koko.State.zoom) {
                                return
                            }
                            Koko.State.zoom = value
                        }
                    }
                    Connections {
                        target: Koko.State
                        function onZoomChanged() {
                            const zoom = Koko.State.zoom
                            const index = zoomBox.indexOfValue(zoom)
                            if (textEditedTimer.running || !zoom || zoomBox.currentValue === zoom) {
                                return
                            }
                            const oldCursorPos = zoomBox.contentItem.cursorPosition
                            const oldTextLength = zoomBox.editText.length
                            zoomBox.currentIndex = Qt.binding(() => zoomBox.indexOfValue(zoom))
                            zoomBox.editText = Qt.binding(() => zoomBox.currentIndex > 0
                                ? zoomBox.currentText
                                : i18nc("@item:inlistbox zoom percent", "%1%", Math.round(zoom * 100)))
                            const percentOffset = zoomBox.editText.endsWith(locale.percent)
                                ? locale.percent.length
                                : (zoomBox.editText.endsWith("%") ? 1 : 0)
                            // Preserve the cursor position relative to the end of the text before the percent sign
                            zoomBox.contentItem.cursorPosition = Math.min(oldCursorPos + (zoomBox.editText.length - oldTextLength),
                                                                          zoomBox.editText.length - percentOffset)
                        }
                    }
                }
                QQC2.ToolSeparator {}
                QQC2.ToolButton {
                    icon.name: "zoom-out"
                    text: i18nc("@action", "Zoom Out")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: Koko.State.zoom > zoomBox.model[0].zoom
                    onClicked: {
                        for (let i = zoomBox.count - 1; i >= 0; --i) {
                            let z = zoomBox.valueAt(i)
                            if (z < Koko.State.zoom && z > 0) {
                                Koko.State.zoom = z
                                zoomBox.currentIndex = i
                                return
                            }
                        }
                    }
                }
                QQC2.ToolButton {
                    icon.name: "zoom-in"
                    text: i18nc("@action", "Zoom In")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: Koko.State.zoom < zoomBox.model[zoomBox.count -1].zoom
                    onClicked: {
                        for (let i = 0; i < zoomBox.count; ++i) {
                            let z = zoomBox.valueAt(i)
                            if (z > Koko.State.zoom) {
                                Koko.State.zoom = z
                                zoomBox.currentIndex = i
                                return
                            }
                        }
                    }
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
            Layout.fillWidth: true
            Layout.fillHeight: true

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
                onActivated: (index, url) => {
                    listView.currentIndex = index;
                }
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

        visible: shouldShow && anchors.bottomMargin > -height

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
                            palette: intervalSpinBox.palette
                            leftPadding: intervalSpinBox.spacing
                            rightPadding: intervalSpinBox.spacing
                            topPadding: 0
                            bottomPadding: 0
                            font: intervalSpinBox.font
                            color: palette.text
                            selectionColor: palette.highlight
                            selectedTextColor: palette.highlightedText
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !intervalSpinBox.editable
                            validator: intervalSpinBox.validator
                            inputMethodHints: intervalSpinBox.inputMethodHints
                            selectByMouse: true
                            background: null
                            // Trying to mimic some of QSpinBox's behavior with suffixes
                            onTextChanged: if (!inputMethodComposing) {
                                const valueText = intervalSpinBox.valueFromText(text).toString()
                                const valueIndex = intervalSpinBox.displayText.indexOf(valueText)
                                if (valueIndex >= 0) {
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

    // Slideshow handling for mobile devices
    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        enabled: Kirigami.Settings.isMobile && slideshowManager.running
        onClicked: mobileSlideshowConfig.open()
    }

    Kirigami.Dialog {
        id: mobileSlideshowConfig
        preferredWidth: Kirigami.Units.gridUnit * 20
        title: "Slideshow"

        customFooterActions: [
            Kirigami.Action {
                text: slideshowManager.running ? i18nc("@action: button", "Stop") : i18nc("@action: button","Start")
                icon.name: slideshowManager.running ? "media-playback-stop" : "media-playback-start"
                onTriggered: {
                    mobileSlideshowConfig.close();
                    if (slideshowManager.running) {
                        slideshowManager.stop()
                    } else {
                        slideshowManager.start()

                    }
                    mobileSlideshowConfig.close();
                }
            }
        ]

        ColumnLayout {
            RowLayout {
                Layout.leftMargin: Kirigami.Units.mediumSpacing
                QQC2.Label {
                    text: i18nc("@label:Slideshow image changing interval", "Interval:")
                }
                TextInput {
                    maximumLength: 2
                    validator: IntValidator { bottom: 1; top:99 }
                    text: Koko.Config.nextImageInterval
                    onActiveFocusChanged: { if (focus) selectAll() }
                    onTextEdited: {
                        Koko.Config.nextImageInterval = text;
                        Koko.Config.save();
                    }
                }
                QQC2.Label {
                    text: i18n("seconds")
                }
            }
            QQC2.CheckBox {
                Layout.leftMargin: Kirigami.Units.mediumSpacing
                text: i18nc("@option:check", "Loop")
                checked: Koko.Config.loopImages
                onToggled: {
                    Koko.Config.loopImages = checked
                    Koko.Config.save()
                }
            }
            QQC2.CheckBox {
                Layout.leftMargin: Kirigami.Units.mediumSpacing
                text: i18nc("@option:check", "Randomize")
                checked: Koko.Config.randomizeImages
                onToggled: {
                    Koko.Config.randomizeImages = checked
                    Koko.Config.save()
                }
            }
        }
    }

    Shortcut {
        sequence: Application.layoutDirection === Qt.RightToLeft ? "Right" : "Left"
        enabled: root.modelReady
        onActivated: listView.decrementCurrentIndex()
    }

    Shortcut {
        sequence: Application.layoutDirection === Qt.RightToLeft ? "Left" : "Right"
        enabled: root.modelReady
        onActivated: listView.incrementCurrentIndex()
    }
}
