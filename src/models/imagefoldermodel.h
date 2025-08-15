/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGEFOLDERMODEL_H
#define IMAGEFOLDERMODEL_H

#include "abstractimagemodel.h"
#include <QSize>
#include <QVariant>
#include <qqmlregistration.h>

class QTimer;
class KDirModel;

/**
 * This class provides a QML binding to KDirModel
 * Provides an easy way to navigate a filesystem from within QML
 *
 * @author Marco Martin <mart@kde.org>
 */
class ImageFolderModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT

    /**
     * @property string The url we want to browse. it may be an absolute path or a correct url of any protocol KIO supports
     */
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged FINAL) // push up?

public:
    explicit ImageFolderModel(QObject *parent = nullptr);

    void setUrl(const QUrl &url);
    QUrl url() const;

    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    bool loading() const;

    Q_INVOKABLE int indexForUrl(const QString &url) const;

    Q_INVOKABLE QVariantMap get(int index) const;

    /**
     * Helper method to empty the trash
     */
    Q_INVOKABLE void emptyTrash();

Q_SIGNALS:
    void urlChanged();
    void loadingChanged();

private:
    KDirModel *const m_dirModel;
    KFileItemList m_items;

    QStringList m_mimeTypes;
    QString m_imagePath;
};

#endif // IMAGEFOLDERMODEL_H
