/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.12 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.koko.private 0.1

Kirigami.ScrollablePage {
    id: page

    property alias model: gridView.model
    property bool isFolderView: false
    property bool isTrashView: gridView.url.toString().startsWith("trash:")
    signal collectionSelected(QtObject selectedModel, string cover)
    signal folderSelected(QtObject selectedModel, string cover, string path)

    property bool bookmarked: isFolderView && kokoConfig.savedFolders.includes(model.sourceModel.url.toString().replace("file:///", "file:/"))
    property var backUrls: [];
    property var backUrlsPosition: 0;

    property alias gridViewItem: gridView

    focus: true

    Component {
        id: normalTitleComponent
        Kirigami.Heading {
             level: 1
             Layout.fillWidth: true
             Layout.maximumWidth: implicitWidth + 1 // The +1 is to make sure we do not trigger eliding at max width
             Layout.minimumWidth: 0
             opacity: page.isCurrentPage ? 1 : 0.4
             maximumLineCount: 1
             elide: Text.ElideRight
             text: page.title
         }
     }

     
    property bool wideMode: Controls.ApplicationWindow.window.width > applicationWindow().wideScreenWidth
     
    // doesn't work without loader
    header: Loader {
        height: active ? implicitHeight : 0 // fix issue where space is being reserved even if not active
        active: page.wideMode
        sourceComponent: mobileHeader
    }
    footer: Loader {
        height: active ? implicitHeight : 0 // fix issue where space is being reserved even if not active
        active: !page.wideMode
        sourceComponent: mobileHeader 
    }
    
    Component {
        id: mobileHeader
        Rectangle {
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor
            
            visible: Kirigami.Settings.isMobile && page.isFolderView;
            height: Kirigami.Settings.isMobile && page.isFolderView ? implicitHeight : 0
            
            implicitHeight: column.implicitHeight
            
            ColumnLayout {
                id: column
                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right
                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: !page.wideMode
                }
                Loader { 
                    active: Kirigami.Settings.isMobile && page.isFolderView; sourceComponent: folderTitle 
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: page.wideMode ? 0 : Kirigami.Units.smallSpacing
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: page.wideMode
                }
            }
        }
    }

    property alias folderTitle: folderTitleComponent
    property alias normalTitle: normalTitleComponent

    Component {
        id: folderTitleComponent

        RowLayout {
            id: folderLayout
            visible: page.isFolderView
            Controls.ToolButton {
                id: backButton
                visible: page.wideMode
                Layout.maximumWidth: height
                Layout.leftMargin: (Kirigami.Settings.isMobile || !page.wideMode && applicationWindow().globalDrawer) ? 0 : -Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                
                icon.name: (LayoutMirroring.enabled ? "go-previous-symbolic-rtl" : "go-previous-symbolic")
                enabled: page.backUrlsPosition > 0
                onClicked: {
                    page.backUrlsPosition--;
                    model.sourceModel.url = page.backUrls[page.backUrlsPosition];
                }
            }

            Controls.ToolButton {
                implicitHeight: Kirigami.Units.gridUnit * 2
                implicitWidth: Kirigami.Units.gridUnit * 2
                visible: page.wideMode
                icon.name: (LayoutMirroring.enabled ? "go-next-symbolic-rtl" : "go-next-symbolic")
                enabled: page.backUrls.length < page.backUrlsPosition
                onClicked: {
                    page.backUrlsPosition++;
                    model.sourceModel.url = page.backUrls[page.backUrlsPosition];
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
                        property bool canBeSimplified: page.isFolderView && Koko.DirModelUtils.inHome(page.model.sourceModel.url)
                        icon.name: canBeSimplified ? "go-home" : "folder-root-symbolic"
                        DragHandler {
                            enabled: scrollView.contentWidth > scrollView.width
                            yAxis.enabled: false
                            xAxis.enabled: false
                        }
                        onClicked: {
                            const tmp = page.backUrls;
                            while (page.backUrlsPosition < page.backUrls.length) {
                                tmp.pop();
                            }
                            tmp.push(page.model.sourceModel.url);
                            page.backUrlsPosition++;
                            page.backUrls = tmp;
                            if (canBeSimplified) {
                                model.sourceModel.url = "file:///" + Koko.DirModelUtils.home;
                            } else {
                                model.sourceModel.url = "file:///";
                            }
                        }
                    }
                    Kirigami.Icon {
                        visible: page.model.sourceModel.url.toString() !== "file:///"
                        source: LayoutMirroring.enabled ? "arrow-left" : "arrow-right"
                        // adds visual balance
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.preferredWidth: visible ? Kirigami.Units.iconSizes.small : 0
                        height: width
                    }
                    Repeater {
                        id: repeater
                        model: page.isFolderView ? Koko.DirModelUtils.getUrlParts(page.model.sourceModel.url) : 0
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
                                    const nextUrl = Koko.DirModelUtils.partialUrlForIndex(page.model.sourceModel.url, index + 1);

                                    if (String(nextUrl) === page.model.sourceModel.url + "/") {
                                        return;
                                    }
                                    const tmp = page.backUrls;
                                    while (page.backUrlsPosition < page.backUrls.length) {
                                        tmp.pop();
                                    }
                                    page.backUrlsPosition++;
                                    tmp.push(page.model.sourceModel.url);
                                    page.backUrls = tmp;
                                    page.model.sourceModel.url = nextUrl;
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
                display: page.wideMode ? Controls.AbstractButton.TextBesideIcon : Controls.AbstractButton.IconOnly
                icon.name: page.bookmarked ? "bookmark-remove" : "bookmark-add-folder"
                text: page.bookmarked ? i18n("Remove Bookmark") : i18nc("@action:button Bookmarks the current folder", "Bookmark Folder")
                visible: Kirigami.Settings.isMobile && bookmarkActionVisible
                onClicked: {
                    if (page.model.sourceModel.url == undefined) {
                        return
                    }
                    if (page.bookmarked) {
                        const index = kokoConfig.savedFolders.indexOf(model.sourceModel.url.toString().replace("file:///", "file:/"));
                        if (index !== -1) {
                            kokoConfig.savedFolders.splice(index, 1);
                        }
                    } else {
                        kokoConfig.savedFolders.push(model.sourceModel.url.toString().replace("file:///", "file:/"));
                    }
                }
            }
        }
    }

    states: [
        State {
            name: "browsing"
            when: !model.hasSelectedImages
        },
        State {
            name: "selecting"
            when: model.hasSelectedImages && Kirigami.Settings.tabletMode
        }
    ]


    property bool bookmarkActionVisible: page.isFolderView && !model.hasSelectedImages && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.pictures)
                                                                                       && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.videos)

    actions: [
        Kirigami.Action {
            id: bookmarkAction
            icon.name: page.bookmarked ? "bookmark-remove" : "bookmark-add-folder"
            text: page.bookmarked ? i18n("Remove Bookmark") : i18nc("@action:button Bookmarks the current folder", "Bookmark Folder")
            visible: Kirigami.Settings.isMobile && page.isFolderView && !model.hasSelectedImages
                && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.pictures)
                && model.sourceModel.url.toString() !== ("file://" + Koko.DirModelUtils.videos)
            onTriggered: {
                if (page.model.sourceModel.url == undefined) {
                    return
                }
                if (page.bookmarked) {
                    const index = kokoConfig.savedFolders.indexOf(model.sourceModel.url.toString().replace("file:///", "file:/"));
                    if (index !== -1) {
                        kokoConfig.savedFolders.splice(index, 1);
                    }
                } else {
                    kokoConfig.savedFolders.push(model.sourceModel.url.toString().replace("file:///", "file:/"));
                }
            }
        },
        Kirigami.Action {
            id: goUpAction
            icon.name: "go-up"
            text: i18n("Go Up")
            visible: page.isFolderView && Kirigami.Settings.isMobile
            onTriggered: {
                const tmp = page.backUrls;
                while (page.backUrlsPosition < page.backUrls.length) {
                    tmp.pop();
                }
                tmp.push(page.model.sourceModel.url);
                page.backUrlsPosition++;
                page.backUrls = tmp;
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
            visible: page.isFolderView && Kirigami.Settings.isMobile
            property bool canBeSimplified: page.isFolderView && Koko.DirModelUtils.canBeSimplified(page.model.sourceModel.url)
            icon.name: canBeSimplified ? "go-home" : "folder-root-symbolic"
            text: canBeSimplified ? i18n("Home") : i18n("Root")
            onTriggered: {
                const tmp = page.backUrls;
                while (page.backUrlsPosition < page.backUrls.length) {
                    tmp.pop();
                }
                tmp.push(page.model.sourceModel.url);
                page.backUrlsPosition++;
                page.backUrls = tmp;
                if (canBeSimplified) {
                    model.sourceModel.url = "file:///" + Koko.DirModelUtils.home;
                } else {
                    model.sourceModel.url = "file:///";
                }
            }
        },
        ShareAction {
            id: shareAction
            visible: model.hasSelectedImages

            property Connections connection: Connections {
                target: model
                function onSelectedImagesChanged() {
                    shareAction.inputData = {
                        urls: model.selectedImages(),
                        mimeType: model.selectedImagesMimeTypes()
                    };
                }
            }

        },
        Kirigami.Action {
            icon.name: "group-delete"
            text: i18n("Delete Selection")
            tooltip: i18n("Move selected items to trash")
            visible: model.hasSelectedImages && !page.isTrashView
            onTriggered: model.deleteSelection()
        },
        Kirigami.Action {
            icon.name: "restoration"
            text: i18n("Restore Selection")
            tooltip: i18n("Restore selected items from trash")
            visible: model.hasSelectedImages && page.isTrashView
            onTriggered: model.restoreSelection()
        },
        Kirigami.Action {
            visible: Kirigami.Settings.isMobile && root.width <= applicationWindow().wideScreenWidth
            icon.name: "configure"
            text: i18n("Configure…")
            onTriggered: applicationWindow().openSettingsPage();
        },
        Kirigami.Action {
            icon.name: "edit-select-all"
            text: i18n("Select All")
            tooltip: i18n("Selects all the media in the current view")
            visible: model.containImages
            onTriggered: model.selectAll()

        },
        Kirigami.Action {
            icon.name: "edit-select-none"
            text: i18n("Deselect All")
            tooltip: i18n("De-selects all the selected media")
            onTriggered: model.clearSelections()
            visible: model.hasSelectedImages
        }
    ]

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Escape:
                gridView.model.clearSelections()
                break;
            default:
                break;
        }
    }

    GridView {
        id: gridView

        property real widthToApproximate: (applicationWindow().wideScreen ? applicationWindow().pageStack.defaultColumnWidth : page.width) - (1||Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)
        property string url: model.sourceModel.url ? model.sourceModel.url : ""

        cellWidth: Math.floor(width/Math.floor(width/(kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2)))
        cellHeight: kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2

        topMargin: Kirigami.Units.gridUnit

        highlightMoveDuration: 0
        keyNavigationEnabled: true
        focus: true

        // always clean selection
        onUrlChanged: model.clearSelections()

        delegate: AlbumDelegate {
            id: delegate
            highlighted: gridView.currentIndex == index

            Controls.ToolTip.text: Koko.DirModelUtils.fileNameOfUrl(model.imageurl)
            Controls.ToolTip.visible: hovered && model.itemType === Koko.Types.Image
            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

            onPressAndHold: gridView.model.toggleSelected(delegate.index)

            onClicked: if (page.state === "selecting" || Controller.keyboardModifiers() & Qt.ControlModifier) {
                gridView.model.toggleSelected(delegate.index)
            } else {
                gridView.model.clearSelections()
                gridView.currentIndex = delegate.index;
                switch(delegate.itemType) {
                    case Koko.Types.Album: {
                        imageListModel.query = imageListModel.queryForIndex( model.sourceIndex)
                        sortedListModel.sourceModel = imageListModel
                        collectionSelected( sortedListModel, delegate.content)
                        break;
                    }
                    case Koko.Types.Folder: {
                        if (!page.isFolderView) {
                            imageFolderModel.url = delegate.imageurl
                            sortedListModel.sourceModel = imageFolderModel
                            folderSelected(sortedListModel, delegate.contetn, delegate.imageurl)
                            return
                        }
                        const tmp = page.backUrls;
                        while (page.backUrlsPosition < page.backUrls.length) {
                            tmp.pop();
                        }
                        tmp.push(page.model.sourceModel.url);
                        page.backUrls = tmp;
                        page.backUrlsPosition++;
                        page.model.sourceModel.url = delegate.imageurl;
                        break;
                    }
                    case Koko.Types.Image: {
                        if (gridView.url.toString().startsWith("trash:")) {
                            break
                        }
                        applicationWindow().pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                            startIndex: page.model.index(gridView.currentIndex, 0),
                            imagesModel: page.model
                        })
                        break;
                    }
                    default: {
                        console.log("Unknown")
                        break;
                    }
                }
            }
            SelectionButton {
                id: selectionButton

                selected: delegate.selected
                index: delegate.index
                opacity: delegate.hovered || page.state === "selecting"
                visible: delegate.itemType !== Koko.Types.Folder && delegate.itemType !== Koko.Types.Album

                anchors {
                    top: delegate.top
                    left: delegate.left
                }
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No Media Found")
            visible: gridView.count === 0
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
        }

        //FIXME: right now if those two objects are out of this, the whole page breaks
        Koko.SortModel {
            id: sortedListModel
        }
        Koko.ImageFolderModel {
            id: imageFolderModel
        }
    }

    onCollectionSelected: pageStack.push(Qt.resolvedUrl("AlbumView.qml"), {
        model: selectedModel,
        title: cover,
    })
    onFolderSelected: pageStack.push(Qt.resolvedUrl("AlbumView.qml"), {
        model: selectedModel,
        title: cover,
        url: path
    })
}
