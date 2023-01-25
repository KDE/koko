// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "openfilemodel.h"

#include "roles.h"
#include <QMimeDatabase>

OpenFileModel::OpenFileModel(const QStringList &images, QObject *parent)
    : QAbstractListModel(parent)
    , m_images(images)
{
}

QHash<int, QByteArray> OpenFileModel::roleNames() const
{
    return Roles::roleNames();
}

QVariant OpenFileModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const int indexValue = index.row();

    switch (role) {
    case Roles::ContentRole:
        // TODO: return the filename component
        return m_images.at(indexValue);

    case Roles::ImageUrlRole:
        return m_images.at(indexValue);

    case Roles::ItemTypeRole:
        return Types::Image;

    case Roles::MimeTypeRole: {
        QMimeDatabase db;
        QMimeType type = db.mimeTypeForFile(m_images.at(indexValue));
        return type.name();
    }

    case Roles::SelectedRole:
        return false;
    }

    return {};
}

int OpenFileModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_images.size();
}

void OpenFileModel::updateOpenFiles(const QStringList &images)
{
    if (!images.isEmpty()) {
        beginResetModel();
        m_images = images;
        endResetModel();
        Q_EMIT urlToOpenChanged();
        Q_EMIT updatedImages();
    }
}

QString OpenFileModel::urlToOpen() const
{
    if (m_images.length() == 1) {
        return m_images.value(0);
    }
    return QString();
}
