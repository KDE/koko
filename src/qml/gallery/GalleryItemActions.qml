import QtQuick

import org.kde.kirigami as Kirigami

import org.kde.koko as Koko

QtObject {
    id: root

    required property fileItemList fileItems
    required property bool isTrashView
    required property Kirigami.ApplicationWindow mainWindow

    readonly property list<url> urls: fileItems.map(item => item.url)

    readonly property bool hasItems: fileItems.length > 0
    readonly property bool singleItem: fileItems.length === 1

    Koko.Exiv2Extractor {
        id: exiv2Extractor
        filePath: root.singleItem ? root.fileItems[0] : undefined
    }

    readonly property Kirigami.Action favoriteAction: Kirigami.Action {
        icon.name: exiv2Extractor.favorite ? "starred-symbolic" : "non-starred-symbolic"
        text: exiv2Extractor.favorite ? i18nc("@action:intoolbar Favorite an image/video", "Favorite")
                                      : i18nc("@action:intoolbar Unfavorite an image/video", "Unfavorite")

        onTriggered: {
            exiv2Extractor.toggleFavorite(exiv2extractor.filePath.toString().replace("file://", ""));
            // makes change immediate
            kokoProcessor.removeFile(exiv2extractor.filePath.toString().replace("file://", ""));
            kokoProcessor.addFile(exiv2extractor.filePath.toString().replace("file://", ""));
        }

        enabled: root.singleItem
        visible: root.singleItem
    }

    readonly property Kirigami.Action shareAction: ShareAction {
        tooltip: i18nc("@info:tooltip", "Share the selected media")
        application: root.mainWindow

        inputData: {
            "urls": root.urls,
            "mimeType": fileItems.map(item => item.mimetype)
        }

        enabled: root.hasItems
        visible: root.hasItems
    }

    readonly property Kirigami.Action restoreTrashAction: Kirigami.Action {
        icon.name: "edit-reset-symbolic"
        text: i18nc("@action:button Restore the selected media from the trash", "Restore")
        tooltip: i18nc("@info:tooltip", "Restore the selected media to their former locations")

        onTriggered: Koko.DirModelUtils.restoreUrls(root.urls)

        enabled: hasItems && root.isTrashView
        visible: hasItems && root.isTrashView
    }
}
