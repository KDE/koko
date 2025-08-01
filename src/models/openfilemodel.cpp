// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "openfilemodel.h"

#include "abstractimagemodel.h"
#include "imagestorage.h"

#include <QMimeDatabase>

OpenFileModel::OpenFileModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_mode(Mode::OpenNone)
{
}

OpenFileModel::~OpenFileModel() = default;

QVariant OpenFileModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &fileItem = m_fileItems[index.row()];
    return dataFromItem(fileItem, role);
}

int OpenFileModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? m_fileItems.size() : 0;
}

void OpenFileModel::updateOpenFiles(const QStringList &paths)
{
    beginResetModel();
    m_fileItems.clear();

    KFileItemList files;
    KFileItemList folders;
    for (const QString &path : paths) {
        KFileItem fileItem = KFileItem(path);
        fileItem.setDelayedMimeTypes(true);

        if (fileItem.isFile()) {
            files.append(fileItem);
        } else {
            folders.append(fileItem);
        }
    }

    if (folders.size() > 0) {
        // Show the folder
        m_mode = Mode::OpenFolder;
        m_fileItems = {folders[0]};
    } else {
        // Show the images
        m_mode = Mode::OpenImages;
        m_fileItems = std::move(files);
    }

    endResetModel();

    Q_EMIT modeChanged();
}

OpenFileModel::Mode OpenFileModel::mode()
{
    return m_mode;
}
