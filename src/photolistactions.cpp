// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "photolistactions.h"
#include "abstractimagemodel.h"

#include <KAuthorized>
#include <KLocalizedString>

#include <KIO/CopyJob>
#include <KIO/RestoreJob>
#include <kstandardactions.h>

using namespace Qt::StringLiterals;

PhotoListActions::PhotoListActions(QObject *parent)
    : QObject(parent)
{
}

QItemSelectionModel *PhotoListActions::selectionModel() const
{
    return m_selectionModel;
}

void PhotoListActions::setSelectionModel(QItemSelectionModel *selectionModel)
{
    if (selectionModel == m_selectionModel) {
        return;
    }

    if (m_selectionModel) {
        disconnect(m_selectionModel, &QItemSelectionModel::selectionChanged, this, nullptr);
        disconnect(m_selectionModel, &QItemSelectionModel::currentChanged, this, nullptr);
    }

    m_selectionModel = selectionModel;
    Q_EMIT selectionModelChanged();

    setActionState();

    if (m_selectionModel) {
        connect(m_selectionModel, &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &selected, const QItemSelection &deselected) {
            Q_UNUSED(selected);
            Q_UNUSED(deselected);
            setActionState();
        });
        connect(m_selectionModel, &QItemSelectionModel::currentChanged, this, [this](const QModelIndex &selected, const QModelIndex &deselected) {
            Q_UNUSED(selected);
            Q_UNUSED(deselected);
            setActionState();
        });
    }
}

PhotosApplication *PhotoListActions::photosApplication() const
{
    return m_photosApplication;
}

KFileItemList PhotoListActions::selectionToItems() const
{
    auto indexes = m_selectionModel->selectedIndexes();
    if (!indexes.contains(m_selectionModel->currentIndex())) {
        indexes << m_selectionModel->currentIndex();
    }

    KFileItemList items;
    for (const auto &index : std::as_const(indexes)) {
        if (!index.isValid()) {
            continue;
        }

        const auto item = index.data(AbstractImageModel::ItemRole).value<KFileItem>();
        if (!items.contains(item)) {
            items << item;
        }
    }
    return items;
}

QList<QUrl> PhotoListActions::selectionToUrls() const
{
    const auto items = selectionToItems();
    QList<QUrl> urls;
    std::ranges::transform(items, std::back_inserter(urls), [](const auto &item) {
        return item.url();
    });
    return urls;
}

void PhotoListActions::setPhotosApplication(PhotosApplication *photosApplication)
{
    if (photosApplication == m_photosApplication) {
        return;
    }
    Q_ASSERT(!m_photosApplication); // should only be set once
    m_photosApplication = photosApplication;
    Q_EMIT photosApplicationChanged();

    m_moveToTrashAction = photosApplication->action(KStandardActions::name(KStandardActions::MoveToTrash));
    connect(m_moveToTrashAction, &QAction::triggered, this, [this] {
        auto trashJob = KIO::trash(selectionToUrls());
        trashJob->start();
    });

    m_restoreAction = photosApplication->action("photos_restore"_L1);
    connect(m_restoreAction, &QAction::triggered, this, [this] {
        auto restoreJob = KIO::restoreFromTrash(selectionToUrls());
        restoreJob->start();
    });

    m_editAction = photosApplication->action("photos_edit"_L1);
    connect(m_editAction, &QAction::triggered, this, [this] {
        Q_EMIT editRequested(m_selectionModel->currentIndex().data(AbstractImageModel::ImageUrlRole).value<QUrl>());
    });

    setActionState();
}

bool PhotoListActions::isTrashView() const
{
    return m_isTrashView;
}

void PhotoListActions::setTrashView(bool isTrashView)
{
    if (m_isTrashView == isTrashView) {
        return;
    }
    m_isTrashView = isTrashView;
    Q_EMIT isTrashViewChanged();
    setActionState();
}

void PhotoListActions::setActionState()
{
    if (!m_selectionModel || !m_photosApplication) {
        return;
    }

    auto selectedIndexes = m_selectionModel->selectedIndexes();
    if (!selectedIndexes.contains(m_selectionModel->currentIndex())) {
        selectedIndexes << m_selectionModel->currentIndex();
    }

    if (m_isTrashView) {
        m_restoreAction->setVisible(!selectedIndexes.isEmpty());
        m_moveToTrashAction->setVisible(false);
    } else {
        m_restoreAction->setVisible(false);
        m_moveToTrashAction->setVisible(!selectedIndexes.isEmpty());
    }

    if (selectedIndexes.size() > 1) {
        m_editAction->setEnabled(false);
    }
}

#include "moc_photolistactions.cpp"
