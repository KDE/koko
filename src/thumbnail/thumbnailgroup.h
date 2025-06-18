// Copied from Gwenview
// SPDX-FileCopyrightText: 2008 Aurélien Gâteau <agateau@kde.org>
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

enum class ThumbnailGroup {
    Normal,
    Large,
    XLarge,
    XXLarge,
};

inline int pixelSize(const ThumbnailGroup value)
{
    switch (value) {
    case ThumbnailGroup::Normal:
        return 128;
    case ThumbnailGroup::Large:
        return 256;
    case ThumbnailGroup::XLarge:
        return 512;
    case ThumbnailGroup::XXLarge:
        return 1024;
    default:
        return 128;
    }
}

inline ThumbnailGroup fromPixelSize(int value)
{
    if (value <= 128) {
        return ThumbnailGroup::Normal;
    } else if (value <= 256) {
        return ThumbnailGroup::Large;
    } else if (value <= 512) {
        return ThumbnailGroup::XLarge;
    } else {
        return ThumbnailGroup::XXLarge;
    }
}
