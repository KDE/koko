/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

/*
 * Helper for providing name filters to a QML FileDialog via supported mimetypes in
 * QImageWriter, as well as selecting the correct name filter for the selected file.
 *
 * If FileDialog were to support MIME filters directly, and did not need a specified
 * index to start with, but would pick it up from the selected file, this would not
 * be necessary.
 */

#pragma once

#include <QObject>
#include <qqmlintegration.h>

class FileDialogHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QStringList nameFilters READ nameFilters CONSTANT)
    Q_PROPERTY(QString selectedFile READ selectedFile WRITE setSelectedFile NOTIFY selectedFileChanged)
    Q_PROPERTY(int selectedNameFilterIndex READ selectedNameFilterIndex NOTIFY selectedNameFilterIndexChanged)

public:
    explicit FileDialogHelper(QObject *parent = nullptr);

    QStringList nameFilters() const;

    void setSelectedFile(const QString &selectedFile);
    QString selectedFile() const;

    int selectedNameFilterIndex() const;

Q_SIGNALS:
    void selectedFileChanged();
    void selectedNameFilterIndexChanged();

private:
    void updateSelectedNameFilterIndex();

    QString m_selectedFile;
    QStringList m_nameFilters;
    int m_selectedNameFilterIndex;
};
