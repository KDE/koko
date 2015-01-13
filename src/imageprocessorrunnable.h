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

#ifndef KOKO_IMAGEPROCESSORRUNNABLE_H
#define KOKO_IMAGEPROCESSORRUNNABLE_H

#include <QRunnable>
#include <QObject>

namespace Koko {

class ReverseGeoCoder;

class ImageProcessorRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    ImageProcessorRunnable(QString& filePath, ReverseGeoCoder* coder);
    virtual void run();

signals:
    void finished();

private:
    QString m_path;
    ReverseGeoCoder* m_geoCoder;
};
}

#endif // KOKO_IMAGEPROCESSORRUNNABLE_H
