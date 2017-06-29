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
    header: Kirigami.ApplicationHeader {}
    
    QtObject {
        id: currentImage
        property int index
        property var model
    }
    
    pageStack.initialPage: AlbumView {
        id: albumView
        onCollectionSelected: pageStack.push(overviewPage, { "model": files, "title": cover})
    }
    
    globalDrawer: Sidebar {
        id: sideBar
        onFilterBy: {
            pageStack.pop(albumView)
            albumView.title = value
            previouslySelectedAction.checked = false
            
            switch( value){
                case "Countries": { 
                    albumView.model = imageLocationModelCountry;
                    break;
                }
                case "States": { 
                    albumView.model = imageLocationModelState;
                    break;
                }
                case "Cities": {
                    albumView.model = imageLocationModelCity;
                    break;
                }
                case "Years": {
                    albumView.model = imageTimeModelYear; 
                    break;
                }
                case "Months": {
                    albumView.model = imageTimeModelMonth;
                    break;
                }
                case "Weeks": {
                    albumView.model = imageTimeModelWeek; 
                    break;
                }
                case "Days": { 
                    albumView.model = imageTimeModelDay; 
                    break;
                }
                case "Folders": { 
                    albumView.model = imageFolderModel; 
                    break; 
                }
            }
        }
    }
    
    Koko.SortModel{
        id: imageFolderModel
        sourceModel: Koko.ImageFolderModel {}
    }
    
    Koko.SortModel {
        id: imageTimeModelYear
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageTimeModel.Year
        }
    }
    
    Koko.SortModel {
        id: imageTimeModelMonth
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageTimeModel.Month
        }
    }
    
    Koko.SortModel {
        id: imageTimeModelWeek
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageTimeModel.Week
        }
    }
    
    Koko.SortModel {
        id: imageTimeModelDay
        sourceModel: Koko.ImageTimeModel {
            group: Koko.ImageTimeModel.Day
        }
    }
    
    Koko.SortModel {
        id: imageLocationModelCountry
        sourceModel: Koko.ImageLocationModel {
            group: Koko.ImageLocationModel.Country
        }
    }
        
    Koko.SortModel {
        id: imageLocationModelState
        sourceModel: Koko.ImageLocationModel {
            group: Koko.ImageLocationModel.State
        }
    }
    
    Koko.SortModel {
        id: imageLocationModelCity
        sourceModel: Koko.ImageLocationModel {
            group: Koko.ImageLocationModel.City
        }
    }    
    
    Component {
        id: overviewPage
        AlbumView {
            id: overviewPageAlbum
            onImageSelected: {
                currentImage.model = model
                currentImage.index = currentIndex
                imageViewer.state = "open";
            }
        }
    }
    
    ImageViewer {
        id: imageViewer
        //go on top of the overlay drawer
        z: sideBar.z+1
        parent: root.overlay
        width: overlay.width
        height: overlay.height
        currentIndex: currentImage.index
        model: currentImage.model        
        focus: true
        imageWidth: root.width
        imageHeight: root.height
    }

    Component.onCompleted: {
        albumView.model = imageFolderModel
        albumView.title = "Folders"
    }
}
