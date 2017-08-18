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

ImageDocument::ImageDocument()
{
    m_image = new QImage();
    connect( this, &ImageDocument::pathChanged, 
             this, [this] (const QString &url) { 
                 /** Since the url passed by the model in the ImageViewer.qml contains 'file://' prefix */
                 QString location = QUrl( url).path();
                 m_image->load( location);
                 emit visualImageChanged();
            });
}

ImageDocument::~ImageDocument()
{
    delete m_image;
}

QString ImageDocument::path()
{
    return m_path;
}

void ImageDocument::setPath(QString& url)
{
    m_path = url;
    emit pathChanged( url);
}

QImage ImageDocument::visualImage()
{
    return *m_image;
}

void ImageDocument::rotate(int angle)
{
    QMatrix matrix;
    matrix.rotate( angle);
    *m_image = m_image->transformed( matrix);
    QString location = QUrl( m_path).path();
    if (QFileInfo( location).isWritable()) {
        m_image->save( location);
    }
    
    emit visualImageChanged();
}

#include "moc_imagedocument.cpp"
