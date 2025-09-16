/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kquickcontrolsaddons as KQA
import org.kde.koko as Koko

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

    title: pageStack?.currentItem?.title ?? "";

    pageStack {
        globalToolBar {
            canContainHandles: true
            style: Kirigami.ApplicationHeaderStyle.ToolBar
            showNavigationButtons: Kirigami.ApplicationHeaderStyle.ShowBackButton;
        }
        popHiddenPages: true

        columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
        columnView.onVisibleChanged: root.updateGlobalDrawer()
        leftSidebar: root.globalDrawer
    }

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20

    function switchApplicationPage(page: Kirigami.Page): Kirigami.Page {
        if (!page || root.pageStack.currentItem === page) {
            return page as Kirigami.Page;
        }

        root.pageStack.clear();
        root.pageStack.push(page);

        return root.pageStack.currentItem as Kirigami.Page;
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
        if (globalDrawer) {
            globalDrawer.drawerOpen = !globalDrawer.modal;
        }
    }

    signal settingsOpened(bool isPage)
    signal placesOpened()

    property var galleryPage: null
    property var placesView: null

    Kirigami.Action {
        fromQAction: root.application.action('open_kcommand_bar')
    }

    Connections {
        target: root.application

        function onNavigate(modelType, path) : void {
            root.navigate(modelType, path);
        }
    }

    function navigate(modelType, path): void {
        let targetModel;

        switch (modelType) {
            case Koko.PhotosApplication.OpenModel:
                targetModel = Koko.GalleryOpenModel;
                break;
            case Koko.PhotosApplication.FolderModel:
                targetModel = galleryFolderModel;
                break;
            case Koko.PhotosApplication.FavoritesModel:
                targetModel = galleryFavoritesModel;
                break;
            case Koko.PhotosApplication.LocationModel:
                targetModel = galleryLocationModel;
                break;
            case Koko.PhotosApplication.TimeModel:
                targetModel = galleryTimeModel;
                break;
            case Koko.PhotosApplication.TagsModel:
                targetModel = galleryTagsModel;
                break;
            default:
                return;
        }

        if (root.galleryPage === null || root.galleryPage !== pageStack.currentItem || root.galleryPage.galleryModel !== targetModel) {
            // Create a new page

            if (targetModel instanceof Koko.AbstractNavigableGalleryModel) {
                targetModel.path = path;
            }

            const component = Qt.createComponent("org.kde.koko", "GalleryPage");
            if (component.status === Component.Error) {
                console.error(component.errorString());
                return;
            }

            root.galleryPage = component.createObject(root, {
                application: root.application,
                mainWindow: root,
                galleryModel: targetModel
            })

            root.galleryPage = switchApplicationPage(root.galleryPage);
            // Give an arbitrary size to the album view:
            // Otherwise it won't get laid out when invisible when the app is started with an image
            // as parameter and its size will stay 0,0
            // When this happen, seems that GridView is trying to instantiate every single
            // delegate, leading to possible long freezes in the app
            root.galleryPage.width = 200
            root.galleryPage.height = 200
        } else {
            // Use existing page

            // Do not preserve history for OpenModel, which will have changed
            let preserveHistory = (modelType === Koko.PhotosApplication.OpenModel);

            root.galleryPage.navigate(path, preserveHistory);
        }

        root.galleryPage.gridViewItem.forceActiveFocus();
    }

    function openWith(): void {
        switch (Koko.GalleryOpenModel.mode) {
            case Koko.GalleryOpenModel.OpenNone:
                return;

            case Koko.GalleryOpenModel.OpenFolder:
                root.navigate(Koko.PhotosApplication.FolderModel, Koko.GalleryOpenModel.urlToOpen);
                return;

            case Koko.GalleryOpenModel.OpenImage:
                root.navigate(Koko.PhotosApplication.FolderModel, Koko.DirModelUtils.directoryOfUrl(Koko.GalleryOpenModel.urlToOpen));
                root.galleryPage.openMediaViewPage(Koko.GalleryOpenModel.urlToOpen);
                return;

            case Koko.GalleryOpenModel.OpenMultiple:
                root.navigate(Koko.PhotosApplication.OpenModel, []);
                return;
        }
    }

    Koko.GalleryFolderModel {
        id: galleryFolderModel
    }

    Koko.GalleryFavoritesModel {
        id: galleryFavoritesModel
    }

    Koko.GalleryLocationModel {
        id: galleryLocationModel
    }

    Koko.GalleryTimeModel {
        id: galleryTimeModel
    }

    Koko.GalleryTagsModel {
        id: galleryTagsModel
    }

    Connections {
        target: Koko.GalleryOpenModel
        function onUpdated(): void {
            root.openWith();
        }
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
        onActiveChanged: {
            if (item) {
                updateGlobalDrawer();
            }
        }
        sourceComponent: Sidebar {
            mainWindow: root
            application: root.application
            sidebarWidth: root.sidebarWidth
        }
    }

    footer: BottomNavBar {
        mainWindow: root
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

        // move mobile handles to toolbar
        pageStack.globalToolBar.canContainHandles = true;

        root.pageStack.clear();
        root.pageStack.layers.clear();

        if (Koko.GalleryOpenModel.mode === Koko.GalleryOpenModel.OpenNone) {
            root.application.action("place_pictures").trigger();
        } else {
            root.openWith();
        }
    }
}
