/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "imagedocument.h"
#include <QMatrix>
#include <QUrl>
#include <QFileInfo>
#include <QDebug>

ImageDocument::ImageDocument()
{
    connect(this, &ImageDocument::pathChanged,
            this, [this] (const QString &url) {
                Q_EMIT resetHandle();
                /** Since the url passed by the model in the ImageViewer.qml contains 'file://' prefix */
                const QString location = QUrl(url).path();
                m_undoImages.append(QImage(location));
                m_edited = false;
                Q_EMIT editedChanged();
                Q_EMIT visualImageChanged();
            });
}

ImageDocument::~ImageDocument()
{
}

QString ImageDocument::path()
{
    return m_path;
}

void ImageDocument::setPath(QString& url)
{
    m_path = url;
    emit pathChanged(url);
}

QImage ImageDocument::visualImage()
{
    return m_undoImages.last();
}

bool ImageDocument::edited()
{
    return m_edited;
}

void ImageDocument::setEdited(bool value)
{
    m_edited = value;
    emit editedChanged();
}

void ImageDocument::rotate(int angle)
{
    QTransform tranform;
    tranform.rotate(angle);
    setEdited(true);
    m_undoImages.append(m_undoImages.last().transformed(tranform,  Qt::FastTransformation));
    Q_EMIT visualImageChanged();
}

void ImageDocument::crop(int x, int y, int width, int height)
{
    const QRect rect(x, y, width, height);
    setEdited(true);
    m_undoImages.append(m_undoImages.last().copy(rect));
    Q_EMIT visualImageChanged();
}

void ImageDocument::save()
{
    QString location = QUrl(m_path).path();

    if(QFileInfo(location).isWritable()) {
        m_undoImages.last().save(location);
        Q_EMIT resetHandle();
        setEdited(false);
        Q_EMIT visualImageChanged();
    } else {
        // TODO add user warning so that they can save the image in another location.
    }
}

void ImageDocument::saveAs()
{
    // TODO
}


void ImageDocument::undo()
{
    Q_ASSERT(m_undoImages.count() > 1);
    m_undoImages.pop_back();

    if (m_undoImages.count() == 1) {
        setEdited(false);
    }

    Q_EMIT visualImageChanged();
}

void ImageDocument::cancel()
{
    while (m_undoImages.count() > 1) {
        m_undoImages.pop_back();
    }
    Q_EMIT resetHandle();
    m_edited = false;
    Q_EMIT editedChanged();
}

#include "moc_imagedocument.cpp"
