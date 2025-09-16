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
    , m_dirModel(new KDirModel(this))
{
    connect(this, &GalleryFolderModel::pathChanged, this, &GalleryFolderModel::titleChanged);

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

    connect(m_dirModel->dirLister(), &KCoreDirLister::completed, this, [this]() {
        m_status = Loaded;
        Q_EMIT statusChanged();
    });
}

QString GalleryFolderModel::title() const
{
    return titleForPath(m_dirModel->dirLister()->url());
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
    return QVariant(m_dirModel->dirLister()->url());
}

void GalleryFolderModel::setPath(const QVariant &path)
{
    QUrl url = path.toUrl();
    if (!url.isValid()) {
        // If we allow user input, we probably want to be unloaded
        return;
    }

    m_dirModel->openUrl(url);
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

    const auto &fileItem = m_dirModel->index(index.row(), 0).data(KDirModel::FileItemRole).value<KFileItem>();
    return dataFromFileItem(fileItem, role);
}

int GalleryFolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_dirModel->rowCount();
}
