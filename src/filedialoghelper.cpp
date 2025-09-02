/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "filedialoghelper.h"

#include <QImageWriter>
#include <QMimeDatabase>

FileDialogHelper::FileDialogHelper(QObject *parent)
    : QObject(parent)
    , m_selectedNameFilterIndex(-1)
{
    const auto mimeTypesNames = QImageWriter::supportedMimeTypes();
    m_nameFilters.reserve(mimeTypesNames.size());

    std::transform(mimeTypesNames.begin(), mimeTypesNames.end(), std::back_inserter(m_nameFilters), [](const QByteArray &mimeTypeName) {
        const QMimeType mimeType = QMimeDatabase().mimeTypeForName(QString::fromUtf8(mimeTypeName));
        return QStringLiteral("%1 (%2)").arg(mimeType.comment(), mimeType.globPatterns().join(QLatin1Char(' ')));
    });
}

QStringList FileDialogHelper::nameFilters() const
{
    return m_nameFilters;
}

void FileDialogHelper::setSelectedFile(const QString &selectedFile)
{
    if (m_selectedFile != selectedFile) {
        m_selectedFile = selectedFile;
        Q_EMIT selectedFileChanged();

        updateSelectedNameFilterIndex();
    }
}

QString FileDialogHelper::selectedFile() const
{
    return m_selectedFile;
}

int FileDialogHelper::selectedNameFilterIndex() const
{
    return m_selectedNameFilterIndex;
}

void FileDialogHelper::updateSelectedNameFilterIndex()
{
    const auto mimeType = QMimeDatabase().mimeTypeForFile(m_selectedFile, QMimeDatabase::MatchExtension);
    const int selectedNameFilterIndex =
        nameFilters().indexOf(QStringLiteral("%1 (%2)").arg(mimeType.comment(), mimeType.globPatterns().join(QLatin1Char(' '))));

    if (m_selectedNameFilterIndex != selectedNameFilterIndex) {
        m_selectedNameFilterIndex = selectedNameFilterIndex;
        Q_EMIT selectedNameFilterIndexChanged();
    }
}
