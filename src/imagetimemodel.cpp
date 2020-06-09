/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#include "imagetimemodel.h"
#include "imagestorage.h"
#include "roles.h"

#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>

ImageTimeModel::ImageTimeModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_group(Types::TimeGroup::Day)
{
    connect(ImageStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
}

void ImageTimeModel::slotPopulate()
{
    beginResetModel();
    auto tg = static_cast<Types::TimeGroup>(m_group);
    m_times = ImageStorage::instance()->timeTypes(tg);
    endResetModel();
}

QHash<int, QByteArray> ImageTimeModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(Roles::FilesRole, "files");
    hash.insert(Roles::FileCountRole, "fileCount");
    // the url role returns the url of the cover image of the collection
    hash.insert(Roles::ImageUrlRole, "imageurl");
    hash.insert(Roles::DateRole, "date");
    hash.insert(Roles::ItemTypeRole, "itemType");

    return hash;
}

QVariant ImageTimeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    QByteArray key = m_times.at(index.row()).first;
    QString display = m_times.at(index.row()).second;

    switch (role) {
    case Qt::DisplayRole:
        return display;

    case Roles::FilesRole: {
        auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->imagesForTime(key, tg);
    }

    case Roles::FileCountRole: {
        auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->imagesForTime(key, tg).size();
    }

    case Roles::ImageUrlRole: {
        auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->imageForTime(key, tg);
    }

    case Roles::DateRole: {
        auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->dateForKey(key, tg);
    }

    case Roles::ItemTypeRole: {
        return Types::Album;
    }
    }

    return QVariant();
}

int ImageTimeModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_times.size();
}

Types::TimeGroup ImageTimeModel::group() const
{
    return m_group;
}

void ImageTimeModel::setGroup(Types::TimeGroup group)
{
    beginResetModel();
    m_group = group;

    auto tg = static_cast<Types::TimeGroup>(m_group);
    m_times = ImageStorage::instance()->timeTypes(tg);
    endResetModel();

    emit groupChanged();
}
