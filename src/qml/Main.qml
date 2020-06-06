/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.1
import QtQuick.Controls 2.0 as Controls

import org.kde.kirigami 2.5 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.koko 0.1 as Koko

Kirigami.ApplicationWindow {
    id: root

    /*
     * currentImage now stores the information related to the source model
     */
    QtObject {
        id: currentImage
        property int index
        property var model
    }

    pageStack.initialPage: AlbumView {
        id: albumView
        model: imageFolderModel
        title: i18n("Folders")
    }

    pageStack.layers.onDepthChanged: {
        sideBar.enabled = pageStack.layers.depth < 2;
        sideBar.drawerOpen = !Kirigami.Settings.isMobile && pageStack.layers.depth < 2;
    }

    globalDrawer: Sidebar {
        id: sideBar

        onFilterBy: {
            pageStack.pop(albumView)
            albumView.title = i18n(value)
            previouslySelectedAction.checked = false
            
            switch( value){
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
                case "Folders": { 
                    albumView.model = imageFolderModel; 
                    imageListModel.locationGroup = -1;
                    imageListModel.timeGroup = -1;
                    break; 
                }
            }
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
}
