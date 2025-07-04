/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "sortmodel.h"
#include "roles.h"
#include "types.h"
#include <QDebug>
#include <QElapsedTimer>
#include <QIcon>
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
            if (Types::Image == data(index(i, 0, QModelIndex()), Roles::ItemTypeRole).toInt() && m_containImages == false) {
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
            const auto itemType = sourceModel()->data(sourceModel()->index(i, 0, {}), Roles::ItemTypeRole).toInt();
            if (Types::Image == itemType && m_containImages == false) {
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

        const KFileItem item(thumbnailSource, QString());

        auto it = std::ranges::find_if(m_itemData, [&item](const auto &itemData) {
            return itemData->item == item;
        });

        if (it == m_itemData.cend()) {
            // we need to or already are generating a preview
            if (!m_itemsToPreview.contains(item)) {
                const_cast<SortModel *>(this)->m_itemsToPreview.append(item);
            }
            if (!m_previewTimer->isActive()) {
                m_previewTimer->start(100ms);
            }
            return false;
        }

        const auto pixmap = (*it)->values.value("iconPixmap").value<QImage>();
        if (pixmap.isNull()) {
            return false;
        }
        return pixmap;
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
        if ((sourceModel()->data(source_left, Roles::ItemTypeRole) == Types::Folder && sourceModel()->data(source_right, Roles::ItemTypeRole) == Types::Folder)
            || (sourceModel()->data(source_left, Roles::ItemTypeRole) != Types::Folder
                && sourceModel()->data(source_right, Roles::ItemTypeRole) != Types::Folder)) {
            return QSortFilterProxyModel::lessThan(source_left, source_right);
        } else if (sourceModel()->data(source_left, Roles::ItemTypeRole) == Types::Folder
                   && sourceModel()->data(source_right, Roles::ItemTypeRole) != Types::Folder) {
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
        if (Types::Image == data(index, Roles::ItemTypeRole))
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
    KFileItemList itemSubSet;

    if (m_itemsToPreview.isEmpty()) {
        return;
    }

    if (m_itemsToPreview.constFirst().isMimeTypeKnown()) {
        // Some mime types are known already, probably because they were
        // determined when loading the icons for the visible items. Start
        // a preview job for all items at the beginning of the list which
        // have a known mime type.
        do {
            itemSubSet.append(m_itemsToPreview.takeFirst());
        } while (!m_itemsToPreview.isEmpty() && m_itemsToPreview.constFirst().isMimeTypeKnown());
    } else {
        // Determine mime types for MaxBlockTimeout ms, and start a preview
        // job for the corresponding items.
        QElapsedTimer timer;
        timer.start();

        do {
            const KFileItem item = m_itemsToPreview.takeFirst();
            item.determineMimeType();
            itemSubSet.append(item);
        } while (!m_itemsToPreview.isEmpty() && timer.elapsed() < MaxBlockTimeout);
    }

    m_itemsInPreviewGeneration << itemSubSet;

    if (itemSubSet.size() > 0) {
        static const auto pluginLists = KIO::PreviewJob::availablePlugins();
        KIO::PreviewJob *job = KIO::filePreview(itemSubSet, m_screenshotSize, &pluginLists);
        job->setIgnoreMaximumSize(true);
#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
        connect(job, &KIO::PreviewJob::generated, this, &SortModel::showPreview);
#else
        connect(job, &KIO::PreviewJob::gotPreview, this, &SortModel::showPreview);
#endif
        connect(job, &KIO::PreviewJob::failed, this, &SortModel::previewFailed);
        connect(job, &KIO::PreviewJob::finished, this, [this] {
            delayedPreview();
        });
    }

    m_itemsToPreview.clear();
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
    m_itemsInPreviewGeneration.removeAll(item);

    if (!index.isValid()) {
        return;
    }
    std::shared_ptr<ItemData> itemData;
    auto it = std::ranges::find_if(m_itemData, [&item](const auto &itemData) {
        return itemData->item == item;
    });

    if (it == m_itemData.cend()) {
        itemData = std::make_shared<ItemData>(item, QHash<QByteArray, QVariant>{});
        m_itemData.push_back(itemData);
    } else {
        itemData = *it;
    }

#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    itemData->values["iconPixmap"] = preview;
#else
    itemData->values["iconPixmap"] = preview.toImage();
#endif

    // qDebug() << "preview size:" << preview.size();
    Q_EMIT dataChanged(index, index, {Roles::Thumbnail});
}

void SortModel::previewFailed(const KFileItem &item)
{
    // Use folder image instead of displaying nothing then thumbnail generation fails
    const auto index = itemToIndex(item);
    m_itemsInPreviewGeneration.removeAll(item);

    if (!index.isValid()) {
        return;
    }

    std::shared_ptr<ItemData> itemData;
    auto it = std::ranges::find_if(m_itemData, [&item](const auto &itemData) {
        return itemData->item == item;
    });

    if (it == m_itemData.cend()) {
        itemData = std::make_shared<ItemData>(item, QHash<QByteArray, QVariant>{});
        m_itemData.push_back(itemData);
    } else {
        itemData = *it;
    }

    itemData->values["iconPixmap"] = QIcon::fromTheme(item.iconName()).pixmap(m_screenshotSize).toImage();
    Q_EMIT dataChanged(index, index, {Roles::Thumbnail});
}
