/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.1
import QtQuick.Controls 2.0 as Controls

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.koko 0.1 as Koko
import org.kde.koko.private 0.1 as KokoPrivate

Kirigami.ApplicationWindow {
    id: root

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20

    function switchApplicationPage(page) {
        if (!page || pageStack.currentItem == page) {
            return;
        }

        pageStack.pop(albumView);
        pageStack.push(page);
        page.forceActiveFocus();
    }

    property bool imageFromParameter: false
    property var albumView: null
    // fetch guard, so we don't needlessly check for image to open when it's not needed
    // this is a temporary binding that's supposed to be broken
    property bool fetchImageToOpen: KokoPrivate.OpenFileModel.rowCount() === 1

    pageStack.layers.onDepthChanged: {
        if (!fetchImageToOpen) {
            sideBar.enabled = pageStack.layers.depth < 2;
            sideBar.drawerOpen = !Kirigami.Settings.isMobile && !sideBar.modal && pageStack.layers.depth < 2;
        }
    }

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

    contextDrawer: Kirigami.ContextDrawer {}

    Connections {
        target: KokoPrivate.OpenFileModel
        function onUpdatedImages() { // this gets called if we use "open with", while app is already open
            if (KokoPrivate.OpenFileModel.rowCount() > 1) {
                imageFromParameter = true;
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

    Component.onCompleted: {
        pageStack.contentItem.columnResizeMode = Kirigami.ColumnView.SingleColumn
        if (KokoPrivate.OpenFileModel.rowCount() > 1) {
            pageStack.initialPage = openFileComponent;
            imageFromParameter = true;
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
    }

    globalDrawer: Sidebar {
        id: sideBar
        tags: imageTagsModel.sourceModel.tags

        onFilterBy: {
            if (imageFromParameter) {
                pageStack.pop(albumView);
                albumView = pageStack.replace(Kirigami.Settings.isMobile ? albumViewComponentMobile : albumViewComponent);
                imageFromParameter = false;
            } else {
                pageStack.pop(albumView)
            }
            if (value === "Folders" && query.length > 0) {
                let str = query
                if (str.endsWith("/")) {
                    str = str.slice(0, -1)
                }
                albumView.title = str.split("/")[str.split("/").length-1]
            } else if (value === "Tags") {
                albumView.title = query
            } else {
                albumView.title = i18n(value)
            }
            if (previouslySelectedAction) {
                previouslySelectedAction.checked = false
            }
            currentlySelectedAction.checked = true;
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
                    imageTagsModel.sourceModel.tag = query
                    imageListModel.locationGroup = -1;
                    imageListModel.timeGroup = -1;
                    break;
                }
                case "Trash":
                case "Remote":
                case "Folders": {
                    albumView.model = imageFolderModel; 
                    albumView.model.sourceModel.url = query
                    albumView.isFolderView = (value === "Folders");
                    imageListModel.locationGroup = -1;
                    imageListModel.timeGroup = -1;
                    break;
                }
            }
            albumView.gridViewItem.forceActiveFocus();
        }
        contentObject: [
            Kirigami.BasicListItem {
                text: i18n("Settings")
                onClicked: root.pageStack.layers.push(settingsPage)
                icon: "settings-configure"
            },
            Kirigami.BasicListItem {
                text: i18n("About")
                onClicked: root.pageStack.layers.push(aboutPage)
                icon: "help-about"
            }
        ]
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

    Component {
        id: aboutPage
        Kirigami.AboutPage {
            aboutData: kokoAboutData
        }
    }

    Component {
        id: settingsPage
        SettingsPage {
        }
    }
}
