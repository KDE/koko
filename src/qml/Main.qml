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

    pageStack.layers.onDepthChanged: {
        sideBar.enabled = pageStack.layers.depth < 2;
        sideBar.drawerOpen = !Kirigami.Settings.isMobile && !sideBar.modal && pageStack.layers.depth < 2;
    }

    Component {
        id: openFileComponent
        AlbumView {
            title: i18n("Images")
            model: Koko.SortModel {
                id: imageLocationModelCity
                sourceModel: KokoPrivate.OpenFileModel
            }
        }
    }

    Component {
        id: albumViewComponent
        AlbumView {
            model: imageFolderModel
            title: i18n("Folders")
        }
    }

    contextDrawer: Kirigami.ContextDrawer {}

    Component.onCompleted: {
        pageStack.contentItem.columnResizeMode = Kirigami.ColumnView.SingleColumn
        if (KokoPrivate.OpenFileModel.rowCount() > 0) {
            pageStack.initialPage = openFileComponent;
            imageFromParameter = true;
        } else {
            pageStack.initialPage = albumViewComponent;
        }
        albumView = pageStack.currentItem;
        if (KokoPrivate.OpenFileModel.rowCount() === 0) {
            albumView.isFolderView = true;
        }
    }

    globalDrawer: Sidebar {
        id: sideBar

        onFilterBy: {
            if (imageFromParameter) {
                pageStack.pop(albumView);
                albumView = pageStack.replace(albumViewComponent);
                imageFromParameter = false;
            } else {
                pageStack.pop(albumView)
            }
            if (value === "Folders" && path.length > 0) {
                let str = path
                if (str.endsWith("/")) {
                    str = str.slice(0, -1)
                }
                albumView.title = str.split("/")[str.split("/").length-1]
            } else {
                albumView.title = i18n(value)
            }
            if (previouslySelectedAction) {
                previouslySelectedAction.checked = false
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
                case "Folders": {
                    albumView.model = imageFolderModel; 
                    albumView.model.sourceModel.url = path
                    albumView.isFolderView = true;
                    imageListModel.locationGroup = -1;
                    imageListModel.timeGroup = -1;
                    break;
                }
            }
            albumView.forceActiveFocus();
        }
        Kirigami.BasicListItem {
            text: i18n("Settings")
            onClicked: root.pageStack.layers.push(settingsPage)
            icon: "settings-configure"
        }
        Kirigami.BasicListItem {
            text: i18n("About")
            onClicked: root.pageStack.layers.push(aboutPage)
            icon: "help-about"
        }
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

    Kirigami.AboutPage {
        id: aboutPage
        aboutData: kokoAboutData
    }

    SettingsPage {
        id: settingsPage
    }
}
