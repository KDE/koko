/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
 */

#include "imagedocument.h"
#include <QFileInfo>
#include <QMatrix>
#include <QUrl>

ImageDocument::ImageDocument()
{
    m_image = new QImage();
    connect(this, &ImageDocument::pathChanged, this, [this](const QString &url) {
        emit resetHandle();
        /** Since the url passed by the model in the ImageViewer.qml contains 'file://' prefix */
        QString location = QUrl(url).path();
        m_image->load(location);
        m_edited = false;
        emit editedChanged();
        emit visualImageChanged();
    });
}

ImageDocument::~ImageDocument()
{
}

QString ImageDocument::path()
{
    return m_path;
}

void ImageDocument::setPath(QString &url)
{
    m_path = url;
    emit pathChanged(url);
}

QImage ImageDocument::visualImage()
{
    return *m_image;
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
    QMatrix matrix;
    matrix.rotate(angle);
    *m_image = m_image->transformed(matrix);
    QString location = QUrl(m_path).path();
    if (QFileInfo(location).isWritable()) {
        m_image->save(location);
    }
    emit visualImageChanged();
}

void ImageDocument::save(QImage image)
{
    QString location = QUrl(m_path).path();
    *m_image = image;
    if (QFileInfo(location).isWritable()) {
        m_image->save(location);
        emit resetHandle();
        m_edited = false;
        emit editedChanged();
    }
    m_image->load(location);
    emit visualImageChanged();
}

void ImageDocument::cancel()
{
    emit resetHandle();
    m_edited = false;
    emit editedChanged();
}

#include "moc_imagedocument.cpp"
