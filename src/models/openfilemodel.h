// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "abstractimagemodel.h"
#include <qqmlregistration.h>

// TODO: QML side (Main.qml)

class OpenFileModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(Mode mode READ mode NOTIFY modeChanged)

public:
    explicit OpenFileModel(QObject *parent = nullptr);
    ~OpenFileModel() override;

    enum Mode {
        OpenNone,
        OpenFolder,
        OpenImages
    };
    Q_ENUM(Mode)

    void updateOpenFiles(const QStringList &paths);

    Mode mode();

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

Q_SIGNALS:
    void modeChanged();

protected:
    KFileItemList m_fileItems;

private:
    Mode m_mode;
};
