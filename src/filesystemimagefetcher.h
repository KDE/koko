/*
 * SPDX-FileCopyrightText: (C) 2012-2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef FILESYSTEMIMAGEFETCHER_H
#define FILESYSTEMIMAGEFETCHER_H

#include "koko_export.h"
#include <QObject>

class KOKO_EXPORT FileSystemImageFetcher : public QObject
{
    Q_OBJECT
public:
    explicit FileSystemImageFetcher(const QString &folder, QObject *parent = 0);
    void fetch();

signals:
    void imageResult(const QString &filePath);
    void finished();

private slots:
    void slotProcess();

private:
    QString m_folder;
};

#endif // FILESYSTEMIMAGEFETCHER_H
