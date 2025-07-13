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
#include <QUrl>

class FileSystemTracker : public QObject
{
    Q_OBJECT

public:
    explicit FileSystemTracker(QObject *parent = nullptr);
    virtual ~FileSystemTracker();

    void setFolder(const QString &folder);
    QString folder() const;

    void setSubFolder(const QString &folder);
    void reindexSubFolder();

    void fileProcessed(const QUrl &file);

    void setupDb();

signals:
    void imageAdded(const QUrl &filePath);
    void imageRemoved(const QUrl &filePath);
    void initialScanComplete();
    void subFolderChanged();

protected:
    void removeFile(const QUrl &filePath);

private slots:
    void slotNewFiles(const QStringList &files);
    void slotImageResult(const QUrl &filePath);
    void slotFetchFinished();

private:
    QString m_folder;
    QString m_subFolder;

    // Path currently found and getting processed
    QSet<QUrl> m_processingPaths;
    QSet<QUrl> m_filePaths;
};

#endif
