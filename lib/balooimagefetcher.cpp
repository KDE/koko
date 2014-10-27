/*
 * <one line to give the library's name and an idea of what it does.>
 * Copyright (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include "balooimagefetcher.h"

#include <Baloo/Query>

#include <QThreadPool>

BalooImageFetcher::BalooImageFetcher(QObject* parent)
    : QObject(parent)
{
}

void BalooImageFetcher::fetchAllImages()
{
    Baloo::Query query;
    query.setType("Image");

    Baloo::QueryRunnable *runnable = new Baloo::QueryRunnable(query);
    connect(runnable, SIGNAL(queryResult(Baloo::QueryRunnable*, Baloo::Result)),
            this, SLOT(queryResult(Baloo::QueryRunnable*, Baloo::Result)), Qt::QueuedConnection);

    QThreadPool::globalInstance()->start(runnable);
}

void BalooImageFetcher::queryResult(Baloo::QueryRunnable*, const Baloo::Result &result)
{
    emit imageFile(result.filePath());
}
