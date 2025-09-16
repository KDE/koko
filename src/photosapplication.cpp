// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#include "photosapplication.h"

#include "dirmodelutils.h"
#include "imagestorage.h"
#include "kokoconfig.h"

#include <KIO/Global>
#include <KLocalizedString>
#include <QActionGroup>
#include <QStandardPaths>

using namespace Qt::StringLiterals;

PhotosApplication::PhotosApplication(QObject *parent)
    : AbstractKirigamiApplication(parent)
    , m_pagesGroup(new QActionGroup(this))
{
    m_pagesGroup->setExclusive(true);
    setupActions();

    auto config = Config::self();
    connect(config, &Config::SavedFoldersChanged, this, &PhotosApplication::updateSavedFolders);
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &PhotosApplication::updateTags);
}

PhotosApplication::~PhotosApplication() = default;

void PhotosApplication::setupActions()
{
    AbstractKirigamiApplication::setupActions();

    struct Place {
        QString id;
        ModelType modelType;
        QVariant path;
        QString text;
        QIcon icon;
    };

    const auto pictures = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    const auto videos = QStandardPaths::standardLocations(QStandardPaths::MoviesLocation);

    const QList<Place> places = {
        Place{QStringLiteral("place_pictures"),
              FolderModel,
              pictures.isEmpty() ? QUrl() : QUrl::fromLocalFile(pictures.constFirst()),
              i18nc("@action:button Navigation button", "Navigate to pictures"),
              QIcon::fromTheme(u"folder-pictures-symbolic"_s)},
        Place{QStringLiteral("place_videos"),
              FolderModel,
              videos.isEmpty() ? QUrl() : QUrl::fromLocalFile(videos.constFirst()),
              i18nc("@action:button Navigation button", "Navigate to videos"),
              QIcon::fromTheme(u"folder-videos-symbolic"_s)},
        Place{QStringLiteral("place_favorites"),
              FavoritesModel,
              {},
              i18nc("@action:button Navigation button", "Navigate to favorites"),
              QIcon::fromTheme(u"starred-symbolic"_s)},
        Place{QStringLiteral("place_trash"),
              FolderModel,
              QUrl("trash:/"),
              i18nc("@action:button Navigation button", "Navigate to the trash"),
              QIcon::fromTheme(u"user-trash-symbolic"_s)},
        Place{QStringLiteral("place_remote"),
              FolderModel,
              QStringLiteral("remote:/"),
              i18nc("@action:button Navigation button", "Navigate to the remote folders"),
              QIcon::fromTheme(u"folder-cloud-symbolic"_s)},
        Place{
            QStringLiteral("place_countries"),
            LocationModel,
            QStringList({QStringLiteral("countries")}),
            i18nc("@action:button Navigation button", "Navigate to pictures grouped by country"),
            QIcon::fromTheme(u"tag-places-symbolic"_s),
        },
        Place{QStringLiteral("place_states"),
              LocationModel,
              QStringList({QStringLiteral("states")}),
              i18nc("@action:button Navigation button, state as in country subdivision", "Navigate to pictures grouped by state"),
              QIcon::fromTheme(u"tag-places-symbolic"_s)},
        Place{QStringLiteral("place_cities"),
              LocationModel,
              QStringList({QStringLiteral("cities")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by cities"),
              QIcon::fromTheme(u"tag-places-symbolic"_s)},
        Place{QStringLiteral("place_years"),
              TimeModel,
              QStringList({QStringLiteral("years")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by year"),
              QIcon::fromTheme(u"view-calendar-symbolic"_s)},
        Place{QStringLiteral("place_months"),
              TimeModel,
              QStringList({QStringLiteral("months")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by month"),
              QIcon::fromTheme(u"view-calendar-symbolic"_s)},
        Place{QStringLiteral("place_weeks"),
              TimeModel,
              QStringList({QStringLiteral("weeks")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by week"),
              QIcon::fromTheme(u"view-calendar-symbolic"_s)},
        Place{QStringLiteral("place_days"),
              TimeModel,
              QStringList({QStringLiteral("days")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by day"),
              QIcon::fromTheme(u"view-calendar-symbolic"_s)},
    };

    for (const auto &place : places) {
        auto placeAction = mainCollection()->addAction(place.id, this, [this, modelType = place.modelType, path = place.path] {
            Q_EMIT navigate(modelType, path);
        });
        placeAction->setCheckable(true);
        placeAction->setActionGroup(m_pagesGroup);
        placeAction->setText(place.text);
        placeAction->setIcon(place.icon);
    }

    updateSavedFolders();
    updateTags();
}

QList<QAction *> PhotosApplication::savedFolders() const
{
    return m_savedFolders;
}

QList<QAction *> PhotosApplication::tags() const
{
    return m_tags;
}

void PhotosApplication::updateSavedFolders()
{
    auto config = Config::self();
    const auto savedFolders = config->savedFolders();

    qDeleteAll(m_savedFolders);
    m_savedFolders.clear();

    for (const auto &folder : savedFolders) {
        // Not added to the managed actions
        QString text = folder;
        if (text.endsWith(u'/')) {
            text.chop(1);
        }
        text = text.split(u'/').constLast();

        auto action = new QAction(QIcon::fromTheme(KIO::iconNameForUrl(folder)), text, this);
        connect(action, &QAction::triggered, this, [this, folder] {
            Q_EMIT navigate(FolderModel, folder);
        });
        action->setCheckable(true);
        action->setActionGroup(m_pagesGroup);
        m_savedFolders << action;
    }

    Q_EMIT savedFoldersChanged();
}

void PhotosApplication::updateTags()
{
    const QStringList tags = ImageStorage::instance()->tags();

    if (m_tagNames == tags) {
        return;
    }

    m_tagNames = tags;

    qDeleteAll(m_tags);
    m_tags.clear();
    for (const auto &tag : std::as_const(m_tagNames)) {
        auto action = new QAction(QIcon::fromTheme(u"tag-symbolic"_s), tag, this);
        connect(action, &QAction::triggered, this, [this, tag] {
            Q_EMIT navigate(TagsModel, QStringList(tag));
        });
        action->setCheckable(true);
        action->setActionGroup(m_pagesGroup);
        m_tags << action;
    }

    Q_EMIT tagsChanged();
}
