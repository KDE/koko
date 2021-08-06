
import QtQuick 2.15
import QtQml 2.15

import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1 as Koko

Item {
    id: root

    property url source

    property bool smooth

    property Image activeImage

    property int status: d.activeImage.status

    property size sourceSize: Qt.size(extractor.width, extractor.height)

    property rect viewportRect
    onViewportRectChanged: Qt.callLater(d.updateSource)

    property size targetSize
    onTargetSizeChanged: {
        d.activeImage.visible = false
        Qt.callLater(d.updateSource)
    }

    //
    property bool largeImage: Math.max(extractor.width, extractor.height) > 5000

    // Provide a base image that is either at the original size or a scaled down
    // version of the original for large images. When not using a large image,
    // it will behave normally, when using a large image it will act as a base
    // layer that will be shown while the proper scaled image is being loaded.
    Image {
        id: baseLevelImage

        anchors.fill: parent

        source: root.source
        asynchronous: true
        smooth: root.smooth
        cache: false
        autoTransform: true

        sourceSize: {
            if (!root.largeImage) {
                return undefined;
            } else {
                return Qt.size(extractor.width / 10, extractor.height / 10)
            }
        }
    }

    // When using a large image, these two images will be swapped based on which
    // one is currently visible and which one is loading image data. They are
    // positioned and scaled based on the viewportRect and targetSize.
    Image {
        id: image0

        visible: d.largeImage

        smooth: parent.smooth
        asynchronous: true
        cache: false
        autoTransform: true


        onStatusChanged: {
            if (status === Image.Ready && d.inactiveImage == image0) {
                d.imageLoaded()
            }
        }
    }

    Image {
        id: image1

        visible: false

        smooth: parent.smooth
        asynchronous: true
        cache: false
        autoTransform: true

        onStatusChanged: {
            if (status === Image.Ready  && d.inactiveImage == image1) {
                d.imageLoaded()
            }
        }
    }

    QtObject {
        id: d

        property Image activeImage: image0
        property Image inactiveImage: image1

        function updateSource() {
            if (!root.largeImage) {
                return
            }

            let size = Qt.size(Math.min(root.targetSize.width, extractor.width), Math.min(root.targetSize.height, extractor.height))

            if (!d.activeImage.source) {
                updateImage(d.activeImage, size)
            }

            updateImage(d.inactiveImage, size)
        }

        // Swap active and inactive images, making the inactive image visible
        // and hiding and unloading the active image.
        function imageLoaded() {
            if (!root.largeImage) {
                return
            }

            inactiveImage.visible = true
            activeImage.visible = false
            activeImage.source = ""

            let tmp = activeImage
            activeImage = inactiveImage
            inactiveImage = tmp
        }

        function updateImage(image, sourceSize) {
            image.sourceClipRect = root.viewportRect
            image.x = root.viewportRect.x
            image.y = root.viewportRect.y
            image.width = root.viewportRect.width
            image.height = root.viewportRect.height
            image.source = root.source
            image.sourceSize = sourceSize
        }
    }

    Koko.Exiv2Extractor {
        id: extractor
        filePath: root.source
    }
}
