import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Layouts 1.3

import org.kde.kcm 1.2 as KCM
import org.kde.kirigami 2.12 as Kirigami

KCM.SimpleKCM {
    title: i18n("Settings")
    Kirigami.FormLayout {
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
    }
}
