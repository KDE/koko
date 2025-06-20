/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.koko as Koko

FormCard.FormCardPage {
    id: root

    required property Koko.PhotosApplication application

    actions: [
        Kirigami.Action {
            text: i18nc("@action:button Open settings dialog", "Settings")
            fromQAction: root.application.action('options_configure')
        }
    ]

    FormCard.FormHeader {
        title: i18nc("@title:group", "General")
    }

    FormCard.FormCard {
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Pictures")
            action: Kirigami.Action {
                fromQAction: root.application?.action('place_pictures') ?? null
            }
        }

        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Videos")
            action: Kirigami.Action {
                fromQAction: root.application?.action('place_videos') ?? null
            }
        }

        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Favorites")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_favorites')
            }
        }

        FormCard.FormButtonDelegate {
            icon.name: "user-trash-symbolic"
            text: i18nc("@action:button Navigation entry in sidebar", "Trash")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_trash')
            }
        }
        FormCard.FormButtonDelegate {
            icon.name: "folder-cloud"
            text: i18nc("@action:button Navigation entry in sidebar", "Network")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_remote')
            }
        }
    }

    FormCard.FormHeader {
        title: i18nc("@title:group", "Bookmarks")
        visible: folderRepeater.count > 0
    }

    FormCard.FormCard {
        visible: folderRepeater.count > 0
        Repeater {
            id: folderRepeater
            model: root.application.savedFolders
            FormCard.FormButtonDelegate {
                id: delegate

                required property var modelData

                action: Kirigami.Action {
                    fromQAction: delegate.modelData
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Locations")
    }

    FormCard.FormCard {
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Countries")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_countries')
            }
        }
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "States")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_states')
            }
        }
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Cities")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_cities')
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("Time")
    }

    FormCard.FormCard {
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Years")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_years')
            }
        }
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Months")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_months')
            }
        }
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Weeks")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_weeks')
            }
        }
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button Navigation entry in sidebar", "Days")
            action: Kirigami.Action {
                fromQAction: root.application.action('place_days')
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Tags")
        visible: tagRepeater.count > 0
    }

    FormCard.FormCard {
        visible: tagRepeater.count > 0

        Repeater {
            id: tagRepeater

            model: root.application.tags

            FormCard.FormButtonDelegate {
                id: delegate

                required property var modelData

                action: Kirigami.Action {
                    fromQAction: delegate.modelData
                }
            }
        }
    }
}
