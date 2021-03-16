// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <exiv2/exiv2.hpp>

class ImageInfo : public QObject
{
    Q_PROPERTY(QString filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
public:
    explicit ImageInfo(QObject *parent = nullptr);
    ~ImageInfo();

    QString filePath() const;
    void setFilePath(const QString &filePath);

Q_SIGNALS:
    void filePathChanged();

private:
    QString m_filePath;
    Exiv2::ExifData m_data;
};
