/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_IMAGEPROCESSORRUNNABLE_H
#define KOKO_IMAGEPROCESSORRUNNABLE_H

#include <QObject>
#include <QRunnable>
#include <QUrl>

namespace Koko
{
class ReverseGeoCoder;

class ImageProcessorRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    ImageProcessorRunnable(const QUrl &url, ReverseGeoCoder *coder);
    void run() override;

signals:
    void finished(const QUrl &url);

private:
    QUrl m_path;
    ReverseGeoCoder *m_geoCoder;
};
}

#endif // KOKO_IMAGEPROCESSORRUNNABLE_H
