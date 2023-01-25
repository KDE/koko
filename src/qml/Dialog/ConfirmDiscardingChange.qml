// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

QQC2.Dialog {
    id: root

    signal discardChanges()

    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    modal: true

    ColumnLayout {
        Kirigami.Heading {
            text: i18n("Discard changes")
        }
        QQC2.Label {
            text: i18n("Are you sure you want to discard all changes?")
        }
    }

    footer: QQC2.DialogButtonBox {
        QQC2.Button {
            text: i18n("Cancel")
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
            onClicked: root.close()
        }

        QQC2.Button {
            text: i18n("Yes")
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            onClicked: {
                root.discardChanges();
                root.close();
            }
        }
    }

    background: Kirigami.ShadowedRectangle {
        radius: 7
        color: Kirigami.Theme.backgroundColor

        border {
            width: 1
            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.3);
        }

        shadow {
            size: Kirigami.Units.gridUnit
            yOffset: 4
            color: Qt.rgba(0, 0, 0, 0.2)
        }

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
    }
}
