/*
 *  SPDX-FileCopyrightText: 2022 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kquickimageeditor

AnnotationViewport {
    id: root

    document: AnnotationDocument {}
    viewportRect: Qt.rect(0, 0, width, height)

    Shortcut {
        enabled: root.enabled
        sequences: [StandardKey.Undo]
        onActivated: root.document.undo()
    }
    Shortcut {
        enabled: root.enabled
        sequences: [StandardKey.Redo]
        onActivated: root.document.redo()
    }
}
