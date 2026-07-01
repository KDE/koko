// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#include "navigationactions.h"

#include "dirmodelutils.h"
#include "imagestorage.h"
#include "kokoconfig.h"

#include <KIO/Global>
#include <KLocalizedString>
#include <QActionGroup>
#include <QStandardPaths>

#include <ActionCollection/ActionCollection>
#include <ActionCollection/ActionCollections>

using namespace Qt::StringLiterals;

NavigationActions::NavigationActions(QObject *parent)
    : QObject(parent)
    , m_pagesGroup(new QActionGroup(this))
{
    KirigamiActions::ActionCollections::self()->createCollection(u"org.kde.koko.navigation"_s, i18nc("Navigation buttons actions group", "Navigation"));
    m_pagesGroup->setExclusive(true);
    setupActions();

    auto config = Config::self();
    connect(config, &Config::SavedFoldersChanged, this, &NavigationActions::updateSavedFolders);
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &NavigationActions::updateTags);
}

NavigationActions::~NavigationActions() = default;

void NavigationActions::setupActions()
{
    struct Place {
        QString id;
        ModelType modelType;
        QVariant path;
        QString text;
        QString icon;
    };

    const auto pictures = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    const auto videos = QStandardPaths::standardLocations(QStandardPaths::MoviesLocation);

    const QList<Place> places = {
        Place{QStringLiteral("place_pictures"),
              FolderModel,
              pictures.isEmpty() ? QUrl() : QUrl::fromLocalFile(pictures.constFirst()),
              i18nc("@action:button Navigation button", "Navigate to pictures"),
              u"folder-pictures-symbolic"_s},
        Place{QStringLiteral("place_videos"),
              FolderModel,
              videos.isEmpty() ? QUrl() : QUrl::fromLocalFile(videos.constFirst()),
              i18nc("@action:button Navigation button", "Navigate to videos"),
              u"folder-videos-symbolic"_s},
        Place{QStringLiteral("place_favorites"), FavoritesModel, {}, i18nc("@action:button Navigation button", "Navigate to favorites"), u"starred-symbolic"_s},
        Place{QStringLiteral("place_trash"),
              FolderModel,
              QUrl("trash:/"),
              i18nc("@action:button Navigation button", "Navigate to the trash"),
              u"user-trash-symbolic"_s},
        Place{QStringLiteral("place_remote"),
              FolderModel,
              QStringLiteral("remote:/"),
              i18nc("@action:button Navigation button", "Navigate to the remote folders"),
              u"folder-cloud-symbolic"_s},
        Place{QStringLiteral("place_countries"),
              LocationModel,
              QStringList({QStringLiteral("countries")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by country"),
              u"tag-places-symbolic"_s},
        Place{QStringLiteral("place_states"),
              LocationModel,
              QStringList({QStringLiteral("states")}),
              i18nc("@action:button Navigation button, state as in country subdivision", "Navigate to pictures grouped by state"),
              u"tag-places-symbolic"_s},
        Place{QStringLiteral("place_cities"),
              LocationModel,
              QStringList({QStringLiteral("cities")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by cities"),
              u"tag-places-symbolic"_s},
        Place{QStringLiteral("place_years"),
              TimeModel,
              QStringList({QStringLiteral("years")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by year"),
              u"view-calendar-symbolic"_s},
        Place{QStringLiteral("place_months"),
              TimeModel,
              QStringList({QStringLiteral("months")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by month"),
              u"view-calendar-symbolic"_s},
        Place{QStringLiteral("place_weeks"),
              TimeModel,
              QStringList({QStringLiteral("weeks")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by week"),
              u"view-calendar-symbolic"_s},
        Place{QStringLiteral("place_days"),
              TimeModel,
              QStringList({QStringLiteral("days")}),
              i18nc("@action:button Navigation button", "Navigate to pictures grouped by day"),
              u"view-calendar-symbolic"_s},
    };

    KirigamiActions::ActionCollection *coll = KirigamiActions::ActionCollections::self()->collection(u"org.kde.koko.navigation"_s);
    for (const auto &place : places) {
        auto action = coll->createAction(place.id, place.icon, place.text);
        action->setCheckable(true);
        QVariantMap data = {{u"modelType"_s, place.modelType}, {u"path"_s, place.path}};
        action->setData(data);
        action->setActionGroup(m_pagesGroup);
        connect(action, &QAction::triggered, this, [this, modelType = place.modelType, path = place.path] {
            Q_EMIT navigate(modelType, path);
        });
    }

    updateSavedFolders();
    updateTags();
}

void NavigationActions::updateSavedFolders()
{
    auto config = Config::self();
    const auto savedFolders = config->savedFolders();

    KirigamiActions::ActionCollection *coll = KirigamiActions::ActionCollections::self()->collection(u"org.kde.koko.navigation"_s);

    QSet<QString> oldSavedFoldersSet(m_savedFolderNames.constBegin(), m_savedFolderNames.constEnd());

    QSet<QString> newSavedFoldersSet;

    std::ranges::copy(savedFolders | std::views::transform([](const QString &folder) {
                          return QUrl::fromLocalFile(QUrl(folder).toLocalFile()).toString();
                      }),
                      std::inserter(newSavedFoldersSet, newSavedFoldersSet.end()));

    for (const auto &folder : m_savedFolderNames) {
        if (!newSavedFoldersSet.contains(folder)) {
            coll->removeAction(folder);
        }
    }
    m_savedFolderNames.clear();

    for (const auto &normalizedFolder : newSavedFoldersSet) {
        m_savedFolderNames << normalizedFolder;
        if (oldSavedFoldersSet.contains(normalizedFolder)) {
            continue;
        }
        // Not added to the managed actions
        QString text = normalizedFolder;
        if (text.endsWith(u'/')) {
            text.chop(1);
        }
        text = text.split(u'/').constLast();

        auto placeAction = coll->createAction(normalizedFolder, KIO::iconNameForUrl(normalizedFolder), text);
        placeAction->setCheckable(true);
        placeAction->setActionGroup(m_pagesGroup);

        QVariantMap data = {{u"modelType"_s, FolderModel}, {u"path"_s, normalizedFolder}};
        placeAction->setData(data);

        connect(placeAction, &QAction::triggered, this, [this, normalizedFolder] {
            Q_EMIT navigate(FolderModel, normalizedFolder);
        });
    }

    Q_EMIT savedFoldersChanged();
}

void NavigationActions::updateTags()
{
    const QStringList tags = ImageStorage::instance()->tags();

    if (m_tagNames == tags) {
        return;
    }

    m_tagNames = tags;

    KirigamiActions::ActionCollection *coll = KirigamiActions::ActionCollections::self()->collection(u"org.kde.koko.navigation"_s);
    for (const auto &tag : std::as_const(m_tagNames)) {
        auto placeAction = coll->createAction(tag, u"tag-symbolic"_s, tag);

        placeAction->setCheckable(true);
        placeAction->setActionGroup(m_pagesGroup);

        QVariantMap data = {{u"modelType"_s, TagsModel}, {u"path"_s, QStringList(tag)}};
        placeAction->setData(data);

        connect(placeAction, &QAction::triggered, this, [this, tag] {
            Q_EMIT navigate(TagsModel, QStringList(tag));
        });
    }

    Q_EMIT tagsChanged();
}

void NavigationActions::goHome()
{
    KirigamiActions::ActionCollection *coll = KirigamiActions::ActionCollections::self()->collection(u"org.kde.koko.navigation"_s);
    Q_ASSERT(coll);
    QAction *action = coll->action(u"place_pictures"_s);
    Q_ASSERT(action);
    action->trigger();
}
