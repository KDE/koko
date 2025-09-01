/*
 * SPDX-FileCopyrightText: 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQml
import QtQuick.Window
import org.kde.koko as Koko
import org.kde.photos.thumbnails as KokoThumbnails

Loader {
    id: loader

    required property int index
    required property url imageurl
    required property string content
    readonly property alias type: info.type
    readonly property alias mimeType: info.mimeType

    readonly property bool dragging: item && item.dragging
    readonly property bool interactive: item && item.interactive

    width: ListView.view.width
    height: ListView.view.height

    property bool supportsVideo: true


    // Don't load images that are not going to be visible.
    active: visible
    onActiveChanged: {
        if (active && info.delegateSource && info.initialProperties) {
            setSource(info.delegateSource, info.initialProperties);
        }
    }

    asynchronous: true

    Koko.FileInfo {
        id: info

        source: loader.imageurl

        // Unfortunately, just binding active to visible above and using
        // setSource in the onStatusChanged handler leads to occasional
        // invisible images due to a slight race condition. Therefore,
        // we need to store them separately and update whenever either
        // delegateSource changes or the loader's active property changes.
        property var initialProperties
        property url delegateSource

        onDelegateSourceChanged: {
            if (loader.active && delegateSource && initialProperties) {
                loader.setSource(delegateSource, initialProperties);
            }
        }

        onInfoChanged: statusChanged()
        onStatusChanged: {
            if (status != Koko.FileInfo.Ready) {
                return;
            }

            let delegate = "";
            let properties = {
                source: Qt.binding(() => loader.imageurl),
                isCurrent: Qt.binding(() => loader.ListView.isCurrentItem),
                mainWindow: root.mainWindow,
                preferAsync: loader.asynchronous
            };

            switch (type) {
            case Koko.FileInfo.VideoType:
                if (!loader.supportsVideo) {
                    return;
                }
                properties.autoplay = Qt.binding(() => loader.index === root.startIndex);
                properties.slideShow = slideshowManager;
                delegate = Qt.resolvedUrl("imagedelegate/VideoDelegate.qml");
                break;
            case Koko.FileInfo.VectorImageType:
                delegate = Qt.resolvedUrl("imagedelegate/VectorImageDelegate.qml");
                break;
            case Koko.FileInfo.AnimatedImageType:
                delegate = Qt.resolvedUrl("imagedelegate/AnimatedImageDelegate.qml");
                break;
            case Koko.FileInfo.RasterImageType:
                delegate = Qt.resolvedUrl("imagedelegate/RasterImageDelegate.qml");
                break;
            default:
                console.warn("Unknown file type for URL", loader.imageurl);
                break;
            }

            if (delegate) {
                // Important: Since the signal handler responsible for
                // loading is attached to the onDelegateSourceChanged,
                // this needs to make sure initialProperties is changed
                // before delegateSource, as otherwise the code will
                // ignore the new initialProperties.
                initialProperties = properties;
                delegateSource = delegate;
            } else {
                initialProperties = {};
                delegateSource = "";
            }
        }
    }
}
