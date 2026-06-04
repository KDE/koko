/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "abstractgallerymodel.h"

#include "gallerysortfilterproxymodel.h"

using namespace Qt::StringLiterals;

AbstractGalleryModel::ImageRoles sortModeToRole(const GallerySortFilterProxyModel::SortMode sortMode)
{
    switch (sortMode) {
    default:
    case GallerySortFilterProxyModel::Name:
        return AbstractGalleryModel::ImageRoles::NameRole;
    case GallerySortFilterProxyModel::Size:
        return AbstractGalleryModel::ImageRoles::SizeRole;
    case GallerySortFilterProxyModel::Modified:
        return AbstractGalleryModel::ImageRoles::ModifiedRole;
    case GallerySortFilterProxyModel::Created:
        return AbstractGalleryModel::ImageRoles::CreatedRole;
    case GallerySortFilterProxyModel::Accessed:
        return AbstractGalleryModel::ImageRoles::AccessedRole;
    }
}

GallerySortFilterProxyModel::GallerySortFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_sortBehavior(Natural)
    , m_sortMode(Name)
    , m_filterString(QString())
{
    m_collator.setNumericMode(true);
    m_collator.setCaseSensitivity(Qt::CaseInsensitive);

    setFilterCaseSensitivity(Qt::CaseInsensitive);
    setSortRole(sortModeToRole(m_sortMode));
    sort(0, Qt::AscendingOrder);
}

GallerySortFilterProxyModel::SortBehavior GallerySortFilterProxyModel::sortBehavior() const
{
    return m_sortBehavior;
}

void GallerySortFilterProxyModel::setSortBehavior(const SortBehavior sortBehavior)
{
    if (m_sortBehavior == sortBehavior) {
        return;
    }

    m_sortBehavior = sortBehavior;
    Q_EMIT sortBehaviorChanged();

    m_collator.setCaseSensitivity(m_sortBehavior == AlphabeticalCaseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive);

    invalidate();
}

GallerySortFilterProxyModel::SortMode GallerySortFilterProxyModel::sortMode() const
{
    return m_sortMode;
}

void GallerySortFilterProxyModel::setSortMode(const SortMode sortMode)
{
    if (m_sortMode == sortMode) {
        return;
    }

    m_sortMode = sortMode;
    Q_EMIT sortModeChanged();

    setSortRole(sortModeToRole(m_sortMode));
    sort(0, sortOrder());
}

bool GallerySortFilterProxyModel::sortReversed() const
{
    return sortOrder() == Qt::DescendingOrder;
}

void GallerySortFilterProxyModel::setSortReversed(const bool sortReversed)
{
    if (sortReversed == (sortOrder() == Qt::DescendingOrder)) {
        return;
    }

    sort(0, sortReversed ? Qt::DescendingOrder : Qt::AscendingOrder);
    Q_EMIT sortReversedChanged();
}

QString GallerySortFilterProxyModel::filterString() const
{
    return m_filterString;
}

void GallerySortFilterProxyModel::setFilterString(const QString &filterString)
{
    if (m_filterString == filterString) {
        return;
    }

    m_filterString = filterString;
    Q_EMIT filterStringChanged();

    setFilterFixedString(filterString);
}

bool GallerySortFilterProxyModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    auto sort_role = sortRole();

    const auto itemTypeLeft = source_left.data(AbstractGalleryModel::ItemTypeRole).value<AbstractGalleryModel::ItemType>();
    const auto itemTypeRight = source_right.data(AbstractGalleryModel::ItemTypeRole).value<AbstractGalleryModel::ItemType>();

    // n.b. We do not define how we might sort collections, because they do not appear mixed with folders or images. The sort order would be
    // unstable if they did. The assertion handles and documents this case. If this assumption changes, then we need to think harder about
    // the following sorting code (probably, Collections then Folders then Images).
    Q_ASSERT((itemTypeLeft == AbstractGalleryModel::ItemType::Collection) == (itemTypeRight == AbstractGalleryModel::ItemType::Collection));

    if (itemTypeLeft == AbstractGalleryModel::ItemType::Collection) {
        // For collections, sort by DisplayRole
        QVariant leftData = source_left.data(Qt::DisplayRole);
        QVariant rightData = source_right.data(Qt::DisplayRole);
        return QVariant::compare(leftData, rightData) < 0;
    }

    // Sort folders before images
    if (itemTypeLeft == AbstractGalleryModel::ItemType::Folder && itemTypeRight != AbstractGalleryModel::ItemType::Folder) {
        return true;
    } else if (itemTypeLeft != AbstractGalleryModel::ItemType::Folder && itemTypeRight == AbstractGalleryModel::ItemType::Folder) {
        return false;
    }

    if (sort_role == AbstractGalleryModel::ImageRoles::NameRole || sort_role == Qt::DisplayRole) {
        const int result = stringCompare(source_left.data(sort_role).toString(), source_right.data(sort_role).toString(), m_collator);
        if (result != 0) {
            return (sortOrder() == Qt::AscendingOrder) ? result < 0 : result > 0;
        }
    }

    return QSortFilterProxyModel::lessThan(source_left, source_right);
}

// The following is borrowed from Dolphin's KFileItemModel, so sorting matches

bool isAsciiDigit(QChar c)
{
    return c >= QLatin1Char('0') && c <= QLatin1Char('9');
}

Qt::strong_ordering orderingFromInt(int result)
{
    if (result < 0) {
        return Qt::strong_ordering::less;
    }

    if (result > 0) {
        return Qt::strong_ordering::greater;
    }

    return Qt::strong_ordering::equivalent;
}

int orderingToInt(Qt::strong_ordering ordering)
{
    if (ordering < 0) {
        return -1;
    }

    if (ordering > 0) {
        return 1;
    }

    return 0;
}

Qt::strong_ordering compareDigitStrings(const QString &a, const QString &b)
{
    int firstSignificantA = 0;
    while (firstSignificantA < a.length() && a.at(firstSignificantA) == QLatin1Char('0')) {
        ++firstSignificantA;
    }

    int firstSignificantB = 0;
    while (firstSignificantB < b.length() && b.at(firstSignificantB) == QLatin1Char('0')) {
        ++firstSignificantB;
    }

    const int significantLengthA = a.length() - firstSignificantA;
    const int significantLengthB = b.length() - firstSignificantB;
    if (significantLengthA != significantLengthB) {
        return significantLengthA < significantLengthB ? Qt::strong_ordering::less : Qt::strong_ordering::greater;
    }

    for (int i = 0; i < significantLengthA; ++i) {
        const QChar digitA = a.at(firstSignificantA + i);
        const QChar digitB = b.at(firstSignificantB + i);
        if (digitA != digitB) {
            return digitA < digitB ? Qt::strong_ordering::less : Qt::strong_ordering::greater;
        }
    }

    return Qt::strong_ordering::equivalent;
}

Qt::strong_ordering compareFractionalDigitStrings(const QString &a, const QString &b)
{
    const int length = std::max(a.length(), b.length());
    for (int i = 0; i < length; ++i) {
        const QChar digitA = i < a.length() ? a.at(i) : QLatin1Char('0');
        const QChar digitB = i < b.length() ? b.at(i) : QLatin1Char('0');
        if (digitA != digitB) {
            return digitA < digitB ? Qt::strong_ordering::less : Qt::strong_ordering::greater;
        }
    }

    return Qt::strong_ordering::equivalent;
}

int findDigitRunEnd(const QString &text, int start)
{
    int end = start;
    while (end < text.length() && isAsciiDigit(text.at(end))) {
        ++end;
    }

    return end;
}

int countNumericChainSegments(const QString &text, int start, int *chainEnd)
{
    int end = findDigitRunEnd(text, start);
    int segmentCount = 1;

    while (end + 1 < text.length() && text.at(end) == QLatin1Char('.') && isAsciiDigit(text.at(end + 1))) {
        end = findDigitRunEnd(text, end + 1);
        ++segmentCount;
    }

    if (chainEnd) {
        *chainEnd = end;
    }

    return segmentCount;
}

Qt::strong_ordering compareNumericChains(const QString &a, int startA, int endA, int segmentCountA, const QString &b, int startB, int endB, int segmentCountB)
{
    if (segmentCountA == 2 && segmentCountB == 2) {
        const int dotA = findDigitRunEnd(a, startA);
        const int dotB = findDigitRunEnd(b, startB);

        const Qt::strong_ordering integerResult = compareDigitStrings(a.mid(startA, dotA - startA), b.mid(startB, dotB - startB));
        if (integerResult != 0) {
            return integerResult;
        }

        return compareFractionalDigitStrings(a.mid(dotA + 1, endA - dotA - 1), b.mid(dotB + 1, endB - dotB - 1));
    }

    int segmentStartA = startA;
    int segmentStartB = startB;

    while (true) {
        const int segmentEndA = findDigitRunEnd(a, segmentStartA);
        const int segmentEndB = findDigitRunEnd(b, segmentStartB);

        const Qt::strong_ordering segmentResult =
            compareDigitStrings(a.mid(segmentStartA, segmentEndA - segmentStartA), b.mid(segmentStartB, segmentEndB - segmentStartB));
        if (segmentResult != 0) {
            return segmentResult;
        }

        const bool hasNextSegmentA = segmentEndA < endA;
        const bool hasNextSegmentB = segmentEndB < endB;
        if (!hasNextSegmentA || !hasNextSegmentB) {
            if (hasNextSegmentA != hasNextSegmentB) {
                return hasNextSegmentA ? Qt::strong_ordering::greater : Qt::strong_ordering::less;
            }

            return Qt::strong_ordering::equivalent;
        }

        segmentStartA = segmentEndA + 1;
        segmentStartB = segmentEndB + 1;
    }
}

int findExtensionSeparator(const QString &text)
{
    for (int i = text.length() - 1; i > 0; --i) {
        if (text.at(i) != QLatin1Char('.')) {
            continue;
        }

        if (isAsciiDigit(text.at(i - 1)) && i + 1 < text.length() && isAsciiDigit(text.at(i + 1))) {
            continue;
        }

        return i;
    }

    return -1;
}

Qt::strong_ordering decimalAwareNaturalCompare(const QString &a, const QString &b, const QCollator &collator)
{
    bool comparedNumericTokens = false;
    int indexA = 0;
    int indexB = 0;

    while (indexA < a.length() && indexB < b.length()) {
        if (isAsciiDigit(a.at(indexA)) && isAsciiDigit(b.at(indexB))) {
            comparedNumericTokens = true;
            int chainEndA = indexA;
            const int segmentCountA = countNumericChainSegments(a, indexA, &chainEndA);
            int chainEndB = indexB;
            const int segmentCountB = countNumericChainSegments(b, indexB, &chainEndB);

            const Qt::strong_ordering numericResult = compareNumericChains(a, indexA, chainEndA, segmentCountA, b, indexB, chainEndB, segmentCountB);
            indexA = chainEndA;
            indexB = chainEndB;
            if (numericResult != 0) {
                return numericResult;
            }

            continue;
        }

        int textEndA = indexA;
        while (textEndA < a.length() && !isAsciiDigit(a.at(textEndA))) {
            ++textEndA;
        }

        int textEndB = indexB;
        while (textEndB < b.length() && !isAsciiDigit(b.at(textEndB))) {
            ++textEndB;
        }

        const Qt::strong_ordering textResult = orderingFromInt(collator.compare(a.mid(indexA, textEndA - indexA), b.mid(indexB, textEndB - indexB)));
        if (textResult != 0) {
            return orderingFromInt(collator.compare(a.mid(indexA), b.mid(indexB)));
        }

        indexA = textEndA;
        indexB = textEndB;
    }

    const Qt::strong_ordering remainderResult = orderingFromInt(collator.compare(a.mid(indexA), b.mid(indexB)));
    if (remainderResult != 0) {
        return remainderResult;
    }

    if (!comparedNumericTokens) {
        return Qt::strong_ordering::equivalent;
    }

    const Qt::strong_ordering result = orderingFromInt(QString::compare(a, b, collator.caseSensitivity()));
    if (result != 0 || collator.caseSensitivity() == Qt::CaseSensitive) {
        return result;
    }

    return orderingFromInt(QString::compare(a, b, Qt::CaseSensitive));
}

int GallerySortFilterProxyModel::stringCompare(const QString &a, const QString &b, const QCollator &collator) const
{
    if (m_sortBehavior == Natural) {
        const int aExtensionSeparator = findExtensionSeparator(a);
        const int bExtensionSeparator = findExtensionSeparator(b);
        const int aBaseNameLength = aExtensionSeparator < 0 ? a.length() : aExtensionSeparator;
        const int bBaseNameLength = bExtensionSeparator < 0 ? b.length() : bExtensionSeparator;

        const int res = orderingToInt(decimalAwareNaturalCompare(a.left(aBaseNameLength), b.left(bBaseNameLength), collator));
        if (res != 0 || (aExtensionSeparator < 0 && bExtensionSeparator < 0)) {
            return res;
        }

        // baseNames were equal, sort by extension
        return orderingToInt(decimalAwareNaturalCompare(a.mid(aBaseNameLength), b.mid(bBaseNameLength), collator));
    }

    const int result = QString::compare(a, b, collator.caseSensitivity());
    if (result != 0 || collator.caseSensitivity() == Qt::CaseSensitive) {
        // Only return the result, if the strings are not equal. If they are equal by a case insensitive
        // comparison, still a deterministic sort order is required. A case sensitive
        // comparison is done as fallback.
        return result;
    }

    return QString::compare(a, b, Qt::CaseSensitive);
}
