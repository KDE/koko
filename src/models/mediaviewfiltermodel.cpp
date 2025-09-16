/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "mediaviewfiltermodel.h"

MediaViewFilterModel::MediaViewFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

GallerySortFilterProxyModel *MediaViewFilterModel::gallerySortFilterProxyModel() const
{
    return m_gallerySortFilterProxyModel;
}

void MediaViewFilterModel::setGallerySortFilterProxyModel(GallerySortFilterProxyModel *gallerySortFilterProxyModel)
{
    if (m_gallerySortFilterProxyModel == gallerySortFilterProxyModel) {
        return;
    }

    m_gallerySortFilterProxyModel = gallerySortFilterProxyModel;
    Q_EMIT gallerySortFilterProxyModelChanged();

    setSourceModel(gallerySortFilterProxyModel);
}

bool MediaViewFilterModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    auto itemType = static_cast<AbstractGalleryModel::ItemType>(sourceModel()->data(index, AbstractGalleryModel::ItemTypeRole).toInt());

    return itemType == AbstractGalleryModel::ItemType::Media;
}
