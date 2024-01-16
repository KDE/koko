/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.koko 0.1 as Koko
import org.kde.koko.private 0.1 as KokoPrivate

Kirigami.ApplicationWindow {
    id: root

    pageStack {
        globalToolBar {
            canContainHandles: true
            style: Kirigami.ApplicationHeaderStyle.ToolBar
            showNavigationButtons: Kirigami.ApplicationHeaderStyle.ShowBackButton;
        }
        popHiddenPages: true

        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
    }

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20

    onClosing: KokoPrivate.Controller.saveWindowGeometry(root)

    // This timer allows to batch update the window size change to reduce
    // the io load and also work around the fact that x/y/width/height are
    // changed when loading the page and overwrite the saved geometry from
    // the previous session.
    Timer {
        id: saveWindowGeometryTimer
        interval: 1000
        onTriggered: if (applicationWindow().visibility !== Window.FullScreen) {
            KokoPrivate.Controller.saveWindowGeometry(root);
        }
    }

    onWidthChanged: saveWindowGeometryTimer.restart()
    onHeightChanged: saveWindowGeometryTimer.restart()
    onXChanged: saveWindowGeometryTimer.restart()
    onYChanged: saveWindowGeometryTimer.restart()

    function switchApplicationPage(page) {
        if (!page || pageStack.currentItem === page) {
            return page;
        }

        pageStack.clear();
        pageStack.push(page);

        return pageStack.currentItem;
    }

    function openPlacesPage() {
        if (placesView === null) {
            placesView = switchApplicationPage(Qt.resolvedUrl("PlacesPage.qml"));
            placesView.title = i18n("Places");
        } else {
            switchApplicationPage(placesView);
        }
        placesOpened();
    }

    function openSettingsView() {
        if (settingsView === null) {
            settingsView = switchApplicationPage(Qt.resolvedUrl("SettingsPage.qml"));
        } else {
            switchApplicationPage(settingsView);
        }
        settingsOpened(true); //isPage
    }

    function openSettingsPage() {
        pageStack.pushDialogLayer(Qt.resolvedUrl("SettingsPage.qml"), {}, {
            title: i18n("Configure"),
            width: Kirigami.Units.gridUnit * 30,
        });
        settingsOpened(false); //isPage
    }

    function updateGlobalDrawer() {
        if (!fetchImageToOpen && globalDrawer) {
            globalDrawer.enabled = pageStack.layers.depth < 2;
            globalDrawer.drawerOpen = !globalDrawer.modal && pageStack.layers.depth < 2;
        }
    }

    signal filterChanged(string value, string query)
    signal settingsOpened(bool isPage)
    signal placesOpened()

    property var tags: imageTagsModel.sourceModel.tags
    property var settingsView: null
    property var albumView: null
    property var placesView: null

    // see https://invent.kde.org/frameworks/kirigami/-/merge_requests/332/diffs
    property real wideScreenWidth: Kirigami.Units.gridUnit * 40

    // fetch guard, so we don't needlessly check for image to open when it's not needed
    // this is a temporary binding that's supposed to be broken
    property bool fetchImageToOpen: KokoPrivate.OpenFileModel.rowCount() === 1

    pageStack.layers.onDepthChanged: root.updateGlobalDrawer()

    Component {
        id: openFileComponent
        AlbumView {
            title: i18n("Images")
            model: Koko.SortModel {
                sourceModel: KokoPrivate.OpenFileModel
            }
        }
    }

    Component {
        id: albumViewComponentMobile
        AlbumView {
            model: imageFolderModel
            title: i18n("Folders")
        }
    }

    Component {
        id: albumViewComponent
        AlbumView {
            titleDelegate: isFolderView ? folderTitle : normalTitle
            model: imageFolderModel
            title: i18n("Folders")
        }
    }

    Connections {
        target: KokoPrivate.OpenFileModel
        function onUpdatedImages() { // this gets called if we use "open with", while app is already open
            if (KokoPrivate.OpenFileModel.rowCount() > 1) {
                pageStack.clear();
                pageStack.layers.clear();
                pageStack.push(openFileComponent);
            } else if (KokoPrivate.OpenFileModel.rowCount() === 1) {
                pageStack.clear();
                pageStack.layers.clear();
                pageStack.push(Kirigami.Settings.isMobile ? albumViewComponentMobile : albumViewComponent);
                albumView = pageStack.currentItem;
                albumView.isFolderView = true;
                const url = String(Koko.DirModelUtils.directoryOfUrl(KokoPrivate.OpenFileModel.urlToOpen)).replace("file:", "");
                albumView.model.sourceModel.url = url;
                fetchImageToOpen = true;
                pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                    imagesModel: imageFolderModel.sourceModel
                });
            }
        }
    }

    function filterBy(value, query) {
        if (albumView === null || albumView !== pageStack.currentItem) {
            albumView = switchApplicationPage(Kirigami.Settings.isMobile ? albumViewComponentMobile : albumViewComponent);
        }

        if (value === "Folders" && query.length > 0) {
            let str = query;
            if (str.endsWith("/")) {
                str = str.slice(0, -1);
            }
            albumView.title = str.split("/")[str.split("/").length-1]
        } else if (value === "Tags") {
            albumView.title = query;
        } else {
            albumView.title = i18n(value);
        }
        albumView.isFolderView = false;

        switch(value) {
            case "Countries": { 
                albumView.model = imageLocationModelCountry;
                imageListModel.locationGroup = Koko.Types.Country;
                break;
            }
            case "States": { 
                albumView.model = imageLocationModelState;
                imageListModel.locationGroup = Koko.Types.State;
                break;
            }
            case "Cities": {
                albumView.model = imageLocationModelCity;
                imageListModel.locationGroup = Koko.Types.City;
                break;
            }
            case "Years": {
                albumView.model = imageTimeModelYear; 
                imageListModel.timeGroup = Koko.Types.Year;
                break;
            }
            case "Months": {
                albumView.model = imageTimeModelMonth;
                imageListModel.timeGroup = Koko.Types.Month;
                break;
            }
            case "Weeks": {
                albumView.model = imageTimeModelWeek;
                imageListModel.timeGroup = Koko.Types.Week;
                break;
            }
            case "Days": { 
                albumView.model = imageTimeModelDay; 
                imageListModel.timeGroup = Koko.Types.Day;
                break;
            }
            case "Favorites": {
                albumView.model = imageFavoritesModel;
                imageListModel.locationGroup = -1;
                imageListModel.timeGroup = -1;
                break;
            }
            case "Tags": {
                albumView.model = imageTagsModel;
                imageTagsModel.sourceModel.tag = query;
                imageListModel.locationGroup = -1;
                imageListModel.timeGroup = -1;
                break;
            }
            case "Trash":
            case "Remote":
            case "Pictures":
            case "Videos":
            case "Folders": {
                albumView.model = imageFolderModel; 
                albumView.model.sourceModel.url = query;
                albumView.isFolderView = (value === "Folders" || value === "Pictures" || value === "Videos");
                imageListModel.locationGroup = -1;
                imageListModel.timeGroup = -1;
                break;
            }
        }
        albumView.gridViewItem.forceActiveFocus();
        filterChanged(value, query)
    }

    contextDrawer: Kirigami.Settings.isMobile ? contextDrawerComponent.createObject(root) : null

    Component {
        id: contextDrawerComponent

        Kirigami.ContextDrawer {
            Component.onCompleted: console.log("frjeoi")
        }
    }

    globalDrawer: Sidebar {}

    footer: BottomNavBar { }

    Koko.SortModel {
        id: imageFolderModel
        sourceModel: Koko.ImageFolderModel {
            url: ""
        }
        /*
         * filterRole is an Item property exposed by the QSortFilterProxyModel
         */
        filterRole: Koko.Roles.MimeTypeRole
    }

    Koko.SortModel {
        id: imageTimeModelYear
        sourceModel: Koko.ImageTimeModel {
            group: Koko.Types.Year
        }
        sortRoleName: "date"
    }
    
    Koko.SortModel {
        id: imageTimeModelMonth
        sourceModel: Koko.ImageTimeModel {
            group: Koko.Types.Month
        }
        sortRoleName: "date"
    }
    
    Koko.SortModel {
        id: imageTimeModelWeek
        sourceModel: Koko.ImageTimeModel {
            group: Koko.Types.Week
        }
        sortRoleName: "date"
    }
    
    Koko.SortModel {
        id: imageTimeModelDay
        sourceModel: Koko.ImageTimeModel {
            group: Koko.Types.Day
        }
        sortRoleName: "date"
    }

    Koko.SortModel {
        id: imageFavoritesModel
        sourceModel: Koko.ImageFavoritesModel {}
    }

    Koko.SortModel {
        id: imageTagsModel
        sourceModel: Koko.ImageTagsModel {}
    }

    Koko.SortModel {
        id: imageLocationModelCountry
        sourceModel: Koko.ImageLocationModel {
            group: Koko.Types.Country
        }
    }
        
    Koko.SortModel {
        id: imageLocationModelState
        sourceModel: Koko.ImageLocationModel {
            group: Koko.Types.State
        }
    }
    
    Koko.SortModel {
        id: imageLocationModelCity
        sourceModel: Koko.ImageLocationModel {
            group: Koko.Types.City
        }
    }
    
    Koko.ImageListModel {
        id: imageListModel
    }
    
    Koko.NotificationManager {
        id: notificationManager
    }
    
    KQA.Clipboard {
        id: clipboard
    }

    Component.onCompleted: {
        // Initialize window or config
        if (kokoConfig.width < root.minimumWidth) {
            kokoConfig.width = root.width
        } else if (kokoConfig.width <= Screen.width) {
            root.width = Math.min(kokoConfig.width, Screen.desktopAvailableWidth)
        }
        if (kokoConfig.height < root.minimumHeight) {
            kokoConfig.height = root.height
        } else {
            root.height = Math.min(kokoConfig.height, Screen.desktopAvailableHeight)
        }
        root.visibility = kokoConfig.visibility
        root.controlsVisible = kokoConfig.controlsVisible
        pageStack.contentItem.columnResizeMode = Kirigami.ColumnView.SingleColumn
        if (KokoPrivate.OpenFileModel.rowCount() > 1) {
            pageStack.initialPage = openFileComponent;
        } else {
            pageStack.initialPage = Kirigami.Settings.isMobile ? albumViewComponentMobile : albumViewComponent;

        }
        albumView = pageStack.currentItem;
        if (KokoPrivate.OpenFileModel.rowCount() <= 1) {
            albumView.isFolderView = true;
        }
        if (KokoPrivate.OpenFileModel.rowCount() === 1) {
            const url = String(Koko.DirModelUtils.directoryOfUrl(KokoPrivate.OpenFileModel.urlToOpen)).replace("file:", "");
            console.log(url)
            albumView.model.sourceModel.url = url;
            fetchImageToOpen = true;
            pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                imagesModel: imageFolderModel.sourceModel
            });
        }
        
        // move mobile handles to toolbar
        pageStack.globalToolBar.canContainHandles = true;
    }
}
