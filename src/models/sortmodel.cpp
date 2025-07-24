/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "sortmodel.h"
#include "abstractimagemodel.h"

#include <QCollator>
#include <QDebug>
#include <QIcon>

#include <KIO/CopyJob>
#include <KIO/RestoreJob>

using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

SortModel::SortModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_containImages(false)
{
    setSortLocaleAware(true);
    setSortRole(AbstractImageModel::ContentRole);
    sort(0);
    m_selectionModel = new QItemSelectionModel(this);

    connect(this, &SortModel::rowsInserted, this, [this](const QModelIndex &parent, int first, int last) {
        Q_UNUSED(parent)

        // No need to re-check if we already contain images before insertion
        if (m_containImages) {
            return;
        }

        bool containImages = false;
        for (int i = first; i <= last; i++) {
            const auto itemType = index(i, 0, {}).data(AbstractImageModel::ItemTypeRole).value<AbstractImageModel::ItemType>();
            if (AbstractImageModel::ItemType::Image == itemType && m_containImages == false) {
                containImages = true;
                break;
            }
        }
        setContainImages(containImages);
    });

    connect(this, &SortModel::sourceModelChanged, this, [this]() {
        if (!sourceModel()) {
            return;
        }
        bool containImages = false;
        for (int i = 0; i < sourceModel()->rowCount(); i++) {
            const auto itemType = sourceModel()->index(i, 0, {}).data(AbstractImageModel::ItemTypeRole).value<AbstractImageModel::ItemType>();
            if (AbstractImageModel::ItemType::Image == itemType && m_containImages == false) {
                containImages = true;
                break;
            }
        }
        setContainImages(containImages);
    });
}

SortModel::~SortModel() = default;

void SortModel::setContainImages(bool value)
{
    m_containImages = value;
    Q_EMIT containImagesChanged();
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
        Q_EMIT sortRoleNameChanged();
        return;
    }

    const QHash<int, QByteArray> AbstractImageModel = sourceModel()->roleNames();
    for (auto it = AbstractImageModel.begin(); it != AbstractImageModel.end(); it++) {
        if (it.value() == name) {
            setSortRole(it.key());
            emit sortRoleNameChanged();
            return;
        }
    }
    qDebug() << "Sort role" << name << "not found";
}

QVariant SortModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    if (role == AbstractImageModel::SelectedRole) {
        return m_selectionModel->isSelected(index);
    }

    return QSortFilterProxyModel::data(index, role);
}

bool SortModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    if (sourceModel()) {
        const auto itemTypeLeft = sourceModel()->data(source_left, AbstractImageModel::ItemTypeRole).value<AbstractImageModel::ItemType>();
        const auto itemTypeRight = sourceModel()->data(source_right, AbstractImageModel::ItemTypeRole).value<AbstractImageModel::ItemType>();

        if ((itemTypeLeft == AbstractImageModel::ItemType::Folder && itemTypeRight == AbstractImageModel::ItemType::Folder)
            || (itemTypeLeft != AbstractImageModel::ItemType::Folder && itemTypeRight != AbstractImageModel::ItemType::Folder)) {
            const QString leftData = sourceModel()->data(source_left, sortRole()).toString();
            const QString rightData = sourceModel()->data(source_right, sortRole()).toString();
            if (!leftData.isEmpty() && !rightData.isEmpty()) {
                static QCollator collator;
                collator.setNumericMode(true);
                return collator.compare(leftData, rightData) < 0;
            }

            return QSortFilterProxyModel::lessThan(source_left, source_right);
        } else if (itemTypeLeft == AbstractImageModel::ItemType::Folder && itemTypeRight != AbstractImageModel::ItemType::Folder) {
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

void SortModel::deleteSelection()
{
    QList<QUrl> filesToDelete;

    for (auto index : m_selectionModel->selectedIndexes()) {
        filesToDelete << data(index, AbstractImageModel::ImageUrlRole).toUrl();
    }

    auto trashJob = KIO::trash(filesToDelete);
    trashJob->exec();
}

void SortModel::restoreSelection()
{
    QList<QUrl> filesToRestore;

    foreach (QModelIndex index, m_selectionModel->selectedIndexes()) {
        filesToRestore << data(index, AbstractImageModel::ImageUrlRole).toUrl();
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

int SortModel::indexForUrl(const QString &url)
{
    for (int row = 0; row < rowCount(); ++row) {
        QModelIndex idx = index(row, 0);
        if (data(idx, AbstractImageModel::ImageUrlRole).toString() == url) {
            return row;
        }
    }
    return -1;
}
