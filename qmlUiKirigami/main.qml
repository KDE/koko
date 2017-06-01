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

import org.kde.kirigami 2.0 as Kirigami
import org.kde.koko 0.1 as Koko

Kirigami.ApplicationWindow {
    id: root
    
    pageStack.initialPage: AlbumView {
        id: albumView
        model: imageFolderModel
        onImageClicked: pageStack.push(overviewPage, { "model": files})
    }
    
    globalDrawer: Sidebar {
        onFilterBy: {
            pageStack.pop(albumView)
            switch( value){
                case "country": { 
                    albumView.model = imageLocationModelCountry;
                    break;
                }
                case "state": { 
                    albumView.model = imageLocationModelState;
                    break;
                }
                case "city": {
                    albumView.model = imageLocationModelCity;
                    break;
                }
                case "year": {
                    albumView.model = imageTimeModelYear; 
                    break;
                }
                case "month": {
                    albumView.model = imageTimeModelMonth;
                    break;
                }
                case "week": {
                    albumView.model = imageTimeModelWeek; 
                    break;
                }
                case "day": { 
                    albumView.model = imageTimeModelDay; 
                    break;
                }
                case "folder": { 
                    albumView.model = imageFolderModel; 
                    break; 
                }
            }
        }
    }
    
    Koko.ImageFolderModel {
        id: imageFolderModel
    }  
    
    Koko.ImageTimeModel {
        id: imageTimeModelYear
        group: Koko.ImageTimeModel.Year
    }
    
    Koko.ImageTimeModel {
        id: imageTimeModelMonth
        group: Koko.ImageTimeModel.Month
    }
    
    Koko.ImageTimeModel {
        id: imageTimeModelWeek
        group: Koko.ImageTimeModel.Week
    }
    
    Koko.ImageTimeModel {
        id: imageTimeModelDay
        group: Koko.ImageTimeModel.Day
    }
    
    Koko.ImageLocationModel {
        id: imageLocationModelCountry
        group: Koko.ImageLocationModel.Country
    }    
    
    Koko.ImageLocationModel {
        id: imageLocationModelState
        group: Koko.ImageLocationModel.State
    }
    
    Koko.ImageLocationModel {
        id: imageLocationModelCity
        group: Koko.ImageLocationModel.City
    }
    
    Component {
        id: overviewPage
        OverviewPage {}
    }
}
