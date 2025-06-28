// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "deviceimagemodel.h"

#include <KCoreDirLister>

#include "roles.h"
#include "types.h"

DeviceImageModel::DeviceImageModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_dirLister(new KCoreDirLister(this))
{
    connect(m_dirLister, &KCoreDirLister::itemsAdded, this, &DeviceImageModel::slotItemsAdded);
    connect(m_dirLister, &KCoreDirLister::itemsDeleted, this, &DeviceImageModel::slotItemsDeleted);
    connect(m_dirLister, QOverload<>::of(&KCoreDirLister::completed), this, &DeviceImageModel::completed);
    connect(m_dirLister, QOverload<>::of(&KCoreDirLister::clear), this, &DeviceImageModel::slotCleared);
    connect(m_dirLister, &KCoreDirLister::clearDir, this, &DeviceImageModel::slotDirCleared);
}

DeviceImageModel::~DeviceImageModel() = default;

QUrl DeviceImageModel::url() const
{
    return m_dirLister->url();
}

void DeviceImageModel::setUrl(const QUrl &url)
{
    beginResetModel();
    clear();
    endResetModel();
    m_dirLister->openUrl(url);
}

void DeviceImageModel::removeAt(int row)
{
    KFileItem item = m_list.takeAt(row);
    m_rowForUrl.remove(item.url());

    // Decrease row value for all urls after the one we removed
    // ("row" now points to the item after the one we removed since we used takeAt)
    const int count = m_list.count();
    for (; row < count; ++row) {
        QUrl url = m_list.at(row).url();
        m_rowForUrl[url]--;
    }
}

void DeviceImageModel::addItem(const KFileItem &item)
{
    m_rowForUrl.insert(item.url(), m_list.count());
    m_list.append(item);
}

void DeviceImageModel::clear()
{
    m_rowForUrl.clear();
    m_list.clear();
}

QHash<int, QByteArray> DeviceImageModel::roleNames() const
{
    return Roles::roleNames();
}

int DeviceImageModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_list.count();
}

QVariant DeviceImageModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid)) {
        qWarning() << "index is invalid" << index << rowCount({});
        return {};
    }

    KFileItem item = m_list.value(index.row());

    if (item.isNull()) {
        return {};
    }

    switch (role) {
    case Roles::ImageUrlRole:
        return item.url().toString();

    case Roles::MimeTypeRole:
        return item.mimetype();

    case Roles::ItemTypeRole:
        return Types::Image;

    case Roles::SelectedRole:
        return false;

    case Roles::ContentRole:
        return {};

    default:
        return {};
    }
}

void DeviceImageModel::slotItemsAdded(const QUrl &, const KFileItemList &newList)
{
    QList<QUrl> dirUrls;
    KFileItemList fileList;
    for (const KFileItem &item : newList) {
        if (item.isFile()) {
            if (m_rowForUrl.value(item.url(), -1) == -1) {
                fileList << item;
            }
        } else {
            dirUrls << item.url();
        }
    }

    if (!fileList.isEmpty()) {
        beginInsertRows({}, m_list.count(), m_list.count() + fileList.count());
        for (const KFileItem &item : std::as_const(fileList)) {
            addItem(item);
        }
        endInsertRows();
    }

    for (const QUrl &url : std::as_const(dirUrls)) {
        m_dirLister->openUrl(url, KCoreDirLister::Keep);
    }
}

void DeviceImageModel::slotItemsDeleted(const KFileItemList &list)
{
    for (const KFileItem &item : list) {
        if (item.isDir()) {
            continue;
        }
        int row = m_rowForUrl.value(item.url(), -1);
        if (row == -1) {
            qFatal() << "Received itemsDeleted for an unknown item: this should not happen!";
            continue;
        }
        beginRemoveRows(QModelIndex(), row, row);
        removeAt(row);
        endRemoveRows();
    }
}

void DeviceImageModel::slotCleared()
{
    if (m_list.isEmpty()) {
        return;
    }
    beginResetModel();
    clear();
    endResetModel();
}

void DeviceImageModel::slotDirCleared(const QUrl &dirUrl)
{
    int row;
    for (row = m_list.count() - 1; row >= 0; --row) {
        const QUrl url = m_list.at(row).url();
        if (dirUrl.isParentOf(url)) {
            beginRemoveRows(QModelIndex(), row, row);
            removeAt(row);
            endRemoveRows();
        }
    }
}
