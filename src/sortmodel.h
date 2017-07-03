/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef JUNGLE_SORTMODEL_H
#define JUNGLE_SORTMODEL_H

#include <QSortFilterProxyModel>
#include <QItemSelectionModel>
#include <QSize>
#include <kdirmodel.h>
#include <QVariant>
#include <kimagecache.h>
#include <kshareddatacache.h>

namespace Jungle {

class SortModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QByteArray sortRoleName READ sortRoleName WRITE setSortRoleName)
    Q_PROPERTY(bool containImages READ containImages NOTIFY containImagesChanged)
    Q_PROPERTY(bool hasSelectedImages READ hasSelectedImages NOTIFY selectedImagesChanged)
public:
    explicit SortModel(QObject* parent = 0);
    virtual ~SortModel();

    QByteArray sortRoleName() const;
    void setSortRoleName(const QByteArray& name);

    QHash<int, QByteArray> roleNames() const;
    QVariant data(const QModelIndex & index, int role) const;
    
    virtual void setSourceModel(QAbstractItemModel* sourceModel);
    bool containImages();
    bool hasSelectedImages();
    
    Q_INVOKABLE void setSelected( int indexValue);
    Q_INVOKABLE void toggleSelected( int indexValue);
    Q_INVOKABLE void clearSelections();
    Q_INVOKABLE void selectAll();
    
protected Q_SLOTS:
    void showPreview(const KFileItem &item, const QPixmap &preview);
    void previewFailed(const KFileItem &item);
    void delayedPreview();
    
signals:
    void containImagesChanged();
    void selectedImagesChanged();

private:
    QByteArray m_sortRoleName;
    QItemSelectionModel *m_selectionModel;
    
    QTimer *m_previewTimer;
    QHash<QUrl, QPersistentModelIndex> m_filesToPreview;
    QSize m_screenshotSize;
    QHash<QUrl, QPersistentModelIndex> m_previewJobs;
    KImageCache* m_imageCache;
};
}

#endif // JUNGLE_SORTMODEL_H
