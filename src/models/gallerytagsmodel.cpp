/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KLocalizedString>

#include "imagestorage.h"

#include "gallerytagsmodel.h"

GalleryTagsModel::GalleryTagsModel(QObject *parent)
    : AbstractNavigableGalleryModel(parent)
    , m_mode(None)
{
    connect(this, &GalleryTagsModel::pathChanged, this, &GalleryTagsModel::titleChanged);
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, [this]() {
        populate(m_path);
    });
}

QString GalleryTagsModel::title() const
{
    return titleForPath(m_path);
}

QString GalleryTagsModel::titleForPath(const QVariant &path) const
{
    const QStringList pathList = path.toStringList();

    if (pathList.size() == 1) {
        return m_path.at(0);
    }

    return i18n("Tags");
}

QVariant GalleryTagsModel::path() const
{
    return QVariant(m_path);
}

void GalleryTagsModel::setPath(const QVariant &path)
{
    const QStringList pathList = path.toStringList();

    if (m_path == pathList) {
        return;
    }

    populate(pathList);

    Q_EMIT pathChanged();
}

QVariant GalleryTagsModel::pathForIndex(const QModelIndex &index) const
{
    switch (m_mode) {
    case None:
    default:
        return {};
    case CollectionMode:
        return QVariant(QStringList{m_tags.at(index.row())});
    case FileItemMode:
        return QVariant(index.data(AbstractGalleryModel::FileItemRole).value<KFileItem>().url());
    }
}

QVariant GalleryTagsModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    switch (m_mode) {
    case None:
    default:
        return {};
    case CollectionMode:
        switch (role) {
        case Qt::DisplayRole:
        case NameRole:
            return m_tags.at(index.row());
        case FileItemRole:
            return ImageStorage::instance()->previewImageForTag(m_tags.at(index.row()));
        case ItemTypeRole:
            return ItemType::Collection;
        case UrlRole:
            return ImageStorage::instance()->previewImageForTag(m_tags.at(index.row())).url();
        case FileCountRole:
            return ImageStorage::instance()->imagesForTag(m_tags.at(index.row())).size();
        default:
            return {};
        }
    case FileItemMode:
        return dataFromFileItem(m_fileItems.at(index.row()), role);
    }
}

int GalleryTagsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    switch (m_mode) {
    case None:
    default:
        return 0;
    case CollectionMode:
        return m_tags.size();
    case FileItemMode:
        return m_fileItems.size();
    }
}

void GalleryTagsModel::populate(const QStringList &path)
{
    beginResetModel();
    m_path = path;

    if (m_path.size() == 0) {
        // Show tags collection
        m_tags = ImageStorage::instance()->tags();
        m_fileItems = {};
        m_mode = CollectionMode;
    } else if (m_path.size() == 1) {
        // Show tagged images
        m_fileItems = ImageStorage::instance()->imagesForTag(m_path.at(0));
        m_mode = FileItemMode;
    } else {
        // Not a valid path
        m_mode = None;
    }
    endResetModel();
}
