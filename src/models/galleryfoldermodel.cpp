/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <KDirLister>

#include "galleryfoldermodel.h"

GalleryFolderModel::GalleryFolderModel(QObject *parent)
    : AbstractNavigableGalleryModel(parent)
    , m_dirModel(new KDirModel(this))
{
    connect(m_dirModel, &KDirModel::rowsAboutToBeInserted, this, &GalleryFolderModel::rowsAboutToBeInserted);
    connect(m_dirModel, &KDirModel::rowsAboutToBeMoved, this, &GalleryFolderModel::rowsAboutToBeMoved);
    connect(m_dirModel, &KDirModel::rowsAboutToBeRemoved, this, &GalleryFolderModel::rowsAboutToBeRemoved);
    connect(m_dirModel, &KDirModel::rowsInserted, this, &GalleryFolderModel::rowsInserted);
    connect(m_dirModel, &KDirModel::rowsMoved, this, &GalleryFolderModel::rowsMoved);
    connect(m_dirModel, &KDirModel::rowsRemoved, this, &GalleryFolderModel::rowsRemoved);
    connect(m_dirModel, &KDirModel::modelReset, this, &GalleryFolderModel::modelReset);
    connect(m_dirModel, &KDirModel::modelAboutToBeReset, this, &GalleryFolderModel::modelAboutToBeReset);
    connect(m_dirModel, &KDirModel::layoutChanged, this, &GalleryFolderModel::layoutChanged);
    connect(m_dirModel, &KDirModel::layoutAboutToBeChanged, this, &GalleryFolderModel::layoutAboutToBeChanged);
}

QString GalleryFolderModel::title() const
{
    return m_dirModel->dirLister()->url().fileName();
}

QVariant GalleryFolderModel::path() const
{
    return QVariant(m_dirModel->dirLister()->url());
}

void GalleryFolderModel::setPath(const QVariant &path)
{
    QUrl url = path.toUrl();
    if (!url.isValid()) {
        return;
    }

    m_dirModel->openUrl(url);
    Q_EMIT pathChanged();
    Q_EMIT titleChanged();
}

QVariant GalleryFolderModel::pathForIndex(const QModelIndex &index) const
{
    return QVariant(index.data(AbstractGalleryModel::FileItemRole).value<KFileItem>().url());
}

QVariant GalleryFolderModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &fileItem = m_dirModel->index(index.row(), 0).data(KDirModel::FileItemRole).value<KFileItem>();
    return dataFromFileItem(fileItem, role);
}

int GalleryFolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_dirModel->rowCount();
}
