// Copied from Gwenview: an image viewer
// SPDX-FileCopyrightText: 2009 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KFileItem>
#include <QObject>

class KCoreDirLister;

/**
 * This class is a worker which tries to find the document dir given a root
 * url. This is useful for digital camera cards, which often have a dir
 * hierarchy like this:
 * /DCIM
 *   /FOOBAR
 *     /PICT0001.JPG
 *     /PICT0002.JPG
 *     ...
 *     /PICTnnnn.JPG
 */
class DocumentDirFinder : public QObject
{
    Q_OBJECT
public:
    enum Status {
        NoDocumentFound,
        DocumentDirFound,
        MultipleDirsFound,
    };
    Q_ENUM(Status);

    explicit DocumentDirFinder(const QUrl &rootUrl);
    ~DocumentDirFinder() override;

    void start();

Q_SIGNALS:
    void done(const QUrl &, DocumentDirFinder::Status);
    void protocollNotSupportedError(const QString &errorText);

private Q_SLOTS:
    void slotItemsAdded(const QUrl &, const KFileItemList &);
    void slotCompleted();

private:
    void finish(const QUrl &, Status);

    QUrl mRootUrl;
    KCoreDirLister *mDirLister = nullptr;

    QUrl mFoundDirUrl;
};
