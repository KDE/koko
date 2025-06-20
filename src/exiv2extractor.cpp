/*
 * SPDX-FileCopyrightText: (C) 2012-2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "exiv2extractor.h"

#include "kokoconfig.h"

#include <KFileItem>
#include <KFileMetaData/UserMetaData>

#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QSize>
#include <QStandardPaths>

#include <KLocalizedString>

using namespace Qt::StringLiterals;

Exiv2Extractor::Exiv2Extractor(QObject *parent)
    : QAbstractListModel(parent)
    , m_filePath(QString())
    , m_latitude(0)
    , m_longitude(0)
    , m_height(0)
    , m_width(0)
    , m_favorite(false)
    , m_rating(0)
    , m_tags(QStringList())
    , m_error(false)
{
}

Exiv2Extractor::~Exiv2Extractor() = default;

QHash<int, QByteArray> Exiv2Extractor::roleNames() const
{
    return {
        {Qt::DisplayRole, "displayName"},
        {LabelRole, "label"},
        {KeyRole, "key"},
        {GroupRole, "group"},
        {EnabledRole, "enabledRole"},
    };
}

int Exiv2Extractor::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.count();
}

QVariant Exiv2Extractor::data(const QModelIndex &index, int role) const
{
    const auto &entry = m_entries.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
        return entry.value;
    case LabelRole:
        return entry.label;
    case KeyRole:
        return entry.key;
    case GroupRole:
        switch (entry.group) {
        case GroupRow::GeneralGroup:
            return i18nc("@title:group", "General");
        case GroupRow::ExifGroup:
            return i18nc("@title:group", "EXIF");
        case GroupRow::IptcGroup:
            return i18nc("@title:group", "IPTC");
        case GroupRow::XmpGroup:
            return i18nc("@title:group", "XMPP");
        default:
            return {};
        }
    case EnabledRole:
        return Config::self()->metadataToDisplay().contains(entry.key);
    default:
        return {};
    }
}

QUrl Exiv2Extractor::filePath() const
{
    return QUrl::fromLocalFile(m_filePath);
}

static QDateTime dateTimeFromString(const QString &dateString)
{
    QDateTime dateTime;

    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy-MM-dd"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd-MM-yyyy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy-MM"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("MM-yyyy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy.MM.dd"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd.MM.yyyy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd MMMM yyyy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("MM.yyyy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy.MM"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yy"));
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, Qt::ISODate);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dddd d MMM yyyy h':'mm':'ss AP"));
        dateTime.setTimeZone(QTimeZone::LocalTime);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy:MM:dd hh:mm:ss"));
        dateTime.setTimeZone(QTimeZone::LocalTime);
    }
    if (!dateTime.isValid()) {
        dateTime = QLocale::system().toDateTime(dateString, QLocale::ShortFormat);
        dateTime.setTimeZone(QTimeZone::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QLocale::system().toDateTime(dateString, QLocale::LongFormat);
        dateTime.setTimeZone(QTimeZone::UTC);
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
        QDateTime val = dateTimeFromString(QString::fromStdString(value.toString()));
        if (val.isValid()) {
            // Datetime is stored in exif as local time.
            val.setTimeZone(QTimeZone::UTC);
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
    m_favorite = false;
    m_dateTime = QDateTime();
    m_rating = 0;
    m_description = {};
    m_tags = {};
    m_filePath = filePath;
    m_item = KFileItem(QUrl::fromLocalFile(m_filePath));

    QByteArray arr = QFile::encodeName(filePath);
    std::string fileString(arr.data(), arr.length());

    Exiv2::LogMsg::setLevel(Exiv2::LogMsg::mute);
    Exiv2::Image::UniquePtr image;

    QFileInfo file_info(m_filePath);

    if (!QFileInfo::exists(m_filePath)) {
        m_error = true; // only critical error (don't prevent indexing stuff without Exif metadata)
        Q_EMIT filePathChanged();
        Q_EMIT favoriteChanged();
        return;
    }

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
    }
    if (m_dateTime.isNull()) {
        it = data.findKey(Exiv2::ExifKey("Exif.Image.DateTime"));
        if (it != data.end()) {
            m_dateTime = toDateTime(it->value());
        }
    }

    {
        QImage img(m_filePath);
        if (!img.isNull()) {
            m_height = img.size().height();
            m_width = img.size().width();
        }
    }

    beginResetModel();
    m_entries.clear();
    initGeneralGroup(m_item);

    m_latitude = fetchGpsDouble(data, "Exif.GPSInfo.GPSLatitude");
    m_longitude = fetchGpsDouble(data, "Exif.GPSInfo.GPSLongitude");

    QByteArray latRef = fetchByteArray(data, "Exif.GPSInfo.GPSLatitudeRef");
    if (!latRef.isEmpty() && latRef[0] == 'S')
        m_latitude *= -1;

    QByteArray longRef = fetchByteArray(data, "Exif.GPSInfo.GPSLongitudeRef");
    if (!longRef.isEmpty() && longRef[0] == 'W')
        m_longitude *= -1;

    if (m_latitude != 0.0 && m_longitude != 0.0) { // Hopefulyl no one took a real photo on the null inland
        m_entries << MetaInfoEntry{GroupRow::GeneralGroup,
                                   u"General.Location"_s,
                                   i18nc("@item:intable", "Location"),
                                   QString::number(m_latitude) + u'x' + QString::number(m_longitude)};
    }

    initExiv2Image(image.get());

    endResetModel();

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

static QString formatFileTime(const KFileItem &item, const KFileItem::FileTimes timeType)
{
    return QLocale().toString(item.time(timeType), QLocale::ShortFormat);
}

template<class Container, class Iterator>
QList<MetaInfoEntry> fillExivGroup(GroupRow groupRow, const Container &container, const Exiv2::ExifData &exifData)
{
    // key aren't always unique (for example, "Iptc.Application2.Keywords"
    // may appear multiple times) so we can't know how many rows we will
    // insert before going through them. That's why we create a hash
    // before.
    using EntryHash = QHash<QString, MetaInfoEntry>;
    EntryHash hash;

    Iterator it = container.begin(), end = container.end();

    for (; it != end; ++it) {
        try {
            // Skip metadatum if its tag is an hex number
            if (it->tagName().substr(0, 2) == "0x") {
                continue;
            }
            const QString key = QString::fromStdString(it->key());
            const QString label = QString::fromStdString(it->tagLabel());
            std::ostringstream stream;
            it->write(stream, &exifData);
            const QString value = QString::fromStdString(stream.str());

            EntryHash::iterator hashIt = hash.find(key);
            if (hashIt != hash.end()) {
                hashIt->value += value;
            } else {
                hash.insert(key, MetaInfoEntry(groupRow, key, label, value));
            }
        } catch (const std::out_of_range &error) {
            // Workaround for https://bugs.launchpad.net/ubuntu/+source/exiv2/+bug/1942799
            // which was fixed with https://github.com/Exiv2/exiv2/pull/1918/commits/8a1e949bff482f74599f60b8ab518442036b1834
            qWarning() << "Failed to read some meta info:" << error.what();
        } catch (const Exiv2::Error &error) {
            qWarning() << "Failed to read some meta info:" << error.what();
        }
    }

    if (hash.isEmpty()) {
        return {};
    }

    const QList<MetaInfoEntry> entries(hash.cbegin(), hash.cend());
    return entries;
}

void Exiv2Extractor::initGeneralGroup(const KFileItem &item)
{
    const QString modifiedString = formatFileTime(item, KFileItem::ModificationTime);
    const QString accessString = formatFileTime(item, KFileItem::AccessTime);

    const QSize size(m_width, m_height);
    QString imageSize;
    if (size.isValid()) {
        imageSize = i18nc("@item:intable %1 is image width, %2 is image height", "%1x%2", QString::number(size.width()), QString::number(size.height()));

        double megaPixels = size.width() * size.height() / 1000000.;
        if (megaPixels > 0.1) {
            const QString megaPixelsString = QString::number(megaPixels, 'f', 1);
            imageSize += u' ';
            imageSize += i18nc("@item:intable %1 is number of millions of pixels in image", "(%1MP)", megaPixelsString);
        }
    } else {
        imageSize = QLatin1Char('-');
    }

    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.Name"_s, i18nc("@item:intable Image file name", "Name"), item.name()};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.Size"_s, i18nc("@item:intable", "File Size"), KIO::convertSize(item.size())};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup,
                               u"General.Created"_s,
                               i18nc("@item:intable", "Date Created"),
                               QLocale().toString(m_dateTime, QLocale::ShortFormat)};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.Modified"_s, i18nc("@item:intable", "Date Modified"), modifiedString};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.Accessed"_s, i18nc("@item:intable", "Date Accessed"), accessString};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.LocalPath"_s, i18nc("@item:intable", "Path"), item.localPath()};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.ImageSize"_s, i18nc("@item:intable", "Image Size"), imageSize};
    m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.MimeType"_s, i18nc("@item:intable", "File Type"), item.mimetype()};
}

void Exiv2Extractor::initExiv2Image(const Exiv2::Image *image)
{
    if (!image) {
        return;
    }

    const auto comment = QString::fromUtf8(image->comment().c_str());
    if (!comment.isEmpty()) {
        m_entries << MetaInfoEntry{GroupRow::GeneralGroup, u"General.Comment"_s, i18nc("@item:intable", "Comment"), comment};
    }

    const Exiv2::ExifData &exifData = image->exifData();
    if (image->checkMode(Exiv2::mdExif) & Exiv2::amRead) {
        m_entries.append(fillExivGroup<Exiv2::ExifData, Exiv2::ExifData::const_iterator>(GroupRow::ExifGroup, exifData, exifData));
    }

    if (image->checkMode(Exiv2::mdIptc) & Exiv2::amRead) {
        const Exiv2::IptcData &iptcData = image->iptcData();
        m_entries.append(fillExivGroup<Exiv2::IptcData, Exiv2::IptcData::const_iterator>(GroupRow::IptcGroup, iptcData, exifData));
    }

    if (image->checkMode(Exiv2::mdXmp) & Exiv2::amRead) {
        const Exiv2::XmpData &xmpData = image->xmpData();
        m_entries.append(fillExivGroup<Exiv2::XmpData, Exiv2::XmpData::const_iterator>(GroupRow::XmpGroup, xmpData, exifData));
    }
}

ExivFilterModel::ExivFilterModel()
{
    connect(Config::self(), &Config::MetadataToDisplayChanged, this, &ExivFilterModel::invalidate);
}
