// SPDX-FileCopyrightText: 2024 KDE Image Viewer Integration
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import org.kde.kirigami as Kirigami

/**
 * Action that allows setting the current image as desktop wallpaper
 */
Kirigami.Action {
    id: wallpaperAction

    text: i18nc("@action Set image as wallpaper", "Set as &Wallpaper")
    icon.name: "desktop-symbolic"
    tooltip: i18nc("@info:tooltip", "Set the current image as desktop wallpaper")

    /**
     * The image path to set as wallpaper
     */
    property string imagePath: ""

    onTriggered: {
        if (imagePath === "") {
            return;
        }
        
        // Create wallpaper service instance
        const wallpaperService = Qt.createQmlObject('import org.kde.koko 1.0; WallpaperService {}', wallpaperAction);
        
        // Connect signals
        wallpaperService.wallpaperSet.connect(function(path) {
            console.log("Wallpaper set successfully:", path);
        });
        
        wallpaperService.wallpaperError.connect(function(error) {
            console.error("Failed to set wallpaper:", error);
        });
        
        // Set the wallpaper (no confirmation needed)
        wallpaperService.setWallpaper(imagePath);
    }
}
