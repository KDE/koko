/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "processor.h"
#include "imageprocessorrunnable.h"
#include "imagestorage.h"

#include <QDebug>
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
    connect(&m_commitTimer, &CommitTimer::timeout, [&]() {
        ImageStorage::instance()->commit();
        if (m_files.isEmpty()) {
            m_geoCoder.deinit();
            if (m_numFiles && m_initialScanDone)
                emit finishedChanged();
        }
    });

    connect(this, &Processor::numFilesChanged, &m_commitTimer, &CommitTimer::start);
}

Processor::~Processor()
{
}

void Processor::addFile(const QString &filePath)
{
    m_files << filePath;
    m_numFiles++;

    QTimer::singleShot(0, this, SLOT(process()));
    emit numFilesChanged();
}

void Processor::removeFile(const QString &filePath)
{
    ImageStorage::instance()->removeImage(filePath);
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
    QString path = m_files.takeLast();

    ImageProcessorRunnable *runnable = new ImageProcessorRunnable(path, &m_geoCoder);
    connect(runnable, SIGNAL(finished()), this, SLOT(slotFinished()));

    QThreadPool::globalInstance()->start(runnable);
}

void Processor::slotFinished()
{
    m_processing = false;
    QTimer::singleShot(0, this, SLOT(process()));

    emit initialProgressChanged();
    m_commitTimer.start();
}

void Processor::initialScanCompleted()
{
    m_initialScanDone = true;
    if (m_files.isEmpty()) {
        emit finishedChanged();
    }
}
