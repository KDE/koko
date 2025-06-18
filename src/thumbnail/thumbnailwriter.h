// Copied from Gwenview
// SPDX-FileCopyrightText: 2000 David Faure <faure@kde.org>
// SPDX-FileCopyrightText: 2012 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QHash>
#include <QMutex>
#include <QThread>

class QImage;

/**
 * Store thumbnails to disk when done generating them
 */
class ThumbnailWriter : public QThread
{
    Q_OBJECT
public:
    // Return thumbnail if it has still not been stored
    QImage value(const QString &) const;

    bool isEmpty() const;

public Q_SLOTS:
    void queueThumbnail(const QString &, const QImage &);

protected:
    void run() override;

private:
    using Cache = QHash<QString, QImage>;
    Cache mCache;
    mutable QMutex mMutex;
};
