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
import QtQuick.Controls 2.1 as Controls
import org.kde.kirigami 2.0 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.koko 0.1 as Koko

Kirigami.Page {
    id: rootEditorView
    title: i18n("Edit")
    leftPadding: 0
    rightPadding: 0
    
    property string imagePath
    
    Koko.ImageDocument {
        id: imageDoc
        path: imagePath
    }
    
    contentItem: Flickable {
        width: rootEditorView.width
        height: rootEditorView.height
        KQA.QImageItem {
            id: editImage
            width: rootEditorView.width
            height: rootEditorView.height
            image: imageDoc.visualImage
        }
    }
    
}
