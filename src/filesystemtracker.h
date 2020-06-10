/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef FILESYSTEMTRACKER_H
#define FILESYSTEMTRACKER_H

#include <QObject>
#include <QSet>

class FileSystemTracker : public QObject
{
    Q_OBJECT

public:
    explicit FileSystemTracker(QObject *parent = 0);
    virtual ~FileSystemTracker();

    void setFolder(const QString &folder);
    QString folder() const;

    void setSubFolder(const QString &folder);
    void reindexSubFolder();

    void setupDb();

signals:
    void imageAdded(const QString &filePath);
    void imageRemoved(const QString &filePath);
    void initialScanComplete();
    void subFolderChanged();

protected:
    void removeFile(const QString &filePath);

private slots:
    void slotNewFiles(const QStringList &files);
    void slotImageResult(const QString &filePath);
    void slotFetchFinished();

private:
    QString m_folder;
    QString m_subFolder;
    QSet<QString> m_filePaths;
};

#endif
