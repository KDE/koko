/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KLocalizedString>

#include "gallerytimemodel.h"

ImageStorage::TimeGroup timeGroupFromKey(const QByteArray &key)
{
    if (key == "years") {
        return ImageStorage::TimeGroup::Year;
    } else if (key == "months") {
        return ImageStorage::TimeGroup::Month;
    } else if (key == "weeks") {
        return ImageStorage::TimeGroup::Week;
    } else if (key == "days") {
        return ImageStorage::TimeGroup::Day;
    } else {
        return ImageStorage::TimeGroup::NotSet;
    }
}

ImageStorage::TimeGroup timeGroupFromPath(const QStringList &path)
{
    if (path.isEmpty()) {
        return ImageStorage::TimeGroup::NotSet;
    }

    return timeGroupFromKey(path.at(0).toUtf8());
}

GalleryTimeModel::GalleryTimeModel(QObject *parent)
    : AbstractNavigableGalleryModel(parent)
    , m_mode(None)
{
    connect(this, &GalleryTimeModel::pathChanged, this, &GalleryTimeModel::titleChanged);
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, [this]() {
        populate(m_path);
    });
}

QString GalleryTimeModel::title() const
{
    return titleForPath(m_path);
}

QString GalleryTimeModel::titleForPath(const QVariant &path) const
{
    const QStringList pathList = path.toStringList();

    if (pathList.size() == 1) {
        switch (timeGroupFromKey(pathList.at(0).toUtf8())) {
        case ImageStorage::TimeGroup::Year:
            return i18n("Years");
        case ImageStorage::TimeGroup::Month:
            return i18n("Months");
        case ImageStorage::TimeGroup::Week:
            return i18n("Weeks");
        case ImageStorage::TimeGroup::Day:
            return i18n("Days");
        case ImageStorage::TimeGroup::NotSet:
        default:
            break;
        }
    } else if (pathList.size() == 2) {
        const QByteArray key = m_path.at(1).toUtf8();
        for (const auto &collection : ImageStorage::instance()->timeTypes(timeGroupFromPath(pathList))) {
            if (collection.key == key) {
                return collection.display;
            }
        }
    }

    return i18n("Times");
}

QVariant GalleryTimeModel::path() const
{
    return QVariant(m_path);
}

void GalleryTimeModel::setPath(const QVariant &path)
{
    const QStringList pathList = path.toStringList();

    if (m_path == pathList) {
        return;
    }

    populate(pathList);

    Q_EMIT pathChanged();
}

QVariant GalleryTimeModel::pathForIndex(const QModelIndex &index) const
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

QVariant GalleryTimeModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    switch (m_mode) {
    case ParentCollectionMode:
    case CollectionMode: {
        ImageStorage::TimeGroup timeGroup = timeGroupFromPath(m_path);
        std::optional<ImageStorage::Collection> collection = m_collections.at(index.row());

        const bool isParentCollection = (m_mode == ParentCollectionMode);
        if (isParentCollection) {
            // We want to show data for the first collection for that group
            timeGroup = timeGroupFromKey(collection.value().key);

            auto collections = ImageStorage::instance()->timeTypes(timeGroup);
            if (collections.isEmpty()) {
                collection = std::nullopt;
            } else {
                collection = collections.first();
            }
        }

        switch (role) {
        case Qt::DisplayRole:
            // Return a sensible value for sorting
            return isParentCollection ? QVariant(static_cast<int>(timeGroup))
                                      : QVariant(ImageStorage::instance()->dateForCollection(collection.value(), timeGroup));
        case NameRole:
            return m_collections.at(index.row()).display;
        case FileItemRole:
            return collection.has_value() ? ImageStorage::instance()->previewImageForTime(collection.value(), timeGroup) : KFileItem();
        case ItemTypeRole:
            return ItemType::Collection;
        case UrlRole:
            return collection.has_value() ? ImageStorage::instance()->previewImageForTime(collection.value(), timeGroup).url() : QUrl();
        case FileCountRole:
            if (isParentCollection) {
                return ImageStorage::instance()->timeTypes(timeGroup).size();
            } else {
                return collection.has_value() ? ImageStorage::instance()->imagesForTime(collection.value().key, timeGroup).size() : 0;
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

int GalleryTimeModel::rowCount(const QModelIndex &parent) const
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

void GalleryTimeModel::populate(const QStringList &path)
{
    beginResetModel();
    m_path = path;

    switch (m_path.size()) {
    case 0:
        m_collections = {
            {"years", i18n("Years"), ImageStorage::QueryType::NotSet},
            {"months", i18n("Months"), ImageStorage::QueryType::NotSet},
            {"weeks", i18n("Weeks"), ImageStorage::QueryType::NotSet},
            {"days", i18n("Days"), ImageStorage::QueryType::NotSet},
        };
        m_fileItems = {};
        m_mode = ParentCollectionMode;
        break;
    case 1:
        m_collections = ImageStorage::instance()->timeTypes(timeGroupFromPath(m_path));
        m_fileItems = {};
        m_mode = m_collections.isEmpty() ? None : CollectionMode;
        break;
    case 2:
        m_collections = {};
        m_fileItems = ImageStorage::instance()->imagesForTime(m_path.at(1).toUtf8(), timeGroupFromPath(m_path));
        m_mode = FileItemMode;
        break;
    default:
        m_mode = None;
        break;
    }

    endResetModel();
}
