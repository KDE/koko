/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QCollator>

#include "gallerysortfilterproxymodel.h"

AbstractGalleryModel::ImageRoles sortModeToRole(const GallerySortFilterProxyModel::SortMode sortMode)
{
    switch (sortMode) {
    default:
    case GallerySortFilterProxyModel::Name:
        return AbstractGalleryModel::ImageRoles::NameRole;
    case GallerySortFilterProxyModel::Size:
        return AbstractGalleryModel::ImageRoles::SizeRole;
    case GallerySortFilterProxyModel::Modified:
        return AbstractGalleryModel::ImageRoles::ModifiedRole;
    case GallerySortFilterProxyModel::Created:
        return AbstractGalleryModel::ImageRoles::CreatedRole;
    case GallerySortFilterProxyModel::Accessed:
        return AbstractGalleryModel::ImageRoles::AccessedRole;
    }
}

class PrivateGallerySortModel : public QSortFilterProxyModel
{
public:
    using QSortFilterProxyModel::QSortFilterProxyModel;

protected:
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override
    {
        //  TODO: Handle sortReversed here instead, because otherwise folders would be last

        const auto sort_role = sortRole();

        const auto itemTypeLeft = source_left.data(AbstractGalleryModel::ItemTypeRole).value<AbstractGalleryModel::ItemType>();
        const auto itemTypeRight = source_right.data(AbstractGalleryModel::ItemTypeRole).value<AbstractGalleryModel::ItemType>();

        // n.b. We do not define how we might sort collections, because they do not appear mixed with folders or images. The sort order would be
        // unstable if they did. The assertion handles and documents this case. If this assumption changes, then we need to think harder about
        // the following sorting code (probably, Collections then Folders then Images).
        Q_ASSERT((itemTypeLeft == AbstractGalleryModel::ItemType::Collection) == (itemTypeRight == AbstractGalleryModel::ItemType::Collection));

        // Sort folders before images
        if (itemTypeLeft == AbstractGalleryModel::ItemType::Folder && itemTypeRight != AbstractGalleryModel::ItemType::Folder) {
            return true;
        } else if (itemTypeLeft != AbstractGalleryModel::ItemType::Folder && itemTypeRight == AbstractGalleryModel::ItemType::Folder) {
            return false;
        }

        if (sort_role == AbstractGalleryModel::ImageRoles::NameRole || sort_role == Qt::DisplayRole) {
            const QString leftName = source_left.data(sort_role).toString();
            const QString rightName = source_right.data(sort_role).toString();

            if (!leftName.isEmpty() && !rightName.isEmpty()) {
                static QCollator collator;
                collator.setNumericMode(true); // As in Dolphin
                return collator.compare(leftName, rightName) < 0;
            }
        }

        return QSortFilterProxyModel::lessThan(source_left, source_right);
    }
};

GallerySortFilterProxyModel::GallerySortFilterProxyModel(QObject *parent)
    : QIdentityProxyModel(parent)
    , m_galleryModel(nullptr)
    , m_sortModel(nullptr)
    , m_filterModel(nullptr)
    , m_sortMode(Name)
    , m_sortReversed(false)
    , m_filterString(QString())
{
}

AbstractGalleryModel *GallerySortFilterProxyModel::galleryModel() const
{
    return m_galleryModel;
}

void GallerySortFilterProxyModel::setGalleryModel(AbstractGalleryModel *galleryModel)
{
    if (m_galleryModel == galleryModel) {
        return;
    }

    m_galleryModel = galleryModel;
    Q_EMIT galleryModelChanged();

    if (m_galleryModel == nullptr) {
        // No model, so destroy the pipeline
        setSourceModel(nullptr);

        if (m_sortModel) {
            m_sortModel->deleteLater();
            m_sortModel = nullptr;
        }

        if (m_filterModel) {
            m_filterModel->deleteLater();
            m_filterModel = nullptr;
        }
    }

    // Set up the pipeline
    if (!m_sortModel) {
        m_sortModel = new PrivateGallerySortModel(this);
        m_sortModel->setFilterFixedString(m_filterString);
        m_sortModel->setSortRole(sortModeToRole(m_sortMode));
        m_sortModel->sort(0, m_sortReversed ? Qt::SortOrder::DescendingOrder : Qt::SortOrder::AscendingOrder);
    }

    if (galleryModel->requiresFiltering() && !m_filterModel) {
        m_filterModel = new QSortFilterProxyModel(this);
        // TODO set up filtering
    }

    if (!galleryModel->requiresFiltering() && m_filterModel) {
        m_filterModel->deleteLater();
        m_filterModel = nullptr;
    }

    m_sortModel->setSourceModel(m_galleryModel);

    if (m_filterModel) {
        m_filterModel->setSourceModel(m_sortModel);
        setSourceModel(m_filterModel);
    } else {
        setSourceModel(m_sortModel);
    }
}

GallerySortFilterProxyModel::SortMode GallerySortFilterProxyModel::sortMode() const
{
    return m_sortMode;
}

void GallerySortFilterProxyModel::setSortMode(SortMode sortMode)
{
    if (m_sortMode != sortMode) {
        m_sortMode = sortMode;
        Q_EMIT sortModeChanged();

        if (m_sortModel) {
            m_sortModel->setSortRole(sortModeToRole(m_sortMode));
            m_sortModel->sort(0, m_sortReversed ? Qt::SortOrder::DescendingOrder : Qt::SortOrder::AscendingOrder);
        }
    }
}

bool GallerySortFilterProxyModel::sortReversed() const
{
    return m_sortReversed;
}

void GallerySortFilterProxyModel::setSortReversed(bool sortReversed)
{
    if (m_sortReversed != sortReversed) {
        m_sortReversed = sortReversed;
        Q_EMIT sortReversedChanged();

        if (m_sortModel) {
            m_sortModel->sort(0, m_sortReversed ? Qt::SortOrder::DescendingOrder : Qt::SortOrder::AscendingOrder);
        }
    }
}

QString GallerySortFilterProxyModel::filterString() const
{
    return m_filterString;
}

void GallerySortFilterProxyModel::setFilterString(const QString &filterString)
{
    if (m_filterString != filterString) {
        m_filterString = filterString;
        Q_EMIT filterStringChanged();

        if (m_sortModel) {
            m_sortModel->setFilterFixedString(filterString);
        }
    }
}
