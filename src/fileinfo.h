/*
 * SPDX-FileCopyrightText: 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef FILEINFO_H
#define FILEINFO_H

#include <memory>

#include <QObject>
#include <QUrl>

struct FileInfoCacheEntry;

/**
 * An object that provides information about a file.
 *
 * This provides several properties with information about a specified source
 * file.
 *
 * The actual information is cached and shared. This means it is cheap to create
 * multiple instances of this and use them in various places. Information
 * retrieval happens in a background thread and will not block any other thread.
 */
class FileInfo : public QObject
{
    Q_OBJECT

public:
    /**
     * The status of information retrieval.
     */
    enum Status {
        Initial, ///< Initial state, no source has been provided yet.
        Reading, ///< Information retrieval is happening in the background.
        Ready, ///< Information retrieval has finished and we have valid data.
        Error, ///< Information retrieval failed for some reason.
    };
    Q_ENUM(Status)

    /**
     * The type of file.
     */
    enum Type {
        UnknownType, ///< This is an unknown file, we don't recognise it as anything we can display.
        RasterImageType, ///< A static raster image.
        VectorImageType, ///< A vector image.
        AnimatedImageType, ///< An animated raster image.
        VideoType, ///< A video.
    };
    Q_ENUM(Type)

    FileInfo(QObject *parent = nullptr);
    ~FileInfo() override;

    /**
     * The URL of the file to check.
     *
     * Note that only local files are currently supported.
     */
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    QUrl source() const;
    void setSource(const QUrl &newSource);
    Q_SIGNAL void sourceChanged();

    /**
     * The status of information retrieval.
     *
     * \see Status
     */
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Status status() const;
    Q_SIGNAL void statusChanged();

    /**
     * The name of the mime type of the file.
     *
     * If we don't have any information about the file, this will be an empty
     * string.
     */
    Q_PROPERTY(QString mimeType READ mimeType NOTIFY infoChanged)
    QString mimeType() const;

    /**
     * What type of file this is.
     */
    Q_PROPERTY(Type type READ type NOTIFY infoChanged)
    Type type() const;

    /**
     * The width of the file.
     *
     * This will only be retrieved for files that are not of type Video. In those
     * cases, if we have valid information, this will be the width in pixels of
     * the file. Otherwise, this will be -1.
     */
    Q_PROPERTY(int width READ width NOTIFY infoChanged)
    int width() const;

    /**
     * The height of the file.
     *
     * This will only be retrieved for files that are not of type Video. In those
     * cases, if we have valid information, this will be the height in pixels of
     * the file. Otherwise, this will be -1.
     */
    Q_PROPERTY(int height READ height NOTIFY infoChanged)
    int height() const;

    /**
     * Emitted whenever we receive valid data about a file.
     */
    Q_SIGNAL void infoChanged();

private:
    void setStatus(Status newStatus);
    void onCacheUpdated(const QUrl &source);

    QUrl m_source;
    Status m_status = Initial;
    std::shared_ptr<FileInfoCacheEntry> m_info;
};

#endif // FILEINFO_H
