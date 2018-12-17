/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.7

import org.kde.koko 0.1 as Koko

AlbumView {
    property alias sourceUrl: albumViewFolderModel.url
    
    model: Koko.SortModel {
        sourceModel: Koko.ImageFolderModel { 
            id: albumViewFolderModel
            onRowsInserted: {
                if (indexForUrl(imagePathArgument[imagePathArgument.length - 1]) != -1) {
                    currentImage.model = this
                    currentImage.index = indexForUrl(imagePathArgument[imagePathArgument.length - 1])
                }
            }
        }
    }
    
}
