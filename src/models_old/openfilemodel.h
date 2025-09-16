// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <qqmlregistration.h>

#include "abstractimagemodel.h"

class OpenFileModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(Mode mode READ mode NOTIFY modeChanged)
    Q_PROPERTY(QUrl urlToOpen READ urlToOpen NOTIFY urlToOpenChanged)

public:
    explicit OpenFileModel(QObject *parent = nullptr);
    ~OpenFileModel() override;

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
