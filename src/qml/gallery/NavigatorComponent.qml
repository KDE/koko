/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.koko as Koko

RowLayout {
    id: root

    required property Koko.AbstractGalleryModel galleryModel
    required property bool canNavigateBackward
    required property bool canNavigateForward

    readonly property var path: galleryModel.path

    signal navigate(path : var)
    signal navigateBackward()
    signal navigateForward()

    enum NavigatorRoot {
        Unknown = 0,
        Home = 1, // Handled by Koko.DirModelUtils.partialUrlForIndex
        Trash = 2,
        Remote = 3,
        Afc = 4,
        Bluetooth = 5,
        Mtp = 6,
        Smb = 7,
        Root = 8,
        Tags = 9,
        Time = 10,
        Location = 11,
        Open = 12
    }

    spacing: Kirigami.Units.smallSpacing

    Controls.ToolButton {
        id: backButton

        icon.name: LayoutMirroring.enabled ? "go-previous-symbolic-rtl" : "go-previous-symbolic"
        text: i18nc("@action:button", "Back")
        display: Controls.AbstractButton.IconOnly

        Controls.ToolTip.text: text
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

        enabled: root.canNavigateBackward
        onClicked: root.navigateBackward()
    }

    Controls.ToolButton {
        id: forwardButton

        icon.name: LayoutMirroring.enabled ? "go-next-symbolic-rtl" : "go-next-symbolic"
        text: i18nc("@action:button", "Forward")
        display: Controls.AbstractButton.IconOnly

        Controls.ToolTip.text: text
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

        enabled: root.canNavigateForward
        onClicked: root.navigateForward()
    }

    Kirigami.Separator {
        Layout.fillHeight: true
    }

    Item {
        id: navigatorContainer
        Layout.fillWidth: true
        Layout.fillHeight: true

        implicitWidth: navigatorRoot.childrenContributingWidth.reduce((total, child) => total + child.implicitWidth, 0)

        RowLayout {
            id: navigatorRoot

            anchors.fill: parent

            readonly property bool isUrlNavigator: root.galleryModel instanceof Koko.GalleryFolderModel
            readonly property list<Item> childrenContributingWidth: navigatorRoot.children.filter(child => child instanceof RowLayout
                                                                                                        || child instanceof Controls.ToolButton)

            // We want to keep at least two path buttons visible, to always allow upward navigation
            property bool restrictedWidthMode: false

            Component.onCompleted: updateLayout()
            onWidthChanged: updateLayout()

            Connections {
                target: root
                function onPathChanged() { navigatorRoot.updateLayout(); }
            }

            function updateLayout() : void {
                let layoutChildren = navigatorRoot.childrenContributingWidth;
                let remainingWidth = navigatorRoot.width;
                let childrenVisibilities = [];
                let restrictedWidth = false;

                for (let i = layoutChildren.length - 1; i >= 0; --i) {
                    remainingWidth -= layoutChildren[i].implicitWidth;
                    childrenVisibilities[i] = (remainingWidth >= 0);
                }

                let widthRestricted = childrenVisibilities.length >= 2 && childrenVisibilities.filter(x => x).length < 2;
                if (widthRestricted) {
                    // Ensure the last two items are visible
                    childrenVisibilities.fill(true, childrenVisibilities.length - 2);
                }

                layoutChildren.forEach((child, i) => child.visible = childrenVisibilities[i]);
                navigatorRoot.restrictedWidthMode = widthRestricted;
            }

            spacing: 0

            Controls.ToolButton {
                id: navigatorRootButton

                readonly property int rootLocation: {
                    if (navigatorRoot.isUrlNavigator) {
                        if (Koko.DirModelUtils.inHome(root.path))
                            return NavigatorComponent.NavigatorRoot.Home;
                        if (root.path.toString().startsWith("trash:"))
                            return NavigatorComponent.NavigatorRoot.Trash;
                        if (root.path.toString().startsWith("remote:"))
                            return NavigatorComponent.NavigatorRoot.Remote;
                        if (root.path.toString().startsWith("afc:"))
                            return NavigatorComponent.NavigatorRoot.Afc;
                        if (root.path.toString().startsWith("bluetooth:"))
                            return NavigatorComponent.NavigatorRoot.Bluetooth;
                        if (root.path.toString().startsWith("mtp:"))
                            return NavigatorComponent.NavigatorRoot.Mtp;
                        if (root.path.toString().startsWith("smb:"))
                            return NavigatorComponent.NavigatorRoot.Smb;

                        return NavigatorComponent.NavigatorRoot.Root;
                    } else {
                        if (root.galleryModel instanceof Koko.GalleryTagsModel)
                            return NavigatorComponent.NavigatorRoot.Tags;
                        if (root.galleryModel instanceof Koko.GalleryTimeModel)
                            return NavigatorComponent.NavigatorRoot.Time;
                        if (root.galleryModel instanceof Koko.GalleryLocationModel)
                            return NavigatorComponent.NavigatorRoot.Location;
                        if (root.galleryModel instanceof Koko.GalleryOpenModel)
                            return NavigatorComponent.NavigatorRoot.Open;
                    }

                    console.warn("Unknown navigator root");
                    return NavigatorComponent.NavigatorRoot.Unknown;
                }

                readonly property var rootLocations: ({
                    [NavigatorComponent.NavigatorRoot.Unknown]: {
                        icon: "folder-root-symbolic",
                        path: []
                    },
                    [NavigatorComponent.NavigatorRoot.Home]: {
                        icon: "go-home-symbolic",
                        path: "file:///" + Koko.DirModelUtils.home
                    },
                    [NavigatorComponent.NavigatorRoot.Trash]: {
                        icon: "user-trash-symbolic",
                        path: "trash:/"
                    },
                    [NavigatorComponent.NavigatorRoot.Remote]: {
                        icon: "folder-cloud-symbolic",
                        path: "remote:/"
                    },
                    [NavigatorComponent.NavigatorRoot.Afc]: {
                        icon: "phone-apple-iphone-symbolic",
                        path: "afc:/"
                    },
                    [NavigatorComponent.NavigatorRoot.Bluetooth]: {
                        icon: "network-bluetooth-symbolic",
                        path: "bluetooth:/"
                    },
                    [NavigatorComponent.NavigatorRoot.Mtp]: {
                        icon: "multimedia-player-symbolic",
                        path: "mtp:/"
                    },
                    [NavigatorComponent.NavigatorRoot.Smb]: {
                        icon: "network-workgroup-symbolic",
                        path: "smb:/"
                    },
                    [NavigatorComponent.NavigatorRoot.Root]: {
                        icon: "folder-root-symbolic",
                        path: "file:///"
                    },
                    [NavigatorComponent.NavigatorRoot.Tags]: {
                        icon: "tag-symbolic",
                        path: []
                    },
                    [NavigatorComponent.NavigatorRoot.Time]: {
                        icon: "view-calendar-symbolic",
                        path: []
                    },
                    [NavigatorComponent.NavigatorRoot.Location]: {
                        icon: "tag-places-symbolic",
                        path: []
                    },
                    [NavigatorComponent.NavigatorRoot.Open]: {
                        icon: "system-run-symbolic",
                        path: []
                    }
                })

                icon.name: rootLocations[rootLocation].icon
                text: root.galleryModel.titleForPath(rootLocations[rootLocation].path)

                onClicked: root.navigate(rootLocations[rootLocation].path)

                display: Controls.AbstractButton.IconOnly

                Controls.ToolTip.text: text
                Controls.ToolTip.visible: hovered && text.length > 0
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Repeater {
                id: navigatorRepeater

                model: navigatorRoot.isUrlNavigator ? Koko.DirModelUtils.getUrlParts(root.path)
                                                    : root.path

                RowLayout {
                    id: navigatorDelegate

                    required property int index
                    required property string modelData

                    spacing: 0

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignVCenter

                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small

                        source: LayoutMirroring.enabled ? "arrow-left-symbolic" : "arrow-right-symbolic"
                    }

                    NavigatorPathButton {
                        id: navigatorPathButton

                        Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                        Layout.fillWidth: navigatorRoot.restrictedWidthMode

                        implicitHeight: navigatorRootButton.implicitHeight // Ensure our text-only buttons match the icon buttons' height

                        pathString: navigatorRoot.isUrlNavigator ? root.galleryModel.titleForPath(Koko.DirModelUtils.partialUrlForIndex(root.path, navigatorDelegate.index + 1))
                                                                 : root.galleryModel.titleForPath(root.path.slice(0, navigatorDelegate.index + 1))

                        onClicked: navigatorRoot.isUrlNavigator ? root.navigate(Koko.DirModelUtils.partialUrlForIndex(root.path, navigatorDelegate.index + 1))
                                                                : root.navigate(root.path.slice(0, navigatorDelegate.index + 1));
                    }
                }
            }

            Item {
                Layout.fillWidth: !navigatorRoot.restrictedWidthMode
                Layout.minimumWidth: 0
            }
        }
    }
}
