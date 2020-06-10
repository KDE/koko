/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.7

import org.kde.kirigami 2.1 as Kirigami

Rectangle { 
    anchors.fill: parent
    z: gridView.z + 1
    
    color: Kirigami.Theme.highlightColor
    opacity: 0.5    
}
