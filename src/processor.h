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

#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <QObject>
#include <QStringList>

#include <KFileMetaData/Extractor>
#include <KFileMetaData/ExtractorCollection>

class Processor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(float initialProgress READ initialProgress NOTIFY initialProgressChanged)
public:
    Processor(QObject* parent = 0);
    ~Processor();

    float initialProgress();

signals:
    void initialProgressChanged();

public slots:
    void addFile(const QString& filePath);
    void removeFile(const QString& filePath);

private slots:
    void process();

private:
    QStringList m_files;
    int m_numFiles;
    bool m_processing;

    KFileMetaData::ExtractorCollection m_extractors;
    KFileMetaData::Extractor* m_imageExtractor;
};

#endif // PROCESSOR_H
