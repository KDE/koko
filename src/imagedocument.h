/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 *   Copyright 2020 by Carl Schwan <carl@carlschwan.eu>
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
    Q_PROPERTY(bool edited READ edited WRITE setEdited NOTIFY editedChanged)
    
public:
    ImageDocument();
    ~ImageDocument();
    
    QString path() const;
    void setPath(const QString &url);
    
    QImage visualImage() const;
    
    bool edited() const;
    void setEdited(bool value);

    /**
     * Rotate the image.
     * @param angle The angle of the rotation in degree.
     */
    Q_INVOKABLE void rotate(int angle);

    /**
     * Mirrror the image.
     * @param horizonal Mirror the image horizontally.
     * @param vertical Mirror the image vertically.
     */
    Q_INVOKABLE void mirror(bool horizontal, bool vertical);
    
    /**
     * Crop the image.
     * @param x The x coordinate of the new image in the old image.
     * @param y The y coordinate of the new image in the old image.
     * @param width The width of the new image.
     * @param height The height of the new image.
     */
    Q_INVOKABLE void crop(int x, int y, int width, int height);

    /**
     * Undo the last edit on the images.
     */
    Q_INVOKABLE void undo();

    /**
     * Cancel all the edit.
     */
    Q_INVOKABLE void cancel();

    /**
     * Save current edited image in place. This is a destructive operation and can't be reverted.
     * @return true iff the file saving operattion was successful.
     */
    Q_INVOKABLE bool save();

    /**
     * Save current edited image as a new image.
     * @param location The location where to save the new image.
     * @return true iff the file saving operattion was successful.
     */
    Q_INVOKABLE bool saveAs(const QUrl &location);

signals:
    void pathChanged(const QString &url);
    void visualImageChanged();
    void editedChanged();
    void resetHandle();
    
private:
    QString m_path;
    QVector<QImage> m_undoImages;
    bool m_edited;
};

#endif
