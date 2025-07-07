/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "sortmodel.h"
#include "imagestorage.h"
#include "roles.h"
#include <QDebug>
#include <QFileInfo>
#include <QIcon>
#include <QMimeDatabase>
#include <QTimer>

#include <KIO/CopyJob>
#include <KIO/PreviewJob>
#include <KIO/RestoreJob>

using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

// Maximum time in ms that the SortModel
// may perform a blocking operation
const int MaxBlockTimeout = 200;

SortModel::SortModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_screenshotSize(256, 256)
    , m_containImages(false)
    , m_itemData(5000)
{
    setSortLocaleAware(true);
    sort(0);
    m_selectionModel = new QItemSelectionModel(this);

    m_previewTimer = new QTimer(this);
    m_previewTimer->setSingleShot(true);
    connect(m_previewTimer, &QTimer::timeout, this, &SortModel::delayedPreview);

    connect(this, &SortModel::rowsInserted, this, [this](const QModelIndex &parent, int first, int last) {
        Q_UNUSED(parent)
        for (int i = first; i <= last; i++) {
            const auto itemType = index(i, 0, {}).data(Roles::ItemTypeRole).value<ImageStorage::ItemTypes>();
            if (ImageStorage::ItemTypes::Image == itemType && m_containImages == false) {
                setContainImages(true);
                break;
            }
        }
    });

    connect(this, &SortModel::sourceModelChanged, this, [this]() {
        if (!sourceModel()) {
            return;
        }
        for (int i = 0; i < sourceModel()->rowCount(); i++) {
            const auto itemType = sourceModel()->data(sourceModel()->index(i, 0, {}), Roles::ItemTypeRole).value<ImageStorage::ItemTypes>();
            if (ImageStorage::ItemTypes::Image == itemType && m_containImages == false) {
                setContainImages(true);
                break;
            }
        }
    });
}

SortModel::~SortModel() = default;

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

void SortModel::setSortRoleName(const QByteArray &name)
{
    if (!sourceModel()) {
        m_sortRoleName = name;
        emit sortRoleNameChanged();
        return;
    }

    const QHash<int, QByteArray> roles = sourceModel()->roleNames();
    for (auto it = roles.begin(); it != roles.end(); it++) {
        if (it.value() == name) {
            setSortRole(it.key());
            emit sortRoleNameChanged();
            return;
        }
    }
    qDebug() << "Sort role" << name << "not found";
}

QHash<int, QByteArray> SortModel::roleNames() const
{
    if (!sourceModel()) {
        return {};
    }
    QHash<int, QByteArray> hash = sourceModel()->roleNames();
    hash.insert(Roles::SelectedRole, "selected");
    hash.insert(Roles::Thumbnail, "thumbnail");
    hash.insert(Roles::SourceIndex, "sourceIndex");
    return hash;
}

QVariant SortModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    switch (role) {
    case Roles::SelectedRole: {
        return m_selectionModel->isSelected(index);
    }

    case Roles::Thumbnail: {
        const QUrl thumbnailSource(data(index, Roles::ImageUrlRole).toString());

        if (m_itemData.contains(thumbnailSource)) {
            const auto pixmap = m_itemData[thumbnailSource]->thumbnail;
            if (pixmap.isNull()) {
                Q_ASSERT_X(false, Q_FUNC_INFO, "At that point we should have a thumbnail");
                return false;
            }
            return pixmap;
        }

        const KFileItem item(thumbnailSource, {});

        if (!m_filesInPreviewGeneration.contains(thumbnailSource) && !m_filesToPreview.contains(item)) {
            QString mimeType;
            static QMimeDatabase db;
            const QString scheme = thumbnailSource.scheme();
            QFileInfo info(thumbnailSource.path());

            if (info.isDir()) {
                mimeType = u"inode/directory"_s;
            } else if (scheme.startsWith(QLatin1String("http")) || scheme == QLatin1String("mailto")) {
                mimeType = u"application/octet-stream"_s;
            } else {
                mimeType = db.mimeTypeForFile(thumbnailSource.path(), QMimeDatabase::MatchMode::MatchExtension).name();
            }

            KFileItem itemWithMimetype(thumbnailSource, mimeType);
            m_filesToPreview.append(itemWithMimetype);

            if (!m_previewTimer->isActive()) {
                m_previewTimer->start();
            }
            return false;
        }

        // already generating the preview
        return false;
    }

    case Roles::SourceIndex: {
        return mapToSource(index).row();
    }
    }

    return QSortFilterProxyModel::data(index, role);
}

bool SortModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    if (sourceModel()) {
        const auto itemTypeLeft = sourceModel()->data(source_left, Roles::ItemTypeRole).value<ImageStorage::ItemTypes>();
        const auto itemTypeRight = sourceModel()->data(source_right, Roles::ItemTypeRole).value<ImageStorage::ItemTypes>();

        if ((itemTypeLeft == ImageStorage::ItemTypes::Folder && itemTypeRight == ImageStorage::ItemTypes::Folder)
            || (itemTypeLeft != ImageStorage::ItemTypes::Folder && itemTypeRight != ImageStorage::ItemTypes::Folder)) {
            return QSortFilterProxyModel::lessThan(source_left, source_right);
        } else if (itemTypeLeft == ImageStorage::ItemTypes::Folder && itemTypeRight != ImageStorage::ItemTypes::Folder) {
            return true;
        } else {
            return false;
        }
    }

    return false;
}

void SortModel::setSourceModel(QAbstractItemModel *sourceModel)
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
    if (indexValue < 0)
        return;

    QModelIndex index = QSortFilterProxyModel::index(indexValue, 0);
    m_selectionModel->select(index, QItemSelectionModel::Select);
    emit dataChanged(index, index);
    emit selectedImagesChanged();
}

void SortModel::toggleSelected(int indexValue)
{
    if (indexValue < 0)
        return;

    QModelIndex index = QSortFilterProxyModel::index(indexValue, 0);
    m_selectionModel->select(index, QItemSelectionModel::Toggle);
    emit dataChanged(index, index);
    emit selectedImagesChanged();
}

void SortModel::clearSelections()
{
    if (m_selectionModel->hasSelection()) {
        QModelIndexList selectedIndex = m_selectionModel->selectedIndexes();
        m_selectionModel->clear();
        for (auto indexValue : selectedIndex) {
            emit dataChanged(indexValue, indexValue);
        }
    }
    emit selectedImagesChanged();
}

void SortModel::selectAll()
{
    QModelIndexList indexList;
    for (int row = 0; row < rowCount(); row++) {
        indexList.append(index(row, 0, QModelIndex()));
    }

    if (m_selectionModel->hasSelection()) {
        m_selectionModel->clear();
    }

    for (auto index : indexList) {
        if (ImageStorage::ItemTypes::Image == data(index, Roles::ItemTypeRole).value<ImageStorage::ItemTypes>())
            m_selectionModel->select(index, QItemSelectionModel::Select);
    }
    emit dataChanged(index(0, 0, QModelIndex()), index(rowCount() - 1, 0, QModelIndex()));
    emit selectedImagesChanged();
}

void SortModel::deleteSelection()
{
    QList<QUrl> filesToDelete;

    for (auto index : m_selectionModel->selectedIndexes()) {
        filesToDelete << data(index, Roles::ImageUrlRole).toUrl();
    }

    auto trashJob = KIO::trash(filesToDelete);
    trashJob->exec();
}

void SortModel::restoreSelection()
{
    QList<QUrl> filesToRestore;

    foreach (QModelIndex index, m_selectionModel->selectedIndexes()) {
        filesToRestore << data(index, Roles::ImageUrlRole).toUrl();
    }

    auto restoreJob = KIO::restoreFromTrash(filesToRestore);
    restoreJob->exec();
}

int SortModel::proxyIndex(const int &indexValue)
{
    if (sourceModel()) {
        return mapFromSource(sourceModel()->index(indexValue, 0, QModelIndex())).row();
    }
    return -1;
}

int SortModel::sourceIndex(const int &indexValue)
{
    return mapToSource(index(indexValue, 0, QModelIndex())).row();
}

QJsonArray SortModel::selectedImages()
{
    QJsonArray arr;

    for (auto index : m_selectionModel->selectedIndexes()) {
        arr.push_back(QJsonValue(data(index, Roles::ImageUrlRole).toString()));
    }

    return arr;
}

QJsonArray SortModel::selectedImagesMimeTypes()
{
    QJsonArray arr;

    for (auto index : m_selectionModel->selectedIndexes()) {
        if (!arr.contains(QJsonValue(data(index, Roles::MimeTypeRole).toString()))) {
            arr.push_back(QJsonValue(data(index, Roles::MimeTypeRole).toString()));
        }
    }

    return arr;
}

int SortModel::indexForUrl(const QString &url)
{
    QModelIndexList indexList;
    for (int row = 0; row < rowCount(); row++) {
        indexList.append(index(row, 0, QModelIndex()));
    }
    for (auto index : indexList) {
        if (url == data(index, Roles::ImageUrlRole).toString()) {
            return index.row();
        }
    }
    return -1;
}

void SortModel::delayedPreview()
{
    if (m_filesToPreview.isEmpty()) {
        return;
    }

    Q_ASSERT(std::ranges::all_of(m_filesToPreview, [](const auto &item) {
        return item.isMimeTypeKnown();
    }));

    for (const auto &file : std::as_const(m_filesToPreview)) {
        m_filesInPreviewGeneration.insert(file.url());
    }

    static const auto pluginLists = KIO::PreviewJob::availablePlugins();
    KIO::PreviewJob *job = KIO::filePreview(QList<KFileItem>(m_filesToPreview.cbegin(), m_filesToPreview.cend()), m_screenshotSize, &pluginLists);
    job->setIgnoreMaximumSize(true);
#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    connect(job, &KIO::PreviewJob::generated, this, &SortModel::showPreview);
#else
    connect(job, &KIO::PreviewJob::gotPreview, this, &SortModel::showPreview);
#endif
    connect(job, &KIO::PreviewJob::failed, this, &SortModel::previewFailed);
    job->start();

    m_filesToPreview.clear();
}

QModelIndex SortModel::itemToIndex(const KFileItem &item)
{
    for (auto i = 0, count = rowCount(); i < count; i++) {
        const QUrl url(index(i, 0).data(Roles::ImageUrlRole).toString());
        if (url == item.url()) {
            return index(i, 0);
        }
    }

    return {};
}

#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
void SortModel::showPreview(const KFileItem &item, const QImage &preview)
#else
void SortModel::showPreview(const KFileItem &item, const QPixmap &preview)
#endif
{
    const auto index = itemToIndex(item);
    m_filesInPreviewGeneration.remove(item.url());

    if (!index.isValid()) {
        return;
    }
    ItemData *itemData;
    if (m_itemData.contains(item.url())) {
        itemData = m_itemData[item.url()];
    } else {
        itemData = new ItemData(item, {});
        m_itemData.insert(item.url(), itemData);
    }

#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    itemData->thumbnail = preview;
#else
    itemData->thumbnail = preview.toImage();
#endif

    // qDebug() << "preview size:" << preview.size();
    Q_EMIT dataChanged(index, index, {Roles::Thumbnail});
}

void SortModel::previewFailed(const KFileItem &item)
{
    // Use folder image instead of displaying nothing then thumbnail generation fails
    const auto index = itemToIndex(item);
    m_filesInPreviewGeneration.remove(item.url());

    if (!index.isValid()) {
        return;
    }

    ItemData *itemData;
    if (m_itemData.contains(item.url())) {
        itemData = m_itemData[item.url()];
    } else {
        itemData = new ItemData(item, {});
        m_itemData.insert(item.url(), itemData);
    }

    itemData->thumbnail = QIcon::fromTheme(item.iconName()).pixmap(m_screenshotSize).toImage();
    Q_EMIT dataChanged(index, index, {Roles::Thumbnail});
}
