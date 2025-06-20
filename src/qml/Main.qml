/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kquickcontrolsaddons as KQA
import org.kde.koko as Koko
import org.kde.koko.private as KokoPrivate
import org.kde.config as KConfig

StatefulApp.StatefulWindow {
    id: root

    application: Koko.PhotosApplication {
        configurationView: Koko.PhotosConfigurationView {
            window: root
            application: root.application
        }
    }

    windowName: "MainWindow"

    pageStack {
        globalToolBar {
            canContainHandles: true
            style: Kirigami.ApplicationHeaderStyle.ToolBar
            showNavigationButtons: Kirigami.ApplicationHeaderStyle.ShowBackButton;
        }
        popHiddenPages: true

        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
        layers.onDepthChanged: root.updateGlobalDrawer()
    }

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20

    function switchApplicationPage(page: Kirigami.Page): Kirigami.Page {
        if (!page || pageStack.currentItem === page) {
            return page;
        }

        pageStack.clear();
        pageStack.push(page);

        return pageStack.currentItem;
    }

    function openPlacesPage(): void {
        if (placesView === null) {
            const component = Qt.createComponent("org.kde.koko", "PlacesPage");
            if (component.status === Component.Error) {
                console.error(component.errorString());
                return;
            }

            const page = component.createObject(root, {
                title: i18nc("@title", "Places"),
                application: root.application,
            });

            placesView = switchApplicationPage(page);
        } else {
            switchApplicationPage(placesView);
        }
        placesOpened();
    }

    function updateGlobalDrawer(): void {
        if (!fetchImageToOpen && globalDrawer) {
            globalDrawer.enabled = pageStack.layers.depth < 2;
            globalDrawer.drawerOpen = !globalDrawer.modal && pageStack.layers.depth < 2;
        }
    }

    signal filterChanged(string value, string query)
    signal settingsOpened(bool isPage)
    signal placesOpened()

    property var settingsView: null
    property var albumView: null
    property var placesView: null

    // fetch guard, so we don't needlessly check for image to open when it's not needed
    // this is a temporary binding that's supposed to be broken
    property bool fetchImageToOpen: KokoPrivate.OpenFileModel.rowCount() === 1

    Kirigami.Action {
        fromQAction: root.application.action('open_kcommand_bar')
    }

    Component {
        id: openFileComponent
        AlbumView {
            title: i18n("Images")
            application: root.application
            mainWindow: root
            model: Koko.SortModel {
                sourceModel: KokoPrivate.OpenFileModel
            }
        }
    }

    Component {
        id: albumViewComponent
        AlbumView {
            application: root.application
            model: imageFolderModel
            mainWindow: root
        }
    }

    Connections {
        target: root.application

        function onFilterBy(filter: string, query: string): void {
            root.filterBy(filter, query);
        }
    }

    Connections {
        target: KokoPrivate.OpenFileModel
        function onUpdatedImages(): void { // this gets called if we use "open with", while app is already open
            if (KokoPrivate.OpenFileModel.rowCount() > 1) {
                pageStack.clear();
                pageStack.layers.clear();
                pageStack.push(openFileComponent);
            } else if (KokoPrivate.OpenFileModel.rowCount() === 1) {
                pageStack.clear();
                pageStack.layers.clear();
                pageStack.push(albumViewComponent);
                albumView = pageStack.currentItem;
                albumView.isFolderView = true;
                const url = String(Koko.DirModelUtils.directoryOfUrl(KokoPrivate.OpenFileModel.urlToOpen)).replace("file:", "");
                albumView.model.sourceModel.url = url;
                fetchImageToOpen = true;
                pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                    imagesModel: imageFolderModel.sourceModel,
                    application: root.application,
                });
            }
        }
    }

    function filterBy(value: string, query: string): void {
        if (albumView === null || albumView !== pageStack.currentItem) {
            const component = Qt.createComponent("org.kde.koko", "AlbumView");
            if (component.status === Component.Error) {
                console.error(component.errorString());
                return;
            }

            albumView = component.createObject(root, {
                model: imageFolderModel,
                application: root.application,
                mainWindow: root,
            });

            albumView = switchApplicationPage(albumView);
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

        Kirigami.ContextDrawer {}
    }

    globalDrawer: Sidebar {
        mainWindow: root
        application: root.application
    }

    footer: BottomNavBar {
        mainWindow: root
    }

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
        root.visibility = Koko.Config.visibility
        root.controlsVisible = Koko.Config.controlsVisible
        pageStack.contentItem.columnResizeMode = Kirigami.ColumnView.SingleColumn
        if (KokoPrivate.OpenFileModel.rowCount() > 1) {
            pageStack.initialPage = openFileComponent;
        } else {
            pageStack.initialPage = albumViewComponent;

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
                imagesModel: imageFolderModel.sourceModel,
                application: root.application,
            });
        }
        
        // move mobile handles to toolbar
        pageStack.globalToolBar.canContainHandles = true;
    }
}
