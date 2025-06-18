// SPDX-FileCopyrightText: 2007 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <memory>

namespace Exiv2
{
class Image;
}

// Local

class QByteArray;
class QString;

struct Exiv2ImageLoaderPrivate;

/**
 * This helper class loads image using libexiv2, and takes care of exception
 * handling for the different versions of libexiv2.
 */
class Exiv2ImageLoader
{
public:
    Exiv2ImageLoader();
    ~Exiv2ImageLoader();

    bool load(const QString &);
    bool load(const QByteArray &);
    QString errorMessage() const;
    std::unique_ptr<Exiv2::Image> popImage();

private:
    std::unique_ptr<Exiv2ImageLoaderPrivate> d;
};
