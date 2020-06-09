/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
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

    QString path();
    void setPath(QString &url);

    QImage visualImage();

    bool edited();
    void setEdited(bool value);

    Q_INVOKABLE void rotate(int angle);
    Q_INVOKABLE void save(QImage image);
    Q_INVOKABLE void cancel();

signals:
    void pathChanged(const QString &url);
    void visualImageChanged();
    void editedChanged();
    void resetHandle();

private:
    QString m_path;
    QImage *m_image;
    bool m_edited;
};

#endif
