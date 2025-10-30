/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

#include "abstractgallerymodel.h"

#include <QIdentityProxyModel>

/*!
 * A model which sorts the source model, and filters if needed
 *
 * If the source model advertises that it is necessary, the model will be
 * filtered after sorting. This is, for instance, needed in the file model which
 * cannot itself filter as sorting is performed after filtering, leading to
 * results which jump around as content is loaded. If no filtering is performed
 * in that model, results can be fetched and sorted relatively quickly, and then
 * filtered by us here with no jumpiness.
 *
 * QIdentityProxyModel isn't perfect here, because [set]sourceModel is public,
 * but anything better would need to be much more elaborate and custom.
 */
class GallerySortFilterProxyModel : public QIdentityProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(AbstractGalleryModel *galleryModel READ galleryModel WRITE setGalleryModel NOTIFY galleryModelChanged REQUIRED)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(bool sortReversed READ sortReversed WRITE setSortReversed NOTIFY sortReversedChanged)
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)

public:
    explicit GallerySortFilterProxyModel(QObject *parent = nullptr);

    enum SortMode {
        Name,
        Size,
        Modified,
        Created,
        Accessed
    };
    Q_ENUM(SortMode)

    AbstractGalleryModel *galleryModel() const;
    void setGalleryModel(AbstractGalleryModel *galleryModel);

    SortMode sortMode() const;
    void setSortMode(SortMode sortMode);

    bool sortReversed() const;
    void setSortReversed(bool sortReversed);

    QString filterString() const;
    void setFilterString(const QString &filterString);

    Q_INVOKABLE QModelIndex mapToGalleryModelIndex(const QModelIndex &proxyIndex) const;

Q_SIGNALS:
    void galleryModelChanged();
    void sortModeChanged();
    void sortReversedChanged();
    void filterStringChanged();

private:
    AbstractGalleryModel *m_galleryModel;

    // Sorts and filters as specified
    QSortFilterProxyModel *m_sortModel;

    // Filters to only accepted MIME types
    QSortFilterProxyModel *m_filterModel;
    QStringList m_filterMimeTypes;

    SortMode m_sortMode;
    bool m_sortReversed;
    QString m_filterString;
};
