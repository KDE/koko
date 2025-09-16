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
import org.kde.koko.private

RowLayout {
    id: root

    enum NavigatorType {
        Url,
        StringList
    }

    required property int navigatorType
    required property var path
    required property bool canNavigateBackward
    required property bool canNavigateForward

    signal navigate(path : var)
    signal navigateBackward()
    signal navigateForward()

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

        icon.name: LayoutMirroring.enabled ? "go-next-sytmbolic-rtl" : "go-next-symbolic"
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

    // TODO: Separation probably unnecessary with logic changes in existing url navigator
    Loader {
        id: navigationSubcomponentLoader

        Layout.fillWidth: true

        sourceComponent: {
            switch (root.navigatorType) {
                case NavigatorComponent.NavigatorType.Url:
                    return urlNavigator;
                case NavigatorComponent.NavigatorType.StringList:
                    return stringListNavigator;
                default:
                    console.warn("No navigation subcomponent for type", root.modelType);
                    return undefined;
            }
        }
    }

    Component {
        id: urlNavigator

        RowLayout {
            id: urlNavigatorRoot

            Layout.fillWidth: true

            // We want to keep at least two path buttons visible, to always allow upward navigation
            property bool restrictedWidthMode: false

            Component.onCompleted: updateLayout()
            onWidthChanged: updateLayout()
            onChildrenChanged: updateLayout()

            function updateLayout() : void {
                let layoutChildren = urlNavigatorRoot.children.filter(child => child instanceof RowLayout || child instanceof Controls.ToolButton);
                let remainingWidth = urlNavigatorRoot.width;
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
                urlNavigatorRoot.restrictedWidthMode = widthRestricted;
                urlNavigatorRoot.implicitWidth = layoutChildren.reduce((total, child) => total + child.implicitWidth, 0)
            }

            spacing: 0

            Controls.ToolButton {
                id: rootButton

                readonly property bool inRemote: root.path.toString().startsWith("remote:")
                                                 || root.path.toString().startsWith("afc:")
                                                 || root.path.toString().startsWith("bluetooth:")
                                                 || root.path.toString().startsWith("mtp:")
                                                 || root.path.toString().startsWith("smb:")
                readonly property bool inTrash: root.path.toString().startsWith("trash:")
                readonly property bool inHome: Koko.DirModelUtils.inHome(root.path)

                icon.name: {
                    if (inRemote) {
                        return "folder-cloud-symbolic"
                    } else if (inTrash) {
                        return "user-trash-symbolic";
                    } else if (inHome) {
                        return "go-home-symbolic";
                    } else {
                        return "folder-root-symbolic";
                    }
                }

                text: {
                    if (inRemote) {
                        return i18nc("@action:button Navigate to the remote directory", "Remote");
                    } else if (inTrash) {
                        return i18nc("@action:button Navigate to the trash directory", "Trash");
                    } else if (inHome) {
                        return i18nc("@action:button Navigate to the home directory", "Home");
                    } else {
                        return i18nc("@action:button Navigate to the root directory", "Root");
                    }
                }

                display: Controls.AbstractButton.IconOnly

                Controls.ToolTip.text: text
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: {
                    if (inRemote) {
                        root.navigate("remote:/");
                    } else if (inTrash) {
                        root.navigate("trash:/");
                    } else if (inHome) {
                        root.navigate("file:///" + Koko.DirModelUtils.home);
                    } else {
                        root.navigate("file:///");
                    }
                }
            }

            Repeater {
                id: urlNavigatorRepeater

                model: Koko.DirModelUtils.getUrlParts(root.path)

                RowLayout {
                    id: urlNavigatorDelegate

                    required property int index
                    required property string modelData

                    spacing: 0

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignVCenter

                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small

                        source: LayoutMirroring.enabled ? "arrow-left" : "arrow-right"
                    }

                    NavigatorPathButton {
                        id: navButton
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                        Layout.fillWidth: urlNavigatorRoot.restrictedWidthMode

                        implicitHeight: rootButton.implicitHeight // Ensure our text-only buttons match the icon buttons' height

                        pathString: urlNavigatorDelegate.modelData

                        onClicked: root.navigate(Koko.DirModelUtils.partialUrlForIndex(root.path, urlNavigatorDelegate.index + 1));
                    }
                }
            }

            Item {
                Layout.fillWidth: !urlNavigatorRoot.restrictedWidthMode
                Layout.minimumWidth: 0
            }
        }
    }

    Component {
        id: stringListNavigator

        RowLayout {
            spacing: 0
        }
    }
}
