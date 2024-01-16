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
import QtQuick.Templates 2 as T
import QtQuick.Controls 2 as QQC2
import QtQuick.Layouts
import org.kde.kirigami 2 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.kquickcontrolsaddons 2 as KQA
import org.kde.coreaddons as KCA
import org.kde.koko.private 0.1 as KokoPrivate

Kirigami.Page {
    id: root

    property var startIndex
    required property var imagesModel
    property int lastWindowVisibility: applicationWindow().visibility

    Connections {
        target: imagesModel
        ignoreUnknownSignals: true
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
            id: infoAction
            icon.name: "kdocumentinfo"
            text: i18n("Info")
            tooltip: !listView.currentItem ? "" :
                      (listView.currentItem.type == Koko.FileInfo.VideoType ? i18n("See information about video") :
                                                                              i18n("See information about image"))
            checkable: true
            checked: false
            onToggled: if (checked) {
                infoSidebarLoader.forceActiveFocus();
            }
        },
        Kirigami.Action {
            icon.name: exiv2Extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
            text: exiv2Extractor.favorite ? i18n("Remove") : i18n("Favorite")
            tooltip: exiv2Extractor.favorite ? i18n("Remove from favorites") : i18n("Add to favorites")
            onTriggered: {
                exiv2Extractor.toggleFavorite(listView.currentItem.imageurl.toString().replace("file://", ""));
                // makes change immediate
                kokoProcessor.removeFile(listView.currentItem.imageurl.toString().replace("file://", ""));
                kokoProcessor.addFile(listView.currentItem.imageurl.toString().replace("file://", ""));
            }
        },
        Kirigami.Action {
            id: editingAction
            icon.name: "edit-entry"
            text: i18nc("verb, edit an image", "Edit")
            visible: listView.currentItem && listView.currentItem.type == Koko.FileInfo.RasterImageType

            onTriggered: {
                const page = applicationWindow().pageStack.layers.push(Qt.resolvedUrl("EditorView.qml"), {
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
            tooltip: !listView.currentItem ? "" :
                     (listView.currentItem.type == Koko.FileInfo.VideoType ? i18n("Share Video") : i18n("Share Image"))
            text: i18nc("verb, share an image/video", "Share")

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
            icon.name: "view-presentation"
            tooltip: i18n("Start Slideshow")
            text: i18n("Slideshow")
            visible: listView.count > 1 && !slideshowManager.running && !Kirigami.Settings.isMobile
            onTriggered: slideshowManager.start()
        },
        Kirigami.Action {
            icon.name: "view-preview"
            // be more descriptive on mobile, since we're less constrained there
            text: !Kirigami.Settings.isMobile ? i18n("Thumbnail Bar") :
                   kokoConfig.imageViewPreview ? i18n("Hide Thumbnail Bar") : i18n("Show Thumbnail Bar")
            tooltip: i18n("Toggle Thumbnail Bar")
            shortcut: "T"
            visible: thumbnailView.count > 1
            onTriggered: kokoConfig.imageViewPreview = !kokoConfig.imageViewPreview
        },
        Kirigami.Action {
            property bool fullscreen: applicationWindow().visibility === Window.FullScreen
            icon.name: !fullscreen ? "view-fullscreen" : "view-restore"
            text: !fullscreen ? i18n("Fullscreen") : i18n("Exit Fullscreen")
            tooltip: !fullscreen ? i18n("Enter Fullscreen") : i18n("Exit Fullscreen")
            shortcut: "F"
            visible: !Kirigami.Settings.isMobile
            onTriggered: {
                if (applicationWindow().visibility === Window.FullScreen) {
                    applicationWindow().visibility = lastWindowVisibility
                } else {
                    KokoPrivate.Controller.saveWindowGeometry(applicationWindow());
                    lastWindowVisibility = applicationWindow().visibility
                    applicationWindow().visibility = Window.FullScreen;
                }
                listView.forceActiveFocus();
            }
        }
    ]


    KokoPrivate.FileMenu {
        id: fileMenu
        url: listView.currentItem.imageurl
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
        KokoPrivate.Controller.restoreWindowGeometry(applicationWindow());
        if (applicationWindow().footer) {
            applicationWindow().footer.visible = true;
        }
        applicationWindow().globalDrawer.enabled = true;
        applicationWindow().pageStack.layers.pop();
    }

    background: Rectangle {
        color: "black"
    }

    Keys.onPressed: {
        switch(event.key) {
            case Qt.Key_Escape:
                if (slideshowManager.running) {
                    slideshowManager.stop();
                } else if (applicationWindow().visibility == Window.FullScreen) {
                    applicationWindow().visibility = lastWindowVisibility;
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

            // Don't show other images when resizing the view
            visible: {
                if (ListView.isCurrentItem) {
                    return true
                }

                if (!listView.moving && !listView.dragging) {
                    return false
                }

                if (index === listView.currentIndex - 1 || index === listView.currentIndex + 1) {
                    return true
                }

                return false
            }

            // Don't load images that are not going to be visible.
            active: visible
            onActiveChanged: {
                if (active && info.delegateSource && info.initialProperties) {
                    setSource(info.delegateSource, info.initialProperties)
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
                        loader.setSource(delegateSource, initialProperties)
                    }
                }

                onStatusChanged: {
                    if (status != Koko.FileInfo.Ready) {
                        return
                    }

                    let delegate = ""
                    let properties = {}
                    properties.source = loader.imageurl
                    properties.isCurrent = Qt.binding(() => loader.ListView.isCurrentItem)

                    switch (type) {
                    case Koko.FileInfo.VideoType:
                        properties.autoplay = loader.index === root.startIndex
                        properties.slideShow = slideshowManager
                        delegate = Qt.resolvedUrl("imagedelegate/VideoDelegate.qml")
                        break
                    case Koko.FileInfo.VectorImageType:
                        delegate = Qt.resolvedUrl("imagedelegate/VectorImageDelegate.qml")
                        break
                    case Koko.FileInfo.AnimatedImageType:
                        delegate = Qt.resolvedUrl("imagedelegate/AnimatedImageDelegate.qml")
                        break
                    case Koko.FileInfo.RasterImageType:
                        delegate = Qt.resolvedUrl("imagedelegate/RasterImageDelegate.qml")
                        break
                    default:
                        console.warn("Unknown file type for URL", loader.imageurl)
                        break
                    }

                    if (delegate) {
                        // Important: Since the signal handler responsible for
                        // loading is attached to the onDelegateSourceChanged,
                        // this needs to make sure initialProperties is changed
                        // before delegateSource, as otherwise the code will
                        // ignore the new initialProperties.
                        initialProperties = properties
                        delegateSource = delegate
                    } else {
                        initialProperties = {}
                        delegateSource = ""
                    }
                }
            }
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
            target: listView.currentItem ? listView.currentItem.item : null
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

    QQC2.ScrollView {
        id: thumbnailScrollView
        visible: !Kirigami.Settings.isMobile && thumbnailView.count > 1
        height: kokoConfig.iconSize + Kirigami.Units.largeSpacing
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff

        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.smallSpacing

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: applicationWindow().controlsVisible && thumbnailScrollView.visible && kokoConfig.imageViewPreview ?
                            Kirigami.Units.smallSpacing : -height
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

            model: Kirigami.Settings.isMobile ? [] : listView.model
            currentIndex: listView.currentIndex
            onActivated: index => listView.currentIndex = index
        }
    }

    QQC2.Pane {
        id: mobileActionsRow
        visible: Kirigami.Settings.isMobile

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: applicationWindow().controlsVisible ? 0 : -height
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

        background: Rectangle {
            color: 'black'
            opacity: 0.7
        }

        contentItem: RowLayout {
            Repeater {
                model: root.actions

                QQC2.AbstractButton {
                    action: modelData
                    visible: modelData.visible

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    contentItem: ColumnLayout {
                        spacing: 0

                        Kirigami.Icon {
                            source: modelData.icon.name
                            color: 'white'
                            isMask: true
                            Layout.preferredWidth: Kirigami.Units.iconSizes.sizeForLabels
                            Layout.preferredHeight: Kirigami.Units.iconSizes.sizeForLabels
                            Layout.alignment: Qt.AlignHCenter
                        }

                        QQC2.Label {
                            text: modelData.text
                            font: Kirigami.Theme.smallFont
                            horizontalAlignment: Text.AlignHCenter
                            color: 'white'
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            QQC2.AbstractButton {
                id: moreButton

                Layout.fillHeight: true
                Layout.fillWidth: true

                icon.name: "view-more-symbolic"
                text: i18n("More")
                checkable: true

                onPressedChanged: {
                    if (pressed) {
                        // fake "pressed" while menu is open
                        checked = Qt.binding(function() {
                            return fileMenu.visible;
                        });
                        fileMenu.visualParent = this;
                        fileMenu.open(pressX, pressY);
                    }
                }

                contentItem: ColumnLayout {
                    spacing: 0

                    Kirigami.Icon {
                        source: moreButton.icon.name
                        color: 'white'
                        isMask: true
                        Layout.preferredWidth: Kirigami.Units.iconSizes.sizeForLabels
                        Layout.preferredHeight: Kirigami.Units.iconSizes.sizeForLabels
                        Layout.alignment: Qt.AlignHCenter
                    }

                    QQC2.Label {
                        text: moreButton.text
                        font: Kirigami.Theme.smallFont
                        horizontalAlignment: Text.AlignHCenter
                        color: 'white'
                        Layout.fillWidth: true
                    }
                }
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

        onClicked: {
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
        visible: !Kirigami.Settings.isMobile && (slideshowManager.running || !applicationWindow().controlsVisible)
        width: parent.width
        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight
        Kirigami.Theme.colorSet: applicationWindow().controlsVisible ?
            Kirigami.Theme.Window : Kirigami.Theme.Header
        Kirigami.Theme.inherit: false
        Kirigami.ShadowedRectangle {
            id: background
            visible: applicationWindow().controlsVisible || hoverHandler.hovered || y > -height
            y: if (applicationWindow().controlsVisible || hoverHandler.hovered) {
                -implicitHeight
            } else {
                -height
            }
            Behavior on y {
                enabled: !applicationWindow().controlsVisible || hoverHandler.hovered
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
                        value: kokoConfig.nextImageInterval
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
                        onValueModified: kokoConfig.nextImageInterval = value
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                    }
                }
                QQC2.CheckBox {
                    visible: slideshowManager.running
                    text: i18nc("@option:check", "Loop")
                    checked: kokoConfig.loopImages
                    onCheckedChanged: kokoConfig.loopImages = checked
                }
                QQC2.CheckBox {
                    visible: slideshowManager.running
                    text: i18nc("@option:check", "Randomize")
                    checked: kokoConfig.randomizeImages
                    onCheckedChanged: kokoConfig.randomizeImages = checked
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
                    visible: slideshowManager.running && !applicationWindow().controlsVisible
                }
                QQC2.ToolButton {
                    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                             implicitContentHeight + topPadding + bottomPadding)
                    visible: !applicationWindow().controlsVisible
                    icon.name: "visibility"
                    text: i18n("Show All Controls")
                    onClicked: applicationWindow().controlsVisible = true
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

    Binding {
        target: root.globalToolBarItem
        property: "visible"
        value: applicationWindow().controlsVisible
    }

    Component.onCompleted: {
        applicationWindow().controlsVisible = true;
        listView.forceActiveFocus();
    }
}
