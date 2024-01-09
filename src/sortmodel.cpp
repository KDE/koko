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
#include <QIcon>
#include <QTimer>

#include <KIO/RestoreJob>
#include <kimagecache.h>
#include <kio/copyjob.h>
#include <kio/previewjob.h>

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

    // using the same cache of the engine, they index both by url
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
        QUrl thumbnailSource(QString(/*"file://" + */ data(index, Roles::ImageUrlRole).toString()));

        KFileItem item(thumbnailSource, QString());
        QImage preview = QImage(m_screenshotSize, QImage::Format_ARGB32_Premultiplied);

        if (m_imageCache->findImage(item.url().toString(), &preview)) {
            return preview;
        }

        m_previewTimer->start(100);
        const_cast<SortModel *>(this)->m_filesToPreview[item.url()] = QPersistentModelIndex(index);
        return {};
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
        const auto pluginLists = KIO::PreviewJob::availablePlugins();
        KIO::PreviewJob *job = KIO::filePreview(list, m_screenshotSize, &pluginLists);
        job->setIgnoreMaximumSize(true);
        connect(job, &KIO::PreviewJob::gotPreview, this, &SortModel::showPreview);
        connect(job, &KIO::PreviewJob::failed, this, &SortModel::previewFailed);
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
    // qDebug() << "preview size:" << preview.size();
    emit dataChanged(index, index);
}

void SortModel::previewFailed(const KFileItem &item)
{
    // Use folder image instead of displaying nothing then thumbnail generation fails
    QPersistentModelIndex index = m_previewJobs.value(item.url());
    m_previewJobs.remove(item.url());

    if (!index.isValid()) {
        return;
    }

    m_imageCache->insertImage(item.url().toString(), QIcon::fromTheme(item.iconName()).pixmap(m_screenshotSize).toImage());
    Q_EMIT dataChanged(index, index);
}
