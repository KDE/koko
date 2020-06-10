/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
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
