/*
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQml.Models

import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.koko.private

Kirigami.ScrollablePage {
    id: page

    required property Koko.PhotosApplication application
    required property Kirigami.ApplicationWindow mainWindow
    required property Koko.AbstractGalleryModel galleryModel

    readonly property bool isEmpty: gridView.count === 0
    readonly property bool isFolderView: galleryModel instanceof Koko.GalleryFolderModel
    readonly property bool isTrashView: isFolderView && galleryModel.url.toString().startsWith("trash:")
    readonly property bool isBookmarked: isFolderView && Koko.Config.savedFolders.includes(galleryModel.url.toString().replace("file:///", "file:/"))

    readonly property bool canBookmark: page.isFolderView
                                        && galleryModel.url.toString() !== ("file://" + Koko.DirModelUtils.pictures)
                                        && galleryModel.url.toString() !== ("file://" + Koko.DirModelUtils.videos)

    // For performance reasons, selection operations need to be disabled if they need to process and store a massive number
    // of items. In the future, we could mitigate this with a custom selection model which switches to storing unselected
    // indexes when 'Select All' is used, and back on 'Deselect All'. It could be a wrapper around QItemSelectionModel with
    // a leaner API, as we only need select all, deselect all, invert, hasSelection and selectedIndexes, all in column 0.
    readonly property int allowMassSelection: gridView.count <= 1000

    Controls.ActionGroup {
        id: sortGroup
        exclusive: true
    }

    actions: [
        // Selection
        ShareAction {
            id: shareAction
            tooltip: i18nc("@info:tooltip", "Share the selected media")
            enabled: selectionModel.hasSelection
            visible: selectionModel.hasSelection

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
            onTriggered: {
                // TODO: DirModelUtils?
            }
        },
        Kirigami.Action {
            id: restoreTrashAction
            icon.name: "group-delete-symbolic"
            text: i18nc("@action:button Move the selected media to the trash", "Restore")
            tooltip: i18nc("@info:tooltip", "Restore the selected media to their former locations")
            enabled: selectionModel.hasSelection && page.isTrashView
            visible: selectionModel.hasSelection && page.isTrashView
            onTriggered: {
                // TODO: DirModelUtils?
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
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Modified
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Modified
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Created")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Created
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Created
            }
            Kirigami.Action {
                Controls.ActionGroup.group: sortGroup
                text: i18nc("@action:inmenu An order to sort media items", "Accessed")
                checkable: true
                checked: gallerySortFilterProxyModel.sortMode === Koko.GallerySortFilterProxyModel.Accessed
                onTriggered: gallerySortFilterProxyModel.sortMode = Koko.GallerySortFilterProxyModel.Accessed
            }
            Kirigami.Action {
                separator: true
            }
            Kirigami.Action {
                text: i18nc("@action:inmenu An option to sort media items in reverse order", "Reverse")
                checkable: true
                checked: gallerySortFilterProxyModel.sortReversed
                onTriggered: gallerySortFilterProxyModel.sortReversed = checked
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
            enabled: canBookmark && !selectionModel.hasSelection
            visible: canBookmark && !selectionModel.hasSelection
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
            enabled: !page.isEmpty && page.allowMassSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            shortcut: "Ctrl+A"
            onTriggered: selectionModel.select(gridView.model.index(0, 0), ItemSelectionModel.Select | ItemSelectionModel.Columns)

        },
        Kirigami.Action {
            id: deselectAllAction
            icon.name: "edit-select-none-symbolic"
            text: i18nc("@action:button", "Deselect All")
            tooltip: i18nc("@info:tooltip", "Deselect all media")
            enabled: !page.isEmpty && page.allowMassSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            onTriggered: selectionModel.clearSelection()
        },
        Kirigami.Action {
            id: invertSelectionAction
            icon.name: "edit-select-invert-symbolic"
            text: i18nc("@action:button", "Invert Selection")
            tooltip: i18nc("@info:tooltip", "Invert the selected media")
            enabled: !page.isEmpty && page.allowMassSelection
            displayHint: Kirigami.DisplayHint.AlwaysHide
            shortcut: "Ctrl+Shift+A"
            onTriggered: selectionModel.select(gridView.model.index(0, 0), ItemSelectionModel.Toggle | ItemSelectionModel.Columns)
        }
    ]

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

        // Instantiate delegates to fill height * 2 above and below
        cacheBuffer: height * 2

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
        delegate: AlbumDelegate {
            id: delegate

            // TODO: cleanup
            required property url url
            imageurl: url

            GridView.onPooled: { thumbnailPriority = -1; }
            GridView.onReused: { thumbnailPriority = Qt.binding(() => gridView.calculateThumbnailPriority(delegate)); }
            thumbnailPriority: gridView.calculateThumbnailPriority(delegate)

            highlighted: gridView.currentIndex == index
            selected: selectionModel.selectedIndexes.includes(gridView.model.index(index, 0))

            Controls.ToolTip.text: name
            Controls.ToolTip.visible: hovered && itemType === Koko.AbstractGalleryModel.Image
            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

            onPressAndHold: selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.Toggle)

            onClicked: {
                if (selectionModel.hasSelection || Koko.Controller.keyboardModifiers() & Qt.ControlModifier) {
                    selectionModel.select(gridView.model.index(index, 0), ItemSelectionModel.Toggle);
                } else {
                    gridView.currentIndex = delegate.index;
                    switch (delegate.itemType) {
                        case Koko.AbstractImageModel.Image:
                            if (page.isTrashView) {
                                break;
                            }

                            page.mainWindow.pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                                startIndex: gridView.model.index(gridView.currentIndex, 0),
                                imagesModel: gridView.model,
                                imageurl: delegate.url,
                                application: page.application,
                                mainWindow: page.mainWindow
                            });
                            break;
                        case Koko.AbstractImageModel.Folder:
                            break;
                        case Koko.AbstractImageModel.Collection:
                            // TODO
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

                visible: delegate.itemType === Koko.AbstractGalleryModel.Image
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
    }
}
