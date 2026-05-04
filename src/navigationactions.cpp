// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#include "navigationactions.h"

#include "dirmodelutils.h"
#include "imagestorage.h"
#include "kokoconfig.h"
#include "placeaction.h"

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
        m_placeActions[place.id] = action;
    }

    updateSavedFolders();
    updateTags();
}

QList<QAction *> NavigationActions::savedFolders() const
{
    return m_savedFolders;
}

QList<QAction *> NavigationActions::tags() const
{
    return m_tags;
}

void NavigationActions::updateSavedFolders()
{
    auto config = Config::self();
    const auto savedFolders = config->savedFolders();

    qDeleteAll(m_savedFolders);
    m_savedFolders.clear();
    m_savedFolderNames.clear();

    KirigamiActions::ActionCollection *coll = KirigamiActions::ActionCollections::self()->collection(u"org.kde.koko.navigation"_s);

    for (const auto &folder : savedFolders) {
        // Not added to the managed actions
        QString text = folder;
        if (text.endsWith(u'/')) {
            text.chop(1);
        }
        text = text.split(u'/').constLast();
        QString normalizedFolder = QUrl::fromLocalFile(QUrl(folder).toLocalFile()).toString();

        auto placeAction = coll->createAction(normalizedFolder, KIO::iconNameForUrl(normalizedFolder), text);
        placeAction->setCheckable(true);
        placeAction->setActionGroup(m_pagesGroup);

        QVariantMap data = {{u"modelType"_s, FolderModel}, {u"path"_s, normalizedFolder}};
        placeAction->setData(data);

        connect(placeAction, &QAction::triggered, this, [this, normalizedFolder] {
            Q_EMIT navigate(FolderModel, normalizedFolder);
        });
        m_savedFolders << placeAction;
        m_savedFolderNames << normalizedFolder;
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

    qDeleteAll(m_tags);
    m_tags.clear();
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
        m_tags << placeAction;
    }

    Q_EMIT tagsChanged();
}

QAction *NavigationActions::placeAction(const QString &name)
{
    return m_placeActions.value(name);
}

void NavigationActions::goHome()
{
    QAction *action = m_placeActions.value("place_pictures");
    Q_ASSERT(action);
    action->trigger();
}
