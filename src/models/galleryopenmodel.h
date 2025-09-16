/*
 *  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include "abstractgallerymodel.h"

// TODO: Base on Navigable model -- so we can navigate to subfolders with OpenMultiple
// So Mode becomes None, Folder, Media, or Collection

/*!
 * Model for content requested to be displayed in Koko
 */
class GalleryOpenModel : public AbstractGalleryModel
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

protected:
    KFileItemList m_fileItems;

private:
    Mode m_mode;
    QUrl m_urlToOpen;
};
