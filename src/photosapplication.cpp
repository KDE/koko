// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#include "photosapplication.h"

#include "dirmodelutils.h"
"

#include <KLocalizedString>
#include <QActionGroup>
#include <QStandardPaths>

    using namespace Qt::StringLiterals;

PhotosApplication::PhotosApplication(QObject *parent)
    : AbstractKirigamiApplication(parent)
{
    setupActions();
}

PhotosApplication::~PhotosApplication() = default;

void PhotosApplication::setupActions()
{
    AbstractKirigamiApplication::setupActions();

    struct Place {
        QString id;
        QString filter;
        QString query;
        QString text;
        QIcon icon;
    };

    const auto videos = QStandardPaths::standardLocations(QStandardPaths::MoviesLocation);

    const QList<Place> places = {
        Place{
            u"place_pictures"_s,
            u"Pictures"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures"),
            QIcon::fromTheme(u"folder-pictures-symbolic"_s),
        },
        Place{
            u"place_favorites"_s,
            u"Favorites"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to favorites"),
            QIcon::fromTheme(u"starred-symbolic"_s),
        },
        Place{
            u"place_videos"_s,
            u"Videos"_s,
            u"file://"_s + (videos.isEmpty() ? QString() : videos.constFirst()),
            i18nc("@action:button Navigation button", "Navigate to videos"),
            QIcon::fromTheme(u"folder-videos-symbolic"_s),
        },
        Place{
            u"place_trash"_s,
            u"Trash"_s,
            u"trash:/"_s,
            i18nc("@action:button Navigation button", "Navigate to the trash"),
            QIcon::fromTheme(u"user-trash-symbolic"_s),
        },
        Place{
            u"place_remote"_s,
            u"Remote"_s,
            u"remote:/"_s,
            i18nc("@action:button Navigation button", "Navigate to the remote folders"),
            QIcon::fromTheme(u"folder-cloud-symbolic"_s),
        },
        Place{
            u"place_countries"_s,
            u"Countries"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by countries"),
            QIcon::fromTheme(u"tag-places-symbolic"_s),
        },
        Place{
            u"place_states"_s,
            u"States"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by states"),
            QIcon::fromTheme(u"tag-places-symbolic"_s),
        },
        Place{
            u"place_cities"_s,
            u"Cities"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by cities"),
            QIcon::fromTheme(u"tag-places-symbolic"_s),
        },
        Place{
            u"place_years"_s,
            u"Years"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by years"),
            QIcon::fromTheme(u"view-calendar-symbolic"_s),
        },
        Place{
            u"place_months"_s,
            u"Months"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by months"),
            QIcon::fromTheme(u"view-calendar-symbolic"_s),
        },
        Place{
            u"place_weeks"_s,
            u"Weeks"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by weeks"),
            QIcon::fromTheme(u"view-calendar-symbolic"_s),
        },
        Place{
            u"place_days"_s,
            u"Days"_s,
            {},
            i18nc("@action:button Navigation button", "Navigate to pictures sorted by days"),
            QIcon::fromTheme(u"view-calendar-symbolic"_s),
        },
    };

    auto pagesGroup = new QActionGroup(this);
    pagesGroup->setExclusive(true);

    for (const auto &place : places) {
        auto placeAction = mainCollection()->addAction(place.id, this, [this, filter = place.filter, query = place.query] {
            Q_EMIT filterBy(filter, query);
        });
        placeAction->setCheckable(true);
        placeAction->setActionGroup(pagesGroup);
        placeAction->setText(place.text);
        placeAction->setIcon(place.icon);
    }
}
