/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQml.Models
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.kquickcontrolsaddons
import org.kde.koko as Koko
import org.kde.koko.private

Kirigami.ScrollablePage {
    id: root

    property Rectangle rubberBand: null
    property alias model: gridView.model
    property bool isFolderView: false
    property bool isTrashView: gridView.url.toString().startsWith("trash:")
    required property Koko.PhotosApplication application
    required property Kirigami.ApplicationWindow mainWindow

    property bool bookmarked: isFolderView && Koko.Config.savedFolders.includes(model.sourceModel.url.toString().replace("file:///", "file:/"))
    property var backUrls: [];
    property var backUrlsPosition: 0;

    property alias gridViewItem: gridView
    property int previouslySelectedItemIndex: -1

    signal collectionSelected(QtObject selectedModel, string cover)
    signal folderSelected(QtObject selectedModel, string cover, string path)

    readonly property Component normalTitleComponent: Kirigami.Heading {
         Layout.fillWidth: true
         Layout.maximumWidth: implicitWidth + 1 // The +1 is to make sure we do not trigger eliding at max width
         Layout.minimumWidth: 0

         opacity: root.isCurrentPage ? 1 : 0.4
         maximumLineCount: 1
         elide: Text.ElideRight
         text: root.title
     }

    focus: true
    titleDelegate: !Kirigami.Settings.isMobile && isFolderView ? folderTitleComponent : normalTitleComponent
    title: i18nc("@title", "Folders")
 
    // doesn't work without loader
    header: Loader {
        height: active ? implicitHeight : 0 // fix issue where space is being reserved even if not active
        active: root.mainWindow.wideScreen && Kirigami.Settings.isMobile
        sourceComponent: mobileHeader
    }

    footer: Loader {
        height: active ? implicitHeight : 0 // fix issue where space is being reserved even if not active
        active: !root.mainWindow.wideScreen && Kirigami.Settings.isMobile
        sourceComponent: mobileHeader 
    }

    function isDrag(fromX, fromY, toX, toY) {
        const length = Math.abs(fromX - toX) + Math.abs(fromY - toY);
        return length >= Qt.styleHints.startDragDistance;
    }

    Component {
        id: mobileHeader
        Rectangle {
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor

            visible: root.isFolderView
            height: visible ? implicitHeight : 0

            implicitHeight: column.implicitHeight

            ColumnLayout {
                id: column
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right
                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: !root.mainWindow.wideScreen
                }
                Loader { 
                    active: Kirigami.Settings.isMobile && root.isFolderView; sourceComponent: folderTitleComponent
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: root.mainWindow.wideScreen ? 0 : Kirigami.Units.smallSpacing
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: root.mainWindow.wideScreen
                }
            }
        }
    }

    Component {
        id: folderTitleComponent

        RowLayout {
            id: folderLayout
            visible: root.isFolderView
            Controls.ToolButton {
                id: backButton
                visible: root.mainWindow.wideScreen
                Layout.maximumWidth: height
                Layout.leftMargin: (Kirigami.Settings.isMobile || !root.mainWindow.wideScreen && root.mainWindow.globalDrawer) ? 0 : -Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                
                icon.name: (LayoutMirroring.enabled ? "go-previous-symbolic-rtl" : "go-previous-symbolic")
                enabled: root.backUrlsPosition > 0
                onClicked: {
                    root.backUrlsPosition--;
                    model.sourceModel.url = root.backUrls[root.backUrlsPosition];
                }
            }

            Controls.ToolButton {
                implicitHeight: Kirigami.Units.gridUnit * 2
                implicitWidth: Kirigami.Units.gridUnit * 2
                visible: root.mainWindow.wideScreen
                icon.name: (LayoutMirroring.enabled ? "go-next-symbolic-rtl" : "go-next-symbolic")
                enabled: root.backUrls.length < root.backUrlsPosition
                onClicked: {
                    root.backUrlsPosition++;
                    model.sourceModel.url = root.backUrls[root.backUrlsPosition];
                }
            }

            Controls.ScrollView {
                id: scrollView

                clip: true

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: Kirigami.Settings.isMobile ? -1 : folderRow.implicitWidth + 1

                Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
                Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AlwaysOff
                
                RowLayout {
                    id: folderRow
                    spacing: 0

                    Controls.ToolButton {
                        implicitHeight: Kirigami.Units.gridUnit * 2
                        implicitWidth: Kirigami.Units.gridUnit * 2
                        property bool canBeSimplified: root.isFolderView && Koko.DirModelUtils.inHome(root.model.sourceModel.url)
                        icon.name: canBeSimplified ? "go-home" : "folder-root-symbolic"
                        DragHandler {
                            enabled: scrollView.contentWidth > scrollView.width
                            yAxis.enabled: false
                            xAxis.enabled: false
                        }
                        onClicked: {
                            const tmp = root.backUrls;
                            while (root.backUrlsPosition < root.backUrls.length) {
                                tmp.pop();
                            }
                            tmp.push(root.model.sourceModel.url);
                            root.backUrlsPosition++;
                            root.backUrls = tmp;
                            if (canBeSimplified) {
                                model.sourceModel.url = "file:///" + Koko.DirModelUtils.home;
                            } else {
                                model.sourceModel.url = "file:///";
                            }
                        }
                    }
                    Kirigami.Icon {
                        visible: root.model.sourceModel.url.toString() !== "file:///"
                        source: LayoutMirroring.enabled ? "arrow-left" : "arrow-right"
                        // adds visual balance
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.preferredWidth: visible ? Kirigami.Units.iconSizes.small : 0
                        height: width
                    }
                    Repeater {
                        id: repeater
                        model: root.isFolderView ? Koko.DirModelUtils.getUrlParts(root.model.sourceModel.url) : 0
                        Row {
                            DragHandler {
                                enabled: scrollView.contentWidth > scrollView.width
                                yAxis.enabled: false
                                xAxis.enabled: false
                            }
                            Controls.ToolButton {
                                height: Kirigami.Units.gridUnit * 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                onClicked: {
                                    const nextUrl = Koko.DirModelUtils.partialUrlForIndex(root.model.sourceModel.url, index + 1);

                                    if (String(nextUrl) === root.model.sourceModel.url + "/") {
                                        return;
                                    }
                                    const tmp = root.backUrls;
                                    while (root.backUrlsPosition < root.backUrls.length) {
                                        tmp.pop();
                                    }
                                    root.backUrlsPosition++;
                                    tmp.push(root.model.sourceModel.url);
                                    root.backUrls = tmp;
                                    root.model.sourceModel.url = nextUrl;
                                }
                            }
                            Kirigami.Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index != repeater.model.length - 1
                                source: LayoutMirroring.enabled ? "arrow-left" : "arrow-right"
                                width: height
                                height: visible ? Kirigami.Units.iconSizes.small : 0
                            }
                        }
                    }
                }
            }
            
            // bookmark button for footer
            Controls.ToolButton {
                implicitHeight: Kirigami.Units.gridUnit * 2
                display: root.mainWindow.wideScreen ? Controls.AbstractButton.TextBesideIcon : Controls.AbstractButton.IconOnly
                icon.name: root.bookmarked ? "bookmark-remove" : "bookmark-add-folder"
                text: root.bookmarked ? i18n("Remove Bookmark") : i18nc("@action:button Bookmarks the current folder", "Bookmark Folder")
                visible: Kirigami.Settings.isMobile && bookmarkActionVisible
                onClicked: {
                    if (root.model.sourceModel.url == undefined) {
                        return
                    }
                    if (root.bookmarked) {
                        const index = Koko.Config.savedFolders.indexOf(model.sourceModel.url.toString().replace("file:///", "file:/"));
                        if (index !== -1) {
                            Koko.Config.savedFolders.splice(index, 1);
                            Koko.Config.save();
                        }
                    } else {
                        Koko.Config.savedFolders.push(model.sourceModel.url.toString().replace("file:///", "file:/"));
                        Koko.Config.save();
                    }
                }
            }
        }
    }

    property bool bookmarkActionVisible: root.isFolderView && !itemSelectionModel.hasSelection
        && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.pictures)
        && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.videos)

    actions: [
        Kirigami.Action {
            id: bookmarkAction
            icon.name: root.bookmarked ? "bookmark-remove" : "bookmark-add-folder"
            text: root.bookmarked ? i18n("Remove Bookmark") : i18nc("@action:button Bookmarks the current folder", "Bookmark Folder")
            visible: !Kirigami.Settings.isMobile && root.isFolderView && !itemSelectionModel.hasSelection
                && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.pictures)
                && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.videos)
            displayHint: Kirigami.DisplayHint.IconOnly
            onTriggered: {
                if (root.model.sourceModel.url == undefined) {
                    return
                }
                if (root.bookmarked) {
                    const index = Koko.Config.savedFolders.indexOf(model.sourceModel.url.toString().replace("file:///", "file:/"));
                    if (index !== -1) {
                        Koko.Config.savedFolders.splice(index, 1);
                        Koko.Config.save();
                    }
                } else {
                    Koko.Config.savedFolders.push(model.sourceModel.url.toString().replace("file:///", "file:/"));
                    Koko.Config.save();
                }
            }

        },
        Kirigami.Action {
            id: goUpAction
            icon.name: "go-up"
            text: i18n("Go Up")
            visible: root.isFolderView && Kirigami.Settings.isMobile
            onTriggered: {
                const tmp = root.backUrls;
                while (root.backUrlsPosition < root.backUrls.length) {
                    tmp.pop();
                }
                tmp.push(root.model.sourceModel.url);
                root.backUrlsPosition++;
                root.backUrls = tmp;
                var str = String(model.sourceModel.url).split("/")
                str.pop()
                if (str.join("/") == "file://") {
                    model.sourceModel.url = "file:///"
                } else {
                    model.sourceModel.url = str.join("/")
                }
            }
        },
        Kirigami.Action {
            visible: root.isFolderView && Kirigami.Settings.isMobile
            property bool canBeSimplified: root.isFolderView && Koko.DirModelUtils.canBeSimplified(root.model.sourceModel.url)
            icon.name: canBeSimplified ? "go-home" : "folder-root-symbolic"
            text: canBeSimplified ? i18n("Home") : i18n("Root")
            onTriggered: {
                const tmp = root.backUrls;
                while (root.backUrlsPosition < root.backUrls.length) {
                    tmp.pop();
                }
                tmp.push(root.model.sourceModel.url);
                root.backUrlsPosition++;
                root.backUrls = tmp;
                if (canBeSimplified) {
                    model.sourceModel.url = "file:///" + Koko.DirModelUtils.home;
                } else {
                    model.sourceModel.url = "file:///";
                }
            }
        },
        ShareAction {
            id: shareAction
            visible: itemSelectionModel.hasSelection

            tooltip: i18nc("@info:tooltip", "Share the selected media")
        },
        Kirigami.Action {
            fromQAction: root.application.action("movetotrash")
        },
        Kirigami.Action {
            fromQAction: root.application.action("photos_restore")
        },
        Kirigami.Action {
            icon.name: "edit-select-all"
            text: i18n("Select All")
            tooltip: i18n("Selects all the media in the current view")
            visible: model.containImages
            onTriggered: {
                for (let i = 0, count = itemSelectionModel.model.rowCount(); i < count; i++) {
                    const index = itemSelectionModel.model.index(i, 0);
                    const isImage = index.data(Koko.AbstractImageModel.ItemTypeRole) === Koko.AbstractImageModel.Image;
                    if (isImage) {
                        itemSelectionModel.select(index, ItemSelectionModel.Select);
                    }
                }
            }
        },
        Kirigami.Action {
            icon.name: "edit-select-none"
            text: i18n("Deselect All")
            tooltip: i18n("De-selects all the selected media")
            onTriggered: itemSelectionModel.clear()
            visible: itemSelectionModel.hasSelection
        }
    ]

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Escape:
                itemSelectionModel.clear()
                break;
            default:
                break;
        }
    }

    ItemSelectionModel {
        id: itemSelectionModel

        model: gridView.model.sourceModel

        onSelectedIndexesChanged: updateShareAction()
        onCurrentIndexChanged: updateShareAction()

        function updateShareAction(): void {
            const urls = [];
            const mimeType = [];

            for (let index of itemSelectionModel.selectedIndexes) {
                urls.push(index.data(Koko.AbstractImageModel.ImageUrlRole));
                const mime = index.data(Koko.AbstractImageModel.MimeTypeRole);
                if (!mimeType.includes(mime)) {
                    mimeType.push(mime);
                }
            }

            const url = currentIndex.data(Koko.AbstractImageModel.ImageUrlRole);
            if (!urls.includes(url)) {
                urls.push(url);
                const mime = currentIndex.data(Koko.AbstractImageModel.MimeTypeRole);
                if (!mimeType.includes(mime)) {
                    mimeType.push(mime);
                }
            }

            shareAction.inputData = { urls, mimeType };
        }
    }

    PhotoListActions {
        id: photoListActions

        selectionModel: itemSelectionModel
        photosApplication: root.application
        isTrashView: root.isTrashView

        onEditRequested: (imagePath) => {
            const page = root.mainWindow.pageStack.layers.push(Qt.resolvedUrl("EditorView.qml"), {
                imagePath,
                // Without this, there's an odd glitch where the root will show for a brief moment
                // before the show animation runs.
                visible: false
            })
            page.imageEdited.connect(() => {
                // TODO
            });
        }
    }

    Component {
        id: imageContextMenu

        Components.ConvergentContextMenu {
            Kirigami.Action {
                icon.name: 'quickview-symbolic'
                text: i18nc("@action:inmenu", "View")
                visible: itemSelectionModel.selectedIndexes.length === 1
                onTriggered: {
                    const startIndex = gridView.model.mapFromSource(itemSelectionModel.currentIndex);
                    root.mainWindow.pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                        startIndex,
                        imagesModel: root.model,
                        application: root.application,
                        mainWindow: root.mainWindow,
                    })
                }
            }

            Kirigami.Action {
                fromQAction: root.application.action('movetotrash')
            }

            Kirigami.Action {
                fromQAction: root.application.action('photos_restore')
            }

            Kirigami.Action {
                fromQAction: root.application.action('photos_edit')
            }

            ShareAction {
                inputData: {
                    'urls': shareAction.inputData.urls,
                    'mimeType': shareAction.inputData.mimeType
                }
            }
        }
    }

    GridView {
        id: gridView

        property bool ctrlPressed: false
        property bool shiftPressed: false
        property Item hoveredItem: null
        readonly property real widthToApproximate: (root.mainWindow.wideScreen ? root.mainWindow.pageStack.defaultColumnWidth : root.width) - (1||Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)
        readonly property string url: model.sourceModel.url ? model.sourceModel.url : ""
        readonly property double columns: Math.max(Math.floor(gridView.width / Koko.Config.iconSize), 2);
        property var cachedRectangleSelection: null

        cellWidth: Math.floor(gridView.width / columns)

        cellHeight: cellWidth

        highlightMoveDuration: 0
        keyNavigationEnabled: true
        focus: true
        reuseItems: true

        // always clean selection
        onUrlChanged: itemSelectionModel.clear()

        // Instantiate delegates to fill height * 2 above and below
        cacheBuffer: height * 2

        // Prioritise thumbnailing delegates in order, with off-screen delegates prioritised sequentially
        function calculateThumbnailPriority(delegate: Item): int {
            let column = Math.floor(delegate.x / gridView.cellWidth);
            let row = Math.ceil((delegate.y - gridView.contentY + gridView.cellHeight) / gridView.cellHeight) - 1;
            let columnCount = Math.floor(gridView.width / gridView.cellWidth);

            let firstVisibleRow = 0;
            let lastVisibleRow = Math.ceil((gridView.height + gridView.cellHeight) / gridView.cellHeight) - 1;

            if (Qt.application.layoutDirection === Qt.RightToLeft) {
                // Reverse column order in RTL
                column = columnCount - 1 - column;
            }

            if (row < firstVisibleRow) {
                // Delegate is off-screen above, so match priority
                // with rows below in reverse column order
                row = lastVisibleRow - row - 1;
                column = columnCount - 1 - column;
            }

            return row * columnCount + column;
        }

        onCachedRectangleSelectionChanged: {
            if (cachedRectangleSelection === null) {
                return;
            }

            if (!gridView.ctrlPressed) {
                itemSelectionModel.clear();
            }

            for (let index of cachedRectangleSelection) {
                const sourceIndex = gridView.model.mapToSource(gridView.model.index(index, 0));
                itemSelectionModel.select(sourceIndex, ItemSelectionModel.Select);
            }
        }

        function rectangleSelect(x: int, y: int, width: int, height: int, rubberBand: Rectangle): void {
            const indexes = [];
            for (let i = x; i < x + width; i += gridView.cellWidth) {
                for (let j = y; j < y + height; j += gridView.cellHeight) {
                    let index = gridView.indexAt(i, j);
                    if (index >= 0 && !indexes.includes(index)) {
                        indexes.push(index);
                    }

                    index = gridView.indexAt(x + width, j);
                    if (index >= 0 && !indexes.includes(index)) {
                        indexes.push(index);
                    }
                }

                const index = gridView.indexAt(i, y + height);
                if (index >= 0 && !indexes.includes(index)) {
                    indexes.push(index);
                }
            }
            gridView.cachedRectangleSelection = indexes;
        }

        onCurrentIndexChanged: if (currentIndex >= 0) {
            const sourceIndex = gridView.model.mapToSource(gridView.model.index(currentIndex, 0));
            itemSelectionModel.setCurrentIndex(sourceIndex, ItemSelectionModel.Current);
            photoListActions.setActionState();
        } else {
            const sourceIndex = gridView.model.mapToSource(gridView.model.index(currentIndex, 0));
            itemSelectionModel.setCurrentIndex(sourceIndex, ItemSelectionModel.Clear);
        }

        delegate: DelegateChooser {
            role: "itemType"

            DelegateChoice {
                roleValue: Koko.AbstractImageModel.Image

                AlbumDelegate {
                    id: delegate

                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    thumbnailPriority: gridView.calculateThumbnailPriority(delegate)

                    selectionModel: itemSelectionModel
                    selected: selectionModel.selectedIndexes.includes(gridView.model.mapToSource(gridView.model.index(index, 0)))

                    highlighted: gridView.currentIndex === index

                    Controls.ToolTip.text: Koko.DirModelUtils.fileNameOfUrl(delegate.imageurl)
                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

                    GridView.onPooled: {
                        thumbnailPriority = -1;
                    }
                    GridView.onReused: {
                        thumbnailPriority = Qt.binding(() => gridView.calculateThumbnailPriority(delegate));
                    }

                    onClicked: if (itemSelectionModel.hasSelection) {
                        const sourceIndex = gridView.model.mapToSource(gridView.model.index(index, 0));
                        itemSelectionModel.select(sourceIndex, ItemSelectionModel.Toggle);
                    } else {
                        gridView.currentIndex = delegate.index;
                        const sourceIndex = gridView.model.mapToSource(gridView.model.index(index, 0));
                        itemSelectionModel.setCurrentIndex(sourceIndex, ItemSelectionModel.Current);
                        photoListActions.setActionState();

                        if (root.isTrashView) {
                            return;
                        }
                        root.mainWindow.pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                            startIndex: root.model.index(gridView.currentIndex, 0),
                            imagesModel: root.model,
                            application: root.application,
                            mainWindow: root.mainWindow,
                        })
                    }

                    onPressAndHold: {
                        const sourceIndex = gridView.model.mapToSource(gridView.model.index(index, 0));
                        itemSelectionModel.select(sourceIndex, ItemSelectionModel.Toggle);
                    }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            if (!itemSelectionModel.hasSelection) {
                                gridView.currentIndex = delegate.index;
                                const sourceIndex = gridView.model.mapToSource(gridView.model.index(delegate.index, 0));
                                itemSelectionModel.setCurrentIndex(sourceIndex, ItemSelectionModel.Current);
                            }

                            photoListActions.setActionState();

                            imageContextMenu.createObject(root.Controls.Overlay.overlay).popup();
                        }
                    }
                }
            }

            DelegateChoice {
                roleValue: Koko.AbstractImageModel.Folder

                FolderDelegate {
                    id: delegate

                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    highlighted: gridView.currentIndex == index

                    thumbnailPriority: gridView.calculateThumbnailPriority(delegate)

                    GridView.onPooled: {
                        thumbnailPriority = -1;
                    }
                    GridView.onReused: {
                        thumbnailPriority = Qt.binding(() => gridView.calculateThumbnailPriority(delegate));
                    }

                    onClicked: {
                        if (!root.isFolderView) {
                            imageFolderModel.url = delegate.imageurl
                            sortedListModel.sourceModel = imageFolderModel
                            folderSelected(sortedListModel, delegate.content, delegate.imageurl)
                            return
                        }
                        const tmp = root.backUrls;
                        while (root.backUrlsPosition < root.backUrls.length) {
                            tmp.pop();
                        }
                        tmp.push(root.model.sourceModel.url);
                        root.backUrls = tmp;
                        root.backUrlsPosition++;
                        root.model.sourceModel.url = delegate.imageurl;
                    }
                }
            }

            DelegateChoice {
                roleValue: Koko.AbstractImageModel.Album

                CollectionDelegate {
                    id: delegate

                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    highlighted: gridView.currentIndex == index

                    onClicked: {
                        const sourceIndex = gridView.model.mapToSource(gridView.model.index(delegate.index, 0));
                        imageListModel.query = imageListModel.queryForIndex(sourceIndex.row)
                        sortedListModel.sourceModel = imageListModel
                        collectionSelected(sortedListModel, delegate.content)
                    }
                }
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No Media Found")
            visible: gridView.count === 0
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
        }

        //FIXME: right now if those two objects are out of this, the whole root breaks
        Koko.SortModel {
            id: sortedListModel
        }
        Koko.ImageFolderModel {
            id: imageFolderModel
        }

        MouseEventListener {
            id: listener

            property alias hoveredItem: gridView.hoveredItem

            property Item pressedItem: null
            property int pressX: -1
            property int pressY: -1
            property int dragX: -1
            property int dragY: -1
            property var cPress: null
            property bool doubleClickInProgress: false
            property bool renameByLabelClickInitiated: false

            anchors.fill: parent

            acceptedButtons: Qt.LeftButton

            hoverEnabled: true

            onPressXChanged: {
                cPress = mapToItem(gridView.contentItem, pressX, pressY);
            }

            onPressYChanged: {
                cPress = mapToItem(gridView.contentItem, pressX, pressY);
            }

            onPressed: mouse => {
                var index = gridView.indexAt(mouse.x, mouse.y);
                var indexItem = gridView.itemAtIndex(index);

                if (indexItem) { // update position in case of touch or untriggered hover
                    gridView.currentIndex = index;
                    hoveredItem = indexItem;
                } else {
                    gridView.currentIndex = -1
                    hoveredItem = null;
                }

                if (mouse.source === Qt.MouseEventSynthesizedByQt) {
                    if (gridView.hoveredItem && gridView.hoveredItem.toolTip.active) {
                        gridView.hoveredItem.toolTip.hideToolTip();
                    }
                }

                pressX = mouse.x;
                pressY = mouse.y;

                if (!hoveredItem) {
                    if (!gridView.ctrlPressed) {
                        gridView.currentIndex = -1;
                        root.previouslySelectedItemIndex = -1;
                        itemSelectionModel.clear();
                    }

                    if (mouse.buttons & Qt.RightButton) {
                        clearPressState();

                        // If it's the desktop, fall through to the desktop context menu plugin
                        imageContextMenu.createObject(root.Controls.Overlay.overlay).popup();
                        mouse.accepted = true;
                    }
                } else {
                    pressedItem = hoveredItem;

                    var pos = mapToItem(hoveredItem.actionsOverlay, mouse.x, mouse.y);

                    if (!(pos.x <= hoveredItem.actionsOverlay.width && pos.y <= hoveredItem.actionsOverlay.height)) {
                        if (gridView.shiftPressed && gridView.currentIndex !== -1) {
                            positioner.setRangeSelected(gridView.anchorIndex, hoveredItem.index);
                        } else {
                            // Deselecting everything else when one item is clicked is handled in onReleased in order to distinguish between drag and click
                            if (!gridView.ctrlPressed && !dir.isSelected(positioner.map(hoveredItem.index))) {
                                root.previouslySelectedItemIndex = -1;
                                itemSelectionModel.clear();
                            }

                            if (gridView.ctrlPressed) {
                                dir.toggleSelected(positioner.map(hoveredItem.index));
                            } else {
                                dir.setSelected(positioner.map(hoveredItem.index));
                            }
                        }

                        gridView.currentIndex = hoveredItem.index;

                        if (mouse.buttons & Qt.RightButton) {
                            if (pressedItem.toolTip && pressedItem.toolTip.active) {
                                pressedItem.toolTip.hideToolTip();
                            }

                            clearPressState();

                            imageContextMenu.createObject(root.Controls.Overlay.overlay).popup();
                            mouse.accepted = true;
                        }
                    }
                }
            }

            function pressCanceled(): void {
                if (root.rubberBand) {
                    root.rubberBand.close();
                    root.rubberBand = null;

                    gridView.interactive = true;
                    gridView.cachedRectangleSelection = null;
                }

                clearPressState();
            }

            function clearPressState(): void {
                pressedItem = null;
                pressX = -1;
                pressY = -1;
            }

            onCanceled: pressCanceled()
            onReleased: pressCanceled();

            onClicked: mouse => {
                clearPressState();

                if (mouse.button === Qt.RightButton) {
                    return;
                }

                let pos = mapToItem(hoveredItem, mouse.x, mouse.y);

                // Moving from an item to its preview popup dialog doesn't unset hoveredItem
                // even though the cursor has left it, so we need to check whether the click
                // actually occurred inside the item we expect it in before going ahead. If it
                // didn't, clean up (e.g. dismissing the dialog as a side-effect of unsetting
                // hoveredItem) and abort.
                if (pos.x < 0 || pos.x > hoveredItem.width || pos.y < 0 || pos.y > hoveredItem.height) {
                    hoveredItem = null;
                    previouslySelectedItemIndex = -1;
                    itemSelectionModel.clear();

                    return;
                }
            }

            onPositionChanged: mouse => {
                gridView.ctrlPressed = (mouse.modifiers & Qt.ControlModifier);
                gridView.shiftPressed = (mouse.modifiers & Qt.ShiftModifier);

                const mappedPos = mapToItem(gridView.contentItem, mouse.x, mouse.y)
                var item = gridView.itemAt(mappedPos.x, mappedPos.y);
                var leftEdge = Math.min(gridView.contentX, gridView.originX);

                if (!item || gridView.hoveredItem && !root.containsDrag) {
                    gridView.hoveredItem = null;
                } else {
                    var fPos = mapToItem(item, mouse.x, mouse.y);

                    if (fPos.x < 0 || fPos.y < 0 || fPos.x > item.width || fPos.y > item.height) {
                        gridView.hoveredItem = null;
                    }
                }

                // Update rubberband geometry.
                if (root.rubberBand) {
                    var rB = root.rubberBand;
                    var cPos = mapToItem(gridView.contentItem, mouse.x, mouse.y);

                    if (cPos.x < cPress.x) {
                        rB.x = Math.max(leftEdge, cPos.x);
                        rB.width = Math.abs(rB.x - cPress.x);
                    } else {
                        rB.x = cPress.x;
                        var ceil = Math.max(gridView.width, gridView.contentItem.width) + leftEdge;
                        rB.width = Math.min(ceil - rB.x, Math.abs(rB.x - cPos.x));
                    }

                    if (cPos.y < cPress.y) {
                        rB.y = Math.max(0, cPos.y);
                        rB.height = Math.abs(rB.y - cPress.y);
                    } else {
                        rB.y = cPress.y;
                        var ceil = Math.max(gridView.height, gridView.contentItem.height);
                        rB.height = Math.min(ceil - rB.y, Math.abs(rB.y - cPos.y));
                    }

                    // Ensure rubberband is at least 1px in size or else it will become
                    // invisible and not match any items.
                    rB.width = Math.max(1, rB.width);
                    rB.height = Math.max(1, rB.height);

                    Qt.callLater(gridView.rectangleSelect, rB.x, rB.y, rB.width, rB.height, root.rubberBand);

                    return;
                }

                // Drag initiation.
                if (pressX !== -1 && root.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                    root.rubberBand = rubberBandObject.createObject(gridView.contentItem, {x: cPress.x, y: cPress.y});
                    gridView.interactive = false;
                }
            }

            Component {
                id: rubberBandObject

                Rectangle {
                    id: rubberBand

                    width: 0
                    height: 0
                    z: 99999

                    radius: Kirigami.Units.cornerRadius
                    border {
                        color: Kirigami.Theme.highlightColor
                        width: 1
                    }

                    color: {
                        const background = Kirigami.Theme.highlightColor;
                        return Qt.hsla(background.hslHue, background.hslSaturation, background.hslLightness, 0.2);
                    }

                    function close(): void {
                        opacityAnimation.restart();
                    }

                    OpacityAnimator {
                        id: opacityAnimation
                        target: rubberBand
                        to: 0
                        from: 1
                        duration: Kirigami.Units.shortDuration

                        // This easing curve has an elognated start, which works
                        // better than a standard easing curve for the rubberband
                        // animation, which fades out fast and is generally of a
                        // small area.
                        easing {
                            bezierCurve: [0.4, 0.0, 1, 1]
                            type: Easing.Bezier
                        }

                        onFinished: {
                            rubberBand.visible = false;
                            rubberBand.enabled = false;
                            // We need to explicitly generate an image here
                            // to make sure we have one before we start dragging
                            //main.generateDragImage();
                            rubberBand.destroy();
                        }
                    }
                }
            }
        }
    }

    onCollectionSelected: pageStack.push(Qt.resolvedUrl("AlbumView.qml"), {
        model: selectedModel,
        title: cover,
        mainWindow: root.mainWindow,
        application: root.application,
    })

    onFolderSelected: pageStack.push(Qt.resolvedUrl("AlbumView.qml"), {
        model: selectedModel,
        title: cover,
        url: path,
        mainWindow: root.mainWindow,
        application: root.application,
    })
}
