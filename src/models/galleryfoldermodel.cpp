/*
 *  SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *  SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KDirLister>

#include "galleryfoldermodel.h"

GalleryFolderModel::GalleryFolderModel(QObject *parent)
    : AbstractNavigableGalleryModel(parent)
    , m_status(Unloaded)
{
    connect(this, &GalleryFolderModel::pathChanged, this, &GalleryFolderModel::titleChanged);

    connect(&m_dirLister, &KokoDirLister::itemsAdded, this, [this](const KFileItemList &items) {
        beginInsertRows(QModelIndex(), m_fileItems.size(), m_fileItems.size() + items.size() - 1);
        m_fileItems.append(items);
        endInsertRows();
    });

    connect(&m_dirLister, &KokoDirLister::itemsDeleted, this, [this](const KFileItemList &items) {
        // Don't bother trying to batch contiguous rows, usually we'll only see one item deleted at a time
        for (const KFileItem &fileItem : items) {
            int index = m_fileItems.indexOf(fileItem);
            if (index != -1) {
                beginRemoveRows(QModelIndex(), index, index);
                m_fileItems.removeAt(index);
                endRemoveRows();
            }
        }
    });

    connect(&m_dirLister, &KokoDirLister::completed, this, [this]() {
        m_status = Loaded;
        Q_EMIT statusChanged();
    });
}

QString GalleryFolderModel::title() const
{
    return titleForPath(m_dirLister.url());
}

AbstractGalleryModel::Status GalleryFolderModel::status() const
{
    return m_status;
}

QString GalleryFolderModel::titleForPath(const QVariant &path) const
{
    QUrl url = path.toUrl();

    KFileItem fileItem(url);
    return fileItem.text();
}

QVariant GalleryFolderModel::path() const
{
    return QVariant(m_dirLister.url());
}

void GalleryFolderModel::setPath(const QVariant &path)
{
    QUrl url = path.toUrl();
    if (!url.isValid()) {
        // If we allow user input, we probably want to be unloaded
        return;
    }

    beginResetModel();
    m_fileItems.clear();
    endResetModel();

    m_dirLister.setUrl(url);
    m_status = Loading;
    Q_EMIT statusChanged();
    Q_EMIT pathChanged();
}

QVariant GalleryFolderModel::pathForIndex(const QModelIndex &index) const
{
    return QVariant(index.data(AbstractGalleryModel::FileItemRole).value<KFileItem>().url());
}

QVariant GalleryFolderModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    return dataFromFileItem(m_fileItems.at(index.row()), role);
}

int GalleryFolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_fileItems.size();
}
