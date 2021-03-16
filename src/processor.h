/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <QObject>
#include <QStringList>

#include "committimer.h"
#include "reversegeocoder.h"

namespace Koko
{
class Processor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(float initialProgress READ initialProgress NOTIFY initialProgressChanged)
    Q_PROPERTY(int numFiles READ numFiles NOTIFY numFilesChanged)
    Q_PROPERTY(bool finished READ finished NOTIFY finishedChanged)
public:
    explicit Processor(QObject *parent = nullptr);
    ~Processor() = default;

    float initialProgress() const;
    int numFiles() const;

    bool finished() const
    {
        return m_initialScanDone;
    }

signals:
    void initialProgressChanged();
    void numFilesChanged();
    void finishedChanged();

public slots:
    Q_INVOKABLE void addFile(const QString &filePath);
    Q_INVOKABLE void removeFile(const QString &filePath);
    void initialScanCompleted();

private slots:
    void process();
    void slotFinished();

private:
    QStringList m_files;
    int m_numFiles;
    bool m_processing;

    CommitTimer m_commitTimer;
    ReverseGeoCoder m_geoCoder;
    bool m_initialScanDone;
};

}
#endif // PROCESSOR_H
