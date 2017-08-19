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

#ifndef IMAGEDOCUMENT_H
#define IMAGEDOCUMENT_H

#include <QImage>

class ImageDocument : public QObject 
{
    Q_OBJECT
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QImage visualImage READ visualImage NOTIFY visualImageChanged)
    Q_PROPERTY(bool edited READ edited NOTIFY editedChanged)
public:
    ImageDocument();
    ~ImageDocument();
    
    QString path();
    void setPath( QString &url);
    
    QImage visualImage();
    
    bool edited();
    
    Q_INVOKABLE void rotate( int angle);
    Q_INVOKABLE void changeBrightness( bool isIncrease);
    Q_INVOKABLE void save();
    Q_INVOKABLE void cancel();
    
signals:
    void pathChanged(const QString &url);
    void visualImageChanged();
    void editedChanged();
    void resetHandle();
    
private:
    QString m_path;
    QImage *m_image;
    QImage m_originalImage;
    bool m_edited;
};

#endif
