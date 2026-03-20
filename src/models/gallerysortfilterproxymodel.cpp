/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <QCollator>

#include "abstractgallerymodel.h"

#include "gallerysortfilterproxymodel.h"

using namespace Qt::StringLiterals;

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

GallerySortFilterProxyModel::GallerySortFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_sortMode(Name)
    , m_filterString(QString())
{
    setSortRole(sortModeToRole(m_sortMode));
    sort(0, Qt::AscendingOrder);
}

GallerySortFilterProxyModel::SortMode GallerySortFilterProxyModel::sortMode() const
{
    return m_sortMode;
}

void GallerySortFilterProxyModel::setSortMode(SortMode sortMode)
{
    if (m_sortMode == sortMode) {
        return;
    }

    m_sortMode = sortMode;
    Q_EMIT sortModeChanged();

    setSortRole(sortModeToRole(m_sortMode));
    sort(0, sortOrder());
}

bool GallerySortFilterProxyModel::sortReversed() const
{
    return sortOrder() == Qt::DescendingOrder;
}

void GallerySortFilterProxyModel::setSortReversed(bool sortReversed)
{
    if (sortReversed == (sortOrder() == Qt::DescendingOrder)) {
        return;
    }

    sort(0, sortReversed ? Qt::DescendingOrder : Qt::AscendingOrder);
    Q_EMIT sortReversedChanged();
}

QString GallerySortFilterProxyModel::filterString() const
{
    return m_filterString;
}

void GallerySortFilterProxyModel::setFilterString(const QString &filterString)
{
    if (m_filterString == filterString) {
        return;
    }

    m_filterString = filterString;
    Q_EMIT filterStringChanged();

    setFilterFixedString(filterString);
}

bool GallerySortFilterProxyModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    auto sort_role = sortRole();

    const auto itemTypeLeft = source_left.data(AbstractGalleryModel::ItemTypeRole).value<AbstractGalleryModel::ItemType>();
    const auto itemTypeRight = source_right.data(AbstractGalleryModel::ItemTypeRole).value<AbstractGalleryModel::ItemType>();

    // n.b. We do not define how we might sort collections, because they do not appear mixed with folders or images. The sort order would be
    // unstable if they did. The assertion handles and documents this case. If this assumption changes, then we need to think harder about
    // the following sorting code (probably, Collections then Folders then Images).
    Q_ASSERT((itemTypeLeft == AbstractGalleryModel::ItemType::Collection) == (itemTypeRight == AbstractGalleryModel::ItemType::Collection));

    if (itemTypeLeft == AbstractGalleryModel::ItemType::Collection) {
        // For collections, sort by DisplayRole
        QVariant leftData = source_left.data(Qt::DisplayRole);
        QVariant rightData = source_right.data(Qt::DisplayRole);
        return QVariant::compare(leftData, rightData) < 0;
    }

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
