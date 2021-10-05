/*
 * SPDX-FileCopyrightText: 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "fileinfo.h"

#include <optional>

#include <QGlobalStatic>
#include <QImageReader>
#include <QMetaObject>
#include <QMimeDatabase>
#include <QRunnable>
#include <QThreadPool>

struct FileInfoCacheEntry {
    QUrl source;
    QString mimeType;
    FileInfo::Type type = FileInfo::UnknownType;
    int width = -1;
    int height = -1;
};

/**
 * To make FileInfo objects cheap to use from QML, we cache the information it
 * uses in a separate structure. This allows FileInfo to quickly lookup and
 * retrieve information if we have already analyzed a file before. If not, we
 * use a background job to retrieve the actual information so we do not block
 * any other thread with potentially expensive file operations.
 */
class FileInfoCache : public QObject
{
    Q_OBJECT
public:
    FileInfoCache();

    std::shared_ptr<FileInfoCacheEntry> get(const QUrl &url);

    void read(const QUrl &url);
    void readingFinished(const QUrl &url, std::shared_ptr<FileInfoCacheEntry> entry);

    Q_SIGNAL void cacheUpdated(const QUrl &url);

    QThreadPool threadPool;
    QHash<QUrl, std::shared_ptr<FileInfoCacheEntry>> cache;
};

Q_GLOBAL_STATIC(FileInfoCache, cache);

class FileInfoRunnable : public QRunnable
{
public:
    QUrl source;

    void run() override
    {
        auto entry = std::make_shared<FileInfoCacheEntry>();
        entry->source = source;

        QMimeDatabase db;
        auto mimeType = db.mimeTypeForFile(source.toLocalFile(), QMimeDatabase::MatchContent);

        if (!mimeType.isValid()) {
            // Mime type is not valid, so either the source does not exist or we
            // don't have permission to read it. In any case, we cannot retrieve
            // information for this file, so abort.

            // Make a local copy of the source variable so we don't need to
            // capture "this" which will be destroyed after it completes.
            auto s = source;

            QMetaObject::invokeMethod(
                cache(),
                [s]() {
                    cache()->readingFinished(s, nullptr);
                },
                Qt::QueuedConnection);
            return;
        }

        auto mimeTypeName = mimeType.name();
        entry->mimeType = mimeTypeName;

        if (mimeTypeName.startsWith(QStringLiteral("video/")) || //
            mimeTypeName == QStringLiteral("application/x-matroska")) {
            entry->type = FileInfo::VideoType;
        } else if (mimeTypeName.startsWith(QStringLiteral("image/svg"))) {
            entry->type = FileInfo::VectorImageType;
        } else if (mimeTypeName == QStringLiteral("image/gif")) {
            entry->type = FileInfo::AnimatedImageType;
        } else if (mimeTypeName.startsWith(QStringLiteral("image/"))) {
            entry->type = FileInfo::RasterImageType;
        }

        if (entry->type != FileInfo::VideoType) {
            QImageReader reader(source.toLocalFile());
            auto size = reader.size();
            if (size.isValid()) {
                entry->width = size.width();
                entry->height = size.height();
            } else {
                auto image = reader.read();
                entry->width = image.width();
                entry->height = image.height();
            }
        }

        QMetaObject::invokeMethod(
            cache(),
            [entry]() {
                cache()->readingFinished(entry->source, entry);
            },
            Qt::QueuedConnection);
    }
};

FileInfoCache::FileInfoCache()
    : QObject(nullptr)
{
    // Since the runnable is mostly IO bound, there is not really any reason to
    // execute more than one of it in parallel.
    threadPool.setMaxThreadCount(1);
}

std::shared_ptr<FileInfoCacheEntry> FileInfoCache::get(const QUrl &url)
{
    if (!url.isValid()) {
        return nullptr;
    }

    if (cache.contains(url)) {
        return cache.value(url);
    }

    return nullptr;
}

void FileInfoCache::read(const QUrl &url)
{
    auto runnable = new FileInfoRunnable;
    runnable->source = url;
    threadPool.start(runnable);
}

void FileInfoCache::readingFinished(const QUrl &source, std::shared_ptr<FileInfoCacheEntry> entry)
{
    if (entry) {
        cache.insert(source, entry);
    }
    Q_EMIT cacheUpdated(source);
}

FileInfo::FileInfo(QObject *parent)
    : QObject(parent)
{
    connect(cache(), &FileInfoCache::cacheUpdated, this, &FileInfo::onCacheUpdated);
}

FileInfo::~FileInfo() = default;

QUrl FileInfo::source() const
{
    return m_source;
}

void FileInfo::setSource(const QUrl &source)
{
    if (m_source == source) {
        return;
    }

    m_source = source;
    Q_EMIT sourceChanged();

    auto result = cache()->get(source);
    if (!result) {
        setStatus(Reading);
        cache()->read(source);
        return;
    }

    m_info = result;
    Q_EMIT infoChanged();

    setStatus(Ready);
}

FileInfo::Status FileInfo::status() const
{
    return m_status;
}

QString FileInfo::mimeType() const
{
    if (!m_info) {
        return QString{};
    }

    return m_info->mimeType;
}

FileInfo::Type FileInfo::type() const
{
    if (!m_info) {
        return UnknownType;
    }

    return m_info->type;
}

int FileInfo::width() const
{
    if (!m_info) {
        return -1;
    }

    return m_info->width;
}

int FileInfo::height() const
{
    if (!m_info) {
        return -1;
    }

    return m_info->height;
}

void FileInfo::setStatus(FileInfo::Status newStatus)
{
    if (newStatus == m_status) {
        return;
    }

    m_status = newStatus;
    Q_EMIT statusChanged();
}

void FileInfo::onCacheUpdated(const QUrl &source)
{
    if (source != m_source) {
        return;
    }

    auto result = cache->get(source);
    if (result) {
        m_info = result;
        Q_EMIT infoChanged();

        setStatus(Ready);
    } else {
        setStatus(Error);
    }
}

#include "fileinfo.moc"
