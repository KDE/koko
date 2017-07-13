/*
 *   Copyright 2017 by Marco Martin <mart@kde.org>
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
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

#ifndef IMAGEFOLDERMODEL_H
#define IMAGEFOLDERMODEL_H

#include <QSize>
#include <kdirmodel.h>
#include <QVariant>

class QTimer;

/**
 * This class provides a QML binding to KDirModel
 * Provides an easy way to navigate a filesystem from within QML
 *
 * @author Marco Martin <mart@kde.org>
 */
class ImageFolderModel : public KDirModel
{
    Q_OBJECT

    /**
     * @property string The url we want to browse. it may be an absolute path or a correct url of any protocol KIO supports
     */
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)

    /**
     * @property count Total number of rows
     */
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    ImageFolderModel(QObject* parent=0);
    virtual ~ImageFolderModel();

    QHash<int, QByteArray> roleNames() const override;

    void setUrl(const QString& url);
    QString url() const;

    QVariant data(const QModelIndex &index, int role) const;
    int count() const {return rowCount();}

    Q_INVOKABLE int indexForUrl(const QString &url) const;

    Q_INVOKABLE QVariantMap get(int index) const;

    /**
      * Helper method to empty the trash
      */
    Q_INVOKABLE void emptyTrash();

Q_SIGNALS:
    void countChanged();
    void urlChanged();
    void showImageViewer(const QString &path);

private:
    QStringList m_mimeTypes;
    QString m_imagePath;
};

#endif // IMAGEFOLDERMODEL_H
