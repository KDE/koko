/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGEFOLDERMODEL_H
#define IMAGEFOLDERMODEL_H

#include <QSize>
#include <QVariant>
#include <kdirmodel.h>

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
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)

    /**
     * @property count Total number of rows
     */
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit ImageFolderModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;

    void setUrl(QUrl &url);
    QUrl url() const;

    QVariant data(const QModelIndex &index, int role) const override;
    int count() const
    {
        return rowCount();
    }

    Q_INVOKABLE int indexForUrl(const QString &url) const;

    Q_INVOKABLE QVariantMap get(int index) const;

    /**
     * Helper method to empty the trash
     */
    Q_INVOKABLE void emptyTrash();

    void jobFinished();

Q_SIGNALS:
    void countChanged();
    void urlChanged();
    void finishedLoading();

private:
    QStringList m_mimeTypes;
    QString m_imagePath;
};

#endif // IMAGEFOLDERMODEL_H
