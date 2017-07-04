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

#include "sortmodel.h"
#include "types.h"
#include "roles.h"
#include <QDebug>
#include <QTimer>

#include <kio/previewjob.h>
#include <kimagecache.h>

using namespace Jungle;

SortModel::SortModel(QObject* parent)
            : QSortFilterProxyModel(parent),
              m_screenshotSize(256, 256),
              m_containImages(false)
{
    setSortLocaleAware(true);
    sort(0);
    m_selectionModel = new QItemSelectionModel(this);
    
    m_previewTimer = new QTimer(this);
    m_previewTimer->setSingleShot(true);
    connect(m_previewTimer, &QTimer::timeout,
            this, &SortModel::delayedPreview);
    
    connect(this, &SortModel::rowsInserted,
            this, [this] (const QModelIndex &parent, int first, int last) {
                Q_UNUSED(parent)
                for (int i = first; i <= last; i++) {
                    if (Types::Image == data(index(i, 0, QModelIndex()), Roles::ItemTypeRole).toInt() && m_containImages == false) {
                        setContainImages(true);
                        break;
                }
            }
        });

    connect(this, &SortModel::sourceModelChanged,
            this, [this] () {
                if (!sourceModel()) {
                    return;
                }
                for (int i = 0; i <= sourceModel()->rowCount(); i++) {
                    if (Types::Image == sourceModel()->data(sourceModel()->index(i, 0, QModelIndex()), Roles::ItemTypeRole).toInt() && m_containImages == false) {
                        setContainImages(true);
                        break;
                }
            }
        });
    
    //using the same cache of the engine, they index both by url
    m_imageCache = new KImageCache(QStringLiteral("org.kde.koko"), 10485760);
    
}

SortModel::~SortModel()
{
    delete m_imageCache;
}

void SortModel::setContainImages(bool value)
{
    m_containImages = value;
    emit containImagesChanged();
}

QByteArray SortModel::sortRoleName() const
{
    int role = sortRole();
    return roleNames().value(role);
}

void SortModel::setSortRoleName(const QByteArray& name)
{
    if (!sourceModel()) {
        m_sortRoleName = name;
        return;
    }

    const QHash<int, QByteArray> roles = sourceModel()->roleNames();
    for (auto it = roles.begin(); it != roles.end(); it++) {
        if (it.value() == name) {
            setSortRole(it.key());
            return;
        }
    }
    qDebug() << "Sort role" << name << "not found";
}

QHash<int, QByteArray> SortModel::roleNames() const
{
    QHash<int, QByteArray> hash = sourceModel()->roleNames();
    hash.insert( Roles::SelectedRole, "selected");
    hash.insert( Roles::Thumbnail, "thumbnail");
    return hash;
}


QVariant SortModel::data(const QModelIndex& index, int role) const
{
    if( !index.isValid()) {
        return QVariant();
    }
    
    switch( role) {
        
        case Roles::SelectedRole: {
            return m_selectionModel->isSelected(index);
        }
        
        case Roles::Thumbnail: {
            QUrl thumbnailSource(QString( /*"file://" + */data( index, Roles::ImageUrlRole).toString()));
            
            KFileItem item( thumbnailSource, QString() );
            QImage preview = QImage(m_screenshotSize, QImage::Format_ARGB32_Premultiplied);
            
            if (m_imageCache->findImage(item.url().toString(), &preview)) {
                return preview;
            }
            
            m_previewTimer->start(100);
            const_cast<SortModel *>(this)->m_filesToPreview[item.url()] = QPersistentModelIndex(index);
        }
        
    }
    
    return QSortFilterProxyModel::data(index, role);
}

void SortModel::setSourceModel(QAbstractItemModel* sourceModel)
{
    QSortFilterProxyModel::setSourceModel(sourceModel);

    if (!m_sortRoleName.isEmpty()) {
        setSortRoleName(m_sortRoleName);
        m_sortRoleName.clear();
    }
}

bool SortModel::containImages()
{
    return m_containImages;
}


bool SortModel::hasSelectedImages() 
{
    return m_selectionModel->hasSelection();
}

void SortModel::setSelected(int indexValue)
{
    if( indexValue < 0)
        return;

    QModelIndex index = QSortFilterProxyModel::index( indexValue, 0);
    m_selectionModel->select( index, QItemSelectionModel::Select );
    emit dataChanged( index, index);
    emit selectedImagesChanged();
}

void SortModel::toggleSelected(int indexValue )
{
    if( indexValue < 0)
        return;
    
    QModelIndex index = QSortFilterProxyModel::index( indexValue, 0);
    m_selectionModel->select( index, QItemSelectionModel::Toggle );
    emit dataChanged( index, index);
    emit selectedImagesChanged();
}

void SortModel::clearSelections()
{
    if(m_selectionModel->hasSelection()) {
        QModelIndexList selectedIndex = m_selectionModel->selectedIndexes();
        m_selectionModel->clear();
        foreach(QModelIndex indexValue, selectedIndex) {
            emit dataChanged( indexValue, indexValue);
        }
    }
    emit selectedImagesChanged();
}

void SortModel::selectAll() 
{
    QModelIndexList indexList;
    for( int row=0; row<rowCount(); row++)
    {
        indexList.append( index( row, 0, QModelIndex()));
    }
    
    if( m_selectionModel->hasSelection()) {
        m_selectionModel->clear();
    }
    
    foreach(QModelIndex index, indexList)
    {
        if( Types::Image == data(index, Roles::ItemTypeRole))
            m_selectionModel->select( index, QItemSelectionModel::Select);
    }
    emit dataChanged( index( 0, 0, QModelIndex()), index( rowCount()-1, 0, QModelIndex()) );
    emit selectedImagesChanged();
}

void SortModel::delayedPreview()
{
    QHash<QUrl, QPersistentModelIndex>::const_iterator i = m_filesToPreview.constBegin();
    
    KFileItemList list;
    
    while (i != m_filesToPreview.constEnd()) {
        QUrl file = i.key();
        QPersistentModelIndex index = i.value();
        
        
        if (!m_previewJobs.contains(file) && file.isValid()) {
            list.append(KFileItem(file, QString(), 0));
            m_previewJobs.insert(file, QPersistentModelIndex(index));
        }
        
        ++i;
    }
    
    if (list.size() > 0) {
        KIO::PreviewJob* job = KIO::filePreview(list, m_screenshotSize);
        job->setIgnoreMaximumSize(true);
        // qDebug() << "Created job" << job;
        connect(job, &KIO::PreviewJob::gotPreview,
                this, &SortModel::showPreview);
        connect(job, &KIO::PreviewJob::failed,
                this, &SortModel::previewFailed);
    }
    
    m_filesToPreview.clear();
}

void SortModel::showPreview(const KFileItem &item, const QPixmap &preview)
{
    QPersistentModelIndex index = m_previewJobs.value(item.url());
    m_previewJobs.remove(item.url());
    
    if (!index.isValid()) {
        return;
    }
    
    m_imageCache->insertImage(item.url().toString(), preview.toImage());
    //qDebug() << "preview size:" << preview.size();
    emit dataChanged(index, index);
}

void SortModel::previewFailed(const KFileItem &item)
{
    m_previewJobs.remove(item.url());
}
