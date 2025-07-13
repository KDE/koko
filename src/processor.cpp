/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "processor.h"
#include "imageprocessorrunnable.h"
#include "imagestorage.h"

#include <QEventLoop>
#include <QFileInfo>
#include <QThreadPool>

using namespace Koko;

Processor::Processor(QObject *parent)
    : QObject(parent)
    , m_numFiles(0)
    , m_processing(false)
    , m_initialScanDone(false)
{
    connect(&m_commitTimer, &CommitTimer::timeout, this, [&]() {
        ImageStorage::instance()->commit();
        if (m_files.isEmpty()) {
            m_geoCoder.deinit();
            if (m_numFiles && m_initialScanDone)
                emit finishedChanged();
        }
    });

    connect(this, &Processor::numFilesChanged, &m_commitTimer, &CommitTimer::start);
}

void Processor::addFile(const QUrl &filePath)
{
    m_files << filePath;
    m_numFiles++;

    QTimer::singleShot(0, this, &Processor::process);
    emit numFilesChanged();
}

void Processor::removeFile(const QUrl &filePath)
{
    ImageStorage::instance()->removeImage(filePath.toLocalFile());
    m_numFiles--;

    emit numFilesChanged();
}

float Processor::initialProgress() const
{
    if (m_numFiles) {
        return 1.0f - (m_files.size() * 1.0f / m_numFiles);
    }

    return 0;
}

int Processor::numFiles() const
{
    return m_numFiles;
}

void Processor::process()
{
    if (m_processing)
        return;

    if (m_files.isEmpty()) {
        return;
    }

    m_processing = true;

    ImageProcessorRunnable *runnable = new ImageProcessorRunnable(m_files.takeLast(), &m_geoCoder);
    connect(runnable, &ImageProcessorRunnable::finished, this, &Processor::slotFinished);

    QThreadPool::globalInstance()->start(runnable);
}

void Processor::slotFinished(const QUrl &url)
{
    m_processing = false;
    QTimer::singleShot(0, this, &Processor::process);

    Q_EMIT initialProgressChanged();
    Q_EMIT fileProcessed(url);
    m_commitTimer.start();
}

void Processor::initialScanCompleted()
{
    m_initialScanDone = true;
    if (m_files.isEmpty()) {
        emit finishedChanged();
    }
}
