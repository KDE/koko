/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQml.Models

import org.kde.kirigami as Kirigami

import org.kde.koko as Koko

Kirigami.ScrollablePage {
    id: page

    required property Koko.PhotosApplication application
    required property Kirigami.ApplicationWindow mainWindow
    required property Koko.AbstractGalleryModel galleryModel

    readonly property Item gridViewItem: gridView

    readonly property bool isEmpty: gridView.count === 0
    readonly property bool isFolderView: galleryModel instanceof Koko.GalleryFolderModel
    readonly property bool isTrashView: isFolderView && galleryModel.path.toString().startsWith("trash:")
    readonly property bool isBookmarked: isFolderView && Koko.Config.savedFolders.includes(galleryModel.path.toString().replace("file:///", "file:/"))

    readonly property bool canBookmark: isFolderView
                                        && !isTrashView
                                        && galleryModel.path.toString() !== ("file://" + Koko.DirModelUtils.pictures)
                                        && galleryModel.path.toString() !== ("file://" + Koko.DirModelUtils.videos)

    readonly property bool canNavigate: galleryModel instanceof Koko.AbstractNavigableGalleryModel
    readonly property bool canNavigateBackward: canNavigate && navigationIndex > 0
    readonly property bool canNavigateForward: canNavigate && navigationIndex < (navigationHistory.length - 1)

    property list<var> navigationHistory: []
    property int navigationIndex: -1

    property bool selectionMode: selectionModel.hasSelection
    property bool suppressVisibleSelectionMode: false

    Component.onCompleted: {
        if (page.canNavigate) {
            page.navigationHistory = [page.galleryModel.path];
            page.navigationIndex = 0;
        }
    }

    function navigateBackward() : void {
        if (!page.canNavigate) {
            return;
        }

        if (page.navigationIndex <= 0) {
            return;
        }

        page.galleryModel.path = page.navigationHistory[--page.navigationIndex];
    }

    function navigateForward() : void {
        if (!page.canNavigate) {
            return;
        }

        if (page.navigationIndex >= (page.navigationHistory.length - 1)) {
            return;
        }

        page.galleryModel.path = page.navigationHistory[++page.navigationIndex];
    }

    function navigate(path, preserveHistory = true) : void {
        if (!page.canNavigate) {
            return;
        }

        if (page.galleryModel.path == path) {
            return;
        }

        if (preserveHistory) {
            let newHistory = page.navigationHistory.slice(0, ++page.navigationIndex);
            newHistory[page.navigationIndex] = path;
            page.navigationHistory = newHistory;
        } else {
            page.navigationHistory = [path];
            page.navigationIndex = 0;
        }

        page.galleryModel.path = path;
    }

    // TODO: For performance reasons, selection operations need to be disabled if they need to process and store a massive number
    // of items. In the future, we could mitigate this with a custom selection model which switches to storing unselected indexes
    // when 'Select All' is used, and back on 'Deselect All'. It could be a wrapper around QItemSelectionModel with a leaner API,
    // as we only need select all, deselect all, invert, hasSelection and selectedIndexes, all in column 0.
    readonly property int disallowMassSelection: gridView.count > 1000

    property int pendingMediaViewIndex: -1;

    function openMediaViewPage(url) {
        if (page.isTrashView) {
            return;
        }

        const mediaViewPage = page.mainWindow.pageStack.layers.push(Qt.resolvedUrl("MediaViewPage.qml"), {
            application: page.application,
            mainWindow: page.mainWindow,
            gallerySortFilterProxyModel: gallerySortFilterProxyModel,
            url: url
        });

        mediaViewPage.currentIndexChanged.connect((index) => {
            page.pendingMediaViewIndex = index;
        });
    }

    Connections {
        target: gridView
        function onVisibleChanged() {
            if (gridView.visible && pendingMediaViewIndex !== -1) {
                const index = page.pendingMediaViewIndex;
                page.pendingMediaViewIndex = -1;

                // HACK: We have had to defer this until the page is visible because otherwise it
                // doesn't work. For some reason, we still need to defer it just a little more:
                Qt.callLater(() => {
                    gridView.currentIndex = index;
                    gridView.positionViewAtIndex(index, GridView.Contain);
                });
            }
        }
    }

    Controls.ActionGroup {
        id: sortGroup
        exclusive: true
    }

    Controls.ActionGroup {
        id: sortReversedGroup
        exclusive: true
    }

    readonly property list<QtObject> toolBarActions: [
        // Selection
        Kirigami.Action {
            id: restoreTrashAction
            icon.name: "edit-reset-symbolic"
            text: i18nc("@action:button Restore the selected media from the trash", "Restore")
            tooltip: i18nc("@info:tooltip", "Restore the selected media to their former locations")
            enabled: selectionModel.hasSelection && page.isTrashView
            visible: selectionModel.hasSelection && page.isTrashView
            onTriggered: {
                let urls = [];
                selectionModel.selectedIndexes.forEach(index => {
                    urls.push(selectionModel.model.data(index, AbstractGalleryModel.UrlRole));
                });

                Koko.DirModelUtils.restoreUrls(urls);
            }
        },

        // Sort/filter
        Kirigami.Action {
            separator: true
            visible: restoreTrashAction.visible
        },
        Kirigami.Action {
            text: i18nc("@action:button %1 is the selected sort order, e.g. Name", "Sort: %1", sortGroup.checkedAction.text)
            icon.name: "view-sort-symbolic"

            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Name")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Name
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Name
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Size")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Size
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Size
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Modified")
                tooltip: i18nc("@info:tooltip An order to sort media items", "Date Modified")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Modified
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Modified
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Created")
                tooltip: i18nc("@info:tooltip An order to sort media items", "Date Created")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Created
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Created
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Accessed")
                tooltip: i18nc("@info:tooltip An order to sort media items", "Date Accessed")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Accessed
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Accessed
            }
            Kirigami.Action {
                separator: true
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortReversedGroup
                text: {
                    switch (gallerySortFilterProxyModel.sortMode) {
                        default:
                            return i18nc("@action:inmenu Sort media items in ascending order", "Ascending")
                        case Koko.GallerySortFilterProxyModel.Name:
                            return i18nc("@action:inmenu Sort media items by name in ascending order", "A-Z")
                        case Koko.GallerySortFilterProxyModel.Size:
                            return i18nc("@action:inmenu Sort media items by size in ascending order", "Smallest First")
                        case Koko.GallerySortFilterProxyModel.Modified:
                        case Koko.GallerySortFilterProxyModel.Created:
                        case Koko.GallerySortFilterProxyModel.Accessed:
                            return i18nc("@action:inmenu Sort media items by date in ascending order", "Oldest First")
                    }
                }
                tooltip: i18nc("@info:tooltip Sort media items in ascending order", "Ascending")
                checkable: true
                checked: gallerySortFilterProxyModel.sortReversed === false
                onTriggered: gallerySortFilterProxyModel.sortReversed = false

            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortReversedGroup
                text: {
                    switch (gallerySortFilterProxyModel.sortMode) {
                        default:
                            return i18nc("@action:inmenu Sort media items in descending order", "Descending")
                        case Koko.GallerySortFilterProxyModel.Name:
                            return i18nc("@action:inmenu Sort media items by name in descending order", "Z-A")
                        case Koko.GallerySortFilterProxyModel.Size:
                            return i18nc("@action:inmenu Sort media items by size in descending order", "Largest First")
                        case Koko.GallerySortFilterProxyModel.Modified:
                        case Koko.GallerySortFilterProxyModel.Created:
                        case Koko.GallerySortFilterProxyModel.Accessed:
                            return i18nc("@action:inmenu Sort media items by date in descending order", "Newest First")
                    }
                }
                tooltip: i18nc("@info:tooltip Sort media items in descending order", "Descending")
                checkable: true
                checked: gallerySortFilterProxyModel.sortReversed === true
                onTriggered: gallerySortFilterProxyModel.sortReversed = true

            }
        },
        Kirigami.Action {
            displayComponent: Kirigami.SearchField {
                width: Kirigami.Units.gridUnit * 10
                onAccepted: gallerySortFilterProxyModel.filterString = text
            }
        },

        // Bookmark
        Kirigami.Action {
            separator: true
            visible: bookmarkAction.visible
        },
        Kirigami.Action {
            id: bookmarkAction
            icon.name: "bookmark-toolbar-symbolic"
            text: i18nc("@action:button Bookmark the current folder", "Bookmark Folder")
            tooltip: i18nc("@info:tooltip", "Bookmark the current folder")
            checkable: true
            checked: page.isBookmarked
            enabled: canBookmark
            visible: canBookmark
            displayHint: Kirigami.DisplayHint.IconOnly
            onToggled: {
                if (!(galleryModel instanceof Koko.GalleryFolderModel) || galleryModel.url == undefined) {
                    return;
                }

                if (page.isBookmarked) {
                    const index = Koko.Config.savedFolders.indexOf(galleryModel.url.toString().replace("file:///", "file:/"));
                    if (index !== -1) {
                        Koko.Config.savedFolders.splice(index, 1);
                        Koko.Config.save();
                    }
                } else {
                    Koko.Config.savedFolders.push(galleryModel.url.toString().replace("file:///", "file:/"));
                    Koko.Config.save();
                }
            }
        }
    ]

    Koko.Exiv2Extractor {
        id: exiv2Extractor
        filePath: selectionModel.selectedIndexes.length === 1
                        ? selectionModel.model.data(selectionModel.selectedIndexes[0], AbstractGalleryModel.UrlRole)
                        : ""
    }

    readonly property list<QtObject> extraHiddenUiActions: [
        Kirigami.Action {
            id: favoriteAction
            text: i18nc("@action:intoolbar Favorite an image/video", "Favorite")
            icon.name: exiv2Extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
            tooltip: exiv2Extractor.favorite ? i18nc("@info:tooltip", "Remove from favorites") : i18nc("@info:tooltip", "Add to favorites")
            checkable: true
            checked: exiv2Extractor.favorite
            enabled: selectionModel.selectedIndexes.length === 1
            visible: selectionModel.selectedIndexes.length === 1
            displayHint: Kirigami.DisplayHint.AlwaysHide
            onToggled: {
                exiv2Extractor.toggleFavorite(exiv2Extractor.filePath.toString().replace("file://", ""));
                // makes change immediate
                kokoProcessor.removeFile(exiv2Extractor.filePath.toString().replace("file://", ""));
                kokoProcessor.addFile(exiv2Extractor.filePath.toString().replace("file://", ""));
            }
        },
        ShareAction {
            id: shareAction
            tooltip: i18nc("@info:tooltip", "Share the selected media")
            enabled: selectionModel.hasSelection
            visible: selectionModel.hasSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            application: page.mainWindow

            property Connections connection: Connections {
                target: selectionModel

                function onSelectionChanged() {
                    let urls = [];
                    let mimeTypes = new Set();

                    selectionModel.selectedIndexes.forEach(index => {
                        const url = selectionModel.model.data(index, AbstractGalleryModel.UrlRole);
                        const mimeType = selectionModel.model.data(index, AbstractGalleryModel.MimeTypeRole);

                        if (url) {
                            urls.push(url.toString());
                        }

                        if (mimeType) {
                            mimeTypes.add(mimeType);
                        }
                    });

                    shareAction.inputData = {
                        urls: urls,
                        mimeType: Array.from(mimeTypes)
                    };
                }
            }
        },
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide
            separator: true
            visible: favoriteAction.visible
        }
    ]

    Koko.FileMenuActions {
        id: fileMenuActions
        urls: selectionModel.selectedIndexes.map(index => selectionModel.model.data(index, AbstractGalleryModel.UrlRole))
    }

    readonly property list<QtObject> otherHiddenUiActions: [
        Kirigami.Action {
            displayHint: Kirigami.DisplayHint.AlwaysHide
            separator: true
        },
        Kirigami.Action {
            id: selectAllAction
            icon.name: "edit-select-all-symbolic"
            text: i18nc("@action:button", "Select All")
            tooltip: i18nc("@info:tooltip", "Select all media")
            enabled: !page.isEmpty && !page.disallowMassSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            shortcut: StandardKey.SelectAll
            onTriggered: selectionModel.select(gridView.model.index(0, 0), ItemSelectionModel.Select | ItemSelectionModel.Columns)

        },
        Kirigami.Action {
            id: deselectAllAction
            icon.name: "edit-select-none-symbolic"
            text: i18nc("@action:button", "Select None")
            tooltip: i18nc("@info:tooltip", "Deselect all media")
            enabled: !page.isEmpty && selectionModel.hasSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            shortcut: StandardKey.Deselect
            onTriggered: selectionModel.clearSelection()
        },
        Kirigami.Action {
            id: invertSelectionAction
            icon.name: "edit-select-invert-symbolic"
            text: i18nc("@action:button", "Invert Selection")
            tooltip: i18nc("@info:tooltip", "Invert the selected media")
            enabled: !page.isEmpty && !page.disallowMassSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            onTriggered: selectionModel.select(gridView.model.index(0, 0), ItemSelectionModel.Toggle | ItemSelectionModel.Columns)
        }
    ]

    Component {
        id: kirigamiActionComponent
        Kirigami.Action {}
    }

    actions: {
        let list = [];
        for (let action of toolBarActions) {
            list.push(action);
        }
        /* Hidden actions */
        for (let action of extraHiddenUiActions) {
            list.push(action);
        }
        for (let fileMenuAction of fileMenuActions.actions) {
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

    title: page.galleryModel.title

    Binding {
        target: page
        property: "titleDelegate"
        value: navigatorTitleComponent
        when: !Kirigami.Settings.isMobile && page.canNavigate
        restoreMode: Binding.RestoreBindingOrValue
        // So we can continue to use the default title delegate when wanted
    }

    header: Loader {
        height: active ? implicitHeight : 0
        // On mobile, sharing the navigation with actions takes too much width
        active: Kirigami.Settings.isMobile && page.canNavigate
        sourceComponent: mobileHeader
    }

    Component {
        id: mobileHeader

        Rectangle {
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor

            implicitHeight: mobileHeaderLayout.implicitHeight

            ColumnLayout {
                id: mobileHeaderLayout
                anchors.left: parent.left
                anchors.right: parent.right

                spacing: 0

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: Kirigami.Units.smallSpacing

                    active: true
                    sourceComponent: navigatorTitleComponent
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }
            }
        }
    }

    Component {
        id: navigatorTitleComponent

        NavigatorComponent {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.maximumWidth: implicitWidth

            galleryModel: page.galleryModel
            canNavigateBackward: page.canNavigateBackward
            canNavigateForward: page.canNavigateForward

            onNavigate: (path) => { page.navigate(path); }
            onNavigateBackward: page.navigateBackward()
            onNavigateForward: page.navigateForward()
        }
    }

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Escape:
                selectionModel.clearSelection()
                break;
            default:
                break;
        }
    }

    Koko.GallerySortFilterProxyModel {
        id: gallerySortFilterProxyModel

        sourceModel: page.galleryModel
        sortMode: Koko.GallerySortFilterProxyModel.Name
        sortReversed: false
        filterString: ""
    }

    ItemSelectionModel {
        id: selectionModel
        model: gallerySortFilterProxyModel
    }

    GridView {
        id: gridView

        cellWidth: Math.floor(width / Math.floor(width / (Koko.Config.iconSize + Kirigami.Units.largeSpacing * 2)))
        cellHeight: Koko.Config.iconSize + Kirigami.Units.largeSpacing * 2

        highlightMoveDuration: 0
        keyNavigationEnabled: true
        focus: true
        reuseItems: true

        model: gallerySortFilterProxyModel

        // Prioritise thumbnailing delegates in order, with off-screen delegates prioritised sequentially
        function calculateThumbnailPriority(delegate: Item): int {
            let column = Math.floor(delegate.x / gridView.cellWidth);
            let row = Math.ceil((delegate.y - gridView.contentY + gridView.cellHeight) / gridView.cellHeight) - 1;
            let columnCount = Math.floor(gridView.width / gridView.cellWidth);

            let firstVisibleRow = 0;
            let lastVisibleRow = Math.ceil((gridView.height + gridView.cellHeight) / gridView.cellHeight) - 1;

            if (Application.layoutDirection === Qt.RightToLeft) {
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

        delegate: GalleryDelegate {
            id: delegate

            GridView.onPooled: { thumbnailPriority = -1; }
            GridView.onReused: { thumbnailPriority = Qt.binding(() => gridView.calculateThumbnailPriority(delegate)); }
            thumbnailPriority: gridView.calculateThumbnailPriority(delegate)

            highlighted: gridView.currentIndex == index
            selected: selectionModel.selectedIndexes.includes(gridView.model.index(index, 0))
            selectionMode: page.selectionMode
            suppressVisibleSelectionMode: page.suppressVisibleSelectionMode

            TapHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                onTapped: (eventPoint, button) => {
                    if (button === Qt.RightButton) {
                        delegate.showMenu();
                    } else if (button === Qt.LeftButton) {
                        if (point.modifiers & Qt.ShiftModifier) {
                            delegate.shiftSelect();
                        } else if (point.modifiers & Qt.ControlModifier) {
                            delegate.ctrlSelect();
                        } else {
                            page.selectionMode ? delegate.ctrlSelect()
                                               : delegate.open();
                        }
                    }
                }
            }

            TapHandler {
                acceptedDevices: PointerDevice.TouchScreen
                onTapped: page.selectionMode ? delegate.ctrlSelect()
                                             : delegate.open()
                onLongPressed: page.selectionMode ? delegate.select()
                                                  : delegate.showMenu()
            }

            Drag.mimeData: {"text/uri-list" : [delegate.url]}
            Drag.dragType: Drag.Automatic
            DragHandler {
                id: dragHandler
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                target: null
                onActiveChanged: {
                    if (!active) {
                        parent.Drag.active = false;
                        parent.Drag.imageSource = "";
                        return;
                    }
                    delegate.grabToImage(result => {
                        parent.Drag.imageSource = result.url;
                        parent.Drag.active = true;
                    });
                }
            }
            // keep background hidden when generating the drag image
            background.visible: !(dragHandler.active && !Drag.active)

            Keys.onSpacePressed: delegate.ctrlSelect()
            Keys.onReturnPressed: event => Keys.enterPressed(event)
            Keys.onEnterPressed: page.selectionMode ? delegate.ctrlSelect()
                                                    : delegate.open()

            function open() {
                gridView.currentIndex = delegate.index;
                switch (delegate.itemType) {
                    case Koko.AbstractGalleryModel.Media:
                        page.openMediaViewPage(delegate.url);
                        break;
                    case Koko.AbstractGalleryModel.Folder:
                    case Koko.AbstractGalleryModel.Collection:
                        let gallerySortFilterProxyModelIndex = gallerySortFilterProxyModel.index(delegate.index, 0);
                        let galleryModelIndex = gallerySortFilterProxyModel.mapToSource(gallerySortFilterProxyModelIndex);
                        let path = page.galleryModel.pathForIndex(galleryModelIndex);

                        page.navigate(path);
                        break;
                    default:
                        break;
                }
            }

            function select() {
                gridView.currentIndex = delegate.index;
                selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.ClearAndSelect);
            }

            function shiftSelect() {
                let fromIndex = Math.min(gridView.currentIndex, delegate.index);
                let toIndex = Math.max(gridView.currentIndex, delegate.index);

                // NOTE: This is not performant, but QML API doesn't allow for anything better
                for (let i = fromIndex; i <= toIndex; ++i) {
                    selectionModel.select(gridView.model.index(i, 0), ItemSelectionModel.Select);
                }
            }

            function ctrlSelect() {
                gridView.currentIndex = delegate.index;
                selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.Toggle);
            }

            function showMenu() {
                let selectionWasEmpty = !selectionModel.hasSelection;
                if (selectionWasEmpty) {
                    // NOTE: This is ugly. It would be better if we could create gallery page actions by
                    // creating a QML QtObject with all of the actions as properties, pass it a KFileItemList
                    // and have it set them up, and then add them to an actions list by referencing their
                    // properties. That would nicely separate context menu actions from the page actions, and
                    // make it so we don't have to select for the context menu. Probably better for Marco's
                    // action collection stuff too. File actions can be exported as proprties of FileMenuActions
                    // and just converted to Kirigami.Action from QAction.
                    page.suppressVisibleSelectionMode = true;
                }

                if (!selectionModel.selectedIndexes.includes(gridView.model.index(index, 0))) {
                    selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.ClearAndSelect);
                }

                let list = [];

                list.push(favoriteAction);
                list.push(shareAction);

                let separatorAction = kirigamiActionComponent.createObject(this, {
                    separator: true
                });
                list.push(separatorAction);

                list.push(restoreTrashAction);

                for (let fileMenuAction of fileMenuActions.actions) {
                    let kirigamiAction = kirigamiActionComponent.createObject(this, {
                        displayHint: Kirigami.DisplayHint.AlwaysHide,
                        fromQAction: fileMenuAction
                    });
                    list.push(kirigamiAction);
                }

                let contextMenu = galleryContextMenu.createObject(page.mainWindow, {
                    galleryActions: list,
                    titleText: selectionModel.selectedIndexes.length === 1 ? selectionModel.model.data(selectionModel.selectedIndexes[0], AbstractGalleryModel.NameRole)
                                                                           : i18np("%1 item", "%1 items", selectionModel.selectedIndexes.length)
                }) as GalleryContextMenu;

                if (selectionWasEmpty) {
                    contextMenu.closed.connect(() => {
                        selectionModel.clearSelection();
                        page.suppressVisibleSelectionMode = false;
                    });
                }

                contextMenu.popup();
            }

            Controls.AbstractButton {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Kirigami.Units.smallSpacing

                width: Kirigami.Units.iconSizes.smallMedium
                height: Kirigami.Units.iconSizes.smallMedium
                z: gridView.z + 2

                visible: (delegate.itemType === Koko.AbstractGalleryModel.Media
                         || delegate.itemType === Koko.AbstractGalleryModel.Folder)
                        // keep button hidden when generating the drag image
                        && !(dragHandler.active && !Drag.active)

                onClicked: delegate.ctrlSelect()

                contentItem: Kirigami.Icon {
                    source: delegate.selected ? "emblem-remove" : "emblem-added"
                    active: parent.hovered
                }

                opacity: (delegate.hovered || (page.selectionMode && !page.suppressVisibleSelectionMode)) ? 0.5 : 0
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            // TODO: Distinguish between search ("No media matching your search") and
            // no items in the location, currently difficult due to filtering after
            text: i18n("No media found")
            visible: page.isEmpty
            width: parent.width - (Kirigami.Units.gridUnit * 2)
        }

        function setThumbnailSize(size) {
            const minSize = 80;
            const maxSize = 256;
            const stepSize = 16;

            size = Math.round(size / stepSize) * stepSize; // snap
            size = Math.max(minSize, Math.min(maxSize, size)); // clamp

            if (size !== Koko.Config.iconSize) {
                Koko.Config.iconSize = size;
                Koko.Config.save();
            }
        }

        function adjustThumbnailSize(steps) {
            setThumbnailSize(Koko.Config.iconSize + steps * 16);
        }

        Shortcut {
            sequences: [StandardKey.ZoomIn]
            context: Qt.WindowShortcut
            enabled: gridView.visible
            onActivated: gridView.adjustThumbnailSize(1)
        }

        Shortcut {
            sequences: [StandardKey.ZoomOut]
            context: Qt.WindowShortcut
            enabled: gridView.visible
            onActivated: gridView.adjustThumbnailSize(-1)
        }

        WheelHandler {
            id: wheelHandler
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            acceptedModifiers: Qt.ControlModifier

            onWheel: (event) => {
                const steps = Math.trunc(wheelHandler.rotation / 15); // 15 degrees is 120 angleDelta is 1 step
                if (steps !== 0) {
                    wheelHandler.rotation -= steps * 15;
                    gridView.adjustThumbnailSize(steps);
                }
            }
        }

        PinchHandler {
            id: pinchHandler

            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything

            property int startSize: 0

            onActiveChanged: {
                if (active) {
                    pinchHandler.startSize = Koko.Config.iconSize;
                }
            }

            onScaleChanged: gridView.setThumbnailSize(startSize * scale)
        }

        MouseArea {
            anchors.fill: parent

            cursorShape: undefined
            acceptedButtons: Qt.BackButton | Qt.ForwardButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.BackButton) {
                    mouse.accepted = true;
                    page.navigateBackward();
                } else if (mouse.button === Qt.ForwardButton) {
                    mouse.accepted = true;
                    page.navigateForward();
                }
            }
        }
    }

    Component {
        id: galleryContextMenu
        GalleryContextMenu {}
    }
}
