/*
 * SPDX-FileCopyrightText: (C) 2012-2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "exiv2extractor.h"

#include <KFileMetaData/UserMetaData>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

Exiv2Extractor::Exiv2Extractor(QObject *parent)
    : QObject(parent)
    , m_filePath(QString())
    , m_latitude(0)
    , m_longitude(0)
    , m_height(0)
    , m_width(0)
    , m_size(0)
    , m_model("")
    , m_time("")
    , m_favorite(false)
    , m_rating(0)
    , m_description("")
    , m_tags(QStringList())
    , m_error(false)
{
}

Exiv2Extractor::~Exiv2Extractor()
{
}

QUrl Exiv2Extractor::filePath() const
{
    return QUrl::fromLocalFile(m_filePath);
}

QString Exiv2Extractor::simplifiedPath() const
{
    auto url = filePath();
    QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    if (QUrl::fromLocalFile(home).isParentOf(url)) {
        return QStringLiteral("~") + url.toLocalFile().remove(0, home.length());
    }
    return url.toLocalFile();
}

static QDateTime dateTimeFromString(const QString &dateString)
{
    QDateTime dateTime;

    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy-MM-dd"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd-MM-yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy-MM"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("MM-yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy.MM.dd"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd.MM.yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd MMMM yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("MM.yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy.MM"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, Qt::ISODate);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dddd d MMM yyyy h':'mm':'ss AP"));
        dateTime.setTimeSpec(Qt::LocalTime);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy:MM:dd hh:mm:ss"));
        dateTime.setTimeSpec(Qt::LocalTime);
    }
    if (!dateTime.isValid()) {
        dateTime = QLocale::system().toDateTime(dateString, QLocale::ShortFormat);
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QLocale::system().toDateTime(dateString, QLocale::LongFormat);
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        qWarning() << "Could not determine correct datetime format from:" << dateString;
        return QDateTime();
    }

    return dateTime;
}
static QDateTime toDateTime(const Exiv2::Value &value)
{
    if (value.typeId() == Exiv2::asciiString) {
        QDateTime val = dateTimeFromString(value.toString().c_str());
        if (val.isValid()) {
            // Datetime is stored in exif as local time.
            val.setOffsetFromUtc(0);
            return val;
        }
    }

    return QDateTime();
}

void Exiv2Extractor::updateFavorite(const QString &filePath)
{
    if (!QFileInfo::exists(filePath)) {
        return;
    }

    auto fileMetaData = KFileMetaData::UserMetaData(filePath);

    m_favorite = fileMetaData.hasAttribute("koko.favorite");

    Q_EMIT favoriteChanged();
}

void Exiv2Extractor::toggleFavorite(const QString &filePath)
{
    if (!QFileInfo::exists(filePath)) {
        return;
    }

    auto fileMetaData = KFileMetaData::UserMetaData(filePath);

    if (fileMetaData.hasAttribute("koko.favorite")) {
        fileMetaData.setAttribute("koko.favorite", "");
    } else {
        fileMetaData.setAttribute("koko.favorite", "true");
    }

    m_favorite = fileMetaData.hasAttribute("koko.favorite");

    Q_EMIT favoriteChanged();
}

void Exiv2Extractor::setRating(const int &rating)
{
    if (rating == m_rating) {
        return;
    }

    if (!QFileInfo::exists(m_filePath)) {
        return;
    }

    auto fileMetaData = KFileMetaData::UserMetaData(m_filePath);

    fileMetaData.setRating(rating);

    m_rating = rating;

    Q_EMIT filePathChanged();
}

void Exiv2Extractor::setDescription(const QString &description)
{
    if (description == m_description) {
        return;
    }

    if (!QFileInfo::exists(m_filePath)) {
        return;
    }

    auto fileMetaData = KFileMetaData::UserMetaData(m_filePath);

    fileMetaData.setUserComment(description);

    m_description = description;

    Q_EMIT filePathChanged();
}

void Exiv2Extractor::setTags(const QStringList &tags)
{
    if (tags == m_tags) {
        return;
    }

    if (!QFileInfo::exists(m_filePath)) {
        return;
    }

    auto fileMetaData = KFileMetaData::UserMetaData(m_filePath);

    fileMetaData.setTags(tags);

    m_tags = tags;

    Q_EMIT filePathChanged();
}

void Exiv2Extractor::extract(const QString &filePath)
{
    if (filePath == m_filePath) {
        return;
    }

    // init values
    m_error = false;
    m_latitude = 0.0;
    m_longitude = 0.0;
    m_width = 0;
    m_height = 0;
    m_size = 0;
    m_model = "";
    m_time = "";
    m_favorite = false;
    m_dateTime = QDateTime();
    m_rating = 0;
    m_description = "";
    m_tags = QStringList();
    m_filePath = filePath;

    QByteArray arr = QFile::encodeName(filePath);
    std::string fileString(arr.data(), arr.length());

    Exiv2::LogMsg::setLevel(Exiv2::LogMsg::mute);
#if EXIV2_TEST_VERSION(0, 27, 99)
    Exiv2::Image::UniquePtr image;
#else
    Exiv2::Image::AutoPtr image;
#endif

    QFileInfo file_info(m_filePath);

    if (!QFileInfo::exists(m_filePath)) {
        m_error = true; // only critical error (don't prevent indexing stuff without Exif metadata)
        Q_EMIT filePathChanged();
        Q_EMIT favoriteChanged();
        return;
    }

    m_size = file_info.size();

    auto fileMetaData = KFileMetaData::UserMetaData(m_filePath);

    m_favorite = fileMetaData.hasAttribute("koko.favorite");
    Q_EMIT favoriteChanged();

    m_rating = fileMetaData.rating();
    m_description = fileMetaData.userComment();
    m_tags = fileMetaData.tags();

    try {
        image = Exiv2::ImageFactory::open(fileString);
    } catch (const std::exception &) {
        Q_EMIT filePathChanged();
        return;
    }
    if (!image.get()) {
        Q_EMIT filePathChanged();
        return;
    }

    if (!image->good()) {
        Q_EMIT filePathChanged();
        return;
    }

    try {
        image->readMetadata();
    } catch (const std::exception &) {
        Q_EMIT filePathChanged();
        return;
    }

    const Exiv2::ExifData &data = image->exifData();

    Exiv2::ExifData::const_iterator it = data.findKey(Exiv2::ExifKey("Exif.Photo.DateTimeOriginal"));
    if (it != data.end()) {
        m_dateTime = toDateTime(it->value());
        m_time = QString::fromStdString(it->toString());
    }
    if (m_dateTime.isNull()) {
        it = data.findKey(Exiv2::ExifKey("Exif.Image.DateTime"));
        if (it != data.end()) {
            m_dateTime = toDateTime(it->value());
        }
    }

    it = data.findKey(Exiv2::ExifKey("Exif.Image.Model"));
    if (it != data.end()) {
        m_model = QString::fromStdString(it->toString());
    }

    m_latitude = fetchGpsDouble(data, "Exif.GPSInfo.GPSLatitude");
    m_longitude = fetchGpsDouble(data, "Exif.GPSInfo.GPSLongitude");

    m_height = image->pixelHeight();
    m_width = image->pixelWidth();

    QByteArray latRef = fetchByteArray(data, "Exif.GPSInfo.GPSLatitudeRef");
    if (!latRef.isEmpty() && latRef[0] == 'S')
        m_latitude *= -1;

    QByteArray longRef = fetchByteArray(data, "Exif.GPSInfo.GPSLongitudeRef");
    if (!longRef.isEmpty() && longRef[0] == 'W')
        m_longitude *= -1;

    Q_EMIT filePathChanged();
}

double Exiv2Extractor::fetchGpsDouble(const Exiv2::ExifData &data, const char *name)
{
    Exiv2::ExifData::const_iterator it = data.findKey(Exiv2::ExifKey(name));
    if (it != data.end() && it->count() == 3) {
        double n = 0.0;
        double d = 0.0;

        n = (*it).toRational(0).first;
        d = (*it).toRational(0).second;

        if (d == 0) {
            return 0.0;
        }

        double deg = n / d;

        n = (*it).toRational(1).first;
        d = (*it).toRational(1).second;

        if (d == 0) {
            return deg;
        }

        double min = n / d;
        if (min != -1.0) {
            deg += min / 60.0;
        }

        n = (*it).toRational(2).first;
        d = (*it).toRational(2).second;

        if (d == 0) {
            return deg;
        }

        double sec = n / d;
        if (sec != -1.0) {
            deg += sec / 3600.0;
        }

        return deg;
    }

    return 0.0;
}

QByteArray Exiv2Extractor::fetchByteArray(const Exiv2::ExifData &data, const char *name)
{
    Exiv2::ExifData::const_iterator it = data.findKey(Exiv2::ExifKey(name));
    if (it != data.end()) {
        std::string str = it->value().toString();
        return QByteArray(str.c_str(), str.size());
    }

    return QByteArray();
}

bool Exiv2Extractor::error() const
{
    return m_error;
}
