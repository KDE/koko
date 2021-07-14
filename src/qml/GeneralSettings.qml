/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Layouts 1.3

import org.kde.kirigami 2.17 as Kirigami

Kirigami.GenericSettingsPage {
    title: i18n("General")

    QQC2.CheckBox {
        Kirigami.FormData.label: i18n("General:")
        text: i18n("Show preview carousel in image view")
        checked: kokoConfig.imageViewPreview
        onCheckedChanged: kokoConfig.imageViewPreview = checked
    }
    QQC2.Slider {
        Kirigami.FormData.label: i18n("Slideshow interval:")
        from: 1
        to: 60
        value: kokoConfig.nextImageInterval
        onMoved: kokoConfig.nextImageInterval = value;
    }
    QQC2.Label {
        text: i18np("1 second", "%1 seconds", kokoConfig.nextImageInterval)
    }
    QQC2.CheckBox {
        text: i18n("Loop")
        checked: kokoConfig.loopImages
        onCheckedChanged: kokoConfig.loopImages = checked
        enabled: !randomizeImagesCheckbox.checked
    }
    QQC2.CheckBox {
        id: randomizeImagesCheckbox
        text: i18n("Random")
        checked: kokoConfig.randomizeImages
        onCheckedChanged: kokoConfig.randomizeImages = checked
    }
}
