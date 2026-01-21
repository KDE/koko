/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KLocalizedString>

#include "gallerylocationmodel.h"

ImageStorage::LocationGroup locationGroupFromKey(const QByteArray &key)
{
    if (key == "countries") {
        return ImageStorage::LocationGroup::Country;
    } else if (key == "states") {
        return ImageStorage::LocationGroup::State;
    } else if (key == "cities") {
        return ImageStorage::LocationGroup::City;
    } else {
        return ImageStorage::LocationGroup::NotSet;
    }
}

ImageStorage::LocationGroup locationGroupFromPath(const QStringList &path)
{
    if (path.isEmpty()) {
        return ImageStorage::LocationGroup::NotSet;
    }

    return locationGroupFromKey(path.at(0).toUtf8());
}

GalleryLocationModel::GalleryLocationModel(QObject *parent)
    : AbstractNavigableGalleryModel(parent)
    , m_mode(None)
{
    connect(this, &GalleryLocationModel::pathChanged, this, &GalleryLocationModel::titleChanged);
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, [this]() {
        populate(m_path);
    });
}

QString GalleryLocationModel::title() const
{
    return titleForPath(m_path);
}

QString GalleryLocationModel::titleForPath(const QVariant &path) const
{
    const QStringList pathList = path.toStringList();

    if (pathList.size() == 1) {
        switch (locationGroupFromKey(pathList.at(0).toUtf8())) {
        case ImageStorage::LocationGroup::Country:
            return i18n("Countries");
        case ImageStorage::LocationGroup::State:
            return i18n("States");
        case ImageStorage::LocationGroup::City:
            return i18n("Cities");
        case ImageStorage::LocationGroup::NotSet:
        default:
            break;
        }
    } else if (pathList.size() == 2) {
        const QByteArray key = m_path.at(1).toUtf8();
        for (const auto &collection : ImageStorage::instance()->locations(locationGroupFromPath(pathList))) {
            if (collection.key == key) {
                return collection.display;
            }
        }
    }

    return i18n("Locations");
}

QVariant GalleryLocationModel::path() const
{
    return QVariant(m_path);
}

void GalleryLocationModel::setPath(const QVariant &path)
{
    const QStringList pathList = path.toStringList();

    if (m_path == pathList) {
        return;
    }

    populate(pathList);

    Q_EMIT pathChanged();
}

QVariant GalleryLocationModel::pathForIndex(const QModelIndex &index) const
{
    switch (m_mode) {
    case ParentCollectionMode:
    case CollectionMode:
        return QStringList(m_path) << QString(m_collections.at(index.row()).key);
    case FileItemMode:
        return QVariant(index.data(AbstractGalleryModel::FileItemRole).value<KFileItem>().url());
    default:
        return {};
    }
}

QVariant GalleryLocationModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    switch (m_mode) {
    case ParentCollectionMode:
    case CollectionMode: {
        ImageStorage::LocationGroup locationGroup = locationGroupFromPath(m_path);
        std::optional<ImageStorage::Collection> collection = m_collections.at(index.row());

        const bool isParentCollection = (m_mode == ParentCollectionMode);
        if (isParentCollection) {
            // We want to show data for the first collection for that group, and if
            // that collection is empty (nullopt) then we should show it as empty
            locationGroup = locationGroupFromKey(collection.value().key);

            auto collections = ImageStorage::instance()->locations(locationGroup);
            if (collections.isEmpty()) {
                collection = std::nullopt;
            } else {
                collection = collections.first();
            }
        }

        switch (role) {
        case Qt::DisplayRole:
            // Return a sensible value for sorting
            return isParentCollection ? QVariant((int)locationGroup) : collection.value().display;
        case NameRole:
            return m_collections.at(index.row()).display;
        case FileItemRole:
            return collection.has_value() ? ImageStorage::instance()->previewImageForLocation(collection.value(), locationGroup) : KFileItem();
        case ItemTypeRole:
            return ItemType::Collection;
        case UrlRole:
            return collection.has_value() ? ImageStorage::instance()->previewImageForLocation(collection.value(), locationGroup).url() : QUrl();
        case FileCountRole:
            if (isParentCollection) {
                return ImageStorage::instance()->locations(locationGroup).size();
            } else {
                return collection.has_value() ? ImageStorage::instance()->imagesForLocation(collection.value().key, locationGroup).size() : 0;
            }
        default:
            return {};
        }
    }
    case FileItemMode:
        return dataFromFileItem(m_fileItems.at(index.row()), role);
    default:
        return {};
    }
}

int GalleryLocationModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    switch (m_mode) {
    case ParentCollectionMode:
    case CollectionMode:
        return m_collections.size();
    case FileItemMode:
        return m_fileItems.size();
    default:
        return 0;
    }
}

void GalleryLocationModel::populate(const QStringList &path)
{
    beginResetModel();
    m_path = path;

    switch (m_path.size()) {
    case 0:
        m_collections = {
            {"countries", i18n("Countries"), ImageStorage::QueryType::NotSet},
            {"states", i18n("States"), ImageStorage::QueryType::NotSet},
            {"cities", i18n("Cities"), ImageStorage::QueryType::NotSet},
        };
        m_fileItems = {};
        m_mode = ParentCollectionMode;
        break;
    case 1:
        m_collections = ImageStorage::instance()->locations(locationGroupFromPath(m_path));
        m_fileItems = {};
        m_mode = m_collections.isEmpty() ? None : CollectionMode;
        break;
    case 2:
        m_collections = {};
        m_fileItems = ImageStorage::instance()->imagesForLocation(m_path.at(1).toUtf8(), locationGroupFromPath(m_path));
        m_mode = FileItemMode;
        break;
    default:
        m_mode = None;
        break;
    }

    endResetModel();
}
