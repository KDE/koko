// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "openfilemodel.h"

OpenFileModel::OpenFileModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_mode(OpenNone)
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
    return parent.isValid() ? 0 : m_fileItems.size();
}

OpenFileModel::Mode OpenFileModel::mode() const
{
    return m_mode;
}

QUrl OpenFileModel::urlToOpen() const
{
    return m_urlToOpen;
}

void OpenFileModel::updateOpenItems(const QList<QUrl> &urls)
{
    beginResetModel();
    m_fileItems.clear();

    for (const QUrl &url : urls) {
        KFileItem fileItem = KFileItem(url);
        fileItem.setDelayedMimeTypes(true);

        m_fileItems.append(fileItem);
    }

    endResetModel();

    Mode mode;
    if (m_fileItems.size() == 0) {
        mode = Mode::OpenNone;
    } else if (m_fileItems.size() == 1) {
        mode = m_fileItems[0].isFile() ? Mode::OpenImage : Mode::OpenFolder;
    } else {
        mode = Mode::OpenMultiple;
    }

    if (m_mode != mode) {
        m_mode = mode;
        Q_EMIT modeChanged();
    }

    QUrl urlToOpen = m_fileItems.size() == 1 ? m_fileItems[0].url() : QUrl();

    if (m_urlToOpen != urlToOpen) {
        m_urlToOpen = urlToOpen;
        Q_EMIT urlToOpenChanged();
    }

    Q_EMIT updated();
}
