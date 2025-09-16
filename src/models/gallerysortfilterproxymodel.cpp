/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <QCollator>
#include <QMimeDatabase>

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

class PrivateGallerySortModel : public QSortFilterProxyModel
{
public:
    using QSortFilterProxyModel::QSortFilterProxyModel;

    void setSortReversed(const bool sortReversed)
    {
        if (m_sortReversed == sortReversed) {
            return;
        }

        m_sortReversed = sortReversed;
        invalidate();
    }

protected:
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override
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
            const bool result = QVariant::compare(leftData, rightData) < 0;
            return m_sortReversed ? !result : result;
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

                const bool result = collator.compare(leftName, rightName) < 0;
                return m_sortReversed ? !result : result;
            }
        }

        const bool result = QSortFilterProxyModel::lessThan(source_left, source_right);
        return m_sortReversed ? !result : result;
    }

private:
    bool m_sortReversed = false;
};

class PrivateGalleryFilterModel : public QSortFilterProxyModel
{
public:
    using QSortFilterProxyModel::QSortFilterProxyModel;

    void setFilterMimeTypes(const QStringList &filterMimeTypes)
    {
        if (m_filterMimeTypes == filterMimeTypes) {
            return;
        }

        m_filterMimeTypes = filterMimeTypes;
        invalidate();
    }

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override
    {
        QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
        QString value = sourceModel()->data(index, AbstractGalleryModel::MimeTypeRole).toString();

        return m_filterMimeTypes.contains(value);
    }

private:
    QStringList m_filterMimeTypes;
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
    // TODO: Use mimetypes advertised by QImageReader and QMediaFormat::supportedFileFormats -> mimetype
    // Build that only once for the entire application and re-use
    QMimeDatabase db;
    const QList<QMimeType> mimeList = db.allMimeTypes();

    m_filterMimeTypes << "inode/directory";
    for (const auto &mime : mimeList) {
        const auto mimeName = mime.name();
        if (mimeName.startsWith("image/"_L1) || mimeName.startsWith("video/"_L1)) {
            m_filterMimeTypes << mime.name();
        }
    }
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
        static_cast<PrivateGallerySortModel *>(m_sortModel)->setSortReversed(m_sortReversed);
        m_sortModel->sort(0);
    }

    if (galleryModel->requiresFiltering() && !m_filterModel) {
        m_filterModel = new PrivateGalleryFilterModel(this);
        static_cast<PrivateGalleryFilterModel *>(m_filterModel)->setFilterMimeTypes(m_filterMimeTypes);
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
    if (m_sortMode == sortMode) {
        return;
    }

    m_sortMode = sortMode;
    Q_EMIT sortModeChanged();

    if (m_sortModel) {
        m_sortModel->setSortRole(sortModeToRole(m_sortMode));
        m_sortModel->sort(0);
    }
}

bool GallerySortFilterProxyModel::sortReversed() const
{
    return m_sortReversed;
}

void GallerySortFilterProxyModel::setSortReversed(bool sortReversed)
{
    if (m_sortReversed == sortReversed) {
        return;
    }

    m_sortReversed = sortReversed;
    Q_EMIT sortReversedChanged();

    if (m_sortModel) {
        static_cast<PrivateGallerySortModel *>(m_sortModel)->setSortReversed(m_sortReversed);
    }
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

    if (m_sortModel) {
        m_sortModel->setFilterFixedString(filterString);
    }
}

QModelIndex GallerySortFilterProxyModel::mapToGalleryModelIndex(const QModelIndex &proxyIndex) const
{
    if (!proxyIndex.isValid()) {
        return {};
    }

    if (m_filterModel) {
        return m_sortModel->mapToSource(m_filterModel->mapToSource(QIdentityProxyModel::mapToSource(proxyIndex)));
    } else {
        return m_sortModel->mapToSource(QIdentityProxyModel::mapToSource(proxyIndex));
    }

    return {};
}
