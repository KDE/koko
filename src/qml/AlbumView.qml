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

Kirigami.ScrollablePage {
    id: page

    property alias model: gridView.model
    property bool isFolderView: false
    signal collectionSelected(QtObject selectedModel, string cover)
    signal folderSelected(QtObject selectedModel, string cover, string path)

    property bool bookmarked: isFolderView && kokoConfig.savedFolders.includes(model.sourceModel.url.toString().replace("file:///", "file:/"))
    property var backUrls: [];
    property var backUrlsPosition: 0;

    keyboardNavigationEnabled: true
    focus: true

    titleDelegate: page.isFolderView ? folderTitle : normalTitle
    globalToolBarStyle: page.isFolderView ? Kirigami.ApplicationHeaderStyle.ToolBar : Kirigami.ApplicationHeaderStyle.Tiles

    Component {
        id: normalTitle
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

    Component {
        id: folderTitle

        RowLayout {
            id: folderLayout
            visible: page.isFolderView
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Settings.isMobile ? -Kirigami.Units.gridUnit * 2: 0
            Controls.ToolButton {
                id: backButton
                icon.name: (LayoutMirroring.enabled ? "go-previous-symbolic-rtl" : "go-previous-symbolic")
                enabled: page.backUrlsPosition > 0
                onClicked: {
                    page.backUrlsPosition--;
                    model.sourceModel.url = page.backUrls[page.backUrlsPosition];
                }
            }

            Controls.ToolButton {
                icon.name: (LayoutMirroring.enabled ? "go-next-symbolic-rtl" : "go-next-symbolic")
                enabled: page.backUrls.length < page.backUrlsPosition
                onClicked: {
                    page.backUrlsPosition++;
                    model.sourceModel.url = page.backUrls[page.backUrlsPosition];
                }
            }

            Controls.ToolSeparator { }

            Controls.ScrollView {
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: folderRow.implicitWidth + 1
                Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
                Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AlwaysOff
                RowLayout {
                    id: folderRow
                    Controls.ToolButton {
                        property bool canBeSimplified: Koko.DirModelUtils.canBeSimplified(page.model.sourceModel.url)
                        icon.name: canBeSimplified ? "go-home" : "folder-root-symbolic"
                        height: parent.height
                        width: height
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
                    Repeater {
                        model: Koko.DirModelUtils.getUrlParts(page.model.sourceModel.url)

                        Controls.ToolButton {
                            icon.name: "arrow-right"
                            text: modelData
                            onClicked: {
                                console.log(page.backUrlsPosition, page.backUrls)
                                const nextUrl = Koko.DirModelUtils.partialUrlForIndex(page.model.sourceModel.url, index);

                                if (nextUrl == page.model.sourceModel.url) {
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

    actions {
        main: Kirigami.Action {
            iconName: page.bookmarked ? "bookmark-remove" : "bookmark-add-folder"
            text: page.bookmarked ? i18n("Remove Bookmark") : i18n("Bookmark Folder")
            visible: page.isFolderView && !model.hasSelectedImages
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
        }
        contextualActions: [
            Kirigami.Action {
                iconName: "edit-select-all"
                text: i18n("Select All")
                tooltip: i18n("Selects all the images in the current view")
                visible: model.containImages
                onTriggered: model.selectAll()
            },
            Kirigami.Action {
                iconName: "edit-select-none"
                text: i18n("Deselect All")
                tooltip: i18n("De-selects all the selected images")
                onTriggered: model.clearSelections()
                visible: model.hasSelectedImages
            },
            Kirigami.Action {
                iconName: "emblem-shared-symbolic"
                text: i18n("Share")
                tooltip: i18n("Share the selected images")
                visible: model.hasSelectedImages
                onTriggered: {
                    shareMenu.open();
                    shareMenu.inputData = {
                        "urls": model.selectedImages(),
                        "mimeType": "image/"
                    }
                }
            },
            Kirigami.Action {
                iconName: "group-delete"
                text: i18n("Delete Selection")
                tooltip: i18n("Move selected items to trash")
                visible: model.hasSelectedImages
                onTriggered: model.deleteSelection()
            }
        ]
    }

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

    ShareDialog {
        id: shareMenu

        inputData: {
            "urls": [],
            "mimeType": ["image/"]
        }
        onFinished: {
            if (error==0 && output.url !== "") {
                console.assert(output.url !== undefined);
                var resultUrl = output.url;
                console.log("Received", resultUrl)
                notificationManager.showNotification( true, resultUrl);
                clipboard.content = resultUrl;
            } else {
                notificationManager.showNotification( false);
            }
        }
    }  

    GridView {
        id: gridView
        //FIXME: right now if those two objects are out of this, the whole page breaks
        Koko.SortModel {
            id: sortedListModel
        }
        Koko.ImageFolderModel {
            id: imageFolderModel
        }

        keyNavigationEnabled: true

        property real widthToApproximate: (applicationWindow().wideScreen ? applicationWindow().pageStack.defaultColumnWidth : page.width) - (1||Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)

        cellWidth: Math.floor(width/Math.floor(width/(kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2)))

        cellHeight: kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2

        topMargin: Kirigami.Units.gridUnit

        highlightMoveDuration: 0

        delegate: AlbumDelegate {
            id: delegate
            modelData: model
            Controls.ToolTip.text: Koko.DirModelUtils.fileNameOfUrl(model.imageurl)
            Controls.ToolTip.visible: hovered && model.itemType === Koko.Types.Image
            Controls.ToolTip.delay: Kirigami.Units.longDuration * 2
            onClicked: {
                if (page.state == "selecting" || (mouse.modifiers & Qt.ControlModifier ) && (model.itemType == Koko.Types.Image)) {
                    gridView.model.toggleSelected(model.index)
                } else {
                    activated();
                }
            }
            onPressAndHold: {
                gridView.model.toggleSelected(model.index)
            }
            onActivated: {
                gridView.model.clearSelections()
                gridView.currentIndex = model.index;
                switch( model.itemType) {
                    case Koko.Types.Album: {
                        imageListModel.query = imageListModel.queryForIndex( model.sourceIndex)
                        sortedListModel.sourceModel = imageListModel
                        collectionSelected( sortedListModel, model.display)
                        break;
                    }
                    case Koko.Types.Folder: {
                        const tmp = page.backUrls;
                        while (page.backUrlsPosition < page.backUrls.length) {
                            tmp.pop();
                        }
                        tmp.push(page.model.sourceModel.url);
                        page.backUrls = tmp;
                        page.backUrlsPosition++;
                        page.model.sourceModel.url = model.imageurl
                        break;
                    }
                    case Koko.Types.Image: {
                        applicationWindow().pageStack.layers.push(Qt.resolvedUrl("ImageViewer.qml"), {
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
                opacity: ( delegate.containsMouse || page.state == "selecting") && !(model.itemType == Koko.Types.Folder || model.itemType == Koko.Types.Album)

                anchors.top: delegate.top
                anchors.left: delegate.left

                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
        
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No Images Found")
            visible: gridView.count == 0
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
        }
    }
    
    onCollectionSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": i18n(cover)})
    onFolderSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": i18n(cover), "url": path })
}
