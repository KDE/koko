/*
 * Copyright (C) 2014  Vishesh Handa <me@vhanda.in>
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

#ifndef _FILESYSTEMTRACKER_H
#define _FILESYSTEMTRACKER_H

#include <QObject>
#include <QSet>

class FileSystemTracker : public QObject
{
    Q_OBJECT
public:
    explicit FileSystemTracker(QObject* parent = 0);
    virtual ~FileSystemTracker();

    void setFolder(const QString& folder);
    QString folder() const;

signals:
    void imageAdded(const QString& filePath);
    void imageRemoved(const QString& filePath);
    void initialScanComplete();

private slots:
    void init();
    void slotImageResult(const QString& filePath);
    void slotFetchFinished();

private:
    QString m_folder;
    QSet<QString> m_filePaths;
};

#endif
