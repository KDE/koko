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

#include "processor.h"
#include "imagestorage.h"
#include "imageprocessorrunnable.h"

#include <QFileInfo>
#include <QEventLoop>
#include <QThreadPool>

using namespace Koko;

Processor::Processor(QObject* parent)
    : QObject(parent)
    , m_numFiles(0)
    , m_processing(false)
{
    m_commitTimer.setInterval(10000);
    connect(&m_commitTimer, &QTimer::timeout, [&]() {
        ImageStorage::instance()->commit();
    });
    m_commitTimer.start();
}


Processor::~Processor()
{

}

void Processor::addFile(const QString& filePath)
{
    m_files << filePath;
    m_numFiles++;

    QTimer::singleShot(0, this, SLOT(process()));
}

void Processor::removeFile(const QString& filePath)
{
    Q_UNUSED(filePath);
    // FIXME: Implement this!
}

float Processor::initialProgress()
{
    if (m_numFiles) {
        return 1.0 - (m_files.size() * 1.0 / m_numFiles);
    }

    return 0;
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

    ImageProcessorRunnable* runnable = new ImageProcessorRunnable(path);
    connect(runnable, SIGNAL(finished()), this, SLOT(slotFinished()));

    QThreadPool::globalInstance()->start(runnable);
}

void Processor::slotFinished()
{
    m_processing = false;
    QTimer::singleShot(0, this, SLOT(process()));

    emit initialProgressChanged();
}
