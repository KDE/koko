// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "imagestorage.h"

#include <QAbstractListModel>
#include <qqmlregistration.h>

#include <KFileItem>
#include <kio_version.h>

class QTimer;

/*!
 * Abstract model for images
 */
class AbstractImageModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Abstract type")

    Q_PROPERTY(bool leading READ loading NOTIFY loadingChanged FINAL)
public:
    enum RoleNames {
        ImageUrlRole = Qt::UserRole + 1,
        MimeTypeRole,
        ItemTypeRole,
        FilesRole,
        FileCountRole,
        DateRole,
        SelectedRole,
        ContentRole,
        ItemRole,
    };
    Q_ENUM(RoleNames);

    enum ItemType {
        Image,
        Folder,
        Collection,
    };
    Q_ENUM(ItemType);

    ~AbstractImageModel() = default;

    QHash<int, QByteArray> roleNames() const override;

    QVariant dataFromItem(const KFileItem &item, int role) const;

    /**
     * Returns true if we are still loading content
     * This is used to avoid showing content that will be moved by the sort filter
     */
    virtual bool loading() const;

Q_SIGNALS:
    void loadingChanged();

protected:
    explicit AbstractImageModel(QObject *parent = nullptr);
};
