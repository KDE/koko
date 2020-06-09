/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#ifndef KOKO_IMAGEPROCESSORRUNNABLE_H
#define KOKO_IMAGEPROCESSORRUNNABLE_H

#include <QObject>
#include <QRunnable>

namespace Koko
{
class ReverseGeoCoder;

class ImageProcessorRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    ImageProcessorRunnable(QString &filePath, ReverseGeoCoder *coder);
    void run() override;

signals:
    void finished();

private:
    QString m_path;
    ReverseGeoCoder *m_geoCoder;
};
}

#endif // KOKO_IMAGEPROCESSORRUNNABLE_H
