// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "photosapplication.h"

#include <KFileItem>
#include <QItemSelectionModel>
#include <QObject>
#include <qqmlregistration.h>

class PhotoListActions : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QItemSelectionModel *selectionModel READ selectionModel WRITE setSelectionModel NOTIFY selectionModelChanged)
    Q_PROPERTY(PhotosApplication *photosApplication READ photosApplication WRITE setPhotosApplication NOTIFY photosApplicationChanged)
    Q_PROPERTY(bool isTrashView READ isTrashView WRITE setTrashView NOTIFY isTrashViewChanged)

public:
    explicit PhotoListActions(QObject *parent = nullptr);

    QItemSelectionModel *selectionModel() const;
    void setSelectionModel(QItemSelectionModel *selectionModel);

    PhotosApplication *photosApplication() const;
    void setPhotosApplication(PhotosApplication *photosApplication);

    bool isTrashView() const;
    void setTrashView(bool isTrashView);

    Q_INVOKABLE void setActionState();

Q_SIGNALS:
    void selectionModelChanged();
    void photosApplicationChanged();
    void isTrashViewChanged();
    void editRequested(const QUrl &imagePath);

private:
    KFileItemList selectionToItems() const;
    QList<QUrl> selectionToUrls() const;

    QItemSelectionModel *m_selectionModel = nullptr;
    PhotosApplication *m_photosApplication = nullptr;

    bool m_isTrashView = false;

    QAction *m_moveToTrashAction = nullptr;
    QAction *m_restoreAction = nullptr;
    QAction *m_editAction = nullptr;
};
