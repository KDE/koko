// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QDebug>
#include <QSignalSpy>
#include <QTest>

#include <QImage>
#include <QTemporaryFile>

#include "fileinfo.h"

class FileInfoTest : public QObject
{
    Q_OBJECT

private slots:
    void testSimple();
    void testCache();
};

void FileInfoTest::testSimple()
{
    QImage empty({1, 1}, QImage::Format_RGB32);
    empty.fill(QColor(0, 0, 0));
    QTemporaryFile file(QStringLiteral("XXXXXX.png"));
    if (file.open()) {
        empty.save(file.fileName(), "PNG");
        FileInfo fileInfo;
        QCOMPARE(fileInfo.status(), FileInfo::Status::Initial);
        fileInfo.setSource(QUrl::fromLocalFile(file.fileName()));
        QCOMPARE(fileInfo.status(), FileInfo::Status::Reading);

        QSignalSpy spy(&fileInfo, &FileInfo::infoChanged);
        spy.wait();

        QCOMPARE(fileInfo.status(), FileInfo::Status::Ready);
        QCOMPARE(fileInfo.mimeType(), QStringLiteral("image/png"));
        QCOMPARE(fileInfo.width(), 1);
        QCOMPARE(fileInfo.height(), 1);
    }
}

void FileInfoTest::testCache()
{
    QImage empty({1, 1}, QImage::Format_RGB32);
    empty.fill(QColor(0, 0, 0));
    QTemporaryFile file(QStringLiteral("XXXXXX.png"));
    QTemporaryFile file1(QStringLiteral("XXXXXX.png"));
    if (file.open() && file1.open()) {
        empty.save(file.fileName(), "PNG");
        empty.save(file1.fileName(), "PNG");

        FileInfo fileInfo;
        QCOMPARE(fileInfo.status(), FileInfo::Status::Initial);
        fileInfo.setSource(QUrl::fromLocalFile(file.fileName()));
        QCOMPARE(fileInfo.status(), FileInfo::Status::Reading);

        // request first image
        QSignalSpy spy(&fileInfo, &FileInfo::infoChanged);
        spy.wait();
        QCOMPARE(fileInfo.status(), FileInfo::Status::Ready);

        // request second image
        fileInfo.setSource(QUrl::fromLocalFile(file1.fileName()));
        QCOMPARE(fileInfo.status(), FileInfo::Status::Reading);
        spy.wait();
        QCOMPARE(fileInfo.status(), FileInfo::Status::Ready);

        // back original file
        fileInfo.setSource(QUrl::fromLocalFile(file.fileName()));
        // still ready because cached
        QCOMPARE(fileInfo.status(), FileInfo::Status::Ready);
    }
}

QTEST_MAIN(FileInfoTest)

#include "fileinfotest.moc"
