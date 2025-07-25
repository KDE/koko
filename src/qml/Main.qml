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

    readonly property int sidebarWidth: Kirigami.Units.gridUnit * 14

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
        leftSidebar: root.globalDrawer
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
            globalDrawer.drawerOpen = !globalDrawer.modal;
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
    property bool fetchImageToOpen: Koko.OpenFileModel.rowCount() === 1

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
                sourceModel: Koko.OpenFileModel
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
        target: Koko.OpenFileModel
        function onUpdatedImages(): void { // this gets called if we use "open with", while app is already open
            if (Koko.OpenFileModel.rowCount() > 1) {
                pageStack.clear();
                pageStack.layers.clear();
                pageStack.push(openFileComponent);
            } else if (Koko.OpenFileModel.rowCount() === 1) {
                pageStack.clear();
                pageStack.layers.clear();
                pageStack.push(albumViewComponent);
                albumView = pageStack.currentItem;
                albumView.isFolderView = true;
                const url = String(Koko.DirModelUtils.directoryOfUrl(Koko.OpenFileModel.urlToOpen)).replace("file:", "");
                albumView.model.sourceModel.url = url;
                fetchImageToOpen = true;
                pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                    imagesModel: imageFolderModel.sourceModel,
                    application: root.application,
                    mainWindow: root,
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
                imageListModel.locationGroup = Koko.ImageStorage.Country;
                break;
            }
            case "States": {
                albumView.model = imageLocationModelState;
                imageListModel.locationGroup = Koko.ImageStorage.State;
                break;
            }
            case "Cities": {
                albumView.model = imageLocationModelCity;
                imageListModel.locationGroup = Koko.ImageStorage.City;
                break;
            }
            case "Years": {
                albumView.model = imageTimeModelYear;
                imageListModel.timeGroup = Koko.ImageStorage.Year;
                break;
            }
            case "Months": {
                albumView.model = imageTimeModelMonth;
                imageListModel.timeGroup = Koko.ImageStorage.Month;
                break;
            }
            case "Weeks": {
                albumView.model = imageTimeModelWeek;
                imageListModel.timeGroup = Koko.ImageStorage.Week;
                break;
            }
            case "Days": {
                albumView.model = imageTimeModelDay;
                imageListModel.timeGroup = Koko.ImageStorage.Day;
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
    wideScreen: width >= root.pageStack.defaultColumnWidth + root.sidebarWidth

    Component {
        id: contextDrawerComponent

        Kirigami.ContextDrawer {}
    }

    Loader {
        onItemChanged: root.globalDrawer = item
        active: !Kirigami.Settings.isMobile || root.wideScreen
        sourceComponent: Sidebar {
            mainWindow: root
            application: root.application
            sidebarWidth: root.sidebarWidth
        }
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
        filterRole: Koko.AbstractImageModel.MimeTypeRole
    }

    Koko.SortModel {
        id: imageTimeModelYear
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageStorage.Year
        }
        sortRoleName: "date"
    }

    Koko.SortModel {
        id: imageTimeModelMonth
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageStorage.Month
        }
        sortRoleName: "date"
    }

    Koko.SortModel {
        id: imageTimeModelWeek
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageStorage.Week
        }
        sortRoleName: "date"
    }

    Koko.SortModel {
        id: imageTimeModelDay
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageStorage.Day
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
            group: Koko.ImageStorage.Country
        }
    }

    Koko.SortModel {
        id: imageLocationModelState
        sourceModel: Koko.ImageLocationModel {
            group: Koko.ImageStorage.State
        }
    }

    Koko.SortModel {
        id: imageLocationModelCity
        sourceModel: Koko.ImageLocationModel {
            group: Koko.ImageStorage.City
        }
    }
    
    Koko.ImageGroupModel {
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

        if (Koko.OpenFileModel.rowCount() === 0) {
            root.application.action("place_pictures").trigger();
            return;
        }

        if (Koko.OpenFileModel.rowCount() > 1) {
            pageStack.initialPage = openFileComponent;
        } else {
            root.application.action("place_pictures").trigger();
            albumView.isFolderView = true;
        }

        if (Koko.OpenFileModel.rowCount() === 1) {
            if (Koko.DirModelUtils.isDirectory(Koko.OpenFileModel.urlToOpen)) {
                albumView.model.sourceModel.url = Koko.OpenFileModel.urlToOpen
                return;
            }

            const url = String(Koko.DirModelUtils.directoryOfUrl(Koko.OpenFileModel.urlToOpen)).replace("file:", "");
            albumView.model.sourceModel.url = url;
            fetchImageToOpen = true;
            pageStack.layers.push(Qt.resolvedUrl("ImageViewPage.qml"), {
                imagesModel: imageFolderModel.sourceModel,
                application: root.application,
                mainWindow: root,
            });
        }

        // move mobile handles to toolbar
        pageStack.globalToolBar.canContainHandles = true;
    }
}
