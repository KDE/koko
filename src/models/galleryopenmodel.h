/*
 *  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include <KDirLister>

#include "abstractnavigablegallerymodel.h"

/*!
 * Singleton model for content requested to be displayed in Koko via command-line
 * arguments or 'Open With'
 */
class GalleryOpenModel : public AbstractNavigableGalleryModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(Mode mode READ mode NOTIFY modeChanged)
    Q_PROPERTY(QUrl urlToOpen READ urlToOpen NOTIFY urlToOpenChanged)

public:
    explicit GalleryOpenModel(QObject *parent = nullptr);

    enum Mode {
        OpenNone, // Nothing specified
        OpenFolder, // Show provided folder
        OpenImage, // Show provided image
        OpenMultiple, // Show multiple items
    };
    Q_ENUM(Mode)

    Mode mode() const;
    QUrl urlToOpen() const;

    void updateOpenItems(const QList<QUrl> &urls);

    QString title() const override;
    Status status() const override;

    QString titleForPath(const QVariant &path) const override;

    QVariant path() const override;
    void setPath(const QVariant &path) override;

    Q_INVOKABLE QVariant pathForIndex(const QModelIndex &index) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    bool requiresFiltering() const override
    {
        return true;
    };

Q_SIGNALS:
    void modeChanged();
    void urlToOpenChanged();

    void updated();

private:
    void populate(const QStringList &path);

    enum GalleryMode {
        Root,
        Directory
    };

    Mode m_mode;
    QList<QUrl> m_openUrls;
    QUrl m_urlToOpen;

    Status m_status;
    GalleryMode m_galleryMode;
    QStringList m_path;

    KFileItemList m_rootFileItems;
    KFileItemList m_fileItems;

    KDirLister *m_dirLister;
};
