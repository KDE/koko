/*
 * Copyright (C) 2015  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef FILESYSTEMIMAGEFETCHER_H
#define FILESYSTEMIMAGEFETCHER_H

#include <QObject>
#include "koko_export.h"

class KOKO_EXPORT FileSystemImageFetcher : public QObject
{
    Q_OBJECT
public:
    explicit FileSystemImageFetcher(const QString& folder, QObject* parent = 0);
    void fetch();

signals:
    void imageResult(const QString& filePath);
    void finished();

private slots:
    void slotProcess();

private:
    QString m_folder;
};

#endif // FILESYSTEMIMAGEFETCHER_H
