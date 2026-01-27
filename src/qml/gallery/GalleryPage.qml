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

    function openMediaViewPage(url) {
        if (page.isTrashView) {
            return;
        }

        page.mainWindow.pageStack.layers.push(Qt.resolvedUrl("MediaViewPage.qml"), {
            application: page.application,
            mainWindow: page.mainWindow,
            gallerySortFilterProxyModel: gallerySortFilterProxyModel,
            url: url
        });
    }

    Controls.ActionGroup {
        id: sortGroup
        exclusive: true
    }

    Controls.ActionGroup {
        id: sortReversedGroup
        exclusive: true
    }

    actions: [
        // Selection
        ShareAction {
            id: shareAction
            tooltip: i18nc("@info:tooltip", "Share the selected media")
            enabled: selectionModel.hasSelection
            visible: selectionModel.hasSelection
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
            id: moveToTrashAction
            icon.name: "group-delete-symbolic"
            text: i18nc("@action:button Move the selected media to the trash", "Move to Trash")
            tooltip: i18nc("@info:tooltip", "Move the selected media to the trash")
            enabled: selectionModel.hasSelection && !page.isTrashView
            visible: selectionModel.hasSelection && !page.isTrashView
            shortcut: StandardKey.Delete
            onTriggered: {
                let urls = [];
                selectionModel.selectedIndexes.forEach(index => {
                    urls.push(selectionModel.model.data(index, AbstractGalleryModel.UrlRole));
                });

                Koko.DirModelUtils.deleteUrls(urls);
            }
        },
        Kirigami.Action {
            id: restoreTrashAction
            icon.name: "group-delete-symbolic"
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
            visible: shareAction.visible || moveToTrashAction.visible || restoreTrashAction.visible
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
        },

        // Hidden
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
            enabled: !page.isEmpty && !page.disallowMassSelection
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

        galleryModel: page.galleryModel
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

        // TODO: Make handling + selection more Dolphin-like?
        delegate: GalleryDelegate {
            id: delegate

            GridView.onPooled: { thumbnailPriority = -1; }
            GridView.onReused: { thumbnailPriority = Qt.binding(() => gridView.calculateThumbnailPriority(delegate)); }
            thumbnailPriority: gridView.calculateThumbnailPriority(delegate)

            highlighted: gridView.currentIndex == index
            selected: selectionModel.selectedIndexes.includes(gridView.model.index(index, 0))

            Controls.ToolTip.text: name
            Controls.ToolTip.visible: hovered && itemType === Koko.AbstractGalleryModel.Media
            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

            onPressAndHold: selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.Toggle)

            onClicked: {
                if (selectionModel.hasSelection || Koko.Controller.keyboardModifiers() & Qt.ControlModifier) {
                    selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.Toggle);
                } else {
                    gridView.currentIndex = delegate.index;
                    switch (delegate.itemType) {
                        case Koko.AbstractGalleryModel.Media:
                            page.openMediaViewPage(delegate.url);
                            break;
                        case Koko.AbstractGalleryModel.Folder:
                        case Koko.AbstractGalleryModel.Collection:
                            let gallerySortFilterProxyModelIndex = gallerySortFilterProxyModel.index(delegate.index, 0);
                            let galleryModelIndex = gallerySortFilterProxyModel.mapToGalleryModelIndex(gallerySortFilterProxyModelIndex);
                            let path = page.galleryModel.pathForIndex(galleryModelIndex);

                            page.navigate(path);
                            break;
                        default:
                            break;
                    }
                }
            }

            Controls.AbstractButton {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Kirigami.Units.smallSpacing

                width: Kirigami.Units.iconSizes.smallMedium
                height: Kirigami.Units.iconSizes.smallMedium
                z: gridView.z + 2

                visible: delegate.itemType === Koko.AbstractGalleryModel.Media
                         || delegate.itemType === Koko.AbstractGalleryModel.Folder

                onClicked: selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.Toggle)

                contentItem: Kirigami.Icon {
                    source: delegate.selected ? "emblem-remove" : "emblem-added"
                    active: parent.hovered
                }

                opacity: (delegate.hovered || selectionModel.hasSelection) ? 0.5 : 0
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
            onActivated: gridView.adjustThumbnailSize(1);
        }

        Shortcut {
            sequences: [StandardKey.ZoomOut]
            onActivated: gridView.adjustThumbnailSize(-1);
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
}
